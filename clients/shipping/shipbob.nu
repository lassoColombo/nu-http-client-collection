# Auto-generated client for API Reference v1.0.0
# Source: https://raw.githubusercontent.com/api-evangelist/shipbob/main/openapi/shipbob-openapi.json
# Auth: --token flag or $env.API_REFERENCE_TOKEN

const BASE_URL = "https://api.shipbob.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o API_REFERENCE_TOKEN | default "" }
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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def base-url-completer [] { ["https://api.shipbob.com" "https://sandbox-api.shipbob.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sales-channel-completer [] { ["amazon" "bigcommerce" "ebay" "faire" "macy" "magento" "shein" "shopify" "squarespace" "targetplus" "temu" "tiktok" "unleashed" "walmart" "woocommerce"] }
def type-completer [] { ["B2B" "DTC" "DropShip"] }
def type-id-completer [] { ["1" "2"] }
def status-completer [] { ["1" "2" "3"] }
def box-packaging-type-completer [] { ["EverythingInOneBox" "MultipleSkuPerBox" "OneSkuPerBox"] }
def package-type-completer [] { ["FloorLoadedContainer" "Package" "Pallet"] }
def sort-order-completer [] { ["Ascending" "Descending"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "2026-01-channel get-channels" } } | get name | first)
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

# Get Channels
#
# GET /2026-01/channel
# operationId: get-channels
export def "2026-01-channel get-channels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --RecordsPerPage: int # The number of records to return per page. This parameter is used for pagination. If not provided, a default value will be used. (default: 50)
  --Cursor: string # A cursor for pagination. This parameter is used to fetch the next set of results.
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<items: table<application_name: string, id: int, name: string, scopes: list>, next: string, prev: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "RecordsPerPage" $RecordsPerPage "scalar") (serialize-qp "Cursor" $Cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2026-01/channel" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Order
#
# POST /2026-01/order
# operationId: create-order
# --financials shape: {total_price?: float}
# --recipient shape: {address: any, email?: string, name: string, phone_number?: string}
# --retailer_program_data shape: {addresses?: list, customer_ticket_number?: string, delivery_date?: string, department?: string, doNotShipBeforeDate?: string, mark_for_store?: string, purchase_order_number?: string, retailer_program_type?: string, shipByDate?: string}
# --shipping_terms shape: {carrier_type?: "Parcel"|"Freight", payment_term?: "Collect"|"ThirdParty"|"Prepaid"|"MerchantResponsible"}
# --tags item shape: {name: string, value: string}
export def "2026-01-order create-order" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --shipbob-channel-id: string # Retrieve your channel ID from the [GET /channel](/api/channels/get-channels) endpoint. Use the channel ID that has write scopes.
  --financials: record # shape: {total_price?: float}
  --gift-message: string # Gift message associated with the order (nullable)
  --location-id: int # Desired Fulfillment Center Location ID. If not specified, ShipBob will determine the location that fulfills this order. (nullable)
  --order-number: string # User friendly orderId or store order number that will be shown on the Orders Page. If not provided, referenceId will be used (nullable)
  --origin-platform-program: string # Origin platform program for the order. Accepts a program name. (nullable)
  products: list # Products included in the order. Products identified by reference_id must also include the product name if there is no matching ShipBob product.
  --purchase-date: string # Date this order was purchase by the end user (nullable, format: date-time)
  recipient: record # Information about the recipient of an order — shape: {address: any, email?: string, name: string, phone_number?: string}
  reference_id: string # Unique and immutable order identifier from your upstream system
  --retailer-program-data: record # Contains properties that needs to be used for fulfilling B2B/Dropship orders. — shape: {addresses?: list, customer_ticket_number?: string, delivery_date?: string, department?: string, doNotShipBeforeDate?: string, mark_for_store?: string, purchase_order_number?: string, retailer_program_type?: string, shipByDate?: string}
  --sales-channel: string@sales-channel-completer
  shipping_method: string # Client-defined shipping method matching what the user has listed as the shipping method on the Ship Option Mapping setup page in the ShipBob Merchant Portal. If they don’t match, we will create a new one and default it to Standard
  --shipping-terms: record # Contains shipping properties that need to be used for fulfilling an order. — shape: {carrier_type?: "Parcel"|"Freight", payment_term?: "Collect"|"ThirdParty"|"Prepaid"|"MerchantResponsible"}
  --tags: list # Key value pair array to store extra information at the order level for API purposes. ShipBob won't display the info in the ShipBob Merchant Portal or react based on this data. (nullable) — item shape: {name: string, value: string}
  type: string@type-completer
]: any -> record<channel: record<id: int, name: string>, created_date: string, financials: record<total_price: float>, gift_message: string, id: int, order_number: string, products: table<external_line_id: int, gtin: string, id: int, quantity: int, quantity_unit_of_measure_code: string, reference_id: string, sku: string, unit_price: float, upc: string>, purchase_date: string, recipient: record<address: any, email: string, name: string, phone_number: string>, reference_id: string, retailer_program_data: record<addresses: list<record>, customer_ticket_number: string, delivery_date: string, department: string, doNotShipBeforeDate: string, mark_for_store: string, purchase_order_number: string, retailer_program_type: string, shipByDate: string>, shipments: table<actual_fulfillment_date: string, created_date: string, delivery_date: string, estimated_fulfillment_date: string, estimated_fulfillment_date_status: string, gift_message: string, id: int, insurance_value: float, invoice_amount: float, invoice_currency_code: string, is_tracking_uploaded: bool, last_tracking_update_at: string, last_update_at: string, location: record, measurements: record, order_id: int, package_material_type: string, parent_cartons: list, products: list, recipient: record, reference_id: string, require_signature: bool, ship_option: string, status: string, status_details: list, tracking: record>, shipping_method: string, shipping_terms: record<carrier_type: string, payment_term: string>, status: string, tags: table<name: string, value: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2026-01/order")
  let body = {financials: $financials, gift_message: $gift_message, location_id: $location_id, order_number: $order_number, origin_platform_program: $origin_platform_program, products: $products, purchase_date: $purchase_date, recipient: $recipient, reference_id: $reference_id, retailer_program_data: $retailer_program_data, sales_channel: $sales_channel, shipping_method: $shipping_method, shipping_terms: $shipping_terms, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "shipbob_channel_id": $shipbob_channel_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Orders
#
# GET /2026-01/order
# operationId: get-orders
export def "2026-01-order get-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Page: int # Page of orders to get
  --Limit: int # Amount of orders per page to request
  --IDs: string # order ids to filter by, comma separated <br /><strong>Example:</strong> ?IDs=1,2
  --ReferenceIds: string # Reference ids to filter by, comma separated <br /><strong>Example:</strong> ?ReferenceIds=Ref1,Ref2
  --StartDate: string # Start date to filter orders inserted later than (format: date-time)
  --EndDate: string # End date to filter orders inserted earlier than (format: date-time)
  --SortOrder: string # Order to sort results in
  --HasTracking: string@bool-completer # Has any portion of this order been assigned a tracking number
  --LastUpdateStartDate: string # Start date to filter orders updated later than (format: date-time)
  --LastUpdateEndDate: string # End date to filter orders updated later than (format: date-time)
  --IsTrackingUploaded: string@bool-completer # Filter orders that their tracking information was fully uploaded
  --LastTrackingUpdateStartDate: string # Start date to filter orders with tracking updates later than the supplied date. Will only return orders that have tracking information (format: date-time)
  --LastTrackingUpdateEndDate: string # End date to filter orders updated later than the supplied date. Will only return orders that have tracking information (format: date-time)
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --shipbob-channel-id: string # Retrieve your channel ID from the [GET /channel](/api/channels/get-channels) endpoint. Use the channel ID that has write scopes.
]: nothing -> table<channel: record<id: int, name: string>, created_date: string, financials: record<total_price: float>, gift_message: string, id: int, order_number: string, products: list<record>, purchase_date: string, recipient: record<address: any, email: string, name: string, phone_number: string>, reference_id: string, retailer_program_data: record<addresses: list, customer_ticket_number: string, delivery_date: string, department: string, doNotShipBeforeDate: string, mark_for_store: string, purchase_order_number: string, retailer_program_type: string, shipByDate: string>, shipments: list<record>, shipping_method: string, shipping_terms: record<carrier_type: string, payment_term: string>, status: string, tags: list<record>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Page" $Page "scalar") (serialize-qp "Limit" $Limit "scalar") (serialize-qp "IDs" $IDs "scalar") (serialize-qp "ReferenceIds" $ReferenceIds "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "SortOrder" $SortOrder "scalar") (serialize-qp "HasTracking" $HasTracking "scalar") (serialize-qp "LastUpdateStartDate" $LastUpdateStartDate "scalar") (serialize-qp "LastUpdateEndDate" $LastUpdateEndDate "scalar") (serialize-qp "IsTrackingUploaded" $IsTrackingUploaded "scalar") (serialize-qp "LastTrackingUpdateStartDate" $LastTrackingUpdateStartDate "scalar") (serialize-qp "LastTrackingUpdateEndDate" $LastTrackingUpdateEndDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2026-01/order" $qp)
  let extra_headers = {"Authorization": $Authorization, "shipbob_channel_id": $shipbob_channel_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Order
#
# GET /2026-01/order/{orderId}
# operationId: get-order
export def "2026-01-order get-order" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --shipbob-channel-id: string # Retrieve your channel ID from the [GET /channel](/api/channels/get-channels) endpoint. Use the channel ID that has write scopes.
]: nothing -> record<channel: record<id: int, name: string>, created_date: string, financials: record<total_price: float>, gift_message: string, id: int, order_number: string, products: table<external_line_id: int, gtin: string, id: int, quantity: int, quantity_unit_of_measure_code: string, reference_id: string, sku: string, unit_price: float, upc: string>, purchase_date: string, recipient: record<address: any, email: string, name: string, phone_number: string>, reference_id: string, retailer_program_data: record<addresses: list<record>, customer_ticket_number: string, delivery_date: string, department: string, doNotShipBeforeDate: string, mark_for_store: string, purchase_order_number: string, retailer_program_type: string, shipByDate: string>, shipments: table<actual_fulfillment_date: string, created_date: string, delivery_date: string, estimated_fulfillment_date: string, estimated_fulfillment_date_status: string, gift_message: string, id: int, insurance_value: float, invoice_amount: float, invoice_currency_code: string, is_tracking_uploaded: bool, last_tracking_update_at: string, last_update_at: string, location: record, measurements: record, order_id: int, package_material_type: string, parent_cartons: list, products: list, recipient: record, reference_id: string, require_signature: bool, ship_option: string, status: string, status_details: list, tracking: record>, shipping_method: string, shipping_terms: record<carrier_type: string, payment_term: string>, status: string, tags: table<name: string, value: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/order/($orderId)")
  let extra_headers = {"Authorization": $Authorization, "shipbob_channel_id": $shipbob_channel_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Shipment
#
# GET /2026-01/shipment/{shipmentId}
# operationId: get-shipment
export def "2026-01-shipment get-shipment" [
  shipmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --shipbob-channel-id: string # Retrieve your channel ID from the [GET /channel](/api/channels/get-channels) endpoint. Use the channel ID that has write scopes.
]: nothing -> record<actual_fulfillment_date: string, created_date: string, delivery_date: string, estimated_fulfillment_date: string, estimated_fulfillment_date_status: string, gift_message: string, id: int, insurance_value: float, invoice_amount: float, invoice_currency_code: string, is_tracking_uploaded: bool, last_tracking_update_at: string, last_update_at: string, location: record<id: int, name: string>, measurements: record<depth_in: int, length_in: int, total_weight_oz: int, width_in: int>, order_id: int, package_material_type: string, parent_cartons: table<barcode: string, cartons: list, measurements: record, type: string>, products: table<id: int, inventory_items: list, name: string, reference_id: string, sku: string>, recipient: record<address: any, email: string, full_name: string, name: string, phone_number: string>, reference_id: string, require_signature: bool, ship_option: string, status: string, status_details: table<description: string, exception_fulfillment_center_id: int, extra_information: record, id: int, inventory_id: int, name: string>, tracking: record<bol: string, carrier: string, carrier_service: string, pro_number: string, scac: string, shipping_date: string, tracking_number: string, tracking_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/shipment/($shipmentId)")
  let extra_headers = {"Authorization": $Authorization, "shipbob_channel_id": $shipbob_channel_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Shipment Timeline
#
# GET /2026-01/shipment/{shipmentId}/timeline
# operationId: get-shipment-timeline
export def "2026-01-shipment-timeline get-shipment-timeline" [
  shipmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --shipbob-channel-id: string # Retrieve your channel ID from the [GET /channel](/api/channels/get-channels) endpoint. Use the channel ID that has write scopes.
]: nothing -> table<log_type_id: int, log_type_name: string, log_type_text: string, metadata: record, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/shipment/($shipmentId)/timeline")
  let extra_headers = {"Authorization": $Authorization, "shipbob_channel_id": $shipbob_channel_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Batch Cancel Shipments
#
# POST /2026-01/shipment:batchCancel
# operationId: batch-cancel-shipments
export def "2026-01-shipment-batch-cancel batch-cancel-shipments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --shipbob-channel-id: string # Retrieve your channel ID from the [GET /channel](/api/channels/get-channels) endpoint. Use the channel ID that has write scopes.
  --shipment-ids: list # Shipment IDs to cancel (nullable)
]: any -> record<results: table<action: string, is_success: bool, reason: string, shipment_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2026-01/shipment:batchCancel")
  let body = {shipment_ids: $shipment_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "shipbob_channel_id": $shipbob_channel_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark Tracking Uploaded
#
# POST /2026-01/shipment:batchUpdateTrackingUpload
# operationId: mark-tracking-uploaded
export def "2026-01-shipment-batch-update-tracking-upload mark-tracking-uploaded" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --is-tracking-uploaded: string@bool-completer # Indicates whether the Shipment was marked with tracking information uploaded to a third-party system where the order originated. Applies to all shipments in shipment_ids
  --shipment-ids: list # Shipment IDs to apply the tracking upload status to (nullable)
]: any -> record<results: table<error: record, isSuccess: bool, shipmentId: int>, summary: record<failed: int, successful: int, total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2026-01/shipment:batchUpdateTrackingUpload")
  let body = {is_tracking_uploaded: $is_tracking_uploaded, shipment_ids: $shipment_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Shipment Address
#
# PUT /2026-01/shipment/{shipmentId}:updateAddress
# operationId: update-shipment-address
export def "2026-01-shipment update-shipment-address" [
  shipmentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  city: string # City of customer address
  --company-name: string # Company name (optional) (nullable)
  --country-code: string # Country code of customer address (nullable)
  --email: string # Customer's email address (nullable)
  --phone-number: string # Phone number of Recipient address (nullable)
  --recipient-name: string # Name of customer (nullable)
  --state: string # State of customer address (nullable)
  street_address1: string # Street Address 1
  --street-address2: string # Street Address 2 (nullable)
  --zip-code: string # Zipcode of customer address (nullable)
]: any -> record<error: record<code: string, message: string>, id: int, is_success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/shipment/($shipmentId):updateAddress")
  let body = {city: $city, company_name: $company_name, country_code: $country_code, email: $email, phone_number: $phone_number, recipient_name: $recipient_name, state: $state, street_address1: $street_address1, street_address2: $street_address2, zip_code: $zip_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Shipment Line Items
#
# GET /2026-01/shipment/{shipmentId}:getLineItems
# operationId: get-shipment-line-items
export def "2026-01-shipment get-shipment-line-items" [
  shipmentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> table<committed_quantity: int, inventory_id: int, is_hazmat: bool, is_lot: bool, lot: record<lot_date: string, lot_number: string, selection_method: string>, product_variant: record<id: int, name: string, sku: string>, quantity: int, serial_numbers: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/shipment/($shipmentId):getLineItems")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Shipment Line Items
#
# POST /2026-01/shipment/{shipmentId}:updateLineItems
# operationId: update-shipment-line-items
# --items item shape: {fulfillment_center_id?: int, id?: int, inventory_id: int, is_manually_assigned_lot?: bool, lot_date?: string, lot_number?: string, quantity: int}
export def "2026-01-shipment update-shipment-line-items" [
  shipmentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  items: list # Complete list of line items for the shipment. Must include all line items — partial updates are not supported — item shape: {fulfillment_center_id?: int, id?: int, inventory_id: int, is_manually_assigned_lot?: bool, lot_date?: string, lot_number?: string, quantity: int}
]: any -> record<error: record<code: string, message: string>, id: int, is_success: bool, shipment_line_items: table<action: string, inventory_id: int, new_value: string, previous_value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/shipment/($shipmentId):updateLineItems")
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk Update Shipping Service
#
# PUT /2026-01/shipment:bulkUpdateShippingService
# operationId: bulk-update-shipping-service
export def "2026-01-shipment-bulk-update-shipping-service bulk-update-shipping-service" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  reason: string # Reason for updating the shipping service
  requested_shipping_service_id: int # ID of the shipping service to assign to the shipments
  shipment_ids: list # List of shipment IDs to update the shipping service for
]: any -> record<results: table<error: record, id: int, is_success: bool>, summary: record<failed: int, successful: int, total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2026-01/shipment:bulkUpdateShippingService")
  let body = {reason: $reason, requested_shipping_service_id: $requested_shipping_service_id, shipment_ids: $shipment_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel Order
#
# POST /2026-01/order/{orderId}:cancel
# operationId: cancel-order
export def "2026-01-order cancel-order" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<canceled_shipment_results: table<action: string, is_success: bool, reason: string, shipment_id: int>, order: record<channel: record<id: int, name: string>, created_date: string, financials: record<total_price: float>, gift_message: string, id: int, order_number: string, products: list<record>, purchase_date: string, recipient: record<address: any, email: string, name: string, phone_number: string>, reference_id: string, retailer_program_data: record<addresses: list, customer_ticket_number: string, delivery_date: string, department: string, doNotShipBeforeDate: string, mark_for_store: string, purchase_order_number: string, retailer_program_type: string, shipByDate: string>, shipments: list<record>, shipping_method: string, shipping_terms: record<carrier_type: string, payment_term: string>, status: string, tags: list<record>, type: string>, order_id: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/order/($orderId):cancel")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel Shipment
#
# POST /2026-01/shipment/{shipmentId}:cancel
# operationId: cancel-shipment
export def "2026-01-shipment cancel-shipment" [
  shipmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<actual_fulfillment_date: string, created_date: string, delivery_date: string, estimated_fulfillment_date: string, estimated_fulfillment_date_status: string, gift_message: string, id: int, insurance_value: float, invoice_amount: float, invoice_currency_code: string, is_tracking_uploaded: bool, last_tracking_update_at: string, last_update_at: string, location: record<id: int, name: string>, measurements: record<depth_in: int, length_in: int, total_weight_oz: int, width_in: int>, order_id: int, package_material_type: string, parent_cartons: table<barcode: string, cartons: list, measurements: record, type: string>, products: table<id: int, inventory_items: list, name: string, reference_id: string, sku: string>, recipient: record<address: any, email: string, full_name: string, name: string, phone_number: string>, reference_id: string, require_signature: bool, ship_option: string, status: string, status_details: table<description: string, exception_fulfillment_center_id: int, extra_information: record, id: int, inventory_id: int, name: string>, tracking: record<bol: string, carrier: string, carrier_service: string, pro_number: string, scac: string, shipping_date: string, tracking_number: string, tracking_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/shipment/($shipmentId):cancel")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Shipping Methods
#
# GET /2026-01/shipping-method
# operationId: get-shipping-methods
export def "2026-01-shipping-method get-shipping-methods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Page: int # Page of orders to get
  --Limit: int # Amount of records per page to request
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> table<active: bool, default: bool, id: int, name: string, service_level: record<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Page" $Page "scalar") (serialize-qp "Limit" $Limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2026-01/shipping-method" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Shipment Status Timeline by Order ID and Shipment ID
#
# GET /2026-01/order/{orderId}/shipment/{shipmentId}/timeline
# operationId: get-shipment-status-timeline-by-order-id-and-shipment-id
export def "2026-01-order-shipment-timeline get-shipment-status-timeline-by-order-id-and-shipment-id" [
  orderId: string
  shipmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --shipbob-channel-id: string # Retrieve your channel ID from the [GET /channel](/api/channels/get-channels) endpoint. Use the channel ID that has write scopes.
]: nothing -> table<log_type_id: int, log_type_name: string, log_type_text: string, metadata: record, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/order/($orderId)/shipment/($shipmentId)/timeline")
  let extra_headers = {"Authorization": $Authorization, "shipbob_channel_id": $shipbob_channel_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Shipments for Order
#
# GET /2026-01/order/{orderId}/shipment
# operationId: get-all-shipments-for-order
export def "2026-01-order-shipment get-all-shipments-for-order" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --shipbob-channel-id: string # Retrieve your channel ID from the [GET /channel](/api/channels/get-channels) endpoint. Use the channel ID that has write scopes.
]: nothing -> table<actual_fulfillment_date: string, created_date: string, delivery_date: string, estimated_fulfillment_date: string, estimated_fulfillment_date_status: string, gift_message: string, id: int, insurance_value: float, invoice_amount: float, invoice_currency_code: string, is_tracking_uploaded: bool, last_tracking_update_at: string, last_update_at: string, location: record<id: int, name: string>, measurements: record<depth_in: int, length_in: int, total_weight_oz: int, width_in: int>, order_id: int, package_material_type: string, parent_cartons: list<record>, products: list<record>, recipient: record<address: any, email: string, full_name: string, name: string, phone_number: string>, reference_id: string, require_signature: bool, ship_option: string, status: string, status_details: list<record>, tracking: record<bol: string, carrier: string, carrier_service: string, pro_number: string, scac: string, shipping_date: string, tracking_number: string, tracking_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/order/($orderId)/shipment")
  let extra_headers = {"Authorization": $Authorization, "shipbob_channel_id": $shipbob_channel_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Shipment Logs by Order ID and Shipment ID
#
# GET /2026-01/order/{orderId}/shipment/{shipmentId}/logs
# operationId: get-shipment-logs-by-order-id-and-shipment-id
export def "2026-01-order-shipment-logs get-shipment-logs-by-order-id-and-shipment-id" [
  orderId: string
  shipmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> table<log_type_id: int, log_type_name: string, log_type_text: string, metadata: record, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/order/($orderId)/shipment/($shipmentId)/logs")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel Shipment by Order ID and Shipment ID
#
# POST /2026-01/order/{orderId}/shipment/{shipmentId}:cancel
# operationId: cancel-shipment-by-order-id-and-shipment-id
export def "2026-01-order-shipment cancel-shipment-by-order-id-and-shipment-id" [
  shipmentId: string
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<actual_fulfillment_date: string, created_date: string, delivery_date: string, estimated_fulfillment_date: string, estimated_fulfillment_date_status: string, gift_message: string, id: int, insurance_value: float, invoice_amount: float, invoice_currency_code: string, is_tracking_uploaded: bool, last_tracking_update_at: string, last_update_at: string, location: record<id: int, name: string>, measurements: record<depth_in: int, length_in: int, total_weight_oz: int, width_in: int>, order_id: int, package_material_type: string, parent_cartons: table<barcode: string, cartons: list, measurements: record, type: string>, products: table<id: int, inventory_items: list, name: string, reference_id: string, sku: string>, recipient: record<address: any, email: string, full_name: string, name: string, phone_number: string>, reference_id: string, require_signature: bool, ship_option: string, status: string, status_details: table<description: string, exception_fulfillment_center_id: int, extra_information: record, id: int, inventory_id: int, name: string>, tracking: record<bol: string, carrier: string, carrier_service: string, pro_number: string, scac: string, shipping_date: string, tracking_number: string, tracking_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/order/($orderId)/shipment/($shipmentId):cancel")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Shipment Logs
#
# GET /2026-01/shipment/{shipmentId}/logs
# operationId: get-shipment-logs
export def "2026-01-shipment-logs get-shipment-logs" [
  shipmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --shipbob-channel-id: string # Retrieve your channel ID from the [GET /channel](/api/channels/get-channels) endpoint. Use the channel ID that has write scopes.
]: nothing -> table<log_type_id: int, log_type_name: string, log_type_text: string, metadata: record, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/shipment/($shipmentId)/logs")
  let extra_headers = {"Authorization": $Authorization, "shipbob_channel_id": $shipbob_channel_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Shipment by Order ID and Shipment ID
#
# GET /2026-01/order/{orderId}/shipment/{shipmentId}
# operationId: get-shipment-by-order-id-and-shipment-id
export def "2026-01-order-shipment get-shipment-by-order-id-and-shipment-id" [
  orderId: string
  shipmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --shipbob-channel-id: string # Retrieve your channel ID from the [GET /channel](/api/channels/get-channels) endpoint. Use the channel ID that has write scopes.
]: nothing -> record<actual_fulfillment_date: string, created_date: string, delivery_date: string, estimated_fulfillment_date: string, estimated_fulfillment_date_status: string, gift_message: string, id: int, insurance_value: float, invoice_amount: float, invoice_currency_code: string, is_tracking_uploaded: bool, last_tracking_update_at: string, last_update_at: string, location: record<id: int, name: string>, measurements: record<depth_in: int, length_in: int, total_weight_oz: int, width_in: int>, order_id: int, package_material_type: string, parent_cartons: table<barcode: string, cartons: list, measurements: record, type: string>, products: table<id: int, inventory_items: list, name: string, reference_id: string, sku: string>, recipient: record<address: any, email: string, full_name: string, name: string, phone_number: string>, reference_id: string, require_signature: bool, ship_option: string, status: string, status_details: table<description: string, exception_fulfillment_center_id: int, extra_information: record, id: int, inventory_id: int, name: string>, tracking: record<bol: string, carrier: string, carrier_service: string, pro_number: string, scac: string, shipping_date: string, tracking_number: string, tracking_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/order/($orderId)/shipment/($shipmentId)")
  let extra_headers = {"Authorization": $Authorization, "shipbob_channel_id": $shipbob_channel_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Estimate Fulfillment Cost For Order
#
# POST /2026-01/order:estimate
# operationId: estimate-fulfillment-cost-for-order
# --address shape: {address1?: string, address2?: string, city?: string, company_name?: string, country: string, state?: string, zip_code?: string}
# --products item shape: {id?: int, quantity: int, reference_id?: string}
export def "2026-01-order-estimate estimate-fulfillment-cost-for-order" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --shipbob-channel-id: string # Retrieve your channel ID from the [GET /channel](/api/channels/get-channels) endpoint. Use the channel ID that has write scopes.
  address: record # shape: {address1?: string, address2?: string, city?: string, company_name?: string, country: string, state?: string, zip_code?: string}
  products: list # Products to be included in the order. Each product must include one of reference_id or id — item shape: {id?: int, quantity: int, reference_id?: string}
  --shipping-methods: list # Array of strings specifying shipping methods for which to fetch estimates.  If this field is omitted we will return estimates for all shipping methods defined in ShipBob (nullable)
]: any -> record<estimates: table<estimated_currency_code: string, estimated_price: float, fulfillment_center: record, shipping_method: string, total_weight_oz: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2026-01/order:estimate")
  let body = {address: $address, products: $products, shipping_methods: $shipping_methods} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "shipbob_channel_id": $shipbob_channel_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Order Store Data
#
# GET /2026-01/order/{orderId}/store-order-json
# operationId: get-order-store-data
export def "2026-01-order-store-order-json get-order-store-data" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/order/($orderId)/store-order-json")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Product
#
# POST /2026-01/product
# operationId: create-product
# --variants item shape: {additional_hazmat_attributes?: record, bundle_definition?: list, channel_metadata?: list, customs?: record, dimension?: record, fulfillment_settings?: record, gtin?: string, is_digital?: bool, lot_information?: record, name?: string, packaging_material_type_id?: int, packaging_requirement_id?: int, return_preferences?: record, sku?: string, status_id?: "0"|"1", upc?: string, weight?: float, barcodes?: list}
export def "2026-01-product create-product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --name: string # The name of the product (nullable)
  --taxonomy-id: int # The taxonomy ID for categorizing the product (nullable)
  --type-id: string@type-id-completer # The product type ID (1 = Regular, 2 = Bundle)
  --is-quarantine: string@bool-completer # Flag indicating whether the product should be created in quarantine status
  --variants: list # List of variants to create with the product. At least one variant is required. Each variant must have a unique SKU. (nullable) — item shape: {additional_hazmat_attributes?: record, bundle_definition?: list, channel_metadata?: list, customs?: record, dimension?: record, fulfillment_settings?: record, gtin?: string, is_digital?: bool, lot_information?: record, name?: string, packaging_material_type_id?: int, packaging_requirement_id?: int, return_preferences?: record, sku?: string, status_id?: "0"|"1", upc?: string, weight?: float, barcodes?: list}
]: any -> record<created_on: string, id: int, name: string, taxonomy: record<id: int, name: string, parent_id: int, parent_name: string, path: string>, type: string, updated_on: string, user_id: int, variants: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2026-01/product")
  let body = {name: $name, taxonomy_id: $taxonomy_id, type_id: $type_id, is_quarantine: $is_quarantine, variants: $variants} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Products
#
# GET /2026-01/product
# operationId: get-products
export def "2026-01-product get-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Search: string # Search Products by name, sku, inventory id or product Id.
  --Barcode: string # Barcode Associated with variant
  --Barcodes: string # Barcodes Associated with variant
  --CategoryIds: string # List of Category Ids associated with product
  --ChannelIds: string # Looks for Products variants by their channel IDs
  --HasDigitalVariants: string # Looks for Products with/without digital variants
  --HasVariants: string # Looks for Products with/without variants
  --InventoryId: string # Looks for variants by its associated inventory id
  --IsInventorySyncEnabled: string # Looks for Products variants by their IsInventorySyncEnabled is true
  --LastUpdatedTimestamp: string # Looks for Products that have been updated since the given date
  --LegacyIds: string # Looks for Products with by Legacy Product Id(s)
  --Name: string # Looks for Products/Variants by name
  --OnHand: string # Looks for Products with inventory
  --PlatformIds: string # Looks for Products variants by their external Platform IDs
  --ProductId: string # Looks for Products with an assigned Id
  --ProductType: string # Looks for Products by type
  --ReviewsPending: string # Looks for Products by ReviewsPending
  --SalesChannel: string # Looks for Products variants assigned to a platform/sales channel 
  --SellerSKU: string # Looks for Products that match the provided Seller query
  --SKU: string # Looks for Products that match the provided Sku query
  --TaxonomyIds: string # Looks for Products variants by their taxonomy id or any descendants of the taxonomies sent separated by comma
  --VariantId: string # Looks for products that contain a variant with the given ID
  --VariantStatus: string # Looks for Products with variants that contain provided status
  --PageSize: string # 1-250
  --SortBy: string # Id, Name, Category, TotalOnHandQty
  --SortOrder: string # ASC,DESC
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<first: string, items: table<created_on: string, id: int, name: string, taxonomy: record, type: string, updated_on: string, user_id: int, variants: list>, last: string, next: string, prev: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Search" $Search "scalar") (serialize-qp "Barcode" $Barcode "scalar") (serialize-qp "Barcodes" $Barcodes "scalar") (serialize-qp "CategoryIds" $CategoryIds "scalar") (serialize-qp "ChannelIds" $ChannelIds "scalar") (serialize-qp "HasDigitalVariants" $HasDigitalVariants "scalar") (serialize-qp "HasVariants" $HasVariants "scalar") (serialize-qp "InventoryId" $InventoryId "scalar") (serialize-qp "IsInventorySyncEnabled" $IsInventorySyncEnabled "scalar") (serialize-qp "LastUpdatedTimestamp" $LastUpdatedTimestamp "scalar") (serialize-qp "LegacyIds" $LegacyIds "scalar") (serialize-qp "Name" $Name "scalar") (serialize-qp "OnHand" $OnHand "scalar") (serialize-qp "PlatformIds" $PlatformIds "scalar") (serialize-qp "ProductId" $ProductId "scalar") (serialize-qp "ProductType" $ProductType "scalar") (serialize-qp "ReviewsPending" $ReviewsPending "scalar") (serialize-qp "SalesChannel" $SalesChannel "scalar") (serialize-qp "SellerSKU" $SellerSKU "scalar") (serialize-qp "SKU" $SKU "scalar") (serialize-qp "TaxonomyIds" $TaxonomyIds "scalar") (serialize-qp "VariantId" $VariantId "scalar") (serialize-qp "VariantStatus" $VariantStatus "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "SortBy" $SortBy "scalar") (serialize-qp "SortOrder" $SortOrder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2026-01/product" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Product
#
# GET /2026-01/product/{productId}
# operationId: get-product
export def "2026-01-product get-product" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<created_on: string, id: int, name: string, taxonomy: record<id: int, name: string, parent_id: int, parent_name: string, path: string>, type: string, updated_on: string, user_id: int, variants: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/product/($productId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Product
#
# PATCH /2026-01/product/{productId}
# operationId: update-product
# --variants item shape: {additional_hazmat_attributes?: record, bundle_definition?: list, channel_metadata?: list, customs?: record, dimension?: record, fulfillment_settings?: record, gtin?: string, is_digital?: bool, lot_information?: record, name?: string, packaging_material_type_id?: int, packaging_requirement_id?: int, return_preferences?: record, sku?: string, status_id?: "0"|"1", upc?: string, weight?: float, barcodes?: list, id?: int}
export def "2026-01-product update-product" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --name: string # The name of the product (nullable)
  --taxonomy-id: int # The taxonomy ID for categorizing the product (nullable)
  --type-id: string@type-id-completer # The product type ID (1 = Regular, 2 = Bundle)
  --id: int # Unique reference ID for the product (format: int64)
  --variants: list # List of variants to update. Each variant must include an ID. Only provided fields will be updated. (nullable) — item shape: {additional_hazmat_attributes?: record, bundle_definition?: list, channel_metadata?: list, customs?: record, dimension?: record, fulfillment_settings?: record, gtin?: string, is_digital?: bool, lot_information?: record, name?: string, packaging_material_type_id?: int, packaging_requirement_id?: int, return_preferences?: record, sku?: string, status_id?: "0"|"1", upc?: string, weight?: float, barcodes?: list, id?: int}
]: any -> record<created_on: string, id: int, name: string, taxonomy: record<id: int, name: string, parent_id: int, parent_name: string, path: string>, type: string, updated_on: string, user_id: int, variants: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/product/($productId)")
  let body = {name: $name, taxonomy_id: $taxonomy_id, type_id: $type_id, id: $id, variants: $variants} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Product Bundle
#
# DELETE /2026-01/product/{productId}
# operationId: delete-product-bundle
export def "2026-01-product delete-product-bundle" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/product/($productId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Product Variants
#
# GET /2026-01/product/{productId}/variants
# operationId: get-product-variants
export def "2026-01-product-variants get-product-variants" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> table<additional_hazmat_attributes: record<charge_state_percentage: float, container_metal: bool, container_type: string, lithium_battery_packaging: string, lithium_battery_type: string, magnet: bool, net_volume: float, net_weight: float>, associated_bundles: list<record>, bundle_definition: list<record>, created_on: string, customs: record<country_code_of_origin: string, currency: string, description: string, hs_tariff_code: string, is321_eligible: bool, value: int>, dimension: record<height: float, is_locked: bool, length: float, source: string, unit: string, width: float>, fulfillment_settings: record<dangerous_goods: bool, is_bpm_parcel: bool, is_case_pick: bool, msds_url: string, requires_prop65: bool, serial_scan: record>, gtin: string, id: int, inventory: record<inventory_id: int, on_hand_qty: int>, is_digital: bool, is_image_uploaded: bool, lot_information: record<is_lot: bool, minimum_shelf_life_days: int>, merge_children: list<record>, name: string, packaging_material_type: record<id: int, name: string>, packaging_requirement: record<id: int, name: string>, return_preferences: record<backup_action: record, instructions: string, primary_action: record, return_to_sender_backup_action: record, return_to_sender_primary_action: record>, reviews_pending: list<string>, sku: string, status: string, upc: string, updated_on: string, weight: record<unit: string, weight: float>, barcodes: list<record>, channel_metadata: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/product/($productId)/variants")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Product Variants
#
# POST /2026-01/product/{productId}/variants
# operationId: add-product-variants
export def "2026-01-product-variants add-product-variants" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --body: record
]: any -> record<created_on: string, id: int, name: string, taxonomy: record<id: int, name: string, parent_id: int, parent_name: string, path: string>, type: string, updated_on: string, user_id: int, variants: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/product/($productId)/variants")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Product Variants
#
# PATCH /2026-01/product/{productId}/variants
# operationId: update-product-variants
# --additional_hazmat_attributes shape: {charge_state_percentage?: float, container_metal?: bool, container_type?: string, lithium_battery_packaging?: string, lithium_battery_type?: string, magnet?: bool, net_volume?: float, net_weight?: float}
# --bundle_definition item shape: {quantity?: int, variant_id?: int}
# --customs shape: {country_code_of_origin?: string, currency?: string, description?: string, hs_tariff_code?: string, is321_eligible?: bool, value?: int}
# --dimension shape: {height?: float, length?: float, width?: float}
# --fulfillment_settings shape: {dangerous_goods?: bool, is_bpm_parcel?: bool, is_case_pick?: bool, msds_url?: string, requires_prop65?: bool, serial_scan?: record}
# --lot_information shape: {is_lot?: bool, minimum_shelf_life_days?: int}
# --return_preferences shape: {backup_action_id?: int, instructions?: string, primary_action_id?: int, return_to_sender_backup_action_id?: int, return_to_sender_primary_action_id?: int}
# --barcodes item shape: {sticker_url?: string, value?: string}
export def "2026-01-product-variants update-product-variants" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --additional-hazmat-attributes: record # shape: {charge_state_percentage?: float, container_metal?: bool, container_type?: string, lithium_battery_packaging?: string, lithium_battery_type?: string, magnet?: bool, net_volume?: float, net_weight?: float}
  --bundle-definition: list # nullable — item shape: {quantity?: int, variant_id?: int}
  --channel-metadata: list # nullable
  --customs: record # shape: {country_code_of_origin?: string, currency?: string, description?: string, hs_tariff_code?: string, is321_eligible?: bool, value?: int}
  --dimension: record # shape: {height?: float, length?: float, width?: float}
  --fulfillment-settings: record # shape: {dangerous_goods?: bool, is_bpm_parcel?: bool, is_case_pick?: bool, msds_url?: string, requires_prop65?: bool, serial_scan?: record}
  --gtin: string # nullable
  --is-digital: string@bool-completer
  --lot-information: record # shape: {is_lot?: bool, minimum_shelf_life_days?: int}
  --name: string # nullable
  --packaging-material-type-id: int # nullable
  --packaging-requirement-id: int # nullable
  --return-preferences: record # shape: {backup_action_id?: int, instructions?: string, primary_action_id?: int, return_to_sender_backup_action_id?: int, return_to_sender_primary_action_id?: int}
  --reviews-pending: list # nullable
  --sku: string # nullable
  --status: string@status-completer
  --upc: string # nullable
  --weight: float # format: double
  --barcodes: list # nullable — item shape: {sticker_url?: string, value?: string}
  --id: int # format: int64
]: any -> table<additional_hazmat_attributes: record<charge_state_percentage: float, container_metal: bool, container_type: string, lithium_battery_packaging: string, lithium_battery_type: string, magnet: bool, net_volume: float, net_weight: float>, associated_bundles: list<record>, bundle_definition: list<record>, created_on: string, customs: record<country_code_of_origin: string, currency: string, description: string, hs_tariff_code: string, is321_eligible: bool, value: int>, dimension: record<height: float, is_locked: bool, length: float, source: string, unit: string, width: float>, fulfillment_settings: record<dangerous_goods: bool, is_bpm_parcel: bool, is_case_pick: bool, msds_url: string, requires_prop65: bool, serial_scan: record>, gtin: string, id: int, inventory: record<inventory_id: int, on_hand_qty: int>, is_digital: bool, is_image_uploaded: bool, lot_information: record<is_lot: bool, minimum_shelf_life_days: int>, merge_children: list<record>, name: string, packaging_material_type: record<id: int, name: string>, packaging_requirement: record<id: int, name: string>, return_preferences: record<backup_action: record, instructions: string, primary_action: record, return_to_sender_backup_action: record, return_to_sender_primary_action: record>, reviews_pending: list<string>, sku: string, status: string, upc: string, updated_on: string, weight: record<unit: string, weight: float>, barcodes: list<record>, channel_metadata: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/product/($productId)/variants")
  let body = {additional_hazmat_attributes: $additional_hazmat_attributes, bundle_definition: $bundle_definition, channel_metadata: $channel_metadata, customs: $customs, dimension: $dimension, fulfillment_settings: $fulfillment_settings, gtin: $gtin, is_digital: $is_digital, lot_information: $lot_information, name: $name, packaging_material_type_id: $packaging_material_type_id, packaging_requirement_id: $packaging_requirement_id, return_preferences: $return_preferences, reviews_pending: $reviews_pending, sku: $sku, status: $status, upc: $upc, weight: $weight, barcodes: $barcodes, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Merge Variants
#
# POST /2026-01/variant/{variantId}:merge
# operationId: merge-variants
export def "2026-01-variant merge-variants" [
  variantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --body: record
]: any -> record<created_on: string, id: int, name: string, taxonomy: record<id: int, name: string, parent_id: int, parent_name: string, path: string>, type: string, updated_on: string, user_id: int, variants: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/variant/($variantId):merge")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Move Variants Between Products
#
# POST /2026-01/product/{productId}:moveVariants
# operationId: move-variants-between-products
# --variants item shape: {id?: int, name?: string}
export def "2026-01-product move-variants-between-products" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --category-id: int # nullable
  --name: string # nullable
  --product-id: int # format: int64
  --sub-category-id: int # nullable
  --taxonomy-id: int # nullable
  --variants: list # nullable — item shape: {id?: int, name?: string}
]: any -> record<category: record<id: int, name: string>, created_on: string, id: int, name: string, sub_category: record<id: int, name: string>, taxonomy: record<id: int, name: string, parent_id: int, parent_name: string, path: string>, type: string, updated_on: string, user_id: int, variants: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/product/($productId):moveVariants")
  let body = {category_id: $category_id, name: $name, product_id: $product_id, sub_category_id: $sub_category_id, taxonomy_id: $taxonomy_id, variants: $variants} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Move Variants to New Product
#
# POST /2026-01/product:moveVariants
# operationId: move-variants-to-new-product
# --variants item shape: {id?: int, name?: string}
export def "2026-01-product-move-variants move-variants-to-new-product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --category-id: int # nullable
  --name: string # nullable
  --product-id: int # format: int64
  --sub-category-id: int # nullable
  --taxonomy-id: int # nullable
  --variants: list # nullable — item shape: {id?: int, name?: string}
]: any -> record<category: record<id: int, name: string>, created_on: string, id: int, name: string, sub_category: record<id: int, name: string>, taxonomy: record<id: int, name: string, parent_id: int, parent_name: string, path: string>, type: string, updated_on: string, user_id: int, variants: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2026-01/product:moveVariants")
  let body = {category_id: $category_id, name: $name, product_id: $product_id, sub_category_id: $sub_category_id, taxonomy_id: $taxonomy_id, variants: $variants} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Packaging Requirement
#
# GET /2026-01/packaging-requirement
# operationId: get-packaging-requirement
export def "2026-01-packaging-requirement get-packaging-requirement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> table<applicable_categories: list<record>, applicable_packaging_material_types: list<record>, applicable_taxonomy: list<string>, description: string, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2026-01/packaging-requirement")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Taxonomies
#
# GET /2026-01/taxonomy
# operationId: get-taxonomies
export def "2026-01-taxonomy get-taxonomies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> table<id: int, name: string, path: string, children: list<record>, parent: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2026-01/taxonomy" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Taxonomy by ID
#
# GET /2026-01/taxonomy/{id}
# operationId: get-taxonomy-by-id
export def "2026-01-taxonomy get-taxonomy-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<id: int, name: string, path: string, children: table<id: int, name: string, path: string, has_children: bool>, parent: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/taxonomy/($id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Taxonomy Parent
#
# GET /2026-01/taxonomy/{id}/parent
# operationId: get-taxonomy-parent
export def "2026-01-taxonomy-parent get-taxonomy-parent" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<id: int, name: string, path: string, children: table<id: int, name: string, path: string, has_children: bool>, parent: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/taxonomy/($id)/parent")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Convert Variant to Bundle
#
# POST /2026-01/variant/{variantId}:convertToBundle
# operationId: convert-variant-to-bundle
# --bundle_definition item shape: {quantity?: int, variant_id?: int}
export def "2026-01-variant convert-variant-to-bundle" [
  variantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --bundle-definition: list # nullable — item shape: {quantity?: int, variant_id?: int}
  --channel-metadata: list # nullable
  --name: string # nullable
  --sku: string # nullable
]: any -> record<created_on: string, id: int, name: string, taxonomy: record<id: int, name: string, parent_id: int, parent_name: string, path: string>, type: string, updated_on: string, user_id: int, variants: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/variant/($variantId):convertToBundle")
  let body = {bundle_definition: $bundle_definition, channel_metadata: $channel_metadata, name: $name, sku: $sku} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get All Inventory Levels
#
# GET /2026-01/inventory-level
# operationId: get-all-inventory-levels
export def "2026-01-inventory-level get-all-inventory-levels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SearchBy: string # Search is available for 3 fields: Inventory ID, Name, and SKU. Expected behavior for search by Inventory ID is exact match. Expected behavior for search by Inventory Name or SKU is partial match (consecutive characters, case insensitive).
  --InventoryIds: string # Comma-separated list of inventory IDs to filter results. Use this to retrieve inventory levels for specific inventory items only.
  --IsActive: string@bool-completer # Filter inventory levels by active status. Set to true to return only active inventory items, false for inactive items. Omit to return all items regardless of status.
  --IsDigital: string@bool-completer # Filter inventory levels by digital product status. Set to true to return only digital products, false for physical products. Digital products are items that don't require physical fulfillment.
  --PageSize: string # Number of inventory level items to return per page. Controls pagination size for the response. (format: int32)
  --SortBy: string # Sort results by field name. Default is ascending order. Prefix with '-' for descending order (e.g., '-total_on_hand_quantity' sorts by quantity descending). Multiple fields can be comma-separated.
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<first: string, items: table<inventory_id: int, name: string, sku: string, total_awaiting_quantity: int, total_backordered_quantity: int, total_committed_quantity: int, total_exception_quantity: int, total_fulfillable_quantity: int, total_internal_transfer_quantity: int, total_on_hand_quantity: int, total_sellable_quantity: int>, last: string, next: string, prev: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SearchBy" $SearchBy "scalar") (serialize-qp "InventoryIds" $InventoryIds "scalar") (serialize-qp "IsActive" $IsActive "scalar") (serialize-qp "IsDigital" $IsDigital "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "SortBy" $SortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2026-01/inventory-level" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Inventory Levels
#
# GET /2026-01/inventory-level/{inventoryId}
# operationId: get-inventory-levels
export def "2026-01-inventory-level get-inventory-levels" [
  inventoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<inventory_id: int, name: string, sku: string, total_awaiting_quantity: int, total_backordered_quantity: int, total_committed_quantity: int, total_exception_quantity: int, total_fulfillable_quantity: int, total_internal_transfer_quantity: int, total_on_hand_quantity: int, total_sellable_quantity: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/inventory-level/($inventoryId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Inventory
#
# GET /2026-01/inventory/{inventoryId}
# operationId: get-inventory
export def "2026-01-inventory get-inventory" [
  inventoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<barcode: string, dimensions: record<height: float, is_locked: bool, length: float, unit: string, validated: bool, width: float>, inventory_id: int, is_case: bool, is_lot: bool, name: string, sku: string, user_id: int, variant: record<hazmat: record<is_hazmat: bool, validated: bool>, is_active: bool, is_bundle: bool, is_digital: bool>, weight: record<unit: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/inventory/($inventoryId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Inventories
#
# GET /2026-01/inventory
# operationId: get-all-inventories
export def "2026-01-inventory get-all-inventories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --SearchBy: string # Search is available for 3 fields: Inventory ID, Name, and SKU. Expected behavior for search by Inventory ID is exact match. Expected behavior for search by Inventory Name or SKU is partial match (consecutive characters, case insensitive).
  --FilterOperations: string # Advanced filtering operations. Apply multiple key-value filters to refine inventory results. Each filter operation contains a 'key' (field name) and 'rawValue' (filter value) to match.
  --InventoryIds: string # Comma-separated list of inventory IDs to filter results. Use this to retrieve information for specific inventory items only.
  --IsActive: string@bool-completer # Filter by active status. True returns only active inventory items, False returns only inactive items. Omit to return both.
  --IsDigital: string@bool-completer # Filter by digital product status. True returns only digital products (no physical fulfillment), False returns only physical products. Omit to return both.
  --PageSize: string # Number of items to return per page. Controls pagination size for the response. (format: int32)
  --SortBy: string # Sort results by field name. Default is ascending order. Prefix with '-' for descending order (e.g., '-name' sorts by name descending). Multiple fields can be comma-separated.
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<first: string, items: table<barcode: string, dimensions: record, inventory_id: int, is_case: bool, is_lot: bool, name: string, sku: string, user_id: int, variant: record, weight: record>, last: string, next: string, prev: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SearchBy" $SearchBy "scalar") (serialize-qp "FilterOperations" $FilterOperations "scalar") (serialize-qp "InventoryIds" $InventoryIds "scalar") (serialize-qp "IsActive" $IsActive "scalar") (serialize-qp "IsDigital" $IsDigital "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "SortBy" $SortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2026-01/inventory" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query Inventory History Events
#
# POST /2026-01/inventory/history:query
# operationId: query-inventory-history-events
export def "2026-01-inventory-history-query query-inventory-history-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # format: int32
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --cursor: int # Optional. Pagination cursor using the `inventory_audit_event_id` from the previous response. Returns events after this ID. (nullable)
  --end-date: string # Recommended. End date for filtering events. If omitted, defaults to current date. (nullable, format: date-time)
  --event-category: string # Recommended. Filter by event type: `OrderPicked`, `InventoryAdjusted`, `InventoryFacilityUpdated`, `AttributeUpdated`, `InventoryReceived`, `InventoryRestocked`, `ReceivingStow`, or `KittingStow`. (nullable)
  facility_id: int # Required. The ShipBob fulfillment center ID where the inventory events occurred. To find available facility IDs, use the [Get Fulfillment Centers](/api/2026-01/receiving/get-fulfillment-centers) endpoint.
  --inventory-ids: list # Recommended. Filter by specific inventory IDs. Returns events for these inventories only. (nullable)
  --start-date: string # Recommended. Start date for filtering events. If omitted, defaults to 90 days ago. Maximum range is 90 days. (nullable, format: date-time)
]: any -> record<data: table<additional_reference: list, decrement: record, event_category: string, event_datetime: string, increment: record, inventory_audit_event_id: int, inventory_id: int, shipbob_order_id: int>, first: string, last: string, next: string, prev: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2026-01/inventory/history:query" $qp)
  let body = {cursor: $cursor, end_date: $end_date, event_category: $event_category, facility_id: $facility_id, inventory_ids: $inventory_ids, start_date: $start_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get All Inventory Levels Grouped By Fulfillment Center
#
# GET /2026-01/inventory-level/locations
# operationId: get-all-inventory-levels-grouped-by-fulfillment-center
export def "2026-01-inventory-level-locations get-all-inventory-levels-grouped-by-fulfillment-center" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --LocationType: string # Filter by location type. Valid values: 'hub', 'spoke', or 'lts'. Defaults to all locations if not specified.
  --LocationId: string # Filter by specific fulfillment center location ID. Use this to retrieve inventory levels for a particular fulfillment center. (format: int32)
  --SearchBy: string # Search is available for 3 fields: Inventory ID, Name, and SKU. Expected behavior for search by Inventory ID is exact match. Expected behavior for search by Inventory Name or SKU is partial match (consecutive characters, case insensitive).
  --InventoryIds: string # Comma-separated list of inventory IDs to filter results. Use this to retrieve location-grouped inventory levels for specific inventory items only.
  --IsActive: string@bool-completer # Filter inventory levels by active status. Set to true to return only active inventory items, false for inactive items. Omit to return all items regardless of status.
  --IsDigital: string@bool-completer # Filter inventory levels by digital product status. Set to true to return only digital products, false for physical products. Digital products are items that don't require physical fulfillment.
  --PageSize: string # Number of location-grouped inventory level items to return per page. Controls pagination size for the response. (format: int32)
  --SortBy: string # Sort results by field name. Default is ascending order. Prefix with '-' for descending order (e.g., '-name' sorts by name descending). Multiple fields can be comma-separated.
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<first: string, items: table<inventory_id: int, locations: list, name: string, sku: string>, last: string, next: string, prev: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LocationType" $LocationType "scalar") (serialize-qp "LocationId" $LocationId "scalar") (serialize-qp "SearchBy" $SearchBy "scalar") (serialize-qp "InventoryIds" $InventoryIds "scalar") (serialize-qp "IsActive" $IsActive "scalar") (serialize-qp "IsDigital" $IsDigital "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "SortBy" $SortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2026-01/inventory-level/locations" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Inventory Levels Grouped By Fulfillment Center
#
# GET /2026-01/inventory-level/{inventoryId}/locations
# operationId: get-inventory-levels-grouped-by-fulfillment-center
export def "2026-01-inventory-level-locations get-inventory-levels-grouped-by-fulfillment-center" [
  inventoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<inventory_id: int, locations: table<awaiting_quantity: int, committed_quantity: int, fulfillable_quantity: int, internal_transfer_quantity: int, location_id: int, name: string, on_hand_quantity: int>, name: string, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/inventory-level/($inventoryId)/locations")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Inventory Levels Grouped By Lot
#
# GET /2026-01/inventory-level/lots
# operationId: get-all-inventory-levels-grouped-by-lot
export def "2026-01-inventory-level-lots get-all-inventory-levels-grouped-by-lot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --LocationId: string # Filter by specific fulfillment center location ID. Use this to retrieve lot-based inventory levels for a particular warehouse or distribution center. (format: int32)
  --SearchBy: string # Search is available for 3 fields: Inventory ID, Name, and SKU. Expected behavior for search by Inventory ID is exact match. Expected behavior for search by Inventory Name or SKU is partial match (consecutive characters, case insensitive).
  --InventoryIds: string # Comma-separated list of inventory IDs to filter results. Use this to retrieve lot-grouped inventory levels for specific inventory items only.
  --IsActive: string@bool-completer # Filter inventory levels by active status. Set to true to return only active inventory items, false for inactive items. Omit to return all items regardless of status.
  --IsDigital: string@bool-completer # Filter inventory levels by digital product status. Set to true to return only digital products, false for physical products. Digital products are items that don't require physical fulfillment.
  --PageSize: string # Number of lot-grouped inventory level items to return per page. Controls pagination size for the response. (format: int32)
  --SortBy: string # Sort results by field name. Default is ascending order. Prefix with '-' for descending order (e.g., '-lot_date' sorts by lot date descending). Multiple fields can be comma-separated.
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<first: string, items: table<inventory_id: int, lots: list, name: string, sku: string>, last: string, next: string, prev: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LocationId" $LocationId "scalar") (serialize-qp "SearchBy" $SearchBy "scalar") (serialize-qp "InventoryIds" $InventoryIds "scalar") (serialize-qp "IsActive" $IsActive "scalar") (serialize-qp "IsDigital" $IsDigital "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "SortBy" $SortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2026-01/inventory-level/lots" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Inventory Levels Grouped By Lot
#
# GET /2026-01/inventory-level/{inventoryId}/lots
# operationId: get-inventory-levels-grouped-by-lot
export def "2026-01-inventory-level-lots get-inventory-levels-grouped-by-lot" [
  inventoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<inventory_id: int, lots: table<awaiting_quantity: int, committed_quantity: int, fulfillable_quantity: int, internal_transfer_quantity: int, locations: list, lot_date: string, lot_number: string, on_hand_quantity: int>, name: string, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/inventory-level/($inventoryId)/lots")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Warehouse Receiving Order
#
# POST /2026-01/receiving
# operationId: create-warehouse-receiving-order
# --boxes item shape: {box_items: list, tracking_number: string}
# --fulfillment_center shape: {id: int}
export def "2026-01-receiving create-warehouse-receiving-order" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  box_packaging_type: string@box-packaging-type-completer
  --boxes: list # Box shipments to be added to this receiving order (nullable) — item shape: {box_items: list, tracking_number: string}
  expected_arrival_date: string # Expected arrival date of all the box shipments in this receiving order (format: date-time)
  fulfillment_center: record # Model containing information that assigns a receiving order to a fulfillment center. If the fulfillment center provided is in a receiving hub region, then the response will be the receiving hub location. — shape: {id: int}
  package_type: string@package-type-completer
  --purchase-order-number: string # Purchase order number for this receiving order (nullable)
]: any -> record<box_labels_uri: string, box_packaging_type: string, expected_arrival_date: string, external_sync_timestamp: string, fulfillment_center: record<address1: string, address2: string, city: string, country: string, email: string, id: int, name: string, phone_number: string, state: string, timezone: string, zip_code: string>, id: int, insert_date: string, inventory_quantities: table<expected_quantity: int, inventory_id: int, received_quantity: int, sku: string, stowed_quantity: int>, last_updated_date: string, package_type: string, purchase_order_number: string, status: string, status_history: table<id: int, status: string, timestamp: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2026-01/receiving")
  let body = {box_packaging_type: $box_packaging_type, boxes: $boxes, expected_arrival_date: $expected_arrival_date, fulfillment_center: $fulfillment_center, package_type: $package_type, purchase_order_number: $purchase_order_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Multiple Warehouse Receiving Orders
#
# GET /2026-01/receiving
# operationId: get-multiple-warehouse-receiving-orders
export def "2026-01-receiving get-multiple-warehouse-receiving-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Page: string # Page of WROs to get  (format: int32)
  --Limit: string # Number of WROs per page to request  (format: int32)
  --IDs: string # Comma separated list of WRO IDs to filter by
  --Statuses: string # Comma separated list of WRO statuses to filter by
  --InsertStartDate: string # Earliest date that a WRO was created  (format: date-time)
  --InsertEndDate: string # Latest date that a WRO was created  (format: date-time)
  --FulfillmentCenterIds: string # Comma separated list of WRO fulfillment center IDs to filter by
  --PurchaseOrderNumbers: string # Comma separated list of WRO PO numbers to filter by
  --ExternalSync: string@bool-completer # Flag to return external_sync_timestamp WROs
  --CompletedStartDate: string # Earliest date that a WRO was completed  (format: date-time)
  --CompletedEndDate: string # Latest date that a WRO was completed  (format: date-time)
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> table<box_labels_uri: string, box_packaging_type: string, expected_arrival_date: string, external_sync_timestamp: string, fulfillment_center: record<address1: string, address2: string, city: string, country: string, email: string, id: int, name: string, phone_number: string, state: string, timezone: string, zip_code: string>, id: int, insert_date: string, inventory_quantities: list<record>, last_updated_date: string, package_type: string, purchase_order_number: string, status: string, status_history: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Page" $Page "scalar") (serialize-qp "Limit" $Limit "scalar") (serialize-qp "IDs" $IDs "scalar") (serialize-qp "Statuses" $Statuses "scalar") (serialize-qp "InsertStartDate" $InsertStartDate "scalar") (serialize-qp "InsertEndDate" $InsertEndDate "scalar") (serialize-qp "FulfillmentCenterIds" $FulfillmentCenterIds "scalar") (serialize-qp "PurchaseOrderNumbers" $PurchaseOrderNumbers "scalar") (serialize-qp "ExternalSync" $ExternalSync "scalar") (serialize-qp "CompletedStartDate" $CompletedStartDate "scalar") (serialize-qp "CompletedEndDate" $CompletedEndDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2026-01/receiving" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Warehouse Receiving Order
#
# GET /2026-01/receiving/{id}
# operationId: get-warehouse-receiving-order
export def "2026-01-receiving get-warehouse-receiving-order" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<box_labels_uri: string, box_packaging_type: string, expected_arrival_date: string, external_sync_timestamp: string, fulfillment_center: record<address1: string, address2: string, city: string, country: string, email: string, id: int, name: string, phone_number: string, state: string, timezone: string, zip_code: string>, id: int, insert_date: string, inventory_quantities: table<expected_quantity: int, inventory_id: int, received_quantity: int, sku: string, stowed_quantity: int>, last_updated_date: string, package_type: string, purchase_order_number: string, status: string, status_history: table<id: int, status: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/receiving/($id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Fulfillment Centers
#
# GET /2026-01/fulfillment-center
# operationId: get-fulfillment-centers
export def "2026-01-fulfillment-center get-fulfillment-centers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> table<address1: string, address2: string, city: string, country: string, email: string, id: int, name: string, phone_number: string, state: string, timezone: string, zip_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2026-01/fulfillment-center")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Warehouse Receiving Order Boxes
#
# GET /2026-01/receiving/{id}/boxes
# operationId: get-warehouse-receiving-order-boxes
export def "2026-01-receiving-boxes get-warehouse-receiving-order-boxes" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> table<arrived_date: string, box_id: int, box_items: list<record>, box_number: int, box_status: string, counting_started_date: string, received_date: string, tracking_number: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/receiving/($id)/boxes")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Warehouse Receiving Order Box Labels
#
# GET /2026-01/receiving/{id}/labels
# operationId: get-warehouse-receiving-order-box-labels
export def "2026-01-receiving-labels get-warehouse-receiving-order-box-labels" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/receiving/($id)/labels")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel Warehouse Receiving Order
#
# POST /2026-01/receiving/{id}:cancel
# operationId: cancel-warehouse-receiving-order
export def "2026-01-receiving cancel-warehouse-receiving-order" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<box_labels_uri: string, box_packaging_type: string, expected_arrival_date: string, external_sync_timestamp: string, fulfillment_center: record<address1: string, address2: string, city: string, country: string, email: string, id: int, name: string, phone_number: string, state: string, timezone: string, zip_code: string>, id: int, insert_date: string, inventory_quantities: table<expected_quantity: int, inventory_id: int, received_quantity: int, sku: string, stowed_quantity: int>, last_updated_date: string, package_type: string, purchase_order_number: string, status: string, status_history: table<id: int, status: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/receiving/($id):cancel")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set ExternalSync flag for Wros
#
# POST /2026-01/receiving:setExternalSync
# operationId: set-external-sync-flag-for-wros
export def "2026-01-receiving-set-external-sync set-external-sync-flag-for-wros" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --ids: list # nullable
  --is-external-sync: string@bool-completer
]: any -> record<box_labels_uri: string, box_packaging_type: string, expected_arrival_date: string, external_sync_timestamp: string, fulfillment_center: record<address1: string, address2: string, city: string, country: string, email: string, id: int, name: string, phone_number: string, state: string, timezone: string, zip_code: string>, id: int, insert_date: string, inventory_quantities: table<expected_quantity: int, inventory_id: int, received_quantity: int, sku: string, stowed_quantity: int>, last_updated_date: string, package_type: string, purchase_order_number: string, status: string, status_history: table<id: int, status: string, timestamp: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2026-01/receiving:setExternalSync")
  let body = {ids: $ids, is_external_sync: $is_external_sync} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Inventory Distributions by WRO ID
#
# GET /2026-01/receiving/{id}/distributions
# operationId: get-inventory-distributions-by-wro-id
export def "2026-01-receiving-distributions get-inventory-distributions-by-wro-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<distributions: table<expected_quantity: int, fulfillment_center_abbreviation: string, fulfillment_center_id: int, inventory_id: int, lot_date: string, lot_number: string, product_sku: string, received_quantity: int, status: string, stowed_quantity: int>, id: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/receiving/($id)/distributions")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Return Order
#
# POST /2026-01/return
# operationId: create-return-order
# --fulfillment_center shape: {id: int, name?: string}
# --inventory item shape: {id: int, lot_date?: string, lot_number?: string, quantity: int, requested_action: "Default"|"Restock"|"Quarantine"|"Dispose"}
export def "2026-01-return create-return-order" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --shipbob-channel-id: string # Retrieve your channel ID from the [GET /channel](/api/channels/get-channels) endpoint. Use the channel ID that has write scopes.
  fulfillment_center: record # A Facility to process Returns. — shape: {id: int, name?: string}
  inventory: list # Array of inventory items being returned — item shape: {id: int, lot_date?: string, lot_number?: string, quantity: int, requested_action: "Default"|"Restock"|"Quarantine"|"Dispose"}
  --original-shipment-id: int # Shipment from which the items in the return originated <example>123456</example> (nullable)
  reference_id: string # Client-defined external unique identifier for the return order.             If tracking id is not provided, this value must appear on the box label as RMA. <example>Example: ShipBob_Return_123</example>
  --tracking-number: string # Tracking number for the return shipment <example>1Z9999999999999999</example> (nullable)
]: any -> record<channel: record<id: int, name: string>, completed_date: string, customer_name: string, fulfillment_center: record<id: int, name: string>, id: int, insert_date: string, inventory: table<action_requested: record, action_taken: list, id: int, name: string, quantity: int>, invoice_amount: float, original_shipment_id: int, reference_id: string, return_type: string, status: string, store_order_id: string, tracking_number: string, transactions: table<amount: float, transaction_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2026-01/return")
  let body = {fulfillment_center: $fulfillment_center, inventory: $inventory, original_shipment_id: $original_shipment_id, reference_id: $reference_id, tracking_number: $tracking_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "shipbob_channel_id": $shipbob_channel_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Return Orders
#
# GET /2026-01/return
# operationId: get-return-orders
export def "2026-01-return get-return-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Ids: string # The IDs of the returns to fetch. Accepts a comma-separated list of return IDs (e.g., 123,456,789).
  --ReferenceIds: string # Comma-separated list of return reference IDs (RMA numbers) to filter by.
  --Status: string # Comma-separated list of return statuses to filter by (e.g., AwaitingArrival,Arrived,Processing,Completed,Cancelled).
  --FulfillmentCenterIds: string # Comma-separated list of fulfillment center IDs to filter by.
  --TrackingNumbers: string # Comma-separated list of tracking numbers to filter by.
  --OriginalShipmentIds: string # Comma-separated list of original shipment IDs to filter by.
  --InventoryIds: string # Comma-separated list of inventory IDs to filter by.
  --StartDate: string # Filter returns created on or after this date (ISO 8601 format).  (format: date-time)
  --EndDate: string # Filter returns created on or before this date (ISO 8601 format).  (format: date-time)
  --ReturnTypes: string # Comma-separated list of return types to filter by (e.g., Regular,ReturnToSender).
  --ReturnActions: string # Comma-separated list of return actions to filter by (e.g., Restock,Quarantine,Dispose).
  --StoreOrderIds: string # Comma-separated list of store order IDs to filter by.
  --Sortby: string # Field to sort results by.
  --CompletedStartDate: string # Filter returns completed on or after this date (ISO 8601 format).  (format: date-time)
  --CompletedEndDate: string # Filter returns completed on or before this date (ISO 8601 format).  (format: date-time)
  --Cursor: int # Page number to retrieve. Used for pagination through result sets.
  --Limit: int # Maximum number of records to return per page.
  --SortOrder: string # Sort order for results. Desc = newest to oldest, Asc = oldest to newest, Desc is default
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --shipbob-channel-id: string # Retrieve your channel ID from the [GET /channel](/api/channels/get-channels) endpoint. Use the channel ID that has write scopes.
]: nothing -> record<first: string, items: table<arrived_date: string, awaiting_arrival_date: string, cancelled_date: string, channel: record, completed_date: string, customer_name: string, fulfillment_center: record, id: int, insert_date: string, inventory: list, invoice: record, original_shipment_id: int, processing_date: string, reference_id: string, return_type: string, shipment_tracking_number: string, status: string, status_history: list, store_order_id: string, tracking_number: string, transactions: list>, last: string, next: string, prev: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Ids" $Ids "scalar") (serialize-qp "ReferenceIds" $ReferenceIds "scalar") (serialize-qp "Status" $Status "scalar") (serialize-qp "FulfillmentCenterIds" $FulfillmentCenterIds "scalar") (serialize-qp "TrackingNumbers" $TrackingNumbers "scalar") (serialize-qp "OriginalShipmentIds" $OriginalShipmentIds "scalar") (serialize-qp "InventoryIds" $InventoryIds "scalar") (serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "ReturnTypes" $ReturnTypes "scalar") (serialize-qp "ReturnActions" $ReturnActions "scalar") (serialize-qp "StoreOrderIds" $StoreOrderIds "scalar") (serialize-qp "Sortby" $Sortby "scalar") (serialize-qp "CompletedStartDate" $CompletedStartDate "scalar") (serialize-qp "CompletedEndDate" $CompletedEndDate "scalar") (serialize-qp "Cursor" $Cursor "scalar") (serialize-qp "Limit" $Limit "scalar") (serialize-qp "SortOrder" $SortOrder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2026-01/return" $qp)
  let extra_headers = {"Authorization": $Authorization, "shipbob_channel_id": $shipbob_channel_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Return Order
#
# GET /2026-01/return/{id}
# operationId: get-return-order
export def "2026-01-return get-return-order" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --shipbob-channel-id: string # Retrieve your channel ID from the [GET /channel](/api/channels/get-channels) endpoint. Use the channel ID that has write scopes.
]: nothing -> record<arrived_date: string, awaiting_arrival_date: string, cancelled_date: string, channel: record<id: int, name: string>, completed_date: string, customer_name: string, fulfillment_center: record<id: int, name: string>, id: int, insert_date: string, inventory: table<action_requested: record, action_taken: list, barcodes: list, id: int, lot_information: record, name: string, quantity: int, sku: string>, invoice: record<amount: float, currency_code: string>, original_shipment_id: int, processing_date: string, reference_id: string, return_type: string, shipment_tracking_number: string, status: string, status_history: table<status: string, timestamp: string>, store_order_id: string, tracking_number: string, transactions: table<amount: float, transaction_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/return/($id)")
  let extra_headers = {"Authorization": $Authorization, "shipbob_channel_id": $shipbob_channel_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit Return Order
#
# PUT /2026-01/return/{id}
# operationId: edit-return-order
# --fulfillment_center shape: {id: int, name?: string}
# --inventory item shape: {id: int, lot_date?: string, lot_number?: string, quantity: int, requested_action: "Default"|"Restock"|"Quarantine"|"Dispose"}
export def "2026-01-return edit-return-order" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  fulfillment_center: record # A Facility to process Returns. — shape: {id: int, name?: string}
  inventory: list # Array of inventory items being returned — item shape: {id: int, lot_date?: string, lot_number?: string, quantity: int, requested_action: "Default"|"Restock"|"Quarantine"|"Dispose"}
  --original-shipment-id: int # Shipment from which the items in the return originated <example>123456</example> (nullable)
  reference_id: string # Client-defined external unique identifier for the return order.             If tracking id is not provided, this value must appear on the box label as RMA. <example>Example: ShipBob_Return_123</example>
  --tracking-number: string # Tracking number for the return shipment <example>1Z9999999999999999</example> (nullable)
]: any -> record<channel: record<id: int, name: string>, completed_date: string, customer_name: string, fulfillment_center: record<id: int, name: string>, id: int, insert_date: string, inventory: table<action_requested: record, action_taken: list, id: int, name: string, quantity: int>, invoice_amount: float, original_shipment_id: int, reference_id: string, return_type: string, status: string, store_order_id: string, tracking_number: string, transactions: table<amount: float, transaction_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/return/($id)")
  let body = {fulfillment_center: $fulfillment_center, inventory: $inventory, original_shipment_id: $original_shipment_id, reference_id: $reference_id, tracking_number: $tracking_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel Return order
#
# POST /2026-01/return/{id}:cancel
# operationId: cancel-return-order
export def "2026-01-return cancel-return-order" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/return/($id):cancel")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Subscription
#
# POST /2026-01/webhook
# operationId: create-subscription
export def "2026-01-webhook create-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --description: string # Description of the webhook subscription. (nullable)
  --secret: string # A secret key used to sign the webhook payload for verifying its authenticity on the receiver's end. (nullable)
  topics: list # The event types for which webhook callbacks will be received.
  --body-url: string # The URL that will be called when an event matching the subscription topic occurs. The URL must use HTTPS, accept POST requests, and handle content of type application/json. (format: uri)
]: any -> record<created_at: string, description: string, id: string, secret: string, topics: list<string>, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2026-01/webhook")
  let body = {description: $description, secret: $secret, topics: $topics, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Subscriptions
#
# GET /2026-01/webhook
# operationId: get-subscriptions
export def "2026-01-webhook get-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --RecordsPerPage: int # Number of webhooks returned per page in a paginated response.
  --Cursor: string # [Optional] A pagination token used to retrieve the next or previous page of results. Omit to start at the first page.
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<items: table<created_at: string, description: string, enabled: bool, id: string, topics: list, url: string>, next: string, prev: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "RecordsPerPage" $RecordsPerPage "scalar") (serialize-qp "Cursor" $Cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2026-01/webhook" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Subscription
#
# DELETE /2026-01/webhook/{id}
# operationId: delete-subscription
export def "2026-01-webhook delete-subscription" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/webhook/($id)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Locations
#
# GET /2026-01/location
# operationId: get-locations
export def "2026-01-location get-locations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --IncludeInactive: string@bool-completer # Whether the inactive locations should be included or not
  --ReceivingEnabled: string@bool-completer # Return all the receiving enabled locations
  --AccessGranted: string@bool-completer # Return all the access granted locations
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> table<abbreviation: string, access_granted: bool, attributes: list<string>, id: int, is_active: bool, is_receiving_enabled: bool, is_shipping_enabled: bool, name: string, region: record<id: int, name: string>, services: list<record>, timezone: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "IncludeInactive" $IncludeInactive "scalar") (serialize-qp "ReceivingEnabled" $ReceivingEnabled "scalar") (serialize-qp "AccessGranted" $AccessGranted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2026-01/location" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Transactions
#
# POST /2026-01/transactions:query
# operationId: search-transactions
export def "2026-01-transactions-query search-transactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Cursor: string # [Optional] A pagination token used to jump to first, last, next or previous pages. When supplied, it overrides all other filter parameters.
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --from-date: string # Start date for filtering transactions by charge date. Defaults to 7 days before the current date if not specified. (nullable, format: date-time)
  --invoice-ids: list # List of invoice IDs to filter transactions by. (nullable)
  --invoiced-status: string@bool-completer # Filter transactions by invoicing status. True returns billed transactions, false returns unbilled transactions, and null returns both billed and unbilled transactions. (nullable)
  --page-size: int # Number of transactions to return per page. Default is 100. Must be between 1 and 1000.
  --reference-ids: list # List of reference IDs (such as Shipment IDs, WRO IDs) to filter transactions. Can be numeric or string identifiers. (nullable)
  --reference-types: list # The types of references associated with the reference IDs to filter by. (nullable)
  --sort-order: string@sort-order-completer # Sort order for results. Ascending sorts from lowest to highest, Descending sorts from highest to lowest. (default: Descending)
  --to-date: string # End date for filtering transactions by charge date. Defaults to the current date if not specified. (nullable, format: date-time)
  --transaction-fees: list # List of transaction fee types to filter by. To get all available transaction fees, use the '/transaction-fees' endpoint. (nullable)
  --transaction-types: list # The classification or nature of the transactions to filter by. (nullable)
]: any -> record<first: string, items: table<additional_details: record, amount: float, charge_date: string, currency_code: string, fulfillment_center: string, invoice_date: string, invoice_id: int, invoice_type: any, invoiced_status: bool, reference_id: string, reference_type: any, taxes: list, transaction_fee: string, transaction_id: string, transaction_type: any>, last: string, next: string, prev: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Cursor" $Cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2026-01/transactions:query" $qp)
  let body = {from_date: $from_date, invoice_ids: $invoice_ids, invoiced_status: $invoiced_status, page_size: $page_size, reference_ids: $reference_ids, reference_types: $reference_types, sort_order: $sort_order, to_date: $to_date, transaction_fees: $transaction_fees, transaction_types: $transaction_types} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Invoices
#
# GET /2026-01/invoices
# operationId: get-invoices
export def "2026-01-invoices get-invoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Cursor: string # [Optional] A pagination token used to jump to first, last, next or previous pages. When supplied, it overrides all other filter parameters.
  --FromDate: string # [Optional] Start date for filtering invoices by invoice date. Default is current - 1 month date.  (format: date-time)
  --ToDate: string # [Optional] End date for filtering invoices by invoice date. Default is current date.  (format: date-time)
  --InvoiceTypes: list # [Optional] Filter invoices by invoice type.
  --PageSize: int # Number of invoices to return per page (default: 100). Must be between 1 and 1000.
  --SortOrder: string # Sort invoices by Invoice Date. Values - Ascending, Descending. Default: Descending.
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<first: string, items: table<amount: float, currency_code: string, invoice_date: string, invoice_id: int, invoice_type: any, running_balance: float>, last: string, next: string, prev: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Cursor" $Cursor "scalar") (serialize-qp "FromDate" $FromDate "scalar") (serialize-qp "ToDate" $ToDate "scalar") (serialize-qp "InvoiceTypes" $InvoiceTypes "multi") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "SortOrder" $SortOrder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2026-01/invoices" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Transactions by Invoice ID
#
# GET /2026-01/invoices/{invoiceId}/transactions
# operationId: get-transactions-by-invoice-id
export def "2026-01-invoices-transactions get-transactions-by-invoice-id" [
  invoiceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Cursor: string # [Optional] A pagination token used to jump to first, last, next or previous pages. When supplied, it overrides all other filter parameters.
  --PageSize: int # Number of transactions to return per page (default is 100, to be entered when API is called for first time). Must be between 1 and 1000.
  --SortOrder: string # Sort order of the results. Valid values: Ascending or Descending (default: Descending).
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<first: string, items: table<additional_details: record, amount: float, charge_date: string, currency_code: string, fulfillment_center: string, invoice_date: string, invoice_id: int, invoice_type: any, invoiced_status: bool, reference_id: string, reference_type: any, taxes: list, transaction_fee: string, transaction_id: string, transaction_type: any>, last: string, next: string, prev: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Cursor" $Cursor "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "SortOrder" $SortOrder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/2026-01/invoices/($invoiceId)/transactions" $qp)
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Transaction Fees
#
# GET /2026-01/transaction-fees
# operationId: get-transaction-fees
export def "2026-01-transaction-fees get-transaction-fees" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<fee_list: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2026-01/transaction-fees")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Simulates Shipment
#
# POST /2026-01/simulate/shipment
# operationId: simulates-shipment
# --simulation shape: {action: any, delay?: int, next?: record}
export def "2026-01-simulate-shipment simulates-shipment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
  --shipment-id: string # The ShipBob shipment id the simulation should target. (nullable)
  simulation: record # Defines a simulation action to run, with an optional delay and an optional next action to allow chaining. — shape: {action: any, delay?: int, next?: record}
]: any -> record<message: string, simulation_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/2026-01/simulate/shipment")
  let body = {shipment_id: $shipment_id, simulation: $simulation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Simulation Status
#
# GET /2026-01/simulate/status/{simulationId}
# operationId: get-simulation-status
export def "2026-01-simulate-status get-simulation-status" [
  simulationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Authentication using Personal Access Token (PAT) token or OAuth2
]: nothing -> record<entity_id: string, entity_type: string, simulation: record<action: any, message: string, next: any, schedule_time: string, status: string>, simulation_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/2026-01/simulate/status/($simulationId)")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
