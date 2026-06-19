# Auto-generated client for Beanstream Payments v1.0.1
# Source: https://api.apis.guru/v2/specs/beanstream.com/1.0.1/swagger.json
# Auth: --token flag or $env.BEANSTREAM_PAYMENTS_TOKEN

const BASE_URL = "https://www.beanstream.com/api/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BEANSTREAM_PAYMENTS_TOKEN | default "" }
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

def base-url-completer [] { ["https://www.beanstream.com/api/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "payments create" } } | get name | first)
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
export def "payments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"amount": $amount, "billing": $billing, "card": $card, "comments": $comments, "custom": $custom, "customer_ip": $customer_ip, "language": $language, "order_number": $order_number, "payment_method": $payment_method, "payment_profile": $payment_profile, "shipping": $shipping, "term_url": $term_url, "token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<adjusted_by: table<amount: float, approval: float, created: string, id: float, message: string, type: string, url: string>, amount: float, approved: bool, auth_code: string, batch_number: string, billing: record<address_line1: string, address_line2: string, city: string, country: string, email_address: string, name: string, phone_number: string, postal_code: string, province: string>, card: record<address_match: int, avs_result: string, card_type: string, cvd_match: int, expiry_month: string, expiry_year: string, last_four: string>, comments: string, created: string, custom: record<ref1: string, ref2: string, ref3: string, ref4: string, ref5: string>, id: float, links: table<href: string, method: string, ref: string>, message: string, message_id: float, order_number: string, payment_method: string, shipping: record<address_line1: string, address_line2: string, city: string, country: string, email_address: string, name: string, phone_number: string, postal_code: string, province: string>, total_completions: float, total_refunds: float, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($trans_id | is-empty) { error make --unspanned { msg: "path parameter 'transId' must be non-empty" } }
  let full_url = (build-url $base ({trans_id: (encode-path-segment $trans_id)} | format pattern "/payments/{trans_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
export def "payments-completions create" [
  trans_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($trans_id | is-empty) { error make --unspanned { msg: "path parameter 'transId' must be non-empty" } }
  let full_url = (build-url $base ({trans_id: (encode-path-segment $trans_id)} | format pattern "/payments/{trans_id}/completions"))
  let req_body = {"amount": $amount, "billing": $billing, "card": $card, "comments": $comments, "custom": $custom, "customer_ip": $customer_ip, "language": $language, "order_number": $order_number, "payment_method": $payment_method, "payment_profile": $payment_profile, "shipping": $shipping, "term_url": $term_url, "token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Return payment
#
# POST /payments/{transId}/returns
export def "payments-returns create" [
  trans_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # The amount of the transaction to return. Must be less than or equal to the original purchase amount. (format: double)
  --order-number: string # alphanumeric (30)
]: any -> record<approved: int, auth_code: string, card: record<address_match: int, card_type: string, cvd_match: int, last_four: string, postal_result: int>, created: string, id: string, links: table<href: string, method: string, ref: string>, message: string, message_id: string, order_number: string, payment_method: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($trans_id | is-empty) { error make --unspanned { msg: "path parameter 'transId' must be non-empty" } }
  let full_url = (build-url $base ({trans_id: (encode-path-segment $trans_id)} | format pattern "/payments/{trans_id}/returns"))
  let req_body = {"amount": $amount, "order_number": $order_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Void Transaction
#
# POST /payments/{transId}/void
export def "payments-void create" [
  trans_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # The amount of the transaction to void. Must be equal to the original purchase amount. You can void purchases as well as pre-auths and returns. The amount you are voiding has to match the amount of that transaction. (format: double)
]: any -> record<approved: int, auth_code: string, card: record<address_match: int, card_type: string, cvd_match: int, last_four: string, postal_result: int>, created: string, id: string, links: table<href: string, method: string, ref: string>, message: string, message_id: string, order_number: string, payment_method: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($trans_id | is-empty) { error make --unspanned { msg: "path parameter 'transId' must be non-empty" } }
  let full_url = (build-url $base ({trans_id: (encode-path-segment $trans_id)} | format pattern "/payments/{trans_id}/void"))
  let req_body = {"amount": $amount} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create Profile
#
# POST /profiles
# --billing shape: {address_line1?: string, address_line2?: string, city?: string, country?: string, email_address?: string, name?: string, phone_number?: string, postal_code?: string, province?: string}
# --card shape: {cvd?: string, expiry_month: string, expiry_year: string, name: string, number: string}
# --custom shape: {ref1?: string, ref2?: string, ref3?: string, ref4?: string, ref5?: string}
# --token shape: {code: string, name: string}
export def "profiles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"billing": $billing, "card": $card, "comment": $comment, "custom": $custom, "language": $language, "token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: float, customer_code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id)} | format pattern "/profiles/{profile_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_ref: string, billing: record<address_line1: string, address_line2: string, city: string, country: string, email_address: string, name: string, phone_number: string, postal_code: string, province: string>, card: record<card_type: string, expiry_month: string, expiry_year: string, name: string, number: string>, code: int, custom: record<ref1: string, ref2: string, ref3: string, ref4: string, ref5: string>, customer_code: string, language: string, last_transaction: string, message: string, modified_date: string, profile_group: string, status: string, velocity_group: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id)} | format pattern "/profiles/{profile_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Profile
#
# PUT /profiles/{profileId}
# --billing shape: {address_line1?: string, address_line2?: string, city?: string, country?: string, email_address?: string, name?: string, phone_number?: string, postal_code?: string, province?: string}
# --card shape: {code?: string, name?: string}
# --custom shape: {ref1?: string, ref2?: string, ref3?: string, ref4?: string, ref5?: string}
export def "profiles update" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id)} | format pattern "/profiles/{profile_id}"))
  let req_body = {"billing": $billing, "card": $card, "comment": $comment, "custom": $custom, "language": $language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<card: table<card_id: string, card_type: string, expiry_month: string, expiry_year: string, function: string, number: string>, code: float, customer_code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id)} | format pattern "/profiles/{profile_id}/cards"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add card
#
# POST /profiles/{profileId}/cards
export def "profiles-cards create" [
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiry-month: string # digits(2)
  --expiry-year: string # digits(2)
  --name: string # cardholder name. alphanumeric(64)
  --number: string # Credit card number. digits(20)
]: any -> record<code: float, customer_code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id)} | format pattern "/profiles/{profile_id}/cards"))
  let req_body = {"expiry_month": $expiry_month, "expiry_year": $expiry_year, "name": $name, "number": $number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: float, customer_code: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  if ($card_id | is-empty) { error make --unspanned { msg: "path parameter 'cardId' must be non-empty" } }
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id), card_id: (encode-path-segment $card_id)} | format pattern "/profiles/{profile_id}/cards/{card_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update card
#
# PUT /profiles/{profileId}/cards/{cardId}
export def "profiles-cards update" [
  profile_id: string
  card_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiry-month: string # digits(2)
  --expiry-year: string # digits(2)
  --name: string # cardholder name. alphanumeric(64)
  --number: string # Credit card number. digits(20)
]: any -> record<code: float, customer_code: string, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($profile_id | is-empty) { error make --unspanned { msg: "path parameter 'profileId' must be non-empty" } }
  if ($card_id | is-empty) { error make --unspanned { msg: "path parameter 'cardId' must be non-empty" } }
  let full_url = (build-url $base ({profile_id: (encode-path-segment $profile_id), card_id: (encode-path-segment $card_id)} | format pattern "/profiles/{profile_id}/cards/{card_id}"))
  let req_body = {"expiry_month": $expiry_month, "expiry_year": $expiry_year, "name": $name, "number": $number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Search Query
#
# POST /reports
# --criteria item shape: {field?: float, operator?: string, value?: string}
export def "reports create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"criteria": $criteria, "end_date": $end_date, "end_row": $end_row, "name": $name, "start_date": $start_date, "start_row": $start_row} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Tokenize credit card
#
# POST /scripts/tokenization/tokens
export def "scripts-tokenization-tokens create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"cvd": $cvd, "expiry_month": $expiry_month, "expiry_year": $expiry_year, "number": $number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
