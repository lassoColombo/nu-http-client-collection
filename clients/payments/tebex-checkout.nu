# Auto-generated client for Tebex Checkout API v1.1.4
# Source: https://raw.githubusercontent.com/tebexio/TebexCheckout-OpenAPI/main/sdks/openapi/openapi.json
# Auth: --token flag or $env.TEBEX_CHECKOUT_API_TOKEN

const BASE_URL = "https://checkout.tebex.io/api"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TEBEX_CHECKOUT_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://checkout.tebex.io/api"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def type-completer [] { ["single" "subscription"] }
def discount-type-completer [] { ["amount" "percentage"] }
def status-completer [] { ["Active" "Paused"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "baskets get" } } | get name | first)
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

# Fetch a basket by its identifier
#
# GET /baskets/{ident}
# operationId: getBasketById
export def "baskets get" [
  ident: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ident: string, expire: string, price: float, priceDetails: record<fullPrice: float, subTotal: float, discounts: list<record>, total: float, tax: float, balance: float, sales: list<record>, giftcards: list<record>, recurring: bool, username: string, roundUp: float>, isPaymentMethodUpdate: bool, returnUrl: string, complete: bool, tax: float, username: string, email_immutable: bool, discounts: list<record>, coupons: list<record>, giftcards: list<record>, address: record<name: string, first_name: string, last_name: string, address: string, email: string, state_id: string, country: string, postal_code: string>, rows: table<id: int, basket: int, package: int, override: int, quantity: int, server: int, price: float, gift_username_id: int, options: record, recurring: bool, recurring_period: string, recurring_next_payment_date: string, meta: record, custom: record, image_url: string, recurring_price: float>, fingerprint: string, creator_code: string, roundup: bool, cancel_url: string, complete_url: string, complete_auto_redirect: bool, recurring_items: list<record>, payment: record<transaction_id: string, status: record<id: int, description: string>, payment_sequence: string, created_at: string, price: record<amount: float, currency: string>, price_paid: record<amount: float, currency: string>, payment_method: record<name: any, refundable: bool>, revenue_share: list<record>, decline_reason: string, fees: record<tax: record, gateway: record>, customer: record<first_name: string, last_name: string, email: string, ip: string, username: string, marketing_consent: bool, country: string, postal_code: string>, products: list<record>, coupons: list<record>, gift_cards: list<record>, recurring_payment_reference: string, custom: record>, custom: record, links: record<payment: string, checkout: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/baskets/($ident)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a basket's details, including expiry date.
#
# PUT /baskets/{ident}
# operationId: updateBasket
export def "baskets updateBasket" [
  ident: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --country: string # nullable
  --name: string # nullable
  --state-id: string # nullable
  --first-name: string # nullable
  --last-name: string # nullable
  --postal-code: string # nullable
  --creator-code: string # nullable
  --complete-auto-redirect: string@bool-completer # nullable
  --expires-at: string # An ISO8601 formatted date. After this date the basket cannot be used to checkout. (nullable, format: date-time, e.g. 2025-01-27T18:09:51Z)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/baskets/($ident)")
  let body = {country: $country, name: $name, state_id: $state_id, first_name: $first_name, last_name: $last_name, postal_code: $postal_code, creator_code: $creator_code, complete_auto_redirect: $complete_auto_redirect, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a package to the basket
#
# POST /baskets/{ident}/packages
# operationId: addPackage
# --package shape: {name?: string, price?: float, type?: "single"|"subscription", qty?: int, expiry_period?: "day"|"month"|"year", expiry_length?: int, custom?: record}
# --revenue_share item shape: {wallet_ref?: string, amount?: float, gateway_fee_percent?: float}
export def "baskets-packages addPackage" [
  ident: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --package: record # shape: {name?: string, price?: float, type?: "single"|"subscription", qty?: int, expiry_period?: "day"|"month"|"year", expiry_length?: int, custom?: record}
  --qty: int # The quantity of `package` in this basket. This is not the total quantity of overall items in the basket. (e.g. 2)
  --type: string@type-completer # The type of payment, either `single` for one-time payments or `subscription`. (e.g. single)
  --revenue-share: list # An array of payment destination objects describing how the purchase should be split between multiple wallets. **Only available with pre-agreement from Tebex.** — item shape: {wallet_ref?: string, amount?: float, gateway_fee_percent?: float}
]: any -> record<ident: string, expire: string, price: float, priceDetails: record<fullPrice: float, subTotal: float, discounts: list<record>, total: float, tax: float, balance: float, sales: list<record>, giftcards: list<record>, recurring: bool, username: string, roundUp: float>, isPaymentMethodUpdate: bool, returnUrl: string, complete: bool, tax: float, username: string, email_immutable: bool, discounts: list<record>, coupons: list<record>, giftcards: list<record>, address: record<name: string, first_name: string, last_name: string, address: string, email: string, state_id: string, country: string, postal_code: string>, rows: table<id: int, basket: int, package: int, override: int, quantity: int, server: int, price: float, gift_username_id: int, options: record, recurring: bool, recurring_period: string, recurring_next_payment_date: string, meta: record, custom: record, image_url: string, recurring_price: float>, fingerprint: string, creator_code: string, roundup: bool, cancel_url: string, complete_url: string, complete_auto_redirect: bool, recurring_items: list<record>, payment: record<transaction_id: string, status: record<id: int, description: string>, payment_sequence: string, created_at: string, price: record<amount: float, currency: string>, price_paid: record<amount: float, currency: string>, payment_method: record<name: any, refundable: bool>, revenue_share: list<record>, decline_reason: string, fees: record<tax: record, gateway: record>, customer: record<first_name: string, last_name: string, email: string, ip: string, username: string, marketing_consent: bool, country: string, postal_code: string>, products: list<record>, coupons: list<record>, gift_cards: list<record>, recurring_payment_reference: string, custom: record>, custom: record, links: record<payment: string, checkout: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/baskets/($ident)/packages")
  let body = {package: $package, qty: $qty, type: $type, revenue_share: $revenue_share} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a row from the basket
#
# DELETE /baskets/{ident}/packages/{rows.id}
# operationId: removeRowFromBasket
export def "baskets-packages removeRowFromBasket" [
  ident: string
  rows.id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/baskets/($ident)/packages/($rows.id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a sale to the basket
#
# POST /baskets/{ident}/sales
# operationId: addSaleToBasket
export def "baskets-sales addSaleToBasket" [
  ident: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the sale (displayed to the customer) (e.g. Test Sale)
  --discount-type: string@discount-type-completer # The type of discount, either `percentage` for deducting a percentage of each item, or `amount` to deduct a fixed amount from each item. (e.g. amount)
  --amount: float # The amount or percentage to deduct (e.g. 4.99)
]: any -> record<ident: string, expire: string, price: float, priceDetails: record<fullPrice: float, subTotal: float, discounts: list<record>, total: float, tax: float, balance: float, sales: list<record>, giftcards: list<record>, recurring: bool, username: string, roundUp: float>, isPaymentMethodUpdate: bool, returnUrl: string, complete: bool, tax: float, username: string, email_immutable: bool, discounts: list<record>, coupons: list<record>, giftcards: list<record>, address: record<name: string, first_name: string, last_name: string, address: string, email: string, state_id: string, country: string, postal_code: string>, rows: table<id: int, basket: int, package: int, override: int, quantity: int, server: int, price: float, gift_username_id: int, options: record, recurring: bool, recurring_period: string, recurring_next_payment_date: string, meta: record, custom: record, image_url: string, recurring_price: float>, fingerprint: string, creator_code: string, roundup: bool, cancel_url: string, complete_url: string, complete_auto_redirect: bool, recurring_items: list<record>, payment: record<transaction_id: string, status: record<id: int, description: string>, payment_sequence: string, created_at: string, price: record<amount: float, currency: string>, price_paid: record<amount: float, currency: string>, payment_method: record<name: any, refundable: bool>, revenue_share: list<record>, decline_reason: string, fees: record<tax: record, gateway: record>, customer: record<first_name: string, last_name: string, email: string, ip: string, username: string, marketing_consent: bool, country: string, postal_code: string>, products: list<record>, coupons: list<record>, gift_cards: list<record>, recurring_payment_reference: string, custom: record>, custom: record, links: record<payment: string, checkout: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/baskets/($ident)/sales")
  let body = {name: $name, discount_type: $discount_type, amount: $amount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a checkout request
#
# POST /checkout
# operationId: checkout
# --basket shape: {first_name?: string, last_name?: string, email?: string, return_url?: string, complete_url?: string, custom?: record}
# --items item shape: {package?: record}
# --sale shape: {name?: string, discount_type?: "percentage"|"amount", amount?: float}
export def "checkout checkout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  basket: record # An object containing the customer's information, relevant links, and any custom tracking data. (e.g. {first_name: Neil, last_name: McNeil, email: example@tebex.io, return_url: https://tebex.io, complete_url: https://tebex.io, custom: {foo: bar, trackingId: 127, list: [1, 2, 3]}}) — shape: {first_name?: string, last_name?: string, email?: string, return_url?: string, complete_url?: string, custom?: record}
  items: list # An array of `Packages` in the basket. — item shape: {package?: record}
  --sale: record # shape: {name?: string, discount_type?: "percentage"|"amount", amount?: float}
]: any -> record<ident: string, expire: string, price: float, priceDetails: record<fullPrice: float, subTotal: float, discounts: list<record>, total: float, tax: float, balance: float, sales: list<record>, giftcards: list<record>, recurring: bool, username: string, roundUp: float>, isPaymentMethodUpdate: bool, returnUrl: string, complete: bool, tax: float, username: string, email_immutable: bool, discounts: list<record>, coupons: list<record>, giftcards: list<record>, address: record<name: string, first_name: string, last_name: string, address: string, email: string, state_id: string, country: string, postal_code: string>, rows: table<id: int, basket: int, package: int, override: int, quantity: int, server: int, price: float, gift_username_id: int, options: record, recurring: bool, recurring_period: string, recurring_next_payment_date: string, meta: record, custom: record, image_url: string, recurring_price: float>, fingerprint: string, creator_code: string, roundup: bool, cancel_url: string, complete_url: string, complete_auto_redirect: bool, recurring_items: list<record>, payment: record<transaction_id: string, status: record<id: int, description: string>, payment_sequence: string, created_at: string, price: record<amount: float, currency: string>, price_paid: record<amount: float, currency: string>, payment_method: record<name: any, refundable: bool>, revenue_share: list<record>, decline_reason: string, fees: record<tax: record, gateway: record>, customer: record<first_name: string, last_name: string, email: string, ip: string, username: string, marketing_consent: bool, country: string, postal_code: string>, products: list<record>, coupons: list<record>, gift_cards: list<record>, recurring_payment_reference: string, custom: record>, custom: record, links: record<payment: string, checkout: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/checkout")
  let body = {basket: $basket, items: $items, sale: $sale} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a payment by its transaction ID
#
# GET /payments/{txnId}?type=txn_id
# operationId: getPaymentById
export def "payments get" [
  txnId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<transaction_id: string, status: record<id: int, description: string>, payment_sequence: string, created_at: string, price: record<amount: float, currency: string>, price_paid: record<amount: float, currency: string>, payment_method: record<name: any, refundable: bool>, revenue_share: table<wallet_ref: string, amount: float, gateway_fee_percent: float>, decline_reason: string, fees: record<tax: record<amount: float, currency: string>, gateway: record<amount: float, currency: string>>, customer: record<first_name: string, last_name: string, email: string, ip: string, username: string, marketing_consent: bool, country: string, postal_code: string>, products: table<id: string, name: string, quantity: int, base_price: record, paid_price: record, variables: list, expires_at: string, custom: record, username: string>, coupons: list<record>, gift_cards: list<record>, recurring_payment_reference: string, custom: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($txnId)?type=txn_id")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refund a payment by its transaction ID
#
# POST /payments/{txnId}/refund?type=txn_id
# operationId: refundPaymentById
export def "payments-refund-typetxn-id refundPaymentById" [
  txnId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<transaction_id: string, status: record<id: int, description: string>, payment_sequence: string, created_at: string, price: record<amount: float, currency: string>, price_paid: record<amount: float, currency: string>, payment_method: record<name: any, refundable: bool>, revenue_share: table<wallet_ref: string, amount: float, gateway_fee_percent: float>, decline_reason: string, fees: record<tax: record<amount: float, currency: string>, gateway: record<amount: float, currency: string>>, customer: record<first_name: string, last_name: string, email: string, ip: string, username: string, marketing_consent: bool, country: string, postal_code: string>, products: table<id: string, name: string, quantity: int, base_price: record, paid_price: record, variables: list, expires_at: string, custom: record, username: string>, coupons: list<record>, gift_cards: list<record>, recurring_payment_reference: string, custom: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/($txnId)/refund?type=txn_id")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a recurring payment
#
# DELETE /recurring-payments/{reference}
# operationId: cancelRecurringPayment
export def "recurring-payments cancelRecurringPayment" [
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, created_at: string, updated_at: string, paused_at: string, paused_until: string, next_payment_date: string, reference: string, account_id: int, interval: string, cancelled_at: string, cancellation_requested_at: string, status: record<id: int, class: string, description: string, active: int>, amount: record<amount: float, tax: float, period: string>, cancel_reason: string, links: record<initial_payment: string, payment_history: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/recurring-payments/($reference)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a recurring payment (subscription) by its reference
#
# GET /recurring-payments/{reference}
# operationId: getRecurringPayment
export def "recurring-payments get" [
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, created_at: string, updated_at: string, paused_at: string, paused_until: string, next_payment_date: string, reference: string, account_id: int, interval: string, cancelled_at: string, cancellation_requested_at: string, status: record<id: int, class: string, description: string, active: int>, amount: record<amount: float, tax: float, period: string>, cancel_reason: string, links: record<initial_payment: string, payment_history: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/recurring-payments/($reference)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a subscription with a new product / amount to pay - replacing the existing product
#
# PUT /recurring-payments/{reference}
# operationId: updateSubscription
# --items item shape: {type?: "single"|"subscription", qty?: float, revenue_share?: list, package?: record}
export def "recurring-payments updateSubscription" [
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --items: list # An array containing the items to be added to the recurring payment. **Only 1 item is supported at this time.** — item shape: {type?: "single"|"subscription", qty?: float, revenue_share?: list, package?: record}
]: any -> record<id: int, created_at: string, updated_at: string, paused_at: string, paused_until: string, next_payment_date: string, reference: string, account_id: int, interval: string, cancelled_at: string, cancellation_requested_at: string, status: record<id: int, class: string, description: string, active: int>, amount: record<amount: float, tax: float, period: string>, cancel_reason: string, links: record<initial_payment: string, payment_history: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/recurring-payments/($reference)")
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Pause or reactivate a recurring payment
#
# PUT /recurring-payments/{reference}/status
# operationId: updateRecurringPayment
export def "recurring-payments-status updateRecurringPayment" [
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  status: string@status-completer # Your desired state of the recurring payment. Provide `Paused` with `paused_until` to pause a recurring payment. Otherwise, provide `Active` to resume a recurring payment. (e.g. Paused)
  --paused-until: string # To pause a payment, provide a ISO8601 formatted date on which the payment should be reactivated. (e.g. 2025-01-27T16:43:53.000000Z)
]: any -> record<id: int, created_at: string, updated_at: string, paused_at: string, paused_until: string, next_payment_date: string, reference: string, account_id: int, interval: string, cancelled_at: string, cancellation_requested_at: string, status: record<id: int, class: string, description: string, active: int>, amount: record<amount: float, tax: float, period: string>, cancel_reason: string, links: record<initial_payment: string, payment_history: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/recurring-payments/($reference)/status")
  let body = {status: $status, paused_until: $paused_until} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a basket that can be used to pay for items
#
# POST /baskets
# operationId: createBasket
export def "baskets createBasket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --return-url: string # The URL a customer can return to without completing checkout (e.g. https://example.tebex.io/)
  --complete-url: string # URL the customer can return to after completing payment (e.g. https://example.tebex.io/complete)
  --custom: record # Any custom data to be passed through the request. This will be returned in a post-completion webhook. (e.g. {foo: bar})
  --first-name: string # The first name of the customer (e.g. Neil)
  --last-name: string # The last name of the customer (e.g. McNeil)
  --email: string # The email address of the customer (e.g. example@tebex.io)
  --complete-auto-redirect: string@bool-completer # Automatically redirect to the complete_url provided (e.g. true)
  --country: string # An ISO 3166-1 alpha-2 character code representing the customer's country. (e.g. US)
  --creator-code: string # The creator code is used to share a percentage of the payment with another party. See more about creator codes at https://docs.tebex.io/creators/tebex-control-panel/engagement/creator-codes
  --ip: string # The IP address of the customer using this basket. Provide the IP if creating a basket on your server backend. (e.g. 1.2.3.4)
]: any -> record<ident: string, expire: string, price: float, priceDetails: record<fullPrice: float, subTotal: float, discounts: list<record>, total: float, tax: float, balance: float, sales: list<record>, giftcards: list<record>, recurring: bool, username: string, roundUp: float>, isPaymentMethodUpdate: bool, returnUrl: string, complete: bool, tax: float, username: string, email_immutable: bool, discounts: list<record>, coupons: list<record>, giftcards: list<record>, address: record<name: string, first_name: string, last_name: string, address: string, email: string, state_id: string, country: string, postal_code: string>, rows: table<id: int, basket: int, package: int, override: int, quantity: int, server: int, price: float, gift_username_id: int, options: record, recurring: bool, recurring_period: string, recurring_next_payment_date: string, meta: record, custom: record, image_url: string, recurring_price: float>, fingerprint: string, creator_code: string, roundup: bool, cancel_url: string, complete_url: string, complete_auto_redirect: bool, recurring_items: list<record>, payment: record<transaction_id: string, status: record<id: int, description: string>, payment_sequence: string, created_at: string, price: record<amount: float, currency: string>, price_paid: record<amount: float, currency: string>, payment_method: record<name: any, refundable: bool>, revenue_share: list<record>, decline_reason: string, fees: record<tax: record, gateway: record>, customer: record<first_name: string, last_name: string, email: string, ip: string, username: string, marketing_consent: bool, country: string, postal_code: string>, products: list<record>, coupons: list<record>, gift_cards: list<record>, recurring_payment_reference: string, custom: record>, custom: record, links: record<payment: string, checkout: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/baskets")
  let body = {return_url: $return_url, complete_url: $complete_url, custom: $custom, first_name: $first_name, last_name: $last_name, email: $email, complete_auto_redirect: $complete_auto_redirect, country: $country, creator_code: $creator_code, ip: $ip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
