# Auto-generated client for Jirafe Events v2.0.0
# Source: https://api.apis.guru/v2/specs/jirafe.com/2.0.0/swagger.json
# Auth: --token flag or $env.JIRAFE_EVENTS_TOKEN

const BASE_URL = "https://event.jirafe.com/v2"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o JIRAFE_EVENTS_TOKEN | default "" }
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

def base-url-completer [] { ["https://event.jirafe.com/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["cancelled"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "batch post" } } | get name | first)
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

# Send a batch for the given site
#
# POST /{siteId}/batch
# operationId: postBatch
# --cart item shape: {cart_id?: string, change_date: string, cookies?: record, create_date: string, currency: string, customer: record, id: string, items: list, previous_items?: list, subtotal: float, total: float, total_discounts: float, total_payment_cost: float, total_shipping: float, total_tax: float, visit?: record}
# --category item shape: {id: string, name: string}
# --customer item shape: {active_flag?: bool, change_date: string, company?: string, cookies?: record, create_date: string, department?: string, email?: string, first_name?: string, id: string, last_name?: string, marketing_opt_in?: bool, name?: string, phone?: string, position?: string}
# --order item shape: {cart_id?: string, change_date: string, create_date: string, currency: string, customer: record, items: list, order_date: string, order_number: string, previous_items?: list, status: "accepted", subtotal: float, total: float, total_discounts: float, total_payment_cost: float, total_shipping: float, total_tax: float}
# --product item shape: {ancestors?: list, attributes?: list, base_product?: record, brand?: string, catalog?: record, categories?: list, change_date: string, code: string, create_date: string, id: string, images?: list, is_order: bool, is_sku: bool, name?: string, rating?: float, urls?: record, vendors?: list}
export def "batch post" [
  siteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cart: list # item shape: {cart_id?: string, change_date: string, cookies?: record, create_date: string, currency: string, customer: record, id: string, items: list, previous_items?: list, subtotal: float, total: float, total_discounts: float, total_payment_cost: float, total_shipping: float, total_tax: float, visit?: record}
  --category: list # item shape: {id: string, name: string}
  --customer: list # item shape: {active_flag?: bool, change_date: string, company?: string, cookies?: record, create_date: string, department?: string, email?: string, first_name?: string, id: string, last_name?: string, marketing_opt_in?: bool, name?: string, phone?: string, position?: string}
  --employee: list
  --order: list # item shape: {cart_id?: string, change_date: string, create_date: string, currency: string, customer: record, items: list, order_date: string, order_number: string, previous_items?: list, status: "accepted", subtotal: float, total: float, total_discounts: float, total_payment_cost: float, total_shipping: float, total_tax: float}
  --product: list # item shape: {ancestors?: list, attributes?: list, base_product?: record, brand?: string, catalog?: record, categories?: list, change_date: string, code: string, create_date: string, id: string, images?: list, is_order: bool, is_sku: bool, name?: string, rating?: float, urls?: record, vendors?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($siteId)/batch")
  let body = {cart: $cart, category: $category, customer: $customer, employee: $employee, order: $order, product: $product} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send a cart for the given site
#
# POST /{siteId}/cart
# operationId: postCart
# --customer shape: {active_flag?: bool, change_date: string, company?: string, cookies?: record, create_date: string, department?: string, email?: string, first_name?: string, id: string, last_name?: string, marketing_opt_in?: bool, name?: string, phone?: string, position?: string}
# --items item shape: {cart_item_number: string, change_date: string, create_date: string, discount_price: float, id: string, price: float, product: record, quantity: int}
# --previous_items item shape: {cart_item_number: string, change_date: string, create_date: string, discount_price: float, id: string, price: float, product: record, quantity: int}
# --visit shape: {last_pageview_id: string, pageview_id: string, visit_id: string, visitor_id: string}
export def "cart post" [
  siteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cart-id: string
  change_date: string # format: date-time
  --cookies: record
  create_date: string # format: date-time
  currency: string
  customer: record # shape: {active_flag?: bool, change_date: string, company?: string, cookies?: record, create_date: string, department?: string, email?: string, first_name?: string, id: string, last_name?: string, marketing_opt_in?: bool, name?: string, phone?: string, position?: string}
  id: string
  items: list # item shape: {cart_item_number: string, change_date: string, create_date: string, discount_price: float, id: string, price: float, product: record, quantity: int}
  --previous-items: list # item shape: {cart_item_number: string, change_date: string, create_date: string, discount_price: float, id: string, price: float, product: record, quantity: int}
  subtotal: float
  total: float
  total_discounts: float
  total_payment_cost: float
  total_shipping: float
  total_tax: float
  --visit: record # shape: {last_pageview_id: string, pageview_id: string, visit_id: string, visitor_id: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($siteId)/cart")
  let body = {cart_id: $cart_id, change_date: $change_date, cookies: $cookies, create_date: $create_date, currency: $currency, customer: $customer, id: $id, items: $items, previous_items: $previous_items, subtotal: $subtotal, total: $total, total_discounts: $total_discounts, total_payment_cost: $total_payment_cost, total_shipping: $total_shipping, total_tax: $total_tax, visit: $visit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send a category for the given site
#
# POST /{siteId}/category
# operationId: postCategory
export def "category post" [
  siteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($siteId)/category")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send a customer for the given site
#
# POST /{siteId}/customer
# operationId: postCustomer
export def "customer post" [
  siteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active-flag: oneof<nothing, bool> # default: true
  change_date: string # format: date-time
  --company: string
  --cookies: record
  create_date: string # format: date-time
  --department: string
  --email: string
  --first-name: string
  id: string
  --last-name: string
  --marketing-opt-in: oneof<nothing, bool>
  --name: string
  --phone: string
  --position: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($siteId)/customer")
  let body = {active_flag: $active_flag, change_date: $change_date, company: $company, cookies: $cookies, create_date: $create_date, department: $department, email: $email, first_name: $first_name, id: $id, last_name: $last_name, marketing_opt_in: $marketing_opt_in, name: $name, phone: $phone, position: $position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send a order for the given site
#
# POST /{siteId}/order
# operationId: postOrderCancelled
export def "order post" [
  siteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  cancel_date: string # format: date-time
  order_number: string
  status: string@status-completer # default: cancelled
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($siteId)/order")
  let body = {cancel_date: $cancel_date, order_number: $order_number, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send a product for the given site
#
# POST /{siteId}/product
# operationId: postProduct
# --attributes item shape: {id: string, name: string, value: string}
# --base_product shape: {code?: string, id?: string, name?: string}
# --catalog shape: {id: string, name?: string, version_id?: string}
# --categories item shape: {id: string, name: string}
# --urls shape: {admin?: string, store?: string}
# --vendors item shape: {id?: string, name?: string}
export def "product post" [
  siteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ancestors: list
  --attributes: list # item shape: {id: string, name: string, value: string}
  --base-product: record # shape: {code?: string, id?: string, name?: string}
  --brand: string
  --catalog: record # shape: {id: string, name?: string, version_id?: string}
  --categories: list # item shape: {id: string, name: string}
  change_date: string # format: date-time
  code: string
  create_date: string # format: date-time
  id: string
  --images: list
  --is-order: oneof<nothing, bool>
  --is-sku: oneof<nothing, bool>
  --name: string
  --rating: float
  --urls: record # shape: {admin?: string, store?: string}
  --vendors: list # item shape: {id?: string, name?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($siteId)/product")
  let body = {ancestors: $ancestors, attributes: $attributes, base_product: $base_product, brand: $brand, catalog: $catalog, categories: $categories, change_date: $change_date, code: $code, create_date: $create_date, id: $id, images: $images, is_order: $is_order, is_sku: $is_sku, name: $name, rating: $rating, urls: $urls, vendors: $vendors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
