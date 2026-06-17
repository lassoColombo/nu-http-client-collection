# Auto-generated client for Beanstream Payments v1.0.1
# Source: https://api.apis.guru/v2/specs/beanstream.com/1.0.1/swagger.json
# Auth: --token flag or $env.BEANSTREAM_PAYMENTS_TOKEN

const BASE_URL = "https://www.beanstream.com/api/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BEANSTREAM_PAYMENTS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://www.beanstream.com/api/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "payments post" } } | get name | first)
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

# Make Payment
#
# POST /payments
# --billing shape: {address_line1?: string, address_line2?: string, city?: string, country?: string, email_address?: string, name?: string, phone_number?: string, postal_code?: string, province?: string}
# --card shape: {complete?: bool, cvd?: string, expiry_month: string, expiry_year: string, name: string, number: string}
# --custom shape: {ref1?: string, ref2?: string, ref3?: string, ref4?: string, ref5?: string}
# --payment_profile shape: {card_id: int, complete?: bool, customer_code: string}
# --shipping shape: {address_line1?: string, address_line2?: string, city?: string, country?: string, email_address?: string, name?: string, phone_number?: string, postal_code?: string, province?: string}
# --token shape: {code: string, complete?: bool, name: string}
export def "payments post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # A decimal value in dollars, or relevant currency. digits(9) (format: double)
  --billing: any # shape: {address_line1?: string, address_line2?: string, city?: string, country?: string, email_address?: string, name?: string, phone_number?: string, postal_code?: string, province?: string}
  --card: any # shape: {complete?: bool, cvd?: string, expiry_month: string, expiry_year: string, name: string, number: string}
  --comments: string # alphanumeric (256)
  --custom: any # shape: {ref1?: string, ref2?: string, ref3?: string, ref4?: string, ref5?: string}
  --customer-ip: string # alphanumeric (30)
  --language: string # characters (3)
  --order-number: string # A unique order number. alphanumeric(30)
  payment_method: string # One of (card, token, payment_profile, cash, cheque). characters(20)
  --payment-profile: any # shape: {card_id: int, complete?: bool, customer_code: string}
  --shipping: any # shape: {address_line1?: string, address_line2?: string, city?: string, country?: string, email_address?: string, name?: string, phone_number?: string, postal_code?: string, province?: string}
  --term-url: string # alphanumeric (256)
  --body-token: any # shape: {code: string, complete?: bool, name: string}
]: any -> record<approved: int, auth_code: string, card: record<address_match: int, card_type: string, cvd_match: int, last_four: string, postal_result: int>, created: string, id: string, links: table<href: string, method: string, ref: string>, message: string, message_id: string, order_number: string, payment_method: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payments")
  let body = {"amount": $amount, "billing": $billing, "card": $card, "comments": $comments, "custom": $custom, "customer_ip": $customer_ip, "language": $language, "order_number": $order_number, "payment_method": $payment_method, "payment_profile": $payment_profile, "shipping": $shipping, "term_url": $term_url, "token": $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get payment
#
# GET /payments/{transId}
export def "payments get" [
  trans_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<adjusted_by: table<amount: float, approval: float, created: string, id: float, message: string, type: string, url: string>, amount: float, approved: bool, auth_code: string, batch_number: string, billing: record<address_line1: string, address_line2: string, city: string, country: string, email_address: string, name: string, phone_number: string, postal_code: string, province: string>, card: record<address_match: int, avs_result: string, card_type: string, cvd_match: int, expiry_month: string, expiry_year: string, last_four: string>, comments: string, created: string, custom: record<ref1: string, ref2: string, ref3: string, ref4: string, ref5: string>, id: float, links: table<href: string, method: string, ref: string>, message: string, message_id: float, order_number: string, payment_method: string, shipping: record<address_line1: string, address_line2: string, city: string, country: string, email_address: string, name: string, phone_number: string, postal_code: string, province: string>, total_completions: float, total_refunds: float, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({trans_id: $trans_id} | format pattern "/payments/{trans_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Complete pre-auth
#
# POST /payments/{transId}/completions
# --billing shape: {address_line1?: string, address_line2?: string, city?: string, country?: string, email_address?: string, name?: string, phone_number?: string, postal_code?: string, province?: string}
# --card shape: {complete?: bool, cvd?: string, expiry_month: string, expiry_year: string, name: string, number: string}
# --custom shape: {ref1?: string, ref2?: string, ref3?: string, ref4?: string, ref5?: string}
# --payment_profile shape: {card_id: int, complete?: bool, customer_code: string}
# --shipping shape: {address_line1?: string, address_line2?: string, city?: string, country?: string, email_address?: string, name?: string, phone_number?: string, postal_code?: string, province?: string}
# --token shape: {code: string, complete?: bool, name: string}
export def "payments-completions post" [
  trans_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # A decimal value in dollars, or relevant currency. digits(9) (format: double)
  --billing: any # shape: {address_line1?: string, address_line2?: string, city?: string, country?: string, email_address?: string, name?: string, phone_number?: string, postal_code?: string, province?: string}
  --card: any # shape: {complete?: bool, cvd?: string, expiry_month: string, expiry_year: string, name: string, number: string}
  --comments: string # alphanumeric (256)
  --custom: any # shape: {ref1?: string, ref2?: string, ref3?: string, ref4?: string, ref5?: string}
  --customer-ip: string # alphanumeric (30)
  --language: string # characters (3)
  --order-number: string # A unique order number. alphanumeric(30)
  payment_method: string # One of (card, token, payment_profile, cash, cheque). characters(20)
  --payment-profile: any # shape: {card_id: int, complete?: bool, customer_code: string}
  --shipping: any # shape: {address_line1?: string, address_line2?: string, city?: string, country?: string, email_address?: string, name?: string, phone_number?: string, postal_code?: string, province?: string}
  --term-url: string # alphanumeric (256)
  --body-token: any # shape: {code: string, complete?: bool, name: string}
]: any -> record<approved: int, auth_code: string, card: record<address_match: int, card_type: string, cvd_match: int, last_four: string, postal_result: int>, created: string, id: string, links: table<href: string, method: string, ref: string>, message: string, message_id: string, order_number: string, payment_method: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({trans_id: $trans_id} | format pattern "/payments/{trans_id}/completions"))
  let body = {"amount": $amount, "billing": $billing, "card": $card, "comments": $comments, "custom": $custom, "customer_ip": $customer_ip, "language": $language, "order_number": $order_number, "payment_method": $payment_method, "payment_profile": $payment_profile, "shipping": $shipping, "term_url": $term_url, "token": $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return payment
#
# POST /payments/{transId}/returns
export def "payments-returns post" [
  trans_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # The amount of the transaction to return. Must be less than or equal to the original purchase amount. (format: double)
  --order-number: string # alphanumeric (30)
]: any -> record<approved: int, auth_code: string, card: record<address_match: int, card_type: string, cvd_match: int, last_four: string, postal_result: int>, created: string, id: string, links: table<href: string, method: string, ref: string>, message: string, message_id: string, order_number: string, payment_method: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({trans_id: $trans_id} | format pattern "/payments/{trans_id}/returns"))
  let body = {"amount": $amount, "order_number": $order_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Void Transaction
#
# POST /payments/{transId}/void
export def "payments-void post" [
  trans_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # The amount of the transaction to void. Must be equal to the original purchase amount. You can void purchases as well as pre-auths and returns. The amount you are voiding has to match the amount of that transaction. (format: double)
]: any -> record<approved: int, auth_code: string, card: record<address_match: int, card_type: string, cvd_match: int, last_four: string, postal_result: int>, created: string, id: string, links: table<href: string, method: string, ref: string>, message: string, message_id: string, order_number: string, payment_method: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({trans_id: $trans_id} | format pattern "/payments/{trans_id}/void"))
  let body = {"amount": $amount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Profile
#
# POST /profiles
# --billing shape: {address_line1?: string, address_line2?: string, city?: string, country?: string, email_address?: string, name?: string, phone_number?: string, postal_code?: string, province?: string}
# --card shape: {cvd?: string, expiry_month: string, expiry_year: string, name: string, number: string}
# --custom shape: {ref1?: string, ref2?: string, ref3?: string, ref4?: string, ref5?: string}
# --token shape: {code: string, name: string}
export def "profiles post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing: any # shape: {address_line1?: string, address_line2?: string, city?: string, country?: string, email_address?: string, name?: string, phone_number?: string, postal_code?: string, province?: string}
  --card: any # shape: {cvd?: string, expiry_month: string, expiry_year: string, name: string, number: string}
  --comment: string # alphanumeric(256)
  --custom: any # shape: {ref1?: string, ref2?: string, ref3?: string, ref4?: string, ref5?: string}
  --language: string # characters(2)
  --body-token: any # shape: {code: string, name: string}
]: any -> record<code: float, customer_code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profiles")
  let body = {"billing": $billing, "card": $card, "comment": $comment, "custom": $custom, "language": $language, "token": $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete profile
#
# DELETE /profiles/{profileId}
export def "profiles delete" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: float, customer_code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({profile_id: $profile_id} | format pattern "/profiles/{profile_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get profile
#
# GET /profiles/{profileId}
export def "profiles get" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_ref: string, billing: record<address_line1: string, address_line2: string, city: string, country: string, email_address: string, name: string, phone_number: string, postal_code: string, province: string>, card: record<card_type: string, expiry_month: string, expiry_year: string, name: string, number: string>, code: int, custom: record<ref1: string, ref2: string, ref3: string, ref4: string, ref5: string>, customer_code: string, language: string, last_transaction: string, message: string, modified_date: string, profile_group: string, status: string, velocity_group: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({profile_id: $profile_id} | format pattern "/profiles/{profile_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Profile
#
# PUT /profiles/{profileId}
# --billing shape: {address_line1?: string, address_line2?: string, city?: string, country?: string, email_address?: string, name?: string, phone_number?: string, postal_code?: string, province?: string}
# --card shape: {code?: string, name?: string}
# --custom shape: {ref1?: string, ref2?: string, ref3?: string, ref4?: string, ref5?: string}
export def "profiles put" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing: any # shape: {address_line1?: string, address_line2?: string, city?: string, country?: string, email_address?: string, name?: string, phone_number?: string, postal_code?: string, province?: string}
  --card: any # shape: {code?: string, name?: string}
  --comment: string # alphanumeric(256)
  --custom: any # shape: {ref1?: string, ref2?: string, ref3?: string, ref4?: string, ref5?: string}
  --language: string # characters(2)
]: any -> record<code: float, customer_code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({profile_id: $profile_id} | format pattern "/profiles/{profile_id}"))
  let body = {"billing": $billing, "card": $card, "comment": $comment, "custom": $custom, "language": $language} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get cards
#
# GET /profiles/{profileId}/cards
export def "profiles-cards get" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<card: table<card_id: string, card_type: string, expiry_month: string, expiry_year: string, function: string, number: string>, code: float, customer_code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({profile_id: $profile_id} | format pattern "/profiles/{profile_id}/cards"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add card
#
# POST /profiles/{profileId}/cards
export def "profiles-cards post" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiry-month: string # digits(2)
  --expiry-year: string # digits(2)
  --name: string # cardholder name. alphanumeric(64)
  --number: string # Credit card number. digits(20)
]: any -> record<code: float, customer_code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({profile_id: $profile_id} | format pattern "/profiles/{profile_id}/cards"))
  let body = {"expiry_month": $expiry_month, "expiry_year": $expiry_year, "name": $name, "number": $number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete card
#
# DELETE /profiles/{profileId}/cards/{cardId}
export def "profiles-cards delete" [
  profile_id: string
  card_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: float, customer_code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({profile_id: $profile_id, card_id: $card_id} | format pattern "/profiles/{profile_id}/cards/{card_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update card
#
# PUT /profiles/{profileId}/cards/{cardId}
export def "profiles-cards put" [
  profile_id: string
  card_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiry-month: string # digits(2)
  --expiry-year: string # digits(2)
  --name: string # cardholder name. alphanumeric(64)
  --number: string # Credit card number. digits(20)
]: any -> record<code: float, customer_code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({profile_id: $profile_id, card_id: $card_id} | format pattern "/profiles/{profile_id}/cards/{card_id}"))
  let body = {"expiry_month": $expiry_month, "expiry_year": $expiry_year, "name": $name, "number": $number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search Query
#
# POST /reports
# --criteria item shape: {field?: float, operator?: string, value?: string}
export def "reports post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --criteria: list # Optional search criteria. All criteria are ANDed together. — item shape: {field?: float, operator?: string, value?: string}
  end_date: string # The end date (inclusive) '2015-04-22T10:03:19' in the timezone of your merchant account.
  end_row: float # Used to page the results. 1-based. This should always be 1 larger than start_row. (format: integer, default: 2)
  name: string # Only accepts 2 values. Can be either 'Search' for all fields or 'TransHistoryMinimal' for a subset of the fields returned in the results.
  start_date: string # The start date (inclusive) '2015-04-22T10:03:19' in the timezone of your merchant account.
  start_row: float # Used to page the results. 1-based (format: integer, default: 1)
]: any -> record<records: table<b_address1: string, b_address2: string, b_city: string, b_country: string, b_email: string, b_name: string, b_phone: string, b_postal: string, b_province: string, customer_code: string, message_id: float, message_text: string, product_id: string, product_name: string, ref1: string, ref2: string, ref3: string, ref4: string, ref5: string, row_id: float, s_address1: string, s_address2: string, s_city: string, s_country: string, s_email: string, s_name: string, s_phone: string, s_postal: string, s_province: string, trn_amount: float, trn_approval_code: string, trn_avs_result: string, trn_batch_no: float, trn_card_expiry: string, trn_card_owner: string, trn_card_type: string, trn_completions: float, trn_cvd_result: float, trn_date_time: string, trn_id: float, trn_ip: string, trn_masked_card: string, trn_order_number: string, trn_payment_method: string, trn_reference: float, trn_response: float, trn_returns: float, trn_type: string, trn_voided: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports")
  let body = {"criteria": $criteria, "end_date": $end_date, "end_row": $end_row, "name": $name, "start_date": $start_date, "start_row": $start_row} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Tokenize credit card
#
# POST /scripts/tokenization/tokens
export def "scripts-tokenization-tokens post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  cvd: string # a 3 to 4 digit representation of CVD/CDD. This is the number usually found on the back of the credit card.
  expiry_month: string # a 2 digit representation of the expiry month. For example March is 03.
  expiry_year: string # a 2 digit representation of the expiry year. For example 2016 is 16.
  number: string # The credit card number
]: any -> record<code: string, message: string, token: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scripts/tokenization/tokens")
  let body = {"cvd": $cvd, "expiry_month": $expiry_month, "expiry_year": $expiry_year, "number": $number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
