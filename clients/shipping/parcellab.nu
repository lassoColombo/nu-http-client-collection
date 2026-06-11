# Auto-generated client for parcelLab API v4
# Source: https://raw.githubusercontent.com/api-evangelist/parcellab/main/openapi/parcellab-openapi.yml
# Auth: --token flag or $env.PARCELLAB_API_TOKEN

const BASE_URL = "https://api.parcellab.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PARCELLAB_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://api.parcellab.com" "https://api.eu.parcellab.com" "https://api.us.parcellab.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def calibration-completer [] { ["aggressive" "balanced" "conservative"] }
def status-completer [] { ["approved" "cancelled" "closed" "created" "invalid" "pending_approval" "pending_label" "processing_failed" "rejected" "submitted"] }
def reference-type-completer [] { ["return_registration" "tracking"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "track-orders upsertOrder" } } | get name | first)
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

# Create or Update Order
#
# PUT /v4/track/orders/
# operationId: upsertOrder
# --shipping_address shape: {name?: string, street?: string, house_no?: string, city?: string, postal_code?: string, country_iso3?: string, state?: string, phone?: string, email?: string}
# --articles_order item shape: {sku?: string, name?: string, quantity?: int, price?: float, currency?: string, image_url?: string}
# --mutations item shape: {type?: "add_tracking"|"cancel_tracking"|"cancel_order"|"change_line_item_quantity"|"add_line_item"|"replace_line_item", payload?: record}
export def "track-orders upsertOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  account: int
  order_number: string
  --destination-country-iso3: string
  --recipient-email: string # format: email
  --recipient-name: string
  --shipping-address: record # shape: {name?: string, street?: string, house_no?: string, city?: string, postal_code?: string, country_iso3?: string, state?: string, phone?: string, email?: string}
  --articles-order: list # item shape: {sku?: string, name?: string, quantity?: int, price?: float, currency?: string, image_url?: string}
  --mutations: list # item shape: {type?: "add_tracking"|"cancel_tracking"|"cancel_order"|"change_line_item_quantity"|"add_line_item"|"replace_line_item", payload?: record}
]: any -> record<external_id: string, order_number: string, mutations: table<type: string, result: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/track/orders/")
  let body = {account: $account, order_number: $order_number, destination_country_iso3: $destination_country_iso3, recipient_email: $recipient_email, recipient_name: $recipient_name, shipping_address: $shipping_address, articles_order: $articles_order, mutations: $mutations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Order Status
#
# GET /v4/track/orders/info/
# operationId: getOrderInfo
export def "track-orders-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account: int
  --order-number: string
  --tracking-number: string
  --courier: string
  --external-order-id: string # format: uuid
  --external-reference: string
  --customer-number: string
  --recipient-email: string # format: email
  --recipient-postal-code: string
  --client-key: string
  --lang: string # default: en
  --s: string # HMAC security signature.
  --live-refresh: string@bool-completer
  --show-returns: string@bool-completer
  --tracking-id: string
  --single-tracking: string@bool-completer
]: nothing -> record<order_number: string, client_key: string, order_date: string, recipient_name: string, recipient_email: string, destination_country_iso3: string, trackings: table<tracking_number: string, courier: string, status: string, lifecycle: string, delivery_estimate: string, checkpoints: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account" $account "scalar") (serialize-qp "order_number" $order_number "scalar") (serialize-qp "tracking_number" $tracking_number "scalar") (serialize-qp "courier" $courier "scalar") (serialize-qp "external_order_id" $external_order_id "scalar") (serialize-qp "external_reference" $external_reference "scalar") (serialize-qp "customer_number" $customer_number "scalar") (serialize-qp "recipient_email" $recipient_email "scalar") (serialize-qp "recipient_postal_code" $recipient_postal_code "scalar") (serialize-qp "client_key" $client_key "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "s" $s "scalar") (serialize-qp "live_refresh" $live_refresh "scalar") (serialize-qp "show_returns" $show_returns "scalar") (serialize-qp "tracking_id" $tracking_id "scalar") (serialize-qp "single_tracking" $single_tracking "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/track/orders/info/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send Shop or Warehouse Event
#
# POST /v4/track/events/
# operationId: sendShopEvent
export def "track-events sendShopEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  event_timestamp: string # format: date-time
  event_status: string
  --location: string
  --event-details: string
  --placeholder-value: string
  --courier: string
  --tracking-number: string
  --account: int
  --reference-number: string
  --order-number: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/track/events/")
  let body = {event_timestamp: $event_timestamp, event_status: $event_status, location: $location, event_details: $event_details, placeholder_value: $placeholder_value, courier: $courier, tracking_number: $tracking_number, account: $account, reference_number: $reference_number, order_number: $order_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Look Up Pickup/Drop-Off Locations
#
# POST /v4/track/place-info/lookup/
# operationId: lookupPlaceInfo
# --lookups item shape: {courier?: string, service_level?: string, query?: string}
# --location shape: {latitude?: float, longitude?: float}
# --location_address shape: {name?: string, street?: string, house_no?: string, city?: string, postal_code?: string, country_iso3?: string, state?: string, phone?: string, email?: string}
export def "track-place-info-lookup lookupPlaceInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account: list
  --ordering: string
  account: int
  country_iso3: string
  lookups: list # item shape: {courier?: string, service_level?: string, query?: string}
  --location: record # shape: {latitude?: float, longitude?: float}
  --external-reference: string
  --location-address: record # shape: {name?: string, street?: string, house_no?: string, city?: string, postal_code?: string, country_iso3?: string, state?: string, phone?: string, email?: string}
]: any -> table<courier: string, place_type: string, address: record<name: string, street: string, house_no: string, city: string, postal_code: string, country_iso3: string, state: string, phone: string, email: string>, location: record<latitude: float, longitude: float>, opening_hours: record, distance_meters: int, services: list<string>, phone: string, website: string, external_reference: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account" $account "multi") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/track/place-info/lookup/" $qp)
  let body = {account: $account, country_iso3: $country_iso3, lookups: $lookups, location: $location, external_reference: $external_reference, location_address: $location_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Predict Delivery Date
#
# GET /v4/promise/prediction/predict/
# operationId: predictDelivery
export def "promise-prediction-predict predictDelivery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account: int
  --destination-country-iso3: string
  --destination-postal-code: string
  --courier: string
  --service-level: string
  --warehouse: string
  --language-iso2: string
  --calibration: string@calibration-completer
  --dispatch-now: string@bool-completer
  --now-override: string # format: date-time
  --draft: string@bool-completer
]: nothing -> record<request_id: string, success: bool, prediction: table<courier: string, service_level: string, date_min: string, date_max: string, date_likely: string, days_min: int, days_max: int, days_likely: int, cutoff: string, localized: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account" $account "scalar") (serialize-qp "destination_country_iso3" $destination_country_iso3 "scalar") (serialize-qp "destination_postal_code" $destination_postal_code "scalar") (serialize-qp "courier" $courier "scalar") (serialize-qp "service_level" $service_level "scalar") (serialize-qp "warehouse" $warehouse "scalar") (serialize-qp "language_iso2" $language_iso2 "scalar") (serialize-qp "calibration" $calibration "scalar") (serialize-qp "dispatch_now" $dispatch_now "scalar") (serialize-qp "now_override" $now_override "scalar") (serialize-qp "draft" $draft "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/promise/prediction/predict/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Return Registrations
#
# GET /v4/returns/return-registrations/
# operationId: listReturnRegistrations
export def "returns-return-registrations listReturnRegistrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account: int
  --limit: int
  --offset: int
  --ordering: string
]: nothing -> record<count: int, next: string, previous: string, results: table<external_id: string, sequence_number: string, account: int, code: string, reference: string, customer_email: string, customer_address: record, status: string, order_date: string, order_delivery_date: string, order_shipping_date: string, order_total_amount: float, order_shipping_amount: float, order_tax_amount: float, order_currency: string, articles_order: list, articles_return: list, return_labels: list, tags: list, metadata: record, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account" $account "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/returns/return-registrations/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Return Registration
#
# POST /v4/returns/return-registrations/
# operationId: createReturnRegistration
# --customer_address shape: {name?: string, street?: string, house_no?: string, city?: string, postal_code?: string, country_iso3?: string, state?: string, phone?: string, email?: string}
# --articles_order item shape: {sku?: string, name?: string, quantity?: int, price?: float, currency?: string, image_url?: string}
# --articles_return item shape: {sku?: string, name?: string, quantity?: int, price?: float, currency?: string, image_url?: string}
export def "returns-return-registrations createReturnRegistration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  account: int
  code: string
  reference: string
  customer_email: string
  --customer-address: record # shape: {name?: string, street?: string, house_no?: string, city?: string, postal_code?: string, country_iso3?: string, state?: string, phone?: string, email?: string}
  --status: string@status-completer
  --order-date: string # format: date-time
  --order-delivery-date: string # format: date-time
  --order-shipping-date: string # format: date-time
  --order-total-amount: float
  --order-shipping-amount: float
  --order-tax-amount: float
  --order-currency: string
  --articles-order: list # item shape: {sku?: string, name?: string, quantity?: int, price?: float, currency?: string, image_url?: string}
  --articles-return: list # item shape: {sku?: string, name?: string, quantity?: int, price?: float, currency?: string, image_url?: string}
  --tags: list
  --metadata: record
]: any -> record<external_id: string, sequence_number: string, account: int, code: string, reference: string, customer_email: string, customer_address: record<name: string, street: string, house_no: string, city: string, postal_code: string, country_iso3: string, state: string, phone: string, email: string>, status: string, order_date: string, order_delivery_date: string, order_shipping_date: string, order_total_amount: float, order_shipping_amount: float, order_tax_amount: float, order_currency: string, articles_order: table<sku: string, name: string, quantity: int, price: float, currency: string, image_url: string>, articles_return: table<sku: string, name: string, quantity: int, price: float, currency: string, image_url: string>, return_labels: list<record>, tags: list<string>, metadata: record, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/returns/return-registrations/")
  let body = {account: $account, code: $code, reference: $reference, customer_email: $customer_email, customer_address: $customer_address, status: $status, order_date: $order_date, order_delivery_date: $order_delivery_date, order_shipping_date: $order_shipping_date, order_total_amount: $order_total_amount, order_shipping_amount: $order_shipping_amount, order_tax_amount: $order_tax_amount, order_currency: $order_currency, articles_order: $articles_order, articles_return: $articles_return, tags: $tags, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Return Registration
#
# GET /v4/returns/return-registrations/{external_id}/
# operationId: getReturnRegistration
export def "returns-return-registrations get" [
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<external_id: string, sequence_number: string, account: int, code: string, reference: string, customer_email: string, customer_address: record<name: string, street: string, house_no: string, city: string, postal_code: string, country_iso3: string, state: string, phone: string, email: string>, status: string, order_date: string, order_delivery_date: string, order_shipping_date: string, order_total_amount: float, order_shipping_amount: float, order_tax_amount: float, order_currency: string, articles_order: table<sku: string, name: string, quantity: int, price: float, currency: string, image_url: string>, articles_return: table<sku: string, name: string, quantity: int, price: float, currency: string, image_url: string>, return_labels: list<record>, tags: list<string>, metadata: record, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/returns/return-registrations/($external_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Return Configurations
#
# GET /v4/returns/returns-configurations/
# operationId: listReturnConfigurations
export def "returns-returns-configurations listReturnConfigurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account: int
  --limit: int
  --offset: int
  --ordering: string
]: nothing -> table<id: string, account: int, code: string, name: string, return_periods: list<record>, return_reasons: list<record>, compensation_methods: list<record>, carrier_options: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account" $account "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/returns/returns-configurations/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Return Configuration
#
# GET /v4/returns/returns-configurations/{id}/
# operationId: getReturnConfiguration
export def "returns-returns-configurations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, account: int, code: string, name: string, return_periods: list<record>, return_reasons: list<record>, compensation_methods: list<record>, carrier_options: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/returns/returns-configurations/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Document Templates
#
# GET /v4/returns/document-templates/
# operationId: listDocumentTemplates
export def "returns-document-templates listDocumentTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account: int
  --limit: int
  --offset: int
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account" $account "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/returns/document-templates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Evaluate Campaign Targeting
#
# GET /v4/campaign/evaluate/
# operationId: evaluateCampaign
export def "campaign-evaluate evaluateCampaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountId: int
  --campaignId: string
  --language: string
  --medium: string
  --message: string
  --orderNumber: string
  --preview: string@bool-completer
  --status: string
  --trackingId: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $accountId "scalar") (serialize-qp "campaignId" $campaignId "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "medium" $medium "scalar") (serialize-qp "message" $message "scalar") (serialize-qp "orderNumber" $orderNumber "scalar") (serialize-qp "preview" $preview "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "trackingId" $trackingId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/campaign/evaluate/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Campaign Redirect Analytics
#
# GET /v4/campaign/redirect/
# operationId: campaignRedirect
export def "campaign-redirect campaignRedirect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --campaignId: string
  --trackingId: string
  --eventType: string
  --medium: string
  --redirectUrl: string # format: uri
  --customerSegmentationId: string
  --emailId: string
  --contentType: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "campaignId" $campaignId "scalar") (serialize-qp "trackingId" $trackingId "scalar") (serialize-qp "eventType" $eventType "scalar") (serialize-qp "medium" $medium "scalar") (serialize-qp "redirectUrl" $redirectUrl "scalar") (serialize-qp "customerSegmentationId" $customerSegmentationId "scalar") (serialize-qp "emailId" $emailId "scalar") (serialize-qp "contentType" $contentType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/campaign/redirect/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Survey
#
# GET /v4/survey/survey/{id}/
# operationId: getSurvey
export def "survey-survey get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, status: string, type: string, surveyUrl: string, config: record, editable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/survey/survey/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Survey Answer
#
# GET /v4/survey/survey/{id}/answer/
# operationId: getSurveyAnswer
export def "survey-survey-answer get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ref-id: string
  --reference-type: string@reference-type-completer
]: nothing -> record<id: string, name: string, status: string, type: string, surveyUrl: string, config: record, editable: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ref_id" $ref_id "scalar") (serialize-qp "reference_type" $reference_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/survey/survey/($id)/answer/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit Survey Answer
#
# POST /v4/survey/survey/{id}/answer/
# operationId: submitSurveyAnswer
export def "survey-survey-answer submitSurveyAnswer" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record
  --is-complete: string@bool-completer
  --reference-id: string
  --reference-type: string@reference-type-completer
]: any -> record<isComplete: bool, detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/survey/survey/($id)/answer/")
  let body = {data: $data, is_complete: $is_complete, reference_id: $reference_id, reference_type: $reference_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Survey Themes
#
# GET /v4/survey/survey/themes/
# operationId: listSurveyThemes
export def "survey-survey-themes listSurveyThemes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --default: string@bool-completer
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "default" $default "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/survey/survey/themes/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
