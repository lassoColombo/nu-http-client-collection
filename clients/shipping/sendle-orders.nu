# Auto-generated client for Sendle Orders API v1.0
# Source: https://raw.githubusercontent.com/api-evangelist/sendle/main/openapi/sendle-orders-api-openapi.yml
# Auth: --token flag or $env.SENDLE_ORDERS_API_TOKEN

const BASE_URL = "https://api.sendle.com/api"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SENDLE_ORDERS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://api.sendle.com/api" "https://sandbox.sendle.com/api"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def first-mile-option-completer [] { ["drop off" "pickup"] }
def packaging-type-completer [] { ["box" "satchel" "unlimited satchel"] }
def contents-type-completer [] { ["Documents" "Gift" "Merchandise" "Other" "Returned Goods" "Sample"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "orders createOrder" } } | get name | first)
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

# Create An Order
#
# POST /orders
# operationId: createOrder
# --sender shape: {contact?: record, address?: record, instructions?: string, tax_ids?: record}
# --receiver shape: {contact?: record, address?: record, instructions?: string, tax_ids?: record}
# --weight shape: {value: string, units: "kg"|"lb"|"g"|"oz"}
# --dimensions shape: {length: string, width: string, height: string, units: "cm"|"in"}
# --volume shape: {value?: string, units?: "l"|"m3"|"in3"|"ft3"}
# --cover shape: {total_cover?: record, price?: record}
# --parcel_contents item shape: {description: string, value: string, quantity?: int, country_of_origin: string, hs_code: string, manufacturer_id?: string}
@deprecated --flag first-mile-option
export def "orders createOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Idempotency-Key: string # Client-provided key to make order creation idempotent.
  sender: record # shape: {contact?: record, address?: record, instructions?: string, tax_ids?: record}
  receiver: record # shape: {contact?: record, address?: record, instructions?: string, tax_ids?: record}
  description: string
  weight: record # shape: {value: string, units: "kg"|"lb"|"g"|"oz"}
  dimensions: record # shape: {length: string, width: string, height: string, units: "cm"|"in"}
  --volume: record # shape: {value?: string, units?: "l"|"m3"|"in3"|"ft3"}
  --customer-reference: string
  --product-code: string
  --first-mile-option: string@first-mile-option-completer # DEPRECATED
  --pickup-date: string # format: date
  --packaging-type: string@packaging-type-completer
  --metadata: record
  --hide-pickup-address: oneof<nothing, bool>
  --cover: record # shape: {total_cover?: record, price?: record}
  --parcel-contents: list # item shape: {description: string, value: string, quantity?: int, country_of_origin: string, hs_code: string, manufacturer_id?: string}
  --contents-type: string@contents-type-completer
]: any -> record<order_id: string, state: string, order_url: string, sendle_reference: string, tracking_url: string, metadata: record, labels: table<format: string, size: string, url: string>, scheduling: record<is_cancellable: bool, pickup_date: string, picked_up_on: string, delivered_on: string, estimated_delivery_date_minimum: string, estimated_delivery_date_maximum: string>, hide_pickup_address: bool, description: string, weight: record<value: string, units: string>, volume: record<value: string, units: string>, dimensions: record<length: string, width: string, height: string, units: string>, customer_reference: string, sender: record<contact: record<name: string, phone: string, email: string, company: string, sendle_id: string>, address: record<address_line1: string, address_line2: string, suburb: string, postcode: string, state_name: string, country: string>, instructions: string, tax_ids: record<ioss: string>>, receiver: record<contact: record<name: string, phone: string, email: string, company: string, sendle_id: string>, address: record<address_line1: string, address_line2: string, suburb: string, postcode: string, state_name: string, country: string>, instructions: string, tax_ids: record<ioss: string>>, route: record<description: string, type: string, delivery_guarantee_status: string>, price: record<gross: record<amount: float, currency: string>, net: record<amount: float, currency: string>, tax: record<amount: float, currency: string>>, price_breakdown: record, tax_breakdown: record, cover: record<total_cover: record<amount: float>, price: record<gross: record, net: record, tax: record>>, packaging_type: string, parcel_contents: table<description: string, value: string, quantity: int, country_of_origin: string, hs_code: string, manufacturer_id: string>, contents_type: string, product: record<code: string, name: string, first_mile_option: string, service: string, atl_only: bool>, expires_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders")
  let body = {sender: $sender, receiver: $receiver, description: $description, weight: $weight, dimensions: $dimensions, volume: $volume, customer_reference: $customer_reference, product_code: $product_code, first_mile_option: $first_mile_option, pickup_date: $pickup_date, packaging_type: $packaging_type, metadata: $metadata, hide_pickup_address: $hide_pickup_address, cover: $cover, parcel_contents: $parcel_contents, contents_type: $contents_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Idempotency-Key": $Idempotency_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# View An Order
#
# GET /orders/{id}
# operationId: viewOrder
export def "orders viewOrder" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<order_id: string, state: string, order_url: string, sendle_reference: string, tracking_url: string, metadata: record, labels: table<format: string, size: string, url: string>, scheduling: record<is_cancellable: bool, pickup_date: string, picked_up_on: string, delivered_on: string, estimated_delivery_date_minimum: string, estimated_delivery_date_maximum: string>, hide_pickup_address: bool, description: string, weight: record<value: string, units: string>, volume: record<value: string, units: string>, dimensions: record<length: string, width: string, height: string, units: string>, customer_reference: string, sender: record<contact: record<name: string, phone: string, email: string, company: string, sendle_id: string>, address: record<address_line1: string, address_line2: string, suburb: string, postcode: string, state_name: string, country: string>, instructions: string, tax_ids: record<ioss: string>>, receiver: record<contact: record<name: string, phone: string, email: string, company: string, sendle_id: string>, address: record<address_line1: string, address_line2: string, suburb: string, postcode: string, state_name: string, country: string>, instructions: string, tax_ids: record<ioss: string>>, route: record<description: string, type: string, delivery_guarantee_status: string>, price: record<gross: record<amount: float, currency: string>, net: record<amount: float, currency: string>, tax: record<amount: float, currency: string>>, price_breakdown: record, tax_breakdown: record, cover: record<total_cover: record<amount: float>, price: record<gross: record, net: record, tax: record>>, packaging_type: string, parcel_contents: table<description: string, value: string, quantity: int, country_of_origin: string, hs_code: string, manufacturer_id: string>, contents_type: string, product: record<code: string, name: string, first_mile_option: string, service: string, atl_only: bool>, expires_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel An Order
#
# POST /orders/{id}/cancel
# operationId: cancelOrder
export def "orders-cancel cancelOrder" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<order_id: string, state: string, order_url: string, cancelled_at: string, cancellable: bool, cancellation_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return An Order
#
# POST /orders/{id}/return
# operationId: returnOrder
# --receiver shape: {instructions?: string}
export def "orders-return returnOrder" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --customer-reference: string
  --receiver: record # shape: {instructions?: string}
]: any -> record<order_id: string, state: string, order_url: string, sendle_reference: string, tracking_url: string, metadata: record, labels: table<format: string, size: string, url: string>, scheduling: record<is_cancellable: bool, pickup_date: string, picked_up_on: string, delivered_on: string, estimated_delivery_date_minimum: string, estimated_delivery_date_maximum: string>, hide_pickup_address: bool, description: string, weight: record<value: string, units: string>, volume: record<value: string, units: string>, dimensions: record<length: string, width: string, height: string, units: string>, customer_reference: string, sender: record<contact: record<name: string, phone: string, email: string, company: string, sendle_id: string>, address: record<address_line1: string, address_line2: string, suburb: string, postcode: string, state_name: string, country: string>, instructions: string, tax_ids: record<ioss: string>>, receiver: record<contact: record<name: string, phone: string, email: string, company: string, sendle_id: string>, address: record<address_line1: string, address_line2: string, suburb: string, postcode: string, state_name: string, country: string>, instructions: string, tax_ids: record<ioss: string>>, route: record<description: string, type: string, delivery_guarantee_status: string>, price: record<gross: record<amount: float, currency: string>, net: record<amount: float, currency: string>, tax: record<amount: float, currency: string>>, price_breakdown: record, tax_breakdown: record, cover: record<total_cover: record<amount: float>, price: record<gross: record, net: record, tax: record>>, packaging_type: string, parcel_contents: table<description: string, value: string, quantity: int, country_of_origin: string, hs_code: string, manufacturer_id: string>, contents_type: string, product: record<code: string, name: string, first_mile_option: string, service: string, atl_only: bool>, expires_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($id)/return")
  let body = {customer_reference: $customer_reference, receiver: $receiver} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# View A Return Order
#
# GET /orders/{id}/return
# operationId: viewReturnOrder
export def "orders-return viewReturnOrder" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<order_id: string, state: string, order_url: string, sendle_reference: string, tracking_url: string, metadata: record, labels: table<format: string, size: string, url: string>, scheduling: record<is_cancellable: bool, pickup_date: string, picked_up_on: string, delivered_on: string, estimated_delivery_date_minimum: string, estimated_delivery_date_maximum: string>, hide_pickup_address: bool, description: string, weight: record<value: string, units: string>, volume: record<value: string, units: string>, dimensions: record<length: string, width: string, height: string, units: string>, customer_reference: string, sender: record<contact: record<name: string, phone: string, email: string, company: string, sendle_id: string>, address: record<address_line1: string, address_line2: string, suburb: string, postcode: string, state_name: string, country: string>, instructions: string, tax_ids: record<ioss: string>>, receiver: record<contact: record<name: string, phone: string, email: string, company: string, sendle_id: string>, address: record<address_line1: string, address_line2: string, suburb: string, postcode: string, state_name: string, country: string>, instructions: string, tax_ids: record<ioss: string>>, route: record<description: string, type: string, delivery_guarantee_status: string>, price: record<gross: record<amount: float, currency: string>, net: record<amount: float, currency: string>, tax: record<amount: float, currency: string>>, price_breakdown: record, tax_breakdown: record, cover: record<total_cover: record<amount: float>, price: record<gross: record, net: record, tax: record>>, packaging_type: string, parcel_contents: table<description: string, value: string, quantity: int, country_of_origin: string, hs_code: string, manufacturer_id: string>, contents_type: string, product: record<code: string, name: string, first_mile_option: string, service: string, atl_only: bool>, expires_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($id)/return")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
