# Auto-generated client for GOV.UK Pay API v1.0.3
# Source: https://api.apis.guru/v2/specs/payments.service.gov.uk/payments/1.0.3/swagger.json
# Auth: --token flag or $env.GOV_UK_PAY_API_TOKEN

const BASE_URL = "https://publicapi.payments.service.gov.uk"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GOV_UK_PAY_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://publicapi.payments.service.gov.uk"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def state-completer [] { ["cancelled" "created" "error" "failed" "started" "submitted" "success"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "payments list" } } | get name | first)
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

# Search payments
#
# GET /v1/payments
# operationId: Search payments
export def "payments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reference: string # Your payment reference to search (exact match, case insensitive)
  --email: string # The user email used in the payment to be searched
  --state: string@state-completer # State of payments to be searched. Example=success
  --card-brand: string # Card brand used for payment. Example=master-card
  --from-date: string # From date of payments to be searched (this date is inclusive). Example=2015-08-13T12:35:00Z
  --to-date: string # To date of payments to be searched (this date is exclusive). Example=2015-08-14T12:35:00Z
  --page: string # Page number requested for the search, should be a positive integer (optional, defaults to 1)
  --display-size: string # Number of results to be shown per page, should be a positive integer (optional, defaults to 500, max 500)
  --cardholder-name: string # Name on card used to make payment
  --first-digits-card-number: string # First six digits of the card used to make payment
  --last-digits-card-number: string # Last four digits of the card used to make payment
  --from-settled-date: string # From settled date of payment to be searched (this date is inclusive). Example=2015-08-13
  --to-settled-date: string # To settled date of payment to be searched (this date is inclusive). Example=2015-08-14
]: nothing -> record<_links: record<first_page: record<href: string, method: string>, last_page: record<href: string, method: string>, next_page: record<href: string, method: string>, prev_page: record<href: string, method: string>, self: record<href: string, method: string>>, count: int, page: int, results: table<_links: record, amount: int, card_brand: string, card_details: record, corporate_card_surcharge: int, created_date: string, delayed_capture: bool, description: string, email: string, fee: int, language: string, metadata: record, moto: bool, net_amount: int, payment_id: string, payment_provider: string, provider_id: string, reference: string, refund_summary: record, return_url: string, settlement_summary: record, state: record, total_amount: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reference" $reference "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "card_brand" $card_brand "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "display_size" $display_size "scalar") (serialize-qp "cardholder_name" $cardholder_name "scalar") (serialize-qp "first_digits_card_number" $first_digits_card_number "scalar") (serialize-qp "last_digits_card_number" $last_digits_card_number "scalar") (serialize-qp "from_settled_date" $from_settled_date "scalar") (serialize-qp "to_settled_date" $to_settled_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"reference": $reference, "email": $email, "state": $state, "card_brand": $card_brand, "from_date": $from_date, "to_date": $to_date, "page": $page, "display_size": $display_size, "cardholder_name": $cardholder_name, "first_digits_card_number": $first_digits_card_number, "last_digits_card_number": $last_digits_card_number, "from_settled_date": $from_settled_date, "to_settled_date": $to_settled_date} | compact), body: null}
}

# Create new payment
#
# POST /v1/payments
# operationId: Create a payment
# --prefilled_cardholder_details shape: {billing_address?: record, cardholder_name?: string}
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
  --prefilled-cardholder-details: record # shape: {billing_address?: record, cardholder_name?: string}
]: any -> record<_links: record<cancel: record<href: string, method: string, params: record, type: string>, capture: record<href: string, method: string, params: record, type: string>, events: record<href: string, method: string>, next_url: record<href: string, method: string>, next_url_post: record<href: string, method: string, params: record, type: string>, refunds: record<href: string, method: string>, self: record<href: string, method: string>>, amount: int, card_details: record<billing_address: record<city: string, country: string, line1: string, line2: string, postcode: string>, card_brand: string, card_type: string, cardholder_name: string, expiry_date: string, first_digits_card_number: string, last_digits_card_number: string>, created_date: string, delayed_capture: bool, description: string, email: string, language: string, metadata: record, moto: bool, payment_id: string, payment_provider: string, provider_id: string, reference: string, refund_summary: record<amount_available: int, amount_submitted: int, status: string>, return_url: string, settlement_summary: record<capture_submit_time: string, captured_date: string, settled_date: string>, state: record<code: string, finished: bool, message: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/payments")
  let req_body = {"prefilled_cardholder_details": $prefilled_cardholder_details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Find payment by ID
#
# GET /v1/payments/{paymentId}
# operationId: Get a payment
export def "payments get" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<cancel: record<href: string, method: string, params: record, type: string>, capture: record<href: string, method: string, params: record, type: string>, events: record<href: string, method: string>, next_url: record<href: string, method: string>, next_url_post: record<href: string, method: string, params: record, type: string>, refunds: record<href: string, method: string>, self: record<href: string, method: string>>, amount: int, card_brand: string, card_details: record<billing_address: record<city: string, country: string, line1: string, line2: string, postcode: string>, card_brand: string, card_type: string, cardholder_name: string, expiry_date: string, first_digits_card_number: string, last_digits_card_number: string>, corporate_card_surcharge: int, created_date: string, delayed_capture: bool, description: string, email: string, fee: int, language: string, metadata: record, moto: bool, net_amount: int, payment_id: string, payment_provider: string, provider_id: string, reference: string, refund_summary: record<amount_available: int, amount_submitted: int, status: string>, return_url: string, settlement_summary: record<capture_submit_time: string, captured_date: string, settled_date: string>, state: record<code: string, finished: bool, message: string, status: string>, total_amount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id)} | format pattern "/v1/payments/{payment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Cancel payment
#
# POST /v1/payments/{paymentId}/cancel
# operationId: Cancel a payment
export def "payments-cancel cancel" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id)} | format pattern "/v1/payments/{payment_id}/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Capture payment
#
# POST /v1/payments/{paymentId}/capture
# operationId: Capture a payment
export def "payments-capture create" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id)} | format pattern "/v1/payments/{payment_id}/capture"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Return payment events by ID
#
# GET /v1/payments/{paymentId}/events
# operationId: Get events for a payment
export def "payments-events get" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<self: record<href: string, method: string>>, events: table<_links: record, payment_id: string, state: record, updated: string>, payment_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id)} | format pattern "/v1/payments/{payment_id}/events"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all refunds for a payment
#
# GET /v1/payments/{paymentId}/refunds
# operationId: Get all refunds for a payment
export def "payments-refunds get-list" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_embedded: record<refunds: list<record>>, _links: record<payment: record<href: string, method: string>, self: record<href: string, method: string>>, payment_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id)} | format pattern "/v1/payments/{payment_id}/refunds"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Submit a refund for a payment
#
# POST /v1/payments/{paymentId}/refunds
# operationId: Submit a refund for a payment
export def "payments-refunds submit" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: int # Amount in pence. Can't be more than the available amount for refunds (format: int32, e.g. 150000)
]: any -> record<_links: record<payment: record<href: string, method: string>, self: record<href: string, method: string>>, amount: int, created_date: string, refund_id: string, settlement_summary: record<settled_date: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id)} | format pattern "/v1/payments/{payment_id}/refunds"))
  let req_body = {"amount": $amount} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Find payment refund by ID
#
# GET /v1/payments/{paymentId}/refunds/{refundId}
# operationId: Get a payment refund
export def "payments-refunds get" [
  payment_id: string
  refund_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_links: record<payment: record<href: string, method: string>, self: record<href: string, method: string>>, amount: int, created_date: string, refund_id: string, settlement_summary: record<settled_date: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  if ($refund_id | is-empty) { error make --unspanned { msg: "path parameter 'refundId' must be non-empty" } }
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id), refund_id: (encode-path-segment $refund_id)} | format pattern "/v1/payments/{payment_id}/refunds/{refund_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Search refunds
#
# GET /v1/refunds
# operationId: Search refunds
export def "refunds list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # From date of refunds to be searched (this date is inclusive). Example=2015-08-13T12:35:00Z
  --to-date: string # To date of refunds to be searched (this date is exclusive). Example=2015-08-14T12:35:00Z
  --from-settled-date: string # From settled date of refund to be searched (this date is inclusive). Example=2015-08-13
  --to-settled-date: string # To settled date of refund to be searched (this date is inclusive). Example=2015-08-13
  --page: string # Page number requested for the search, should be a positive integer (optional, defaults to 1)
  --display-size: string # Number of results to be shown per page, should be a positive integer (optional, defaults to 500, max 500)
]: nothing -> record<_links: record<first_page: record<href: string, method: string>, last_page: record<href: string, method: string>, next_page: record<href: string, method: string>, prev_page: record<href: string, method: string>, self: record<href: string, method: string>>, count: int, page: int, results: table<_links: record, amount: int, created_date: string, refund_id: string, settlement_summary: record, status: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "from_settled_date" $from_settled_date "scalar") (serialize-qp "to_settled_date" $to_settled_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "display_size" $display_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/refunds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"from_date": $from_date, "to_date": $to_date, "from_settled_date": $from_settled_date, "to_settled_date": $to_settled_date, "page": $page, "display_size": $display_size} | compact), body: null}
}
