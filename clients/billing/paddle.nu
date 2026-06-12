# Auto-generated client for Paddle API v1.0
# Source: https://raw.githubusercontent.com/PaddleHQ/paddle-openapi/main/v1/openapi.yaml
# Auth: --token flag or $env.PADDLE_API_TOKEN

const BASE_URL = "https://sandbox-api.paddle.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PADDLE_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://sandbox-api.paddle.com" "https://api.paddle.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["active" "archived"] }
def action-completer [] { ["chargeback" "chargeback_reverse" "chargeback_warning" "chargeback_warning_reverse" "credit" "credit_reverse" "refund"] }
def disposition-completer [] { ["attachment" "inline"] }
def mode-completer [] { ["custom" "standard"] }
def traffic-source-completer [] { ["all" "platform" "simulation"] }
def type-completer [] { ["custom" "standard"] }
def tax-category-completer [] { ["digital-goods" "ebooks" "implementation-services" "professional-services" "saas" "software-programming-services" "standard" "training-services" "website-hosting"] }
def collection-mode-completer [] { ["automatic" "manual"] }
def proration-billing-mode-completer [] { ["do_not_bill" "full_immediately" "full_next_billing_period" "prorated_immediately" "prorated_next_billing_period"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "customers-addresses list-addresses" } } | get name | first)
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

# List addresses for a customer
#
# GET /customers/{customer_id}/addresses
# Docs: https://developer.paddle.com/api-reference/addresses/list-addresses — List addresses for a customer
# operationId: list-addresses
export def "customers-addresses list-addresses" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list # Return only the IDs specified. Use a comma-separated list to get multiple entities.
  --after: string # Return entities after the specified Paddle ID when working with paginated endpoints. Used in the `meta.pagination.next` URL in responses for list operations.
  --per-page: int # Set how many entities are returned per page. Paddle returns the maximum number of results if a number greater than the maximum is requested. Check `meta.pagination.per_page` in the response to see how many were returned.  Default: `50`; Maximum: `200`. (default: 50)
  --order-by: string # Order returned entities by the specified field and direction (`[ASC]` or `[DESC]`). For example, `?order_by=id[ASC]`.  Valid fields for ordering: `id`. (default: id[DESC])
  --status: list # Return entities that match the specified status. Use a comma-separated list to specify multiple status values. (default: [active])
  --search: string # Return entities that match a search query. Searches all fields except `status`, `created_at`, and `updated_at`.
]: nothing -> record<data: table<id: record, customer_id: record, description: any, first_line: any, second_line: any, city: any, postal_code: any, region: any, country_code: record, custom_data: any, status: record, created_at: record, updated_at: record, import_meta: any>, meta: record<request_id: string, pagination: record<per_page: int, next: string, has_more: bool, estimated_total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "after" $after "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "status" $status "csv") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/customers/($customer_id)/addresses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an address for a customer
#
# POST /customers/{customer_id}/addresses
# Docs: https://developer.paddle.com/api-reference/addresses/create-address — Create an address for a customer
# operationId: create-address
export def "customers-addresses create-address" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: any # Memorable description for this address.
  --first-line: any # First line of this address.
  --second-line: any # Second line of this address.
  --city: any # City of this address.
  --postal-code: any # ZIP or postal code of this address. Required for some countries.
  --region: any # State, county, or region of this address.
  country_code: any # Supported two-letter ISO 3166-1 alpha-2 country code for this address.
  --custom-data: any # Your own structured key-value data.
  --import-meta: any # Import information for this entity. `null` if this entity is not imported.
]: any -> record<data: record<id: record, customer_id: record, description: any, first_line: any, second_line: any, city: any, postal_code: any, region: any, country_code: record, custom_data: any, status: record, created_at: record, updated_at: record, import_meta: any>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($customer_id)/addresses")
  let body = {description: $description, first_line: $first_line, second_line: $second_line, city: $city, postal_code: $postal_code, region: $region, country_code: $country_code, custom_data: $custom_data, import_meta: $import_meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an address for a customer
#
# GET /customers/{customer_id}/addresses/{address_id}
# Docs: https://developer.paddle.com/api-reference/addresses/get-address — Get an address for a customer
# operationId: get-address
export def "customers-addresses get-address" [
  address_id: string
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: record, customer_id: record, description: any, first_line: any, second_line: any, city: any, postal_code: any, region: any, country_code: record, custom_data: any, status: record, created_at: record, updated_at: record, import_meta: any>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($customer_id)/addresses/($address_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an address for a customer
#
# PATCH /customers/{customer_id}/addresses/{address_id}
# Docs: https://developer.paddle.com/api-reference/addresses/update-adddress — Update an address for a customer
# operationId: update-address
export def "customers-addresses update-address" [
  address_id: string
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: any # Memorable description for this address.
  --first-line: any # First line of this address.
  --second-line: any # Second line of this address.
  --city: any # City of this address.
  --postal-code: any # ZIP or postal code of this address. Required for some countries.
  --region: any # State, county, or region of this address.
  --country-code: any # Supported two-letter ISO 3166-1 alpha-2 country code for this address.
  --custom-data: any # Your own structured key-value data.
  --status: string@status-completer # Whether this entity can be used in Paddle.
]: any -> record<data: record<id: record, customer_id: record, description: any, first_line: any, second_line: any, city: any, postal_code: any, region: any, country_code: record, custom_data: any, status: record, created_at: record, updated_at: record, import_meta: any>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($customer_id)/addresses/($address_id)")
  let body = {description: $description, first_line: $first_line, second_line: $second_line, city: $city, postal_code: $postal_code, region: $region, country_code: $country_code, custom_data: $custom_data, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List adjustments
#
# GET /adjustments
# Docs: https://developer.paddle.com/api-reference/adjustments/list-adjustments — List adjustments
# operationId: list-adjustments
export def "adjustments list-adjustments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list # Return only the IDs specified. Use a comma-separated list to get multiple entities.
  --after: string # Return entities after the specified Paddle ID when working with paginated endpoints. Used in the `meta.pagination.next` URL in responses for list operations.
  --action: string@action-completer # Return entities for the specified action.
  --customer-id: list # Return entities related to the specified customer. Use a comma-separated list to specify multiple customer IDs.
  --order-by: string # Order returned entities by the specified field and direction (`[ASC]` or `[DESC]`). For example, `?order_by=id[ASC]`.  Valid fields for ordering: `id`. (default: id[DESC])
  --per-page: int # Set how many entities are returned per page. Paddle returns the maximum number of results if a number greater than the maximum is requested. Check `meta.pagination.per_page` in the response to see how many were returned.  Default: `10`; Maximum: `50`. (default: 10)
  --status: list # Return entities that match the specified status. Use a comma-separated list to specify multiple status values.
  --subscription-id: list # Return entities related to the specified subscription. Use a comma-separated list to specify multiple subscription IDs.
  --transaction-id: list # Return entities related to the specified transaction. Use a comma-separated list to specify multiple transaction IDs.
]: nothing -> record<data: table<id: record, action: string, type: record, transaction_id: record, subscription_id: any, customer_id: record, reason: string, credit_applied_to_balance: any, currency_code: record, status: record, items: list, totals: record, payout_totals: any, tax_rates_used: list, created_at: record, updated_at: record>, meta: record<request_id: string, pagination: record<per_page: int, next: string, has_more: bool, estimated_total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "after" $after "scalar") (serialize-qp "action" $action "scalar") (serialize-qp "customer_id" $customer_id "csv") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "status" $status "csv") (serialize-qp "subscription_id" $subscription_id "csv") (serialize-qp "transaction_id" $transaction_id "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/adjustments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an adjustment
#
# POST /adjustments
# Docs: https://developer.paddle.com/api-reference/adjustments/create-adjustment — Create an adjustment
# operationId: create-adjustment
export def "adjustments create-adjustment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  action: string@action-completer # How this adjustment impacts the related transaction.
  --type: any # default: partial
  --tax-mode: any # default: internal
  transaction_id: any # Paddle ID of the transaction that this adjustment is for, prefixed with `txn_`.  Automatically-collected transactions must be `completed`; manually-collected transactions must have a status of `billed` or `past_due`  You can't create an adjustment for a transaction that has a refund that's pending approval.
  reason: string # Why this adjustment was created. Appears in the Paddle dashboard. Retained for recordkeeping purposes.
  --items: any # List of transaction items to adjust. Required if `type` is not populated or set to `partial`.
]: any -> record<data: record<id: record, action: string, type: record, transaction_id: record, subscription_id: any, customer_id: record, reason: string, credit_applied_to_balance: any, currency_code: record, status: record, items: list<record>, totals: record<subtotal: string, tax: string, total: string, fee: string, retained_fee: string, earnings: string, currency_code: record>, payout_totals: any, tax_rates_used: list<record>, created_at: record, updated_at: record>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/adjustments")
  let body = {action: $action, type: $type, tax_mode: $tax_mode, transaction_id: $transaction_id, reason: $reason, items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a PDF credit note for an adjustment
#
# GET /adjustments/{adjustment_id}/credit-note
# Docs: https://developer.paddle.com/api-reference/adjustments/get-credit-note-pdf — Get a PDF credit note for an adjustment
# operationId: get-adjustment-credit-note
export def "adjustments-credit-note get-adjustment-credit-note" [
  adjustment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --disposition: string@disposition-completer # Determine whether the generated URL should download the PDF as an attachment saved locally, or open it inline in the browser.  Default: `attachment`.
]: nothing -> record<data: record<url: string>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "disposition" $disposition "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/adjustments/($adjustment_id)/credit-note" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List businesses for a customer
#
# GET /customers/{customer_id}/businesses
# Docs: https://developer.paddle.com/api-reference/businesses/list-businesses — List businesses for a customer
# operationId: list-businesses
export def "customers-businesses list-businesses" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list # Return only the IDs specified. Use a comma-separated list to get multiple entities.
  --after: string # Return entities after the specified Paddle ID when working with paginated endpoints. Used in the `meta.pagination.next` URL in responses for list operations.
  --per-page: int # Set how many entities are returned per page. Paddle returns the maximum number of results if a number greater than the maximum is requested. Check `meta.pagination.per_page` in the response to see how many were returned.  Default: `50`; Maximum: `200`. (default: 50)
  --order-by: string # Order returned entities by the specified field and direction (`[ASC]` or `[DESC]`). For example, `?order_by=id[ASC]`.  Valid fields for ordering: `id`. (default: id[DESC])
  --status: list # Return entities that match the specified status. Use a comma-separated list to specify multiple status values. (default: [active])
  --search: string # Return entities that match a search query. Searches all fields, including contacts, except `status`, `created_at`, and `updated_at`.
]: nothing -> record<data: table<id: record, customer_id: record, name: record, company_number: any, tax_identifier: any, status: record, contacts: list, created_at: record, updated_at: record, custom_data: any, import_meta: any>, meta: record<request_id: string, pagination: record<per_page: int, next: string, has_more: bool, estimated_total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "after" $after "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "status" $status "csv") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/customers/($customer_id)/businesses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a business for a customer
#
# POST /customers/{customer_id}/businesses
# Docs: https://developer.paddle.com/api-reference/businesses/create-business — Create a business for a customer
# operationId: create-business
export def "customers-businesses create-business" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: any # Name of this business.
  --company-number: any # Company number for this business.
  --tax-identifier: any # Tax or VAT Number for this business.
  --contacts: any # List of contacts related to this business, typically used for sending invoices.
  --custom-data: any # Your own structured key-value data.
  --import-meta: any # Import information for this entity. `null` if this entity is not imported.
]: any -> record<data: record<id: record, customer_id: record, name: record, company_number: any, tax_identifier: any, status: record, contacts: list<record>, created_at: record, updated_at: record, custom_data: any, import_meta: any>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($customer_id)/businesses")
  let body = {name: $name, company_number: $company_number, tax_identifier: $tax_identifier, contacts: $contacts, custom_data: $custom_data, import_meta: $import_meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a business for a customer
#
# GET /customers/{customer_id}/businesses/{business_id}
# Docs: https://developer.paddle.com/api-reference/businesses/get-business — Get a business for a customer
# operationId: get-business
export def "customers-businesses get-business" [
  business_id: string
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: record, customer_id: record, name: record, company_number: any, tax_identifier: any, status: record, contacts: list<record>, created_at: record, updated_at: record, custom_data: any, import_meta: any>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($customer_id)/businesses/($business_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a business for a customer
#
# PATCH /customers/{customer_id}/businesses/{business_id}
# Docs: https://developer.paddle.com/api-reference/businesses/update-business — Update a business for a customer
# operationId: update-business
export def "customers-businesses update-business" [
  business_id: string
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: any # Name of this business.
  --company-number: any # Company number for this business.
  --tax-identifier: any # Tax or VAT Number for this business.
  --status: string@status-completer # Whether this entity can be used in Paddle.
  --contacts: any # List of contacts related to this business, typically used for sending invoices.
  --custom-data: any # Your own structured key-value data.
]: any -> record<data: record<id: record, customer_id: record, name: record, company_number: any, tax_identifier: any, status: record, contacts: list<record>, created_at: record, updated_at: record, custom_data: any, import_meta: any>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($customer_id)/businesses/($business_id)")
  let body = {name: $name, company_number: $company_number, tax_identifier: $tax_identifier, status: $status, contacts: $contacts, custom_data: $custom_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List client-side tokens
#
# GET /client-tokens
# Docs: https://developer.paddle.com/api-reference/client-tokens/list-client-tokens — List client-side tokens
# operationId: list-client-tokens
export def "client-tokens list-client-tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Return entities after the specified Paddle ID when working with paginated endpoints. Used in the `meta.pagination.next` URL in responses for list operations.
  --per-page: int # Set how many entities are returned per page. Paddle returns the maximum number of results if a number greater than the maximum is requested. Check `meta.pagination.per_page` in the response to see how many were returned.  Default: `50`; Maximum: `200`. (default: 50)
  --order-by: string # Order returned entities by the specified field and direction (`[ASC]` or `[DESC]`). For example, `?order_by=id[ASC]`.  Valid fields for ordering: `id`. (default: id[DESC])
  --status: list # Return entities that match the specified status. Use a comma-separated list to specify multiple status values. (default: [active])
]: nothing -> record<data: table<id: record, token: record, name: string, description: any, status: record, revoked_at: any, created_at: record, updated_at: record>, meta: record<request_id: string, pagination: record<per_page: int, next: string, has_more: bool, estimated_total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "status" $status "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/client-tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a client-side token
#
# POST /client-tokens
# Docs: https://developer.paddle.com/api-reference/client-tokens/create-client-token — Create a client-side token
# operationId: create-client-token
export def "client-tokens create-client-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Short name of this client-side token. Typically unique and human-identifiable.
  --description: any
]: any -> record<data: record<id: record, token: record, name: string, description: any, status: record, revoked_at: any, created_at: record, updated_at: record>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/client-tokens")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a client-side token
#
# GET /client-tokens/{client_token_id}
# Docs: https://developer.paddle.com/api-reference/client-tokens/get-client-token — Get a client-side token
# operationId: get-client-token
export def "client-tokens get-client-token" [
  client_token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: record, token: record, name: string, description: any, status: record, revoked_at: any, created_at: record, updated_at: record>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/client-tokens/($client_token_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a client-side token
#
# PATCH /client-tokens/{client_token_id}
# Docs: https://developer.paddle.com/api-reference/client-tokens/update-client-token — Update a client-side token
# operationId: update-client-token
export def "client-tokens update-client-token" [
  client_token_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  status: any # default: active
]: any -> record<data: record<id: record, token: record, name: string, description: any, status: record, revoked_at: any, created_at: record, updated_at: record>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/client-tokens/($client_token_id)")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List customers
#
# GET /customers
# Docs: https://developer.paddle.com/api-reference/customers/list-customers — List customers
# operationId: list-customers
export def "customers list-customers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list # Return only the IDs specified. Use a comma-separated list to get multiple entities.
  --after: string # Return entities after the specified Paddle ID when working with paginated endpoints. Used in the `meta.pagination.next` URL in responses for list operations.
  --per-page: int # Set how many entities are returned per page. Paddle returns the maximum number of results if a number greater than the maximum is requested. Check `meta.pagination.per_page` in the response to see how many were returned.  Default: `50`; Maximum: `200`. (default: 50)
  --email: list # Return entities that exactly match the specified email address. Use a comma-separated list to specify multiple email addresses. Recommended for precise matching of email addresses.
  --order-by: string # Order returned entities by the specified field and direction (`[ASC]` or `[DESC]`). For example, `?order_by=id[ASC]`.  Valid fields for ordering: `id`. (default: id[DESC])
  --status: list # Return entities that match the specified status. Use a comma-separated list to specify multiple status values. (default: [active])
  --search: string # Return entities that match a search query. Searches `id`, `name`, and `email` fields. Use the `email` query parameter for precise matching of email addresses.
]: nothing -> record<data: table<id: record, name: any, email: record, marketing_consent: bool, status: record, custom_data: any, locale: string, created_at: record, updated_at: record, import_meta: any>, meta: record<request_id: string, pagination: record<per_page: int, next: string, has_more: bool, estimated_total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "after" $after "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "email" $email "csv") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "status" $status "csv") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a customer
#
# POST /customers
# Docs: https://developer.paddle.com/api-reference/customers/create-customer — Create a customer
# operationId: create-customer
export def "customers create-customer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: any # Full name of this customer. Required when creating transactions where `collection_mode` is `manual` (invoices).
  email: any # Email address for this customer.
  --marketing-consent: oneof<nothing, bool> # Whether this customer opted into marketing from you. `false` unless customers check the marketing consent box when using Paddle Checkout. Set automatically by Paddle. (default: false)
  --custom-data: any # Your own structured key-value data.
  --locale: string # Valid IETF BCP 47 short form locale tag. If omitted, defaults to `en`. (default: en)
  --import-meta: any # Import information for this entity. `null` if this entity is not imported.
]: any -> record<data: record<id: record, name: any, email: record, marketing_consent: bool, status: record, custom_data: any, locale: string, created_at: record, updated_at: record, import_meta: any>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customers")
  let body = {name: $name, email: $email, marketing_consent: $marketing_consent, custom_data: $custom_data, locale: $locale, import_meta: $import_meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a customer
#
# GET /customers/{customer_id}
# Docs: https://developer.paddle.com/api-reference/customers/get-customer — Get a customer
# operationId: get-customer
export def "customers get-customer" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: record, name: any, email: record, marketing_consent: bool, status: record, custom_data: any, locale: string, created_at: record, updated_at: record, import_meta: any>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($customer_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a customer
#
# PATCH /customers/{customer_id}
# Docs: https://developer.paddle.com/api-reference/customers/update-customer — Update a customer
# operationId: update-customer
export def "customers update-customer" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: any # Full name of this customer. Required when creating transactions where `collection_mode` is `manual` (invoices).
  --email: any # Email address for this customer.
  --marketing-consent: oneof<nothing, bool> # Whether this customer opted into marketing from you. `false` unless customers check the marketing consent box when using Paddle Checkout. Set automatically by Paddle. (default: false)
  --status: string@status-completer # Whether this entity can be used in Paddle.
  --custom-data: any # Your own structured key-value data.
  --locale: string # Valid IETF BCP 47 short form locale tag. (default: en)
  --import-meta: any # Import information for this entity. `null` if this entity is not imported.
]: any -> record<data: record<id: record, name: any, email: record, marketing_consent: bool, status: record, custom_data: any, locale: string, created_at: record, updated_at: record, import_meta: any>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($customer_id)")
  let body = {name: $name, email: $email, marketing_consent: $marketing_consent, status: $status, custom_data: $custom_data, locale: $locale, import_meta: $import_meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List credit balances for a customer
#
# GET /customers/{customer_id}/credit-balances
# Docs: https://developer.paddle.com/api-reference/customers/list-credit-balances — List credit balances for a customer
# operationId: list-credit-balances
export def "customers-credit-balances list-credit-balances" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --currency-code: list # Return entities that match the currency code. Use a comma-separated list to specify multiple currency codes.
]: nothing -> record<data: table<customer_id: record, currency_code: record, balance: record>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currency_code" $currency_code "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/customers/($customer_id)/credit-balances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate an authentication token for a customer
#
# POST /customers/{customer_id}/auth-token
# Docs: https://developer.paddle.com/api-reference/customers/generate-customer-authentication-token — Generate an authentication token for a customer
# operationId: generate-customer-authentication-token
export def "customers-auth-token generate-customer-authentication-token" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<customer_auth_token: string, expires_at: record>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($customer_id)/auth-token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a customer portal session
#
# POST /customers/{customer_id}/portal-sessions
# Docs: https://developer.paddle.com/api-reference/customer-portals/create-customer-portal-session — Create a customer portal session
# operationId: create-customer-portal-session
export def "customers-portal-sessions create-customer-portal-session" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-ids: list # List of subscriptions to create authenticated customer portal deep links for.
]: any -> record<data: record<id: record, customer_id: record, urls: record<general: record, subscriptions: list>, created_at: record>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($customer_id)/portal-sessions")
  let body = {subscription_ids: $subscription_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List discount groups
#
# GET /discount-groups
# Docs: https://developer.paddle.com/api-reference/discount-groups/list-discount-groups — List discount groups
# operationId: list-discount-groups
export def "discount-groups list-discount-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list # Return only the IDs specified. Use a comma-separated list to get multiple entities.
  --after: string # Return entities after the specified Paddle ID when working with paginated endpoints. Used in the `meta.pagination.next` URL in responses for list operations.
  --per-page: int # Set how many entities are returned per page. Paddle returns the maximum number of results if a number greater than the maximum is requested. Check `meta.pagination.per_page` in the response to see how many were returned.  Default: `50`; Maximum: `200`. (default: 50)
  --order-by: string # Order returned entities by the specified field and direction (`[ASC]` or `[DESC]`). For example, `?order_by=id[ASC]`.  Valid fields for ordering: `created_at` and `id`. (default: id[DESC])
]: nothing -> record<data: table<id: record, name: string, status: string, created_at: record, updated_at: record, import_meta: any>, meta: record<request_id: string, pagination: record<per_page: int, next: string, has_more: bool, estimated_total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "after" $after "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/discount-groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a discount group
#
# POST /discount-groups
# Docs: https://developer.paddle.com/api-reference/discount-groups/create-discount-group — Create a discount group
# operationId: create-discount-group
export def "discount-groups create-discount-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of this discount group, typically something short and memorable for categorization. Not shown to customers.
]: any -> record<data: record<id: record, name: string, status: string, created_at: record, updated_at: record, import_meta: any>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/discount-groups")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a discount group
#
# GET /discount-groups/{discount_group_id}
# Docs: https://developer.paddle.com/api-reference/discount-groups/get-discount-group — Get a discount group
# operationId: get-discount-group
export def "discount-groups get-discount-group" [
  discount_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: record, name: string, status: string, created_at: record, updated_at: record, import_meta: any>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/discount-groups/($discount_group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a discount group
#
# PATCH /discount-groups/{discount_group_id}
# Docs: https://developer.paddle.com/api-reference/discount-groups/update-discount-group — Update a discount group
# operationId: update-discount-group
export def "discount-groups update-discount-group" [
  discount_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # Whether this entity can be used in Paddle.
  --name: string # Name of this discount group, typically something short and memorable for categorization. Not shown to customers.
]: any -> record<data: record<id: record, name: string, status: string, created_at: record, updated_at: record, import_meta: any>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/discount-groups/($discount_group_id)")
  let body = {status: $status, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List discounts
#
# GET /discounts
# Docs: https://developer.paddle.com/api-reference/discounts/list-discounts — List discounts
# operationId: list-discounts
export def "discounts list-discounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list # Return only the IDs specified. Use a comma-separated list to get multiple entities.
  --after: string # Return entities after the specified Paddle ID when working with paginated endpoints. Used in the `meta.pagination.next` URL in responses for list operations.
  --per-page: int # Set how many entities are returned per page. Paddle returns the maximum number of results if a number greater than the maximum is requested. Check `meta.pagination.per_page` in the response to see how many were returned.  Default: `50`; Maximum: `200`. (default: 50)
  --include: list # Include related entities in the response. Use a comma-separated list to specify multiple entities.
  --code: list # Return entities that match the discount code. Use a comma-separated list to specify multiple discount codes.
  --order-by: string # Order returned entities by the specified field and direction (`[ASC]` or `[DESC]`). For example, `?order_by=id[ASC]`.  Valid fields for ordering: `created_at` and `id`. (default: id[DESC])
  --status: list # Return entities that match the specified status. Use a comma-separated list to specify multiple status values. (default: [active])
  --mode: string@mode-completer # Return entities that match the specified mode.
  --discount-group-id: list # Return entities related to the specified discount group. Use a comma-separated list to specify multiple discount group IDs.
]: nothing -> record<data: table<id: record, status: record, description: string, enabled_for_checkout: bool, code: any, type: string, mode: record, amount: string, currency_code: any, recur: bool, maximum_recurring_intervals: any, usage_limit: any, restrict_to: any, expires_at: any, custom_data: any, times_used: int, discount_group_id: any, created_at: record, updated_at: record, import_meta: any, discount_group: record>, meta: record<request_id: string, pagination: record<per_page: int, next: string, has_more: bool, estimated_total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "after" $after "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include" $include "csv") (serialize-qp "code" $code "csv") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "status" $status "csv") (serialize-qp "mode" $mode "scalar") (serialize-qp "discount_group_id" $discount_group_id "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/discounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a discount
#
# POST /discounts
# Docs: https://developer.paddle.com/api-reference/discounts/create-discount — Create a discount
# operationId: create-discount
export def "discounts create-discount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # Short description for this discount for your reference. Not shown to customers.
  --enabled-for-checkout: oneof<nothing, bool> # Whether this discount can be redeemed by customers at checkout (`true`) or not (`false`). (default: true)
  --code: any # Unique code that customers can use to redeem this discount at checkout. Use letters and numbers only, up to 32 characters. Not case-sensitive.  If omitted and `enabled_for_checkout` is `true`, Paddle generates a random 10-character code.
  type: any # Type of discount. Determines how this discount impacts the checkout or transaction total.
  --mode: any # Discount mode. Standard discounts are considered part of your catalog and are shown in the Paddle dashboard. If omitted, defaults to `standard`. (default: standard)
  amount: string # Amount to discount by. For `percentage` discounts, must be an amount between `0.01` and `100`. For `flat` and `flat_per_seat` discounts, amount in the lowest denomination for a currency.
  --currency-code: any # Supported three-letter ISO 4217 currency code. Required where discount type is `flat` or `flat_per_seat`.
  --recur: oneof<nothing, bool> # Whether this discount applies for multiple subscription billing periods (`true`) or not (`false`). If omitted, defaults to `false`. (default: false)
  --maximum-recurring-intervals: any # Number of subscription billing periods that this discount recurs for. Requires `recur`. `null` if this discount recurs forever.  Subscription renewals, midcycle changes, and one-time charges billed to a subscription aren't considered a redemption. `times_used` is not incremented in these cases.
  --usage-limit: any # Maximum number of times this discount can be redeemed. This is an overall limit for this discount, rather than a per-customer limit. `null` if this discount can be redeemed an unlimited amount of times.  Paddle counts a usage as a redemption on a checkout, transaction, or the initial application against a subscription. Transactions created for subscription renewals, midcycle changes, and one-time charges aren't considered a redemption.
  --restrict-to: any # Product or price IDs that this discount is for. When including a product ID, all prices for that product can be discounted. `null` if this discount applies to all products and prices.
  --expires-at: any # RFC 3339 datetime string of when this discount expires. Discount can no longer be redeemed after this date has elapsed. `null` if this discount can be redeemed forever.  Expired discounts can't be redeemed against transactions or checkouts, but can be applied when updating subscriptions.
  --custom-data: any # Your own structured key-value data.
  --discount-group-id: any # Paddle ID for the discount group related to this discount, prefixed with `dsg_`. `null` if not in a discount group.
  --import-meta: any # Import information for this entity. `null` if this entity is not imported.
]: any -> record<data: record<id: record, status: record, description: string, enabled_for_checkout: bool, code: any, type: string, mode: record, amount: string, currency_code: any, recur: bool, maximum_recurring_intervals: any, usage_limit: any, restrict_to: any, expires_at: any, custom_data: any, times_used: int, discount_group_id: any, created_at: record, updated_at: record, import_meta: any>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/discounts")
  let body = {description: $description, enabled_for_checkout: $enabled_for_checkout, code: $code, type: $type, mode: $mode, amount: $amount, currency_code: $currency_code, recur: $recur, maximum_recurring_intervals: $maximum_recurring_intervals, usage_limit: $usage_limit, restrict_to: $restrict_to, expires_at: $expires_at, custom_data: $custom_data, discount_group_id: $discount_group_id, import_meta: $import_meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a discount
#
# GET /discounts/{discount_id}
# Docs: https://developer.paddle.com/api-reference/discounts/get-discount — Get a discount
# operationId: get-discount
export def "discounts get-discount" [
  discount_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Include related entities in the response. Use a comma-separated list to specify multiple entities.
]: nothing -> record<data: record<id: record, status: record, description: string, enabled_for_checkout: bool, code: any, type: string, mode: record, amount: string, currency_code: any, recur: bool, maximum_recurring_intervals: any, usage_limit: any, restrict_to: any, expires_at: any, custom_data: any, times_used: int, discount_group_id: any, created_at: record, updated_at: record, import_meta: any, discount_group: record<id: record, name: string, status: string, created_at: record, updated_at: record, import_meta: any>>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/discounts/($discount_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a discount
#
# PATCH /discounts/{discount_id}
# Docs: https://developer.paddle.com/api-reference/discounts/update-discount — Update a discount
# operationId: update-discount
export def "discounts update-discount" [
  discount_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # Whether this entity can be used in Paddle.
  --description: string # Short description for this discount for your reference. Not shown to customers.
  --enabled-for-checkout: oneof<nothing, bool> # Whether this discount can be redeemed by customers at checkout (`true`) or not (`false`). (default: true)
  --code: any # Unique code that customers can use to redeem this discount at checkout. Not case-sensitive.
  --type: any # Type of discount. Determines how this discount impacts the checkout or transaction total.
  --mode: any # Discount mode. Standard discounts are considered part of your catalog and are shown in the Paddle dashboard. (default: standard)
  --amount: string # Amount to discount by. For `percentage` discounts, must be an amount between `0.01` and `100`. For `flat` and `flat_per_seat` discounts, amount in the lowest denomination for a currency.
  --currency-code: any # Supported three-letter ISO 4217 currency code. Required where discount type is `flat` or `flat_per_seat`.
  --recur: oneof<nothing, bool> # Whether this discount applies for multiple subscription billing periods (`true`) or not (`false`). (default: false)
  --maximum-recurring-intervals: any # Number of subscription billing periods that this discount recurs for. Requires `recur`. `null` if this discount recurs forever.  Subscription renewals, midcycle changes, and one-time charges billed to a subscription aren't considered a redemption. `times_used` is not incremented in these cases.
  --usage-limit: any # Maximum number of times this discount can be redeemed. This is an overall limit for this discount, rather than a per-customer limit. `null` if this discount can be redeemed an unlimited amount of times.  Paddle counts a usage as a redemption on a checkout, transaction, or the initial application against a subscription. Transactions created for subscription renewals, midcycle changes, and one-time charges aren't considered a redemption.
  --restrict-to: any # Product or price IDs that this discount is for. When including a product ID, all prices for that product can be discounted. `null` if this discount applies to all products and prices.
  --expires-at: any # RFC 3339 datetime string of when this discount expires. Discount can no longer be redeemed after this date has elapsed. `null` if this discount can be redeemed forever.  Expired discounts can't be redeemed against transactions or checkouts, but can be applied when updating subscriptions.
  --custom-data: any # Your own structured key-value data.
  --discount-group-id: any # Paddle ID for the discount group related to this discount, prefixed with `dsg_`. `null` if not in a discount group.
  --import-meta: any # Import information for this entity. `null` if this entity is not imported.
]: any -> record<data: record<id: record, status: record, description: string, enabled_for_checkout: bool, code: any, type: string, mode: record, amount: string, currency_code: any, recur: bool, maximum_recurring_intervals: any, usage_limit: any, restrict_to: any, expires_at: any, custom_data: any, times_used: int, discount_group_id: any, created_at: record, updated_at: record, import_meta: any>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/discounts/($discount_id)")
  let body = {status: $status, description: $description, enabled_for_checkout: $enabled_for_checkout, code: $code, type: $type, mode: $mode, amount: $amount, currency_code: $currency_code, recur: $recur, maximum_recurring_intervals: $maximum_recurring_intervals, usage_limit: $usage_limit, restrict_to: $restrict_to, expires_at: $expires_at, custom_data: $custom_data, discount_group_id: $discount_group_id, import_meta: $import_meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List events types
#
# GET /event-types
# Docs: https://developer.paddle.com/api-reference/event-types/list-event-types — List events types
# operationId: list-event-types
export def "event-types list-event-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<name: record, description: string, group: string, available_versions: list>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/event-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List events
#
# GET /events
# Docs: https://developer.paddle.com/api-reference/events/list-events — List events
# operationId: list-events
export def "events list-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Return entities after the specified Paddle ID when working with paginated endpoints. Used in the `meta.pagination.next` URL in responses for list operations.
  --per-page: int # Set how many entities are returned per page. Paddle returns the maximum number of results if a number greater than the maximum is requested. Check `meta.pagination.per_page` in the response to see how many were returned.  Default: `50`; Maximum: `200`. (default: 50)
  --order-by: string # Order returned entities by the specified field and direction (`[ASC]` or `[DESC]`). For example, `?order_by=id[ASC]`.  Valid fields for ordering: `id` (for `event_id`). (default: id[DESC])
  --event-type: list # Return events that match the specified event type. Use a comma-separated list to specify multiple event types.
]: nothing -> record<data: table<event_id: record, event_type: record, occurred_at: record, data: record>, meta: record<request_id: string, pagination: record<per_page: int, next: string, has_more: bool, estimated_total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "event_type" $event_type "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Paddle IP addresses
#
# GET /ips
# operationId: get-ip-addresses
export def "ips get-ip-addresses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<ipv4_cidrs: list<string>>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ips")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List notification settings
#
# GET /notification-settings
# Docs: https://developer.paddle.com/api-reference/notification-settings/list-notification-settings — List notification settings
# operationId: list-notification-settings
export def "notification-settings list-notification-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Return entities after the specified Paddle ID when working with paginated endpoints. Used in the `meta.pagination.next` URL in responses for list operations.
  --per-page: int # Set how many entities are returned per page. Paddle returns the maximum number of results if a number greater than the maximum is requested. Check `meta.pagination.per_page` in the response to see how many were returned.  Default: `200`; Maximum: `200`. (default: 200)
  --order-by: string # Order returned entities by the specified field and direction (`[ASC]` or `[DESC]`). For example, `?order_by=id[ASC]`.  Valid fields for ordering: `id`. (default: id[DESC])
  --active: oneof<nothing, bool> # Determine whether returned entities are active (`true`) or not (`false`).
  --traffic-source: string@traffic-source-completer # Return entities that match the specified traffic source.
]: nothing -> record<data: table<id: record, description: string, type: record, destination: string, active: bool, api_version: int, include_sensitive_fields: bool, subscribed_events: list, endpoint_secret_key: string, traffic_source: record>, meta: record<request_id: string, pagination: record<per_page: int, next: string, has_more: bool, estimated_total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "traffic_source" $traffic_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notification-settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a notification setting
#
# POST /notification-settings
# Docs: https://developer.paddle.com/api-reference/notification-settings/create-notification-setting — Create a notification setting
# operationId: create-notification-setting
export def "notification-settings create-notification-setting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # Short description for this notification destination. Shown in the Paddle Dashboard.
  type: any # Where notifications should be sent for this destination.
  destination: string # Webhook endpoint URL or email address.
  --api-version: int # API version that returned objects for events should conform to. Must be a valid version of the Paddle API. Can't be a version older than your account default. If omitted, defaults to your account default version.
  --include-sensitive-fields: oneof<nothing, bool> # Whether potentially sensitive fields should be sent to this notification destination. If omitted, defaults to `false`. (default: false)
  subscribed_events: list # Subscribed events for this notification destination. When creating or updating a notification destination, pass an array of event type names only. Paddle returns the complete event type object.
  --traffic-source: any # Whether Paddle should deliver real platform events, simulation events or both to this notification destination. If omitted, defaults to `platform`. (default: platform)
]: any -> record<data: record<id: record, description: string, type: record, destination: string, active: bool, api_version: int, include_sensitive_fields: bool, subscribed_events: list<record>, endpoint_secret_key: string, traffic_source: record>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notification-settings")
  let body = {description: $description, type: $type, destination: $destination, api_version: $api_version, include_sensitive_fields: $include_sensitive_fields, subscribed_events: $subscribed_events, traffic_source: $traffic_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a notification setting
#
# GET /notification-settings/{notification_setting_id}
# Docs: https://developer.paddle.com/api-reference/notification-settings/get-notification-setting — Get a notification setting
# operationId: get-notification-setting
export def "notification-settings get-notification-setting" [
  notification_setting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: record, description: string, type: record, destination: string, active: bool, api_version: int, include_sensitive_fields: bool, subscribed_events: list<record>, endpoint_secret_key: string, traffic_source: record>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notification-settings/($notification_setting_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a notification setting
#
# PATCH /notification-settings/{notification_setting_id}
# Docs: https://developer.paddle.com/api-reference/notification-settings/update-notification-setting — Update a notification setting
# operationId: update-notification-setting
export def "notification-settings update-notification-setting" [
  notification_setting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Short description for this notification destination. Shown in the Paddle Dashboard.
  --destination: string # Webhook endpoint URL or email address.
  --active: oneof<nothing, bool> # Whether Paddle should try to deliver events to this notification destination. (default: true)
  --api-version: int # API version that returned objects for events should conform to. Must be a valid version of the Paddle API. Can't be a version older than your account default. Defaults to your account default if omitted.
  --include-sensitive-fields: oneof<nothing, bool> # Whether potentially sensitive fields should be sent to this notification destination. (default: false)
  --subscribed-events: list # Subscribed events for this notification destination. When creating or updating a notification destination, pass an array of event type names only. Paddle returns the complete event type object.
  --traffic-source: any # Whether Paddle should deliver real platform events, simulation events or both to this notification destination.
]: any -> record<data: record<id: record, description: string, type: record, destination: string, active: bool, api_version: int, include_sensitive_fields: bool, subscribed_events: list<record>, endpoint_secret_key: string, traffic_source: record>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notification-settings/($notification_setting_id)")
  let body = {description: $description, destination: $destination, active: $active, api_version: $api_version, include_sensitive_fields: $include_sensitive_fields, subscribed_events: $subscribed_events, traffic_source: $traffic_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a notification setting
#
# DELETE /notification-settings/{notification_setting_id}
# Docs: https://developer.paddle.com/api-reference/notification-settings/delete-notification-setting — Delete a notification setting
# operationId: delete-notification-setting
export def "notification-settings delete-notification-setting" [
  notification_setting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<type: record, code: string, detail: string, documentation_url: string, errors: list<record>>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notification-settings/($notification_setting_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List notifications
#
# GET /notifications
# Docs: https://developer.paddle.com/api-reference/notifications/list-notifications — List notifications
# operationId: list-notifications
export def "notifications list-notifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Return entities after the specified Paddle ID when working with paginated endpoints. Used in the `meta.pagination.next` URL in responses for list operations.
  --per-page: int # Set how many entities are returned per page. Paddle returns the maximum number of results if a number greater than the maximum is requested. Check `meta.pagination.per_page` in the response to see how many were returned.  Default: `50`; Maximum: `200`. (default: 50)
  --notification-setting-id: list # Return entities related to the specified notification destination. Use a comma-separated list to specify multiple notification destination IDs.
  --order-by: string # Order returned entities by the specified field and direction (`[ASC]` or `[DESC]`). For example, `?order_by=id[ASC]`.  Valid fields for ordering: `id`. (default: id[DESC])
  --search: string # Return entities that match a search query. Searches `id` and `type` fields.
  --status: list # Return entities that match the specified status. Use a comma-separated list to specify multiple status values.
  --filter: string # Return entities that contain the Paddle ID specified. Pass a transaction, customer, or subscription ID.
  --qp-to: string # Return entities up to a specific time. Pass an RFC 3339 datetime string.
  --qp-from: string # Return entities from a specific time. Pass an RFC 3339 datetime string.
]: nothing -> record<data: table<id: record, type: record, status: record, payload: record, occurred_at: record, delivered_at: any, replayed_at: any, origin: record, last_attempt_at: any, retry_at: any, times_attempted: int, notification_setting_id: record>, meta: record<request_id: string, pagination: record<per_page: int, next: string, has_more: bool, estimated_total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "notification_setting_id" $notification_setting_id "csv") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "status" $status "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "from" $qp_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a notification
#
# GET /notifications/{notification_id}
# Docs: https://developer.paddle.com/api-reference/notifications/get-notification — Get a notification
# operationId: get-notification
export def "notifications get-notification" [
  notification_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: record, type: record, status: record, payload: record<event_id: record, event_type: record, occurred_at: record, data: record, notification_id: string>, occurred_at: record, delivered_at: any, replayed_at: any, origin: record, last_attempt_at: any, retry_at: any, times_attempted: int, notification_setting_id: record>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/($notification_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List logs for a notification
#
# GET /notifications/{notification_id}/logs
# Docs: https://developer.paddle.com/api-reference/notification-logs/list-notification-logs — List logs for a notification
# operationId: list-notification-logs
export def "notifications-logs list-notification-logs" [
  notification_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Return entities after the specified Paddle ID when working with paginated endpoints. Used in the `meta.pagination.next` URL in responses for list operations.
  --per-page: int # Set how many entities are returned per page. Paddle returns the maximum number of results if a number greater than the maximum is requested. Check `meta.pagination.per_page` in the response to see how many were returned.  Default: `50`; Maximum: `200`. (default: 50)
]: nothing -> record<data: table<id: record, response_code: int, response_content_type: any, response_body: string, attempted_at: record>, meta: record<request_id: string, pagination: record<per_page: int, next: string, has_more: bool, estimated_total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/notifications/($notification_id)/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replay a notification
#
# POST /notifications/{notification_id}/replay
# Docs: https://developer.paddle.com/api-reference/notifications/replay-notification — Replay a notification
# operationId: replay-notification
export def "notifications-replay replay-notification" [
  notification_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<notification_id: string>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/($notification_id)/replay")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List payment methods for a customer
#
# GET /customers/{customer_id}/payment-methods
# Docs: https://developer.paddle.com/api-reference/payment-methods/list-payment-methods — List payment methods for a customer
# operationId: list-customer-payment-methods
export def "customers-payment-methods list-customer-payment-methods" [
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Return entities after the specified Paddle ID when working with paginated endpoints. Used in the `meta.pagination.next` URL in responses for list operations.
  --per-page: int # Set how many entities are returned per page. Paddle returns the maximum number of results if a number greater than the maximum is requested. Check `meta.pagination.per_page` in the response to see how many were returned.  Default: `50`; Maximum: `200`. (default: 50)
  --address-id: list # Return entities related to the specified address. Use a comma-separated list to specify multiple address IDs.
  --order-by: string # Order returned entities by the specified field and direction (`[ASC]` or `[DESC]`). For example, `?order_by=id[ASC]`.  Valid fields for ordering: `id`. (default: id[DESC])
  --supports-checkout: oneof<nothing, bool> # Return entities that support being presented at checkout (`true`) or not (`false`).
]: nothing -> record<data: table<id: record, customer_id: record, address_id: record, type: record, card: any, paypal: any, underlying_details: any, south_korea_local_card: any, origin: record, saved_at: record, updated_at: record>, meta: record<request_id: string, pagination: record<per_page: int, next: string, has_more: bool, estimated_total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "address_id" $address_id "csv") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "supports_checkout" $supports_checkout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/customers/($customer_id)/payment-methods" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a payment method for a customer
#
# GET /customers/{customer_id}/payment-methods/{payment_method_id}
# Docs: https://developer.paddle.com/api-reference/payment-methods/get-payment-method — Get a payment method for a customer
# operationId: get-customer-payment-method
export def "customers-payment-methods get-customer-payment-method" [
  customer_id: string
  payment_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: record, customer_id: record, address_id: record, type: record, card: any, paypal: any, underlying_details: any, south_korea_local_card: any, origin: record, saved_at: record, updated_at: record>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($customer_id)/payment-methods/($payment_method_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a payment method for a customer
#
# DELETE /customers/{customer_id}/payment-methods/{payment_method_id}
# Docs: https://developer.paddle.com/api-reference/payment-methods/delete-payment-method — Delete a payment method for a customer
# operationId: delete-customer-payment-method
export def "customers-payment-methods delete-customer-payment-method" [
  customer_id: string
  payment_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: record<type: record, code: string, detail: string, documentation_url: string, errors: list<record>>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($customer_id)/payment-methods/($payment_method_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List prices
#
# GET /prices
# Docs: https://developer.paddle.com/api-reference/prices/list-prices — List prices
# operationId: list-prices
export def "prices list-prices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list # Return only the IDs specified. Use a comma-separated list to get multiple entities.
  --after: string # Return entities after the specified Paddle ID when working with paginated endpoints. Used in the `meta.pagination.next` URL in responses for list operations.
  --per-page: int # Set how many entities are returned per page. Paddle returns the maximum number of results if a number greater than the maximum is requested. Check `meta.pagination.per_page` in the response to see how many were returned.  Default: `50`; Maximum: `200`. (default: 50)
  --include: list # Include related entities in the response.
  --order-by: string # Order returned entities by the specified field and direction (`[ASC]` or `[DESC]`). For example, `?order_by=id[ASC]`.  Valid fields for ordering: `billing_cycle.frequency`, `billing_cycle.interval`, `id`, `product_id`, `quantity.maximum`, `quantity.minimum`, `status`, `tax_mode`, `unit_price.amount`, and `unit_price.currency_code`. (default: id[DESC])
  --product-id: list # Return entities related to the specified product. Use a comma-separated list to specify multiple product IDs.
  --status: list # Return entities that match the specified status. Use a comma-separated list to specify multiple status values. (default: [active])
  --recurring: oneof<nothing, bool> # Determine whether returned entities are for recurring prices (`true`) or one-time prices (`false`).
  --type: string@type-completer # Return items that match the specified type.
]: nothing -> record<data: table<id: record, product_id: record, description: string, type: record, name: any, billing_cycle: any, trial_period: any, tax_mode: record, unit_price: record, unit_price_overrides: list, quantity: record, status: record, custom_data: any, import_meta: any, created_at: record, updated_at: record, product: record>, meta: record<request_id: string, pagination: record<per_page: int, next: string, has_more: bool, estimated_total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "after" $after "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include" $include "csv") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "product_id" $product_id "csv") (serialize-qp "status" $status "csv") (serialize-qp "recurring" $recurring "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/prices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a price
#
# POST /prices
# Docs: https://developer.paddle.com/api-reference/prices/create-price — Create a price
# operationId: create-price
# --unit_price_overrides item shape: {country_codes: list, unit_price: any}
export def "prices create-price" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: any
  description: string # Internal description for this price, not shown to customers. Typically notes for your team.
  --type: any # Type of item. Standard items are considered part of your catalog and are shown in the Paddle dashboard. If omitted, defaults to `standard`. (default: standard)
  --name: any
  product_id: any # Paddle ID for the product that this price is for, prefixed with `pro_`.
  --billing-cycle: any # How often this price should be charged. `null` if price is non-recurring (one-time). If omitted, defaults to `null`.
  --trial-period: any # Trial period for the product related to this price. The billing cycle begins once the trial period is over. `null` for no trial period. Requires `billing_cycle`. If omitted, defaults to `null`.
  --tax-mode: any # How tax is calculated for this price. If omitted, defaults to `account_setting`. (default: account_setting)
  unit_price: any # Base price. This price applies to all customers, except for customers located in countries where you have `unit_price_overrides`.
  --unit-price-overrides: list # List of unit price overrides. Use to override the base price with a custom price and currency for a country or group of countries. — item shape: {country_codes: list, unit_price: any}
  --quantity: any # Limits on how many times the related product can be purchased at this price. Useful for discount campaigns. If omitted, defaults to 1-100.
  --custom-data: any # Your own structured key-value data.
  --import-meta: any # Import information for this entity. `null` if this entity is not imported.
]: any -> record<data: record<id: record, product_id: record, description: string, type: record, name: any, billing_cycle: any, trial_period: any, tax_mode: record, unit_price: record<amount: string, currency_code: string>, unit_price_overrides: list<record>, quantity: record<minimum: int, maximum: int>, status: record, custom_data: any, import_meta: any, created_at: record, updated_at: record>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/prices")
  let body = {id: $id, description: $description, type: $type, name: $name, product_id: $product_id, billing_cycle: $billing_cycle, trial_period: $trial_period, tax_mode: $tax_mode, unit_price: $unit_price, unit_price_overrides: $unit_price_overrides, quantity: $quantity, custom_data: $custom_data, import_meta: $import_meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a price
#
# GET /prices/{price_id}
# Docs: https://developer.paddle.com/api-reference/prices/get-price — Get a price
# operationId: get-price
export def "prices get-price" [
  price_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Include related entities in the response.
]: nothing -> record<data: record<id: record, product_id: record, description: string, type: record, name: any, billing_cycle: any, trial_period: any, tax_mode: record, unit_price: record<amount: string, currency_code: string>, unit_price_overrides: list<record>, quantity: record<minimum: int, maximum: int>, status: record, custom_data: any, import_meta: any, created_at: record, updated_at: record, product: record<id: record, name: string, description: any, type: record, tax_category: string, image_url: any, custom_data: any, status: record, import_meta: any, created_at: record, updated_at: record>>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/prices/($price_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a price
#
# PATCH /prices/{price_id}
# Docs: https://developer.paddle.com/api-reference/prices/update-price — Update a price
# operationId: update-price
# --unit_price_overrides item shape: {country_codes: list, unit_price: any}
export def "prices update-price" [
  price_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Internal description for this price, not shown to customers. Typically notes for your team.
  --type: any # default: standard
  --name: any
  --billing-cycle: any # How often this price should be charged. `null` if price is non-recurring (one-time).
  --trial-period: any # Trial period for the product related to this price. The billing cycle begins once the trial period is over. `null` for no trial period. Requires `billing_cycle`.
  --tax-mode: any # default: account_setting
  --unit-price: any # Base price. This price applies to all customers, except for customers located in countries where you have `unit_price_overrides`.
  --unit-price-overrides: list # List of unit price overrides. Use to override the base price with a custom price and currency for a country or group of countries. — item shape: {country_codes: list, unit_price: any}
  --quantity: any # Limits on how many times the related product can be purchased at this price. Useful for discount campaigns.
  --status: string@status-completer # Whether this entity can be used in Paddle.
  --custom-data: any # Your own structured key-value data.
]: any -> record<data: record<id: record, product_id: record, description: string, type: record, name: any, billing_cycle: any, trial_period: any, tax_mode: record, unit_price: record<amount: string, currency_code: string>, unit_price_overrides: list<record>, quantity: record<minimum: int, maximum: int>, status: record, custom_data: any, import_meta: any, created_at: record, updated_at: record>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/prices/($price_id)")
  let body = {description: $description, type: $type, name: $name, billing_cycle: $billing_cycle, trial_period: $trial_period, tax_mode: $tax_mode, unit_price: $unit_price, unit_price_overrides: $unit_price_overrides, quantity: $quantity, status: $status, custom_data: $custom_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Preview prices
#
# POST /pricing-preview
# Docs: https://developer.paddle.com/api-reference/pricing-preview/preview-prices — Preview prices
# operationId: preview-prices
# --items item shape: {price_id?: any, quantity: int}
export def "pricing-preview preview-prices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-id: any # Paddle ID of the customer that this preview is for, prefixed with `ctm_`.
  --address-id: any # Paddle ID of the address that this preview is for, prefixed with `add_`. Send one of `address_id`, `customer_ip_address`, or the `address` object when previewing.
  --business-id: any # Paddle ID of the business that this preview is for, prefixed with `biz_`.
  --currency-code: any # Supported three-letter ISO 4217 currency code.
  --discount-id: any # Paddle ID of the discount applied to this preview, prefixed with `dsc_`.
  --address: any # Address for this preview. Send one of `address_id`, `customer_ip_address`, or the `address` object when previewing.
  --customer-ip-address: any # IP address for this transaction preview. Send one of `address_id`, `customer_ip_address`, or the `address` object when previewing.
  items: list # List of items to preview price calculations for. — item shape: {price_id?: any, quantity: int}
]: any -> record<data: record<customer_id: any, address_id: any, business_id: any, currency_code: any, discount_id: any, address: any, customer_ip_address: any, details: record<line_items: list>, available_payment_methods: list<string>>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pricing-preview")
  let body = {customer_id: $customer_id, address_id: $address_id, business_id: $business_id, currency_code: $currency_code, discount_id: $discount_id, address: $address, customer_ip_address: $customer_ip_address, items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List products
#
# GET /products
# Docs: https://developer.paddle.com/api-reference/products/list-products — List products
# operationId: list-products
export def "products list-products" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list # Return only the IDs specified. Use a comma-separated list to get multiple entities.
  --after: string # Return entities after the specified Paddle ID when working with paginated endpoints. Used in the `meta.pagination.next` URL in responses for list operations.
  --per-page: int # Set how many entities are returned per page. Paddle returns the maximum number of results if a number greater than the maximum is requested. Check `meta.pagination.per_page` in the response to see how many were returned.  Default: `50`; Maximum: `200`. (default: 50)
  --include: list # Include related entities in the response. Use a comma-separated list to specify multiple entities.
  --order-by: string # Order returned entities by the specified field and direction (`[ASC]` or `[DESC]`). For example, `?order_by=id[ASC]`.  Valid fields for ordering: `created_at`, `custom_data`, `description`, `id`, `image_url`, `name`, `status`, `tax_category`, and `updated_at`. (default: id[DESC])
  --status: list # Return entities that match the specified status. Use a comma-separated list to specify multiple status values. (default: [active])
  --tax-category: list # Return entities that match the specified tax category. Use a comma-separated list to specify multiple tax categories.
  --type: string@type-completer # Return items that match the specified type.
]: nothing -> record<data: table<id: record, name: string, description: any, type: record, tax_category: string, image_url: any, custom_data: any, status: record, import_meta: any, created_at: record, updated_at: record, prices: list>, meta: record<request_id: string, pagination: record<per_page: int, next: string, has_more: bool, estimated_total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "after" $after "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include" $include "csv") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "status" $status "csv") (serialize-qp "tax_category" $tax_category "csv") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/products" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a product
#
# POST /products
# Docs: https://developer.paddle.com/api-reference/products/create-product — Create product
# operationId: create-product
export def "products create-product" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: any
  name: string # Name of this product.
  --description: any # Short description for this product.
  --type: any # Type of item. Standard items are considered part of your catalog and are shown in the Paddle dashboard. If omitted, defaults to `standard`. (default: standard)
  tax_category: string@tax-category-completer # Tax category for this product. Used for charging the correct rate of tax. Selected tax category must be enabled on your Paddle account.
  --image-url: any # Image for this product. Included in the checkout and on some customer documents.
  --custom-data: any # Your own structured key-value data.
  --import-meta: any # Import information for this entity. `null` if this entity is not imported.
]: any -> record<data: record<id: record, name: string, description: any, type: record, tax_category: string, image_url: any, custom_data: any, status: record, import_meta: any, created_at: record, updated_at: record>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/products")
  let body = {id: $id, name: $name, description: $description, type: $type, tax_category: $tax_category, image_url: $image_url, custom_data: $custom_data, import_meta: $import_meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a product
#
# GET /products/{product_id}
# Docs: https://developer.paddle.com/api-reference/products/get-product — Get a product
# operationId: get-product
export def "products get-product" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Include related entities in the response. Use a comma-separated list to specify multiple entities.
]: nothing -> record<data: record<id: record, name: string, description: any, type: record, tax_category: string, image_url: any, custom_data: any, status: record, import_meta: any, created_at: record, updated_at: record, prices: list<record>>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/products/($product_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a product
#
# PATCH /products/{product_id}
# Docs: https://developer.paddle.com/api-reference/products/update-product — Update a product
# operationId: update-product
export def "products update-product" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of this product.
  --description: any # Short description for this product.
  --type: any # default: standard
  --tax-category: string@tax-category-completer # Tax category for this product. Used for charging the correct rate of tax. Selected tax category must be enabled on your Paddle account.
  --image-url: any # Image for this product. Included in the checkout and on some customer documents.
  --custom-data: any # Your own structured key-value data.
  --status: string@status-completer # Whether this entity can be used in Paddle.
]: any -> record<data: record<id: record, name: string, description: any, type: record, tax_category: string, image_url: any, custom_data: any, status: record, import_meta: any, created_at: record, updated_at: record>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/($product_id)")
  let body = {name: $name, description: $description, type: $type, tax_category: $tax_category, image_url: $image_url, custom_data: $custom_data, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List reports
#
# GET /reports
# Docs: https://developer.paddle.com/api-reference/reports/list-reports — List reports
# operationId: list-reports
export def "reports list-reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --after: string # Return entities after the specified Paddle ID when working with paginated endpoints. Used in the `meta.pagination.next` URL in responses for list operations.
  --per-page: int # Set how many entities are returned per page. Paddle returns the maximum number of results if a number greater than the maximum is requested. Check `meta.pagination.per_page` in the response to see how many were returned.  Default: `50`; Maximum: `200`. (default: 50)
  --order-by: string # Order returned entities by the specified field and direction (`[ASC]` or `[DESC]`). For example, `?order_by=id[ASC]`.  Valid fields for ordering: `id`. (default: id[DESC])
  --status: list # Return entities that match the specified status. Use a comma-separated list to specify multiple status values.
]: nothing -> record<data: list<any>, meta: record<request_id: string, pagination: record<per_page: int, next: string, has_more: bool, estimated_total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "status" $status "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a report
#
# POST /reports
# Docs: https://developer.paddle.com/api-reference/reports/create-report — Create a report
# operationId: create-report
# --filters item shape: {name?: any, operator?: any, value?: any}
export def "reports create-report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: any # Type of report to create.
  --filters: list # Filter criteria for this report. If omitted, reports are filtered to include data updated in the last 30 days. This means `updated_at` is greater than or equal to (`gte`) the date 30 days ago from the time the report was generated. — item shape: {name?: any, operator?: any, value?: any}
]: any -> record<data: any, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports")
  let body = {type: $type, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a report
#
# GET /reports/{report_id}
# Docs: https://developer.paddle.com/api-reference/reports/get-report — Get a report
# operationId: get-report
export def "reports get-report" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: any, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/reports/($report_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a CSV file for a report
#
# GET /reports/{report_id}/download-url
# Docs: https://developer.paddle.com/api-reference/reports/get-report-csv — Get a CSV file for a report
# operationId: get-report-csv
export def "reports-download-url get-report-csv" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<request_id: string>, data: record<url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/reports/($report_id)/download-url")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List simulation types
#
# GET /simulation-types
# Docs: https://developer.paddle.com/api-reference/simulation-types/list-simulation-types — List simulation types
# operationId: list-simulation-types
export def "simulation-types list-simulation-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<name: string, label: string, description: string, group: string, type: record, events: list>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/simulation-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List simulations
#
# GET /simulations
# Docs: https://developer.paddle.com/api-reference/simulations/list-simulations — List simulations
# operationId: list-simulations
export def "simulations list-simulations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list # Return only the IDs specified. Use a comma-separated list to get multiple entities.
  --after: string # Return entities after the specified Paddle ID when working with paginated endpoints. Used in the `meta.pagination.next` URL in responses for list operations.
  --per-page: int # Set how many entities are returned per page. Paddle returns the maximum number of results if a number greater than the maximum is requested. Check `meta.pagination.per_page` in the response to see how many were returned.  Default: `50`; Maximum: `200`. (default: 50)
  --notification-setting-id: list # Return entities related to the specified notification destination. Use a comma-separated list to specify multiple notification destination IDs.
  --order-by: string # Order returned entities by the specified field and direction (`[ASC]` or `[DESC]`). For example, `?order_by=id[ASC]`.  Valid fields for ordering: `id`. (default: id[DESC])
  --status: list # Return entities that match the specified status. Use a comma-separated list to specify multiple status values. (default: [active])
]: nothing -> record<data: list<any>, meta: record<request_id: string, pagination: record<per_page: int, next: string, has_more: bool, estimated_total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "after" $after "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "notification_setting_id" $notification_setting_id "csv") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "status" $status "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/simulations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a simulation
#
# POST /simulations
# Docs: https://developer.paddle.com/api-reference/simulations/create-simulation — Create a simulation
# operationId: create-simulation
export def "simulations create-simulation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of this simulation.
  --type: any # Single event sent for this simulation, in the format `entity.event_type`.
  --payload: any # Simulation payload. Pass a JSON object that matches the schema for an event type to simulate a custom payload. If omitted, Paddle populates with a demo example.
  --config: any # Configuration for this scenario simulation. Use to simulate more granular flows and populate payloads with your own entity data. If omitted, Paddle simulates the default scenario flow and populates payloads with demo examples.
]: any -> record<data: any, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/simulations")
  let body = {name: $name, type: $type, payload: $payload, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a simulation
#
# GET /simulations/{simulation_id}
# Docs: https://developer.paddle.com/api-reference/simulations/get-simulation — Get a simulation
# operationId: get-simulation
export def "simulations get-simulation" [
  simulation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: any, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/simulations/($simulation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a simulation
#
# PATCH /simulations/{simulation_id}
# Docs: https://developer.paddle.com/api-reference/simulations/update-simulation — Update a simulation
# operationId: update-simulation
export def "simulations update-simulation" [
  simulation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of this simulation.
  --status: string@status-completer # Whether this entity can be used in Paddle.
  --type: any # Single event sent for this simulation, in the format `entity.event_type`.
  --payload: any # Simulation payload. Pass a JSON object that matches the schema for an event type to simulate a custom payload. Set to `null` to clear and populate with a demo example.
  --config: any # Configuration for this scenario simulation. Use to simulate more granular flows and populate payloads with your own entity data. If omitted, Paddle simulates the default scenario flow and populates payloads with demo examples.
]: any -> record<data: any, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/simulations/($simulation_id)")
  let body = {name: $name, status: $status, type: $type, payload: $payload, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List runs for a simulation
#
# GET /simulations/{simulation_id}/runs
# Docs: https://developer.paddle.com/api-reference/simulation-runs/list-simulation-runs — List runs for a simulation
# operationId: list-simulation-runs
export def "simulations-runs list-simulation-runs" [
  simulation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list # Return only the IDs specified. Use a comma-separated list to get multiple entities.
  --after: string # Return entities after the specified Paddle ID when working with paginated endpoints. Used in the `meta.pagination.next` URL in responses for list operations.
  --per-page: int # Set how many entities are returned per page. Paddle returns the maximum number of results if a number greater than the maximum is requested. Check `meta.pagination.per_page` in the response to see how many were returned.  Default: `50`; Maximum: `200`. (default: 50)
  --include: list # Include related entities in the response.
  --order-by: string # Order returned entities by the specified field and direction (`[ASC]` or `[DESC]`). For example, `?order_by=id[ASC]`.  Valid fields for ordering: `id`. (default: id[DESC])
]: nothing -> record<data: list<any>, meta: record<request_id: string, pagination: record<per_page: int, next: string, has_more: bool, estimated_total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "after" $after "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "include" $include "csv") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/simulations/($simulation_id)/runs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a run for a simulation
#
# POST /simulations/{simulation_id}/runs
# Docs: https://developer.paddle.com/api-reference/simulation-runs/create-simulation-run — Create a run for a simulation
# operationId: create-simulation-run
export def "simulations-runs create-simulation-run" [
  simulation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: any, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/simulations/($simulation_id)/runs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a run for a simulation
#
# GET /simulations/{simulation_id}/runs/{simulation_run_id}
# Docs: https://developer.paddle.com/api-reference/simulation-runs/get-simulation-run — Get a run for a simulation
# operationId: get-simulation-run
export def "simulations-runs get-simulation-run" [
  simulation_id: string
  simulation_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Include related entities in the response.
]: nothing -> record<data: any, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/simulations/($simulation_id)/runs/($simulation_run_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List events for a simulation run
#
# GET /simulations/{simulation_id}/runs/{simulation_run_id}/events
# Docs: https://developer.paddle.com/api-reference/simulation-events/list-simulation-events — List events for a simulation run
# operationId: list-simulations-events
export def "simulations-runs-events list-simulations-events" [
  simulation_id: string
  simulation_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list # Return only the IDs specified. Use a comma-separated list to get multiple entities.
  --after: string # Return entities after the specified Paddle ID when working with paginated endpoints. Used in the `meta.pagination.next` URL in responses for list operations.
  --per-page: int # Set how many entities are returned per page. Paddle returns the maximum number of results if a number greater than the maximum is requested. Check `meta.pagination.per_page` in the response to see how many were returned.  Default: `50`; Maximum: `200`. (default: 50)
  --order-by: string # Order returned entities by the specified field and direction (`[ASC]` or `[DESC]`). For example, `?order_by=id[ASC]`.  Valid fields for ordering: `id`. (default: id[DESC])
]: nothing -> record<data: table<id: record, status: record, event_type: record, payload: record, request: any, response: any, created_at: record, updated_at: record>, meta: record<request_id: string, pagination: record<per_page: int, next: string, has_more: bool, estimated_total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "after" $after "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/simulations/($simulation_id)/runs/($simulation_run_id)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an event for a simulation run
#
# GET /simulations/{simulation_id}/runs/{simulation_run_id}/events/{simulation_event_id}
# Docs: https://developer.paddle.com/api-reference/simulation-events/get-simulation-event — Get an event for a simulation run
# operationId: get-simulation-event
export def "simulations-runs-events get-simulation-event" [
  simulation_id: string
  simulation_run_id: string
  simulation_event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: record, status: record, event_type: record, payload: record, request: any, response: any, created_at: record, updated_at: record>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/simulations/($simulation_id)/runs/($simulation_run_id)/events/($simulation_event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replay an event for a simulation run
#
# POST /simulations/{simulation_id}/runs/{simulation_run_id}/events/{simulation_event_id}/replay
# Docs: https://developer.paddle.com/api-reference/simulation-events/replay-simulation-run-event — Replay an event for a simulation run
# operationId: replay-simulation-run-event
export def "simulations-runs-events-replay replay-simulation-run-event" [
  simulation_id: string
  simulation_run_id: string
  simulation_event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: record, status: record, event_type: record, payload: record, request: any, response: any, created_at: record, updated_at: record>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/simulations/($simulation_id)/runs/($simulation_run_id)/events/($simulation_event_id)/replay")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List subscriptions
#
# GET /subscriptions
# Docs: https://developer.paddle.com/api-reference/subscriptions/list-subscriptions — List subscriptions
# operationId: list-subscriptions
export def "subscriptions list-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list # Return only the IDs specified. Use a comma-separated list to get multiple entities.
  --after: string # Return entities after the specified Paddle ID when working with paginated endpoints. Used in the `meta.pagination.next` URL in responses for list operations.
  --per-page: int # Set how many entities are returned per page. Paddle returns the maximum number of results if a number greater than the maximum is requested. Check `meta.pagination.per_page` in the response to see how many were returned.  Default: `50`; Maximum: `200`. (default: 50)
  --address-id: list # Return entities related to the specified address. Use a comma-separated list to specify multiple address IDs.
  --collection-mode: string@collection-mode-completer # Return entities that match the specified collection mode.
  --customer-id: list # Return entities related to the specified customer. Use a comma-separated list to specify multiple customer IDs.
  --order-by: string # Order returned entities by the specified field and direction (`[ASC]` or `[DESC]`). For example, `?order_by=id[ASC]`.  Valid fields for ordering: `id`. (default: id[DESC])
  --price-id: list # Return entities related to the specified price. Use a comma-separated list to specify multiple price IDs.
  --scheduled-change-action: list # Return subscriptions that have a scheduled change. Use a comma-separated list to specify multiple scheduled change actions.
  --status: list # Return entities that match the specified status. Use a comma-separated list to specify multiple status values.
]: nothing -> record<data: table<id: record, status: record, customer_id: record, address_id: record, business_id: any, currency_code: record, created_at: record, updated_at: record, started_at: any, first_billed_at: any, next_billed_at: any, paused_at: any, canceled_at: any, discount: any, collection_mode: record, billing_details: any, current_billing_period: any, billing_cycle: record, scheduled_change: any, management_urls: record, items: list, custom_data: any, import_meta: any>, meta: record<request_id: string, pagination: record<per_page: int, next: string, has_more: bool, estimated_total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "csv") (serialize-qp "after" $after "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "address_id" $address_id "csv") (serialize-qp "collection_mode" $collection_mode "scalar") (serialize-qp "customer_id" $customer_id "csv") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "price_id" $price_id "csv") (serialize-qp "scheduled_change_action" $scheduled_change_action "csv") (serialize-qp "status" $status "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a subscription
#
# GET /subscriptions/{subscription_id}
# Docs: https://developer.paddle.com/api-reference/subscriptions/get-subscription — Get a subscription
# operationId: get-subscription
export def "subscriptions get-subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Include related entities in the response. Use a comma-separated list to specify multiple entities.
]: nothing -> record<data: record<id: record, status: record, customer_id: record, address_id: record, business_id: any, currency_code: record, created_at: record, updated_at: record, started_at: any, first_billed_at: any, next_billed_at: any, paused_at: any, canceled_at: any, discount: any, collection_mode: record, billing_details: any, current_billing_period: any, billing_cycle: record<interval: record, frequency: int>, scheduled_change: any, management_urls: record<update_payment_method: any, cancel: string>, items: list<record>, custom_data: any, import_meta: any, next_transaction: any, recurring_transaction_details: record<tax_rates_used: list, totals: record, line_items: list>>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscription_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a subscription
#
# PATCH /subscriptions/{subscription_id}
# Docs: https://developer.paddle.com/api-reference/subscriptions/update-subscription — Update a subscription
# operationId: update-subscription
export def "subscriptions update-subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-id: any # Paddle ID of the customer that this subscription is for, prefixed with `ctm_`. Include to change the customer for a subscription.
  --address-id: any # Paddle ID of the address that this subscription is for, prefixed with `add_`. Include to change the address for a subscription.
  --business-id: any # Paddle ID of the business that this subscription is for, prefixed with `biz_`. Include to change the business for a subscription.
  --currency-code: any # Supported three-letter ISO 4217 currency code. Include to change the currency that a subscription bills in. When changing `collection_mode` to `manual`, you may need to change currency code to `USD`, `EUR`, or `GBP`.
  --next-billed-at: any # RFC 3339 datetime string of when this subscription is next scheduled to be billed. Include to change the next billing date.
  --discount: any # Details of the discount applied to this subscription. Include to add a discount to a subscription. `null` to remove a discount.
  --collection-mode: any # How payment is collected for transactions created for this subscription. `automatic` for checkout, `manual` for invoices.
  --billing-details: any # Details for invoicing. Required if `collection_mode` is `manual`. `null` if changing `collection_mode` to `automatic`.
  --scheduled-change: any # Change that's scheduled to be applied to a subscription. When updating, you may only set to `null` to remove a scheduled change. Use the pause subscription, cancel subscription, and resume subscription operations to create scheduled changes.
  --items: list # List of items on this subscription. Only recurring items may be added. Send the complete list of items that should be on this subscription, including existing items to retain.
  --custom-data: any # Your own structured key-value data.
  --proration-billing-mode: string@proration-billing-mode-completer # How Paddle should handle proration calculation for changes made to a subscription or its items. Required when making changes that impact billing.  For automatically-collected subscriptions, responses may take longer than usual if a proration billing mode that collects for payment immediately is used.
  --on-payment-failure: any # default: prevent_change
]: any -> record<data: record<id: record, status: record, customer_id: record, address_id: record, business_id: any, currency_code: record, created_at: record, updated_at: record, started_at: any, first_billed_at: any, next_billed_at: any, paused_at: any, canceled_at: any, discount: any, collection_mode: record, billing_details: any, current_billing_period: any, billing_cycle: record<interval: record, frequency: int>, scheduled_change: any, management_urls: record<update_payment_method: any, cancel: string>, items: list<record>, custom_data: any, import_meta: any>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)")
  let body = {customer_id: $customer_id, address_id: $address_id, business_id: $business_id, currency_code: $currency_code, next_billed_at: $next_billed_at, discount: $discount, collection_mode: $collection_mode, billing_details: $billing_details, scheduled_change: $scheduled_change, items: $items, custom_data: $custom_data, proration_billing_mode: $proration_billing_mode, on_payment_failure: $on_payment_failure} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel a subscription
#
# POST /subscriptions/{subscription_id}/cancel
# Docs: https://developer.paddle.com/api-reference/subscriptions/cancel-subscription — Cancel a subscription
# operationId: cancel-subscription
export def "subscriptions-cancel cancel-subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --effective-from: any # default: next_billing_period
]: any -> record<data: record<id: record, status: record, customer_id: record, address_id: record, business_id: any, currency_code: record, created_at: record, updated_at: record, started_at: any, first_billed_at: any, next_billed_at: any, paused_at: any, canceled_at: any, discount: any, collection_mode: record, billing_details: any, current_billing_period: any, billing_cycle: record<interval: record, frequency: int>, scheduled_change: any, management_urls: record<update_payment_method: any, cancel: string>, items: list<record>, custom_data: any, import_meta: any>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/cancel")
  let body = {effective_from: $effective_from} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Pause a subscription
#
# POST /subscriptions/{subscription_id}/pause
# Docs: https://developer.paddle.com/api-reference/subscriptions/pause-subscription — Pause a subscription
# operationId: pause-subscription
export def "subscriptions-pause pause-subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --effective-from: any # default: next_billing_period
  --resume-at: any # RFC 3339 datetime string of when the paused subscription should resume. Omit to pause indefinitely until resumed.
  --on-resume: any # default: start_new_billing_period
]: any -> record<data: record<id: record, status: record, customer_id: record, address_id: record, business_id: any, currency_code: record, created_at: record, updated_at: record, started_at: any, first_billed_at: any, next_billed_at: any, paused_at: any, canceled_at: any, discount: any, collection_mode: record, billing_details: any, current_billing_period: any, billing_cycle: record<interval: record, frequency: int>, scheduled_change: any, management_urls: record<update_payment_method: any, cancel: string>, items: list<record>, custom_data: any, import_meta: any>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/pause")
  let body = {effective_from: $effective_from, resume_at: $resume_at, on_resume: $on_resume} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resume a paused subscription
#
# POST /subscriptions/{subscription_id}/resume
# Docs: https://developer.paddle.com/api-reference/subscriptions/resume-subscription — Resume a paused subscription
# operationId: resume-subscription
export def "subscriptions-resume resume-subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --effective-from: any # When this scheduled change should take effect from. RFC 3339 datetime string of when the subscription should resume.  Valid where subscriptions are `active` with a scheduled change to pause, or where they have the status of `paused`.
  --on-resume: any # default: start_new_billing_period
]: any -> record<data: record<id: record, status: record, customer_id: record, address_id: record, business_id: any, currency_code: record, created_at: record, updated_at: record, started_at: any, first_billed_at: any, next_billed_at: any, paused_at: any, canceled_at: any, discount: any, collection_mode: record, billing_details: any, current_billing_period: any, billing_cycle: record<interval: record, frequency: int>, scheduled_change: any, management_urls: record<update_payment_method: any, cancel: string>, items: list<record>, custom_data: any, import_meta: any>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/resume")
  let body = {effective_from: $effective_from, on_resume: $on_resume} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Activate a trialing subscription
#
# POST /subscriptions/{subscription_id}/activate
# Docs: https://developer.paddle.com/api-reference/subscriptions/activate-subscription — Activate a trialing subscription
# operationId: activate-subscription
export def "subscriptions-activate activate-subscription" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: record, status: record, customer_id: record, address_id: record, business_id: any, currency_code: record, created_at: record, updated_at: record, started_at: any, first_billed_at: any, next_billed_at: any, paused_at: any, canceled_at: any, discount: any, collection_mode: record, billing_details: any, current_billing_period: any, billing_cycle: record<interval: record, frequency: int>, scheduled_change: any, management_urls: record<update_payment_method: any, cancel: string>, items: list<record>, custom_data: any, import_meta: any>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/activate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a transaction to update payment method
#
# GET /subscriptions/{subscription_id}/update-payment-method-transaction
# Docs: https://developer.paddle.com/api-reference/subscriptions/update-payment-method — Get a transaction to update payment method
# operationId: get-subscription-update-payment-method-transaction
export def "subscriptions-update-payment-method-transaction get-subscription-update-payment-method-transaction" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: record, status: string, customer_id: any, address_id: any, business_id: any, custom_data: any, currency_code: record, origin: record, subscription_id: any, invoice_id: any, invoice_number: any, collection_mode: record, discount_id: any, billing_details: any, billing_period: any, items: list<record>, details: record<tax_rates_used: list, totals: record, adjusted_totals: record, payout_totals: any, adjusted_payout_totals: any, line_items: list>, payments: list<record>, checkout: any, created_at: record, updated_at: record, billed_at: any, revised_at: any, customer: record<id: record, name: any, email: record, marketing_consent: bool, status: record, custom_data: any, locale: string, created_at: record, updated_at: record, import_meta: any>, address: record<id: record, customer_id: record, description: any, first_line: any, second_line: any, city: any, postal_code: any, region: any, country_code: record, custom_data: any, status: record, created_at: record, updated_at: record, import_meta: any>, business: record<id: record, customer_id: record, name: record, company_number: any, tax_identifier: any, status: record, contacts: list, created_at: record, updated_at: record, custom_data: any, import_meta: any>, discount: record<id: record, status: record, description: string, enabled_for_checkout: bool, code: any, type: string, mode: record, amount: string, currency_code: any, recur: bool, maximum_recurring_intervals: any, usage_limit: any, restrict_to: any, expires_at: any, custom_data: any, times_used: int, discount_group_id: any, created_at: record, updated_at: record, import_meta: any>, adjustments: list<record>, adjustments_totals: record<subtotal: string, tax: string, total: string, fee: string, retained_fee: string, earnings: string, breakdown: record, currency_code: record>, available_payment_methods: list<string>>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/update-payment-method-transaction")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Preview an update to a subscription
#
# PATCH /subscriptions/{subscription_id}/preview
# Docs: https://developer.paddle.com/api-reference/subscriptions/preview-subscription — Preview an update to a subscription
# operationId: preview-subscription-update
export def "subscriptions-preview preview-subscription-update" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-id: any # Paddle ID of the customer that this subscription is for, prefixed with `ctm_`. Include to change the customer for a subscription.
  --address-id: any # Paddle ID of the address that this subscription is for, prefixed with `add_`. Include to change the address for a subscription.
  --business-id: any # Paddle ID of the business that this subscription is for, prefixed with `biz_`. Include to change the business for a subscription.
  --currency-code: any # Supported three-letter ISO 4217 currency code. Include to change the currency that a subscription bills in. When changing `collection_mode` to `manual`, you may need to change currency code to `USD`, `EUR`, or `GBP`.
  --next-billed-at: any # RFC 3339 datetime string of when this subscription is next scheduled to be billed. Include to change the next billing date.
  --discount: any # Details of the discount applied to this subscription. Include to add a discount to a subscription. `null` to remove a discount.
  --collection-mode: any # How payment is collected for transactions created for this subscription. `automatic` for checkout, `manual` for invoices.
  --billing-details: any # Details for invoicing. Required if `collection_mode` is `manual`. `null` if changing `collection_mode` to `automatic`.
  --scheduled-change: any # Change that's scheduled to be applied to a subscription. When updating, you may only set to `null` to remove a scheduled change. Use the pause subscription, cancel subscription, and resume subscription operations to create scheduled changes.
  --items: list # List of items on this subscription. Only recurring items may be added. Send the complete list of items that should be on this subscription, including existing items to retain.
  --custom-data: any # Your own structured key-value data.
  --proration-billing-mode: string@proration-billing-mode-completer # How Paddle should handle proration calculation for changes made to a subscription or its items. Required when making changes that impact billing.  For automatically-collected subscriptions, responses may take longer than usual if a proration billing mode that collects for payment immediately is used.
  --on-payment-failure: any # default: prevent_change
]: any -> record<data: record<status: record, customer_id: record, address_id: record, business_id: any, currency_code: record, created_at: record, updated_at: record, started_at: any, first_billed_at: any, next_billed_at: any, paused_at: any, canceled_at: any, discount: any, collection_mode: record, billing_details: any, current_billing_period: any, billing_cycle: record<interval: record, frequency: int>, scheduled_change: any, management_urls: record<update_payment_method: any, cancel: string>, items: list<record>, custom_data: any, immediate_transaction: any, next_transaction: any, recurring_transaction_details: record<tax_rates_used: list, totals: record, line_items: list>, update_summary: any, import_meta: any>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/preview")
  let body = {customer_id: $customer_id, address_id: $address_id, business_id: $business_id, currency_code: $currency_code, next_billed_at: $next_billed_at, discount: $discount, collection_mode: $collection_mode, billing_details: $billing_details, scheduled_change: $scheduled_change, items: $items, custom_data: $custom_data, proration_billing_mode: $proration_billing_mode, on_payment_failure: $on_payment_failure} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a one-time charge for a subscription
#
# POST /subscriptions/{subscription_id}/charge
# Docs: https://developer.paddle.com/api-reference/subscriptions/create-one-time-charge — Create a one-time charge for a subscription
# operationId: create-subscription-charge
export def "subscriptions-charge create-subscription-charge" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  effective_from: any # When one-time charges should be billed.
  items: list # List of one-time charges to bill for. Only prices where the `billing_cycle` is `null` may be added.  You can charge for items that you've added to your catalog by passing the Paddle ID of an existing price entity, or you can charge for non-catalog items by passing a price object.  Non-catalog items can be for existing products, or you can pass a product object as part of your price to charge for a non-catalog product.
  --on-payment-failure: any # default: prevent_change
]: any -> record<data: record<id: record, status: record, customer_id: record, address_id: record, business_id: any, currency_code: record, created_at: record, updated_at: record, started_at: any, first_billed_at: any, next_billed_at: any, paused_at: any, canceled_at: any, discount: any, collection_mode: record, billing_details: any, current_billing_period: any, billing_cycle: record<interval: record, frequency: int>, scheduled_change: any, management_urls: record<update_payment_method: any, cancel: string>, items: list<record>, custom_data: any, import_meta: any>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/charge")
  let body = {effective_from: $effective_from, items: $items, on_payment_failure: $on_payment_failure} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Preview a one-time charge for a subscription
#
# POST /subscriptions/{subscription_id}/charge/preview
# Docs: https://developer.paddle.com/api-reference/subscriptions/preview-subscription-charge — Preview a one-time charge for a subscription
# operationId: preview-subscription-charge
export def "subscriptions-charge-preview preview-subscription-charge" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  effective_from: any # When one-time charges should be billed.
  items: list # List of one-time charges to bill for. Only prices where the `billing_cycle` is `null` may be added.  You can charge for items that you've added to your catalog by passing the Paddle ID of an existing price entity, or you can charge for non-catalog items by passing a price object.  Non-catalog items can be for existing products, or you can pass a product object as part of your price to charge for a non-catalog product.
  --on-payment-failure: any # default: prevent_change
]: any -> record<data: record<status: record, customer_id: record, address_id: record, business_id: any, currency_code: record, created_at: record, updated_at: record, started_at: any, first_billed_at: any, next_billed_at: any, paused_at: any, canceled_at: any, discount: any, collection_mode: record, billing_details: any, current_billing_period: any, billing_cycle: record<interval: record, frequency: int>, scheduled_change: any, management_urls: record<update_payment_method: any, cancel: string>, items: list<record>, custom_data: any, immediate_transaction: any, next_transaction: any, recurring_transaction_details: record<tax_rates_used: list, totals: record, line_items: list>, update_summary: any, import_meta: any>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscriptions/($subscription_id)/charge/preview")
  let body = {effective_from: $effective_from, items: $items, on_payment_failure: $on_payment_failure} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List transactions
#
# GET /transactions
# Docs: https://developer.paddle.com/api-reference/transactions/list-transactions — List transactions
# operationId: list-transactions
export def "transactions list-transactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Include related entities in the response. Use a comma-separated list to specify multiple entities.
  --id: list # Return only the IDs specified. Use a comma-separated list to get multiple entities.
  --after: string # Return entities after the specified Paddle ID when working with paginated endpoints. Used in the `meta.pagination.next` URL in responses for list operations.
  --billed-at: string # Return entities billed at a specific time. Pass an RFC 3339 datetime string, or use `[LT]` (less than), `[LTE]` (less than or equal to), `[GT]` (greater than), or `[GTE]` (greater than or equal to) operators. For example, `billed_at=2023-04-18T17:03:26` or `billed_at[LT]=2023-04-18T17:03:26`.
  --collection-mode: string@collection-mode-completer # Return entities that match the specified collection mode.
  --created-at: string # Return entities created at a specific time. Pass an RFC 3339 datetime string, or use `[LT]` (less than), `[LTE]` (less than or equal to), `[GT]` (greater than), or `[GTE]` (greater than or equal to) operators. For example, `created_at=2023-04-18T17:03:26` or `created_at[LT]=2023-04-18T17:03:26`.
  --customer-id: list # Return entities related to the specified customer. Use a comma-separated list to specify multiple customer IDs.
  --invoice-number: list # Return entities that match the invoice number. Use a comma-separated list to specify multiple invoice numbers.
  --origin: list # Return entities related to the specified origin. Use a comma-separated list to specify multiple origins.
  --order-by: string # Order returned entities by the specified field and direction (`[ASC]` or `[DESC]`). For example, `?order_by=id[ASC]`.  Valid fields for ordering: `billed_at`, `created_at`, `id`, and `updated_at`. (default: id[DESC])
  --status: list # Return entities that match the specified status. Use a comma-separated list to specify multiple status values.
  --subscription-id: string # Return entities related to the specified subscription. Use a comma-separated list to specify multiple subscription IDs. Pass `null` to return entities that aren't related to any subscription.
  --per-page: int # Set how many entities are returned per page. Paddle returns the maximum number of results if a number greater than the maximum is requested. Check `meta.pagination.per_page` in the response to see how many were returned.  Default: `30`; Maximum: `30`. (default: 30)
  --updated-at: string # Return entities updated at a specific time. Pass an RFC 3339 datetime string, or use `[LT]` (less than), `[LTE]` (less than or equal to), `[GT]` (greater than), or `[GTE]` (greater than or equal to) operators. For example, `updated_at=2023-04-18T17:03:26` or `updated_at[LT]=2023-04-18T17:03:26`.
]: nothing -> record<data: table<id: record, status: string, customer_id: any, address_id: any, business_id: any, custom_data: any, currency_code: record, origin: record, subscription_id: any, invoice_id: any, invoice_number: any, collection_mode: record, discount_id: any, billing_details: any, billing_period: any, items: list, details: record, payments: list, checkout: any, created_at: record, updated_at: record, billed_at: any, revised_at: any, address: record, adjustments: list, adjustments_totals: record, business: record, customer: record, discount: record, available_payment_methods: list>, meta: record<request_id: string, pagination: record<per_page: int, next: string, has_more: bool, estimated_total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "csv") (serialize-qp "id" $id "csv") (serialize-qp "after" $after "scalar") (serialize-qp "billed_at" $billed_at "scalar") (serialize-qp "collection_mode" $collection_mode "scalar") (serialize-qp "created_at" $created_at "scalar") (serialize-qp "customer_id" $customer_id "csv") (serialize-qp "invoice_number" $invoice_number "csv") (serialize-qp "origin" $origin "csv") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "status" $status "csv") (serialize-qp "subscription_id" $subscription_id "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "updated_at" $updated_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a transaction
#
# POST /transactions
# Docs: https://developer.paddle.com/api-reference/transactions/create-transaction — Create a transaction
# operationId: create-transaction
# --payments item shape: {payment_attempt_id: string, stored_payment_method_id: string, payment_method_id: any, amount: string, error_code: any, method_details: record, captured_at: any}
export def "transactions create-transaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Include related entities in the response. Use a comma-separated list to specify multiple entities.
  --status: any # Status of this transaction. You may set a transaction to `billed` when creating, or omit to let Paddle set the status. Transactions are created as `ready` if they have an `address_id`, `customer_id`, and `items`, otherwise they are created as `draft`.  Marking as `billed` when creating is typically used when working with manually-collected transactions as part of an invoicing workflow. Billed transactions cannot be updated, only canceled.
  --customer-id: any # Paddle ID of the customer that this transaction is for, prefixed with `ctm_`. If omitted, transaction status is `draft`.
  --address-id: any # Paddle ID of the address that this transaction is for, prefixed with `add_`. Requires `customer_id`. If omitted, transaction status is `draft`.
  --business-id: any # Paddle ID of the business that this transaction is for, prefixed with `biz_`. Requires `customer_id`. 
  --custom-data: any # Your own structured key-value data.
  --currency-code: any # Supported three-letter ISO 4217 currency code. Must be `USD`, `EUR`, or `GBP` if `collection_mode` is `manual`.
  --origin: any
  --subscription-id: any # Paddle ID of the subscription that this transaction is for, prefixed with `sub_`.
  --collection-mode: any # How payment is collected for this transaction. `automatic` for checkout, `manual` for invoices. If omitted, defaults to `automatic`. (default: automatic)
  --discount-id: any # Paddle ID of the discount to apply to this transaction, prefixed with `dsc_`.
  --billing-details: any # Details for invoicing. Required if `collection_mode` is `manual`.
  --billing-period: any # Time period that this transaction is for. Set automatically by Paddle for subscription renewals to describe the period that charges are for.
  items: list # List of items to charge for. You can charge for items that you've added to your catalog by passing the Paddle ID of an existing price entity, or you can charge for non-catalog items by passing a price object.  Non-catalog items can be for existing products, or you can pass a product object as part of your price to charge for a non-catalog product.
  --checkout: any # Paddle Checkout details for this transaction. You may pass a URL when creating or updating an automatically-collected transaction, or when creating or updating a manually-collected transaction where `billing_details.enable_checkout` is `true`.
]: any -> record<data: record<id: record, status: string, customer_id: any, address_id: any, business_id: any, custom_data: any, currency_code: record, origin: record, subscription_id: any, invoice_id: any, invoice_number: any, collection_mode: record, discount_id: any, billing_details: any, billing_period: any, items: list<record>, details: record<tax_rates_used: list, totals: record, adjusted_totals: record, payout_totals: any, adjusted_payout_totals: any, line_items: list>, payments: list<record>, checkout: any, created_at: record, updated_at: record, billed_at: any, revised_at: any, address: record<id: record, customer_id: record, description: any, first_line: any, second_line: any, city: any, postal_code: any, region: any, country_code: record, custom_data: any, status: record, created_at: record, updated_at: record, import_meta: any>, adjustments: list<record>, adjustments_totals: record<subtotal: string, tax: string, total: string, fee: string, retained_fee: string, earnings: string, breakdown: record, currency_code: record>, business: record<id: record, customer_id: record, name: record, company_number: any, tax_identifier: any, status: record, contacts: list, created_at: record, updated_at: record, custom_data: any, import_meta: any>, customer: record<id: record, name: any, email: record, marketing_consent: bool, status: record, custom_data: any, locale: string, created_at: record, updated_at: record, import_meta: any>, discount: record<id: record, status: record, description: string, enabled_for_checkout: bool, code: any, type: string, mode: record, amount: string, currency_code: any, recur: bool, maximum_recurring_intervals: any, usage_limit: any, restrict_to: any, expires_at: any, custom_data: any, times_used: int, discount_group_id: any, created_at: record, updated_at: record, import_meta: any>, available_payment_methods: list<string>>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/transactions" $qp)
  let body = {status: $status, customer_id: $customer_id, address_id: $address_id, business_id: $business_id, custom_data: $custom_data, currency_code: $currency_code, origin: $origin, subscription_id: $subscription_id, collection_mode: $collection_mode, discount_id: $discount_id, billing_details: $billing_details, billing_period: $billing_period, items: $items, checkout: $checkout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a transaction
#
# GET /transactions/{transaction_id}
# Docs: https://developer.paddle.com/api-reference/transactions/get-transaction — Get a transaction
# operationId: get-transaction
export def "transactions get-transaction" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Include related entities in the response. Use a comma-separated list to specify multiple entities.
]: nothing -> record<data: record<id: record, status: string, customer_id: any, address_id: any, business_id: any, custom_data: any, currency_code: record, origin: record, subscription_id: any, invoice_id: any, invoice_number: any, collection_mode: record, discount_id: any, billing_details: any, billing_period: any, items: list<record>, details: record<tax_rates_used: list, totals: record, adjusted_totals: record, payout_totals: any, adjusted_payout_totals: any, line_items: list>, payments: list<record>, checkout: any, created_at: record, updated_at: record, billed_at: any, revised_at: any, address: record<id: record, customer_id: record, description: any, first_line: any, second_line: any, city: any, postal_code: any, region: any, country_code: record, custom_data: any, status: record, created_at: record, updated_at: record, import_meta: any>, adjustments: list<record>, adjustments_totals: record<subtotal: string, tax: string, total: string, fee: string, retained_fee: string, earnings: string, breakdown: record, currency_code: record>, business: record<id: record, customer_id: record, name: record, company_number: any, tax_identifier: any, status: record, contacts: list, created_at: record, updated_at: record, custom_data: any, import_meta: any>, customer: record<id: record, name: any, email: record, marketing_consent: bool, status: record, custom_data: any, locale: string, created_at: record, updated_at: record, import_meta: any>, discount: record<id: record, status: record, description: string, enabled_for_checkout: bool, code: any, type: string, mode: record, amount: string, currency_code: any, recur: bool, maximum_recurring_intervals: any, usage_limit: any, restrict_to: any, expires_at: any, custom_data: any, times_used: int, discount_group_id: any, created_at: record, updated_at: record, import_meta: any>, available_payment_methods: list<string>>, meta: record<request_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/transactions/($transaction_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a transaction
#
# PATCH /transactions/{transaction_id}
# Docs: https://developer.paddle.com/api-reference/transactions/update-transaction — Update a transaction
# operationId: update-transaction
# --payments item shape: {payment_attempt_id: string, stored_payment_method_id: string, payment_method_id: any, amount: string, error_code: any, method_details: record, captured_at: any}
export def "transactions update-transaction" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list # Include related entities in the response. Use a comma-separated list to specify multiple entities.
  --status: any # Status of this transaction. You may set a transaction to `billed` or `canceled`. Billed transactions cannot be changed.  For manually-collected transactions, marking as `billed` is essentially issuing an invoice.
  --customer-id: any # Paddle ID of the customer that this transaction is for, prefixed with `ctm_`.
  --address-id: any # Paddle ID of the address that this transaction is for, prefixed with `add_`.
  --business-id: any # Paddle ID of the business that this transaction is for, prefixed with `biz_`.
  --custom-data: any # Your own structured key-value data.
  --currency-code: any # Supported three-letter ISO 4217 currency code. Must be `USD`, `EUR`, or `GBP` if `collection_mode` is `manual`.
  --origin: any
  --subscription-id: any # Paddle ID of the subscription that this transaction is for, prefixed with `sub_`.
  --collection-mode: any # How payment is collected for this transaction. `automatic` for checkout, `manual` for invoices.
  --discount-id: any # Paddle ID of the discount to apply to this transaction, prefixed with `dsc_`.
  --billing-details: any # Details for invoicing. Required if `collection_mode` is `manual`.
  --billing-period: any # Time period that this transaction is for. Set automatically by Paddle for subscription renewals to describe the period that charges are for.
  --items: list # List of items on this transaction.  When making a request, each object must contain either a `price_id` or a `price` object, and a `quantity`.  Include a `price_id` to charge for an existing catalog item, or a `price` object to charge for a non-catalog item.
  --checkout: any # Paddle Checkout details for this transaction. You may pass a URL when creating or updating an automatically-collected transaction, or when creating or updating a manually-collected transaction where `billing_details.enable_checkout` is `true`.
]: any -> record<data: record<id: record, status: string, customer_id: any, address_id: any, business_id: any, custom_data: any, currency_code: record, origin: record, subscription_id: any, invoice_id: any, invoice_number: any, collection_mode: record, discount_id: any, billing_details: any, billing_period: any, items: list<record>, details: record<tax_rates_used: list, totals: record, adjusted_totals: record, payout_totals: any, adjusted_payout_totals: any, line_items: list>, payments: list<record>, checkout: any, created_at: record, updated_at: record, billed_at: any, revised_at: any, address: record<id: record, customer_id: record, description: any, first_line: any, second_line: any, city: any, postal_code: any, region: any, country_code: record, custom_data: any, status: record, created_at: record, updated_at: record, import_meta: any>, adjustments: list<record>, adjustments_totals: record<subtotal: string, tax: string, total: string, fee: string, retained_fee: string, earnings: string, breakdown: record, currency_code: record>, business: record<id: record, customer_id: record, name: record, company_number: any, tax_identifier: any, status: record, contacts: list, created_at: record, updated_at: record, custom_data: any, import_meta: any>, customer: record<id: record, name: any, email: record, marketing_consent: bool, status: record, custom_data: any, locale: string, created_at: record, updated_at: record, import_meta: any>, discount: record<id: record, status: record, description: string, enabled_for_checkout: bool, code: any, type: string, mode: record, amount: string, currency_code: any, recur: bool, maximum_recurring_intervals: any, usage_limit: any, restrict_to: any, expires_at: any, custom_data: any, times_used: int, discount_group_id: any, created_at: record, updated_at: record, import_meta: any>, available_payment_methods: list<string>>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/transactions/($transaction_id)" $qp)
  let body = {status: $status, customer_id: $customer_id, address_id: $address_id, business_id: $business_id, custom_data: $custom_data, currency_code: $currency_code, origin: $origin, subscription_id: $subscription_id, collection_mode: $collection_mode, discount_id: $discount_id, billing_details: $billing_details, billing_period: $billing_period, items: $items, checkout: $checkout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Preview a transaction
#
# POST /transactions/preview
# Docs: https://developer.paddle.com/api-reference/transactions/preview-transaction — Preview a transaction
# operationId: preview-transaction-create
export def "transactions-preview preview-transaction-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-id: any # Paddle ID of the customer that this transaction preview is for, prefixed with `ctm_`.
  --currency-code: any # Supported three-letter ISO 4217 currency code.
  --discount-id: any # Paddle ID of the discount to apply to this transaction preview, prefixed with `dsc_`.
  --ignore-trials: oneof<nothing, bool> # Whether trials should be ignored for transaction preview calculations.  By default, recurring items with trials are considered to have a zero charge when previewing. Set to `true` to disable this. (default: false)
  --items: list # List of items to preview charging for. You can preview charging for items that you've added to your catalog by passing the Paddle ID of an existing price entity, or you can preview charging for non-catalog items by passing a price object.  Non-catalog items can be for existing products, or you can pass a product object as part of your price to preview charging for a non-catalog product.
  --address: any # Address for this transaction preview.
  --customer-ip-address: string # IP address for this transaction preview.
  --address-id: any # Paddle ID of the address that this transaction preview is for, prefixed with `add_`. Requires `customer_id`.
  --business-id: any # Paddle ID of the business that this transaction preview is for, prefixed with `biz_`.
]: any -> record<data: record<customer_id: any, address_id: any, business_id: any, currency_code: record, discount_id: any, customer_ip_address: any, address: any, ignore_trials: bool, items: list<record>, details: record<tax_rates_used: list, totals: record, line_items: list>, available_payment_methods: list<string>>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactions/preview")
  let body = {customer_id: $customer_id, currency_code: $currency_code, discount_id: $discount_id, ignore_trials: $ignore_trials, items: $items, address: $address, customer_ip_address: $customer_ip_address, address_id: $address_id, business_id: $business_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revise customer information on a billed or completed transaction
#
# POST /transactions/{transaction_id}/revise
# Docs: https://developer.paddle.com/api-reference/transactions/revise-transaction — Revise a transaction
# operationId: revise-transaction
export def "transactions-revise revise-transaction" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer: any # Revised customer information for this transaction.
  --business: any # Revised business information for this transaction.
  --address: any # Revised address information for this transaction.
]: any -> record<data: record<id: record, status: string, customer_id: any, address_id: any, business_id: any, custom_data: any, currency_code: record, origin: record, subscription_id: any, invoice_id: any, invoice_number: any, collection_mode: record, discount_id: any, billing_details: any, billing_period: any, items: list<record>, details: record<tax_rates_used: list, totals: record, adjusted_totals: record, payout_totals: any, adjusted_payout_totals: any, line_items: list>, payments: list<record>, checkout: any, created_at: record, updated_at: record, billed_at: any, revised_at: any>, meta: record<request_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transactions/($transaction_id)/revise")
  let body = {customer: $customer, business: $business, address: $address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a PDF invoice for a transaction
#
# GET /transactions/{transaction_id}/invoice
# Docs: https://developer.paddle.com/api-reference/transactions/get-invoice-pdf — Get a PDF invoice for a transaction
# operationId: get-transaction-invoice
export def "transactions-invoice get-transaction-invoice" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --disposition: string@disposition-completer # Determine whether the generated URL should download the PDF as an attachment saved locally, or open it inline in the browser.  Default: `attachment`.
]: nothing -> record<meta: record<request_id: string>, data: record<url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "disposition" $disposition "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/transactions/($transaction_id)/invoice" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
