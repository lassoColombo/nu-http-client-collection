# Auto-generated client for Jirafe Events v2.0.0
# Source: https://api.apis.guru/v2/specs/jirafe.com/2.0.0/swagger.json
# Auth: --token flag or $env.JIRAFE_EVENTS_TOKEN

const BASE_URL = "https://event.jirafe.com/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o JIRAFE_EVENTS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://event.jirafe.com/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["cancelled"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "batch create" } } | get name | first)
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
# --product item shape: {ancestors?: list<string>, attributes?: list, base_product?: record, brand?: string, catalog?: record, categories?: list, change_date: string, code: string, create_date: string, id: string, images?: list, is_order: bool, is_sku: bool, name?: string, rating?: float, urls?: record, vendors?: list}
export def "batch create" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cart: list # item shape: {cart_id?: string, change_date: string, cookies?: record, create_date: string, currency: string, customer: record, id: string, items: list, previous_items?: list, subtotal: float, total: float, total_discounts: float, total_payment_cost: float, total_shipping: float, total_tax: float, visit?: record}
  --category: list # item shape: {id: string, name: string}
  --customer: list # item shape: {active_flag?: bool, change_date: string, company?: string, cookies?: record, create_date: string, department?: string, email?: string, first_name?: string, id: string, last_name?: string, marketing_opt_in?: bool, name?: string, phone?: string, position?: string}
  --employee: list
  --order: list # item shape: {cart_id?: string, change_date: string, create_date: string, currency: string, customer: record, items: list, order_date: string, order_number: string, previous_items?: list, status: "accepted", subtotal: float, total: float, total_discounts: float, total_payment_cost: float, total_shipping: float, total_tax: float}
  --product: list # item shape: {ancestors?: list<string>, attributes?: list, base_product?: record, brand?: string, catalog?: record, categories?: list, change_date: string, code: string, create_date: string, id: string, images?: list, is_order: bool, is_sku: bool, name?: string, rating?: float, urls?: record, vendors?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'siteId' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/{site_id}/batch") $auth.query)
  let req_body = {"cart": $cart, "category": $category, "customer": $customer, "employee": $employee, "order": $order, "product": $product} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Send a cart for the given site
#
# POST /{siteId}/cart
# operationId: postCart
# --customer shape: {active_flag?: bool, change_date: string, company?: string, cookies?: record, create_date: string, department?: string, email?: string, first_name?: string, id: string, last_name?: string, marketing_opt_in?: bool, name?: string, phone?: string, position?: string}
# --items item shape: {cart_item_number: string, change_date: string, create_date: string, discount_price: float, id: string, price: float, product: record, quantity: int}
# --previous_items item shape: {cart_item_number: string, change_date: string, create_date: string, discount_price: float, id: string, price: float, product: record, quantity: int}
# --visit shape: {last_pageview_id: string, pageview_id: string, visit_id: string, visitor_id: string}
export def "cart create" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'siteId' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/{site_id}/cart") $auth.query)
  let req_body = {"cart_id": $cart_id, "change_date": $change_date, "cookies": $cookies, "create_date": $create_date, "currency": $currency, "customer": $customer, "id": $id, "items": $items, "previous_items": $previous_items, "subtotal": $subtotal, "total": $total, "total_discounts": $total_discounts, "total_payment_cost": $total_payment_cost, "total_shipping": $total_shipping, "total_tax": $total_tax, "visit": $visit} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Send a category for the given site
#
# POST /{siteId}/category
# operationId: postCategory
export def "category create" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'siteId' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/{site_id}/category") $auth.query)
  let req_body = {"id": $id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Send a customer for the given site
#
# POST /{siteId}/customer
# operationId: postCustomer
export def "customer create" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'siteId' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/{site_id}/customer") $auth.query)
  let req_body = {"active_flag": $active_flag, "change_date": $change_date, "company": $company, "cookies": $cookies, "create_date": $create_date, "department": $department, "email": $email, "first_name": $first_name, "id": $id, "last_name": $last_name, "marketing_opt_in": $marketing_opt_in, "name": $name, "phone": $phone, "position": $position} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Send a order for the given site
#
# POST /{siteId}/order
# operationId: postOrderCancelled
export def "order create-cancelled" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  cancel_date: string # format: date-time
  order_number: string
  status: string@status-completer # default: cancelled
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'siteId' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/{site_id}/order") $auth.query)
  let req_body = {"cancel_date": $cancel_date, "order_number": $order_number, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
export def "product create" [
  site_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ancestors: list<string>
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
  if ($site_id | is-empty) { error make --unspanned { msg: "path parameter 'siteId' must be non-empty" } }
  let full_url = (build-url $base ({site_id: (encode-path-segment $site_id)} | format pattern "/{site_id}/product") $auth.query)
  let req_body = {"ancestors": $ancestors, "attributes": $attributes, "base_product": $base_product, "brand": $brand, "catalog": $catalog, "categories": $categories, "change_date": $change_date, "code": $code, "create_date": $create_date, "id": $id, "images": $images, "is_order": $is_order, "is_sku": $is_sku, "name": $name, "rating": $rating, "urls": $urls, "vendors": $vendors} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
