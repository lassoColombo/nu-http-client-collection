# Auto-generated client for Billingo API v3 v3.0.7
# Source: https://api.apis.guru/v2/specs/billingo.hu/3.0.7/openapi.json
# Auth: --token flag or $env.BILLINGO_API_V3_TOKEN

const BASE_URL = "https://api.billingo.hu/v3"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BILLINGO_API_V3_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-api-key" => { {scheme: $scheme, headers: {X-API-KEY: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.billingo.hu/v3"] }
def auth-scheme-completer [] { ["x-api-key"] }

# Completers for enum parameters
def currency-completer [] { ["AUD" "BGN" "BRL" "CAD" "CHF" "CNY" "CZK" "DKK" "EUR" "GBP" "HKD" "HRK" "HUF" "IDR" "ILS" "INR" "ISK" "JPY" "KRW" "LTL" "LVL" "MXN" "MYR" "NOK" "NZD" "PHP" "PLN" "RON" "RSD" "RUB" "SEK" "SGD" "THB" "TRY" "UAH" "USD" "ZAR"] }
def from-completer [] { ["AUD" "BGN" "BRL" "CAD" "CHF" "CNY" "CZK" "DKK" "EUR" "GBP" "HKD" "HRK" "HUF" "IDR" "ILS" "INR" "ISK" "JPY" "KRW" "LTL" "LVL" "MXN" "MYR" "NOK" "NZD" "PHP" "PLN" "RON" "RSD" "RUB" "SEK" "SGD" "THB" "TRY" "UAH" "USD" "ZAR"] }
def to-completer [] { ["AUD" "BGN" "BRL" "CAD" "CHF" "CNY" "CZK" "DKK" "EUR" "GBP" "HKD" "HRK" "HUF" "IDR" "ILS" "INR" "ISK" "JPY" "KRW" "LTL" "LVL" "MXN" "MYR" "NOK" "NZD" "PHP" "PLN" "RON" "RSD" "RUB" "SEK" "SGD" "THB" "TRY" "UAH" "USD" "ZAR"] }
def payment-method-completer [] { ["aruhitel" "bankcard" "barion" "barter" "cash" "cash_on_delivery" "coupon" "elore_utalas" "ep_kartya" "kompenzacio" "levonas" "online_bankcard" "payoneer" "paypal" "paypal_utolag" "payu" "pick_pack_pont" "postai_csekk" "postautalvany" "skrill" "szep_card" "transferwise" "upwork" "utalvany" "valto" "wire_transfer"] }
def payment-status-completer [] { ["expired" "none" "outstanding" "paid" "partially_paid"] }
def language-completer [] { ["de" "en" "fr" "hr" "hu" "it" "ro" "sk"] }
def type-completer [] { ["advance" "draft" "invoice" "proforma"] }
def accept-completer [] { ["application/json" "application/pdf"] }
def vat-completer [] { ["0%" "1%" "10%" "11%" "12%" "13%" "14%" "15%" "16%" "17%" "18%" "19%" "2%" "20%" "21%" "22%" "23%" "24%" "25%" "26%" "27%" "3%" "4%" "5%" "6%" "7%" "8%" "9%" "AAM" "AM" "EU" "EUK" "F.AFA" "FAD" "K.AFA" "MAA" "TAM" "ÁKK" "ÁTHK"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bank-accounts list" } } | get name | first)
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

# List all bank account
#
# GET /bank-accounts
# operationId: ListBankAccount
export def "bank-accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # default: 1
  --per-page: int # default: 25
]: nothing -> record<current_page: int, data: table<account_number: string, account_number_iban: string, currency: string, id: int, name: string, need_qr: bool, swift: string>, last_page: int, next_page_url: string, per_page: int, prev_page_url: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bank-accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Create a bank account
#
# POST /bank-accounts
# operationId: CreateBankAccount
export def "bank-accounts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_number: string
  --account-number-iban: string
  currency: string@currency-completer
  name: string
  --need-qr: oneof<nothing, bool> # default: false
  --swift: string
]: any -> record<account_number: string, account_number_iban: string, currency: string, id: int, name: string, need_qr: bool, swift: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank-accounts")
  let req_body = {"account_number": $account_number, "account_number_iban": $account_number_iban, "currency": $currency, "name": $name, "need_qr": $need_qr, "swift": $swift} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a bank account
#
# DELETE /bank-accounts/{id}
# operationId: DeleteBankAccount
export def "bank-accounts delete" [
  id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bank-accounts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a bank account
#
# GET /bank-accounts/{id}
# operationId: GetBankAccount
export def "bank-accounts get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_number: string, account_number_iban: string, currency: string, id: int, name: string, need_qr: bool, swift: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bank-accounts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a bank account
#
# PUT /bank-accounts/{id}
# operationId: UpdateBankAccount
export def "bank-accounts update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_number: string
  --account-number-iban: string
  currency: string@currency-completer
  name: string
  --need-qr: oneof<nothing, bool> # default: false
  --swift: string
]: any -> record<account_number: string, account_number_iban: string, currency: string, id: int, name: string, need_qr: bool, swift: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/bank-accounts/{id}"))
  let req_body = {"account_number": $account_number, "account_number_iban": $account_number_iban, "currency": $currency, "name": $name, "need_qr": $need_qr, "swift": $swift} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get currencies exchange rate.
#
# GET /currencies
# operationId: GetConversionRate
export def "currencies get-conversion-rate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string@from-completer
  --qp-to: string@to-completer
]: nothing -> record<conversation_rate: float, from_currency: string, to_currency: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/currencies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"from": $qp_from, "to": $qp_to} | compact), body: null}
}

# List all document blocks
#
# GET /document-blocks
# operationId: ListDocumentBlock
export def "document-blocks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # default: 1
  --per-page: int # default: 25
]: nothing -> record<current_page: int, data: table<custom_field1: string, custom_field2: string, id: int, name: string, prefix: string>, last_page: int, next_page_url: string, per_page: int, prev_page_url: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/document-blocks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# List all documents
#
# GET /documents
# operationId: ListDocument
export def "documents list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # default: 1
  --per-page: int # default: 25
  --block-id: int # Filter documents by the identifier of your DocumentBlock.
  --partner-id: int # Filter documents by the identifier of your Partner.
  --payment-method: string@payment-method-completer # Filter documents by PaymentMethod value. (e.g. cash)
  --payment-status: string@payment-status-completer # Filter documents by PaymentStatus value. (e.g. paid)
  --start-date: string # Filter documents by date. (format: date, e.g. 2020-05-15)
  --end-date: string # Filter documents by date. (format: date, e.g. 2020-05-15)
  --start-number: int # Starting number of the document, should not contain year or any other formatting. Required if `start_year` given (e.g. 1)
  --end-number: int # Ending number of the document, should not contain year or any other formatting. Required if `end_year` given (e.g. 10)
  --start-year: int # Year for `start_number` parameter. Required if `start_number` given. (e.g. 2020)
  --end-year: int # Year for `end_number` parameter. Required if `end_number` given. (e.g. 2020)
]: nothing -> record<current_page: int, data: table<block_id: int, cancelled: bool, comment: string, conversion_rate: float, currency: string, due_date: string, electronic: bool, fulfillment_date: string, gross_total: float, id: int, invoice_date: string, invoice_number: string, items: list, language: string, notification_status: string, organization: record, paid_date: string, partner: record, payment_method: string, payment_status: string, settings: record, summary: record, tags: list, type: string>, last_page: int, next_page_url: string, per_page: int, prev_page_url: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "block_id" $block_id "scalar") (serialize-qp "partner_id" $partner_id "scalar") (serialize-qp "payment_method" $payment_method "scalar") (serialize-qp "payment_status" $payment_status "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "start_number" $start_number "scalar") (serialize-qp "end_number" $end_number "scalar") (serialize-qp "start_year" $start_year "scalar") (serialize-qp "end_year" $end_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page, "block_id": $block_id, "partner_id": $partner_id, "payment_method": $payment_method, "payment_status": $payment_status, "start_date": $start_date, "end_date": $end_date, "start_number": $start_number, "end_number": $end_number, "start_year": $start_year, "end_year": $end_year} | compact), body: null}
}

# Create a document
#
# POST /documents
# operationId: CreateDocument
# --settings shape: {mediated_service?: bool, online_payment?: ""|"Barion"|"SimplePay"|"no", place_id?: int, round?: "five"|"none"|"one"|"ten", without_financial_fulfillment?: bool}
export def "documents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bank-account-id: int
  block_id: int
  --comment: string
  --conversion-rate: float # format: float, default: 1
  currency: string@currency-completer
  due_date: string # format: date
  --electronic: oneof<nothing, bool> # default: false
  fulfillment_date: string # format: date
  --items: list
  language: string@language-completer
  --paid: oneof<nothing, bool> # default: false
  partner_id: int
  payment_method: string@payment-method-completer
  --settings: record # shape: {mediated_service?: bool, online_payment?: ""|"Barion"|"SimplePay"|"no", place_id?: int, round?: "five"|"none"|"one"|"ten", without_financial_fulfillment?: bool}
  type: string@type-completer
  --vendor-id: string
]: any -> record<block_id: int, cancelled: bool, comment: string, conversion_rate: float, currency: string, due_date: string, electronic: bool, fulfillment_date: string, gross_total: float, id: int, invoice_date: string, invoice_number: string, items: table<gross_amount: float, name: string, net_amount: float, net_unit_amount: float, product_id: int, quantity: float, vat: string, vat_amount: float>, language: string, notification_status: string, organization: record<address: record<address: string, city: string, country_code: string, post_code: string>, bank_account: record<account_number: string, account_number_iban: string, id: int, name: string, swift: string>, cash_settled: bool, eu_tax_number: string, ev_number: string, name: string, small_taxpayer: bool, tax_number: string>, paid_date: string, partner: record<account_number: string, address: record<address: string, city: string, country_code: string, post_code: string>, emails: list<string>, general_ledger_number: string, iban: string, name: string, phone: string, swift: string, taxcode: string, id: int>, payment_method: string, payment_status: string, settings: record<mediated_service: bool, online_payment: string, place_id: int, round: string, without_financial_fulfillment: bool>, summary: record<gross_amount_local: float, net_amount: float, net_amount_local: float, vat_amount: float, vat_amount_local: float, vat_rate_summary: list<record>>, tags: list<string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/documents")
  let req_body = {"bank_account_id": $bank_account_id, "block_id": $block_id, "comment": $comment, "conversion_rate": $conversion_rate, "currency": $currency, "due_date": $due_date, "electronic": $electronic, "fulfillment_date": $fulfillment_date, "items": $items, "language": $language, "paid": $paid, "partner_id": $partner_id, "payment_method": $payment_method, "settings": $settings, "type": $type, "vendor_id": $vendor_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a document
#
# GET /documents/{id}
# operationId: GetDocument
export def "documents get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<block_id: int, cancelled: bool, comment: string, conversion_rate: float, currency: string, due_date: string, electronic: bool, fulfillment_date: string, gross_total: float, id: int, invoice_date: string, invoice_number: string, items: table<gross_amount: float, name: string, net_amount: float, net_unit_amount: float, product_id: int, quantity: float, vat: string, vat_amount: float>, language: string, notification_status: string, organization: record<address: record<address: string, city: string, country_code: string, post_code: string>, bank_account: record<account_number: string, account_number_iban: string, id: int, name: string, swift: string>, cash_settled: bool, eu_tax_number: string, ev_number: string, name: string, small_taxpayer: bool, tax_number: string>, paid_date: string, partner: record<account_number: string, address: record<address: string, city: string, country_code: string, post_code: string>, emails: list<string>, general_ledger_number: string, iban: string, name: string, phone: string, swift: string, taxcode: string, id: int>, payment_method: string, payment_status: string, settings: record<mediated_service: bool, online_payment: string, place_id: int, round: string, without_financial_fulfillment: bool>, summary: record<gross_amount_local: float, net_amount: float, net_amount_local: float, vat_amount: float, vat_amount_local: float, vat_rate_summary: list<record>>, tags: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/documents/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Cancel a document
#
# POST /documents/{id}/cancel
# operationId: CancelDocument
export def "documents-cancel cancel" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<block_id: int, cancelled: bool, comment: string, conversion_rate: float, currency: string, due_date: string, electronic: bool, fulfillment_date: string, gross_total: float, id: int, invoice_date: string, invoice_number: string, items: table<gross_amount: float, name: string, net_amount: float, net_unit_amount: float, product_id: int, quantity: float, vat: string, vat_amount: float>, language: string, notification_status: string, organization: record<address: record<address: string, city: string, country_code: string, post_code: string>, bank_account: record<account_number: string, account_number_iban: string, id: int, name: string, swift: string>, cash_settled: bool, eu_tax_number: string, ev_number: string, name: string, small_taxpayer: bool, tax_number: string>, paid_date: string, partner: record<account_number: string, address: record<address: string, city: string, country_code: string, post_code: string>, emails: list<string>, general_ledger_number: string, iban: string, name: string, phone: string, swift: string, taxcode: string, id: int>, payment_method: string, payment_status: string, settings: record<mediated_service: bool, online_payment: string, place_id: int, round: string, without_financial_fulfillment: bool>, summary: record<gross_amount_local: float, net_amount: float, net_amount_local: float, vat_amount: float, vat_amount_local: float, vat_rate_summary: list<record>>, tags: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/documents/{id}/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a document from proforma.
#
# POST /documents/{id}/create-from-proforma
# operationId: CreateDocumentFromProforma
export def "documents-create-from-proforma create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<block_id: int, cancelled: bool, comment: string, conversion_rate: float, currency: string, due_date: string, electronic: bool, fulfillment_date: string, gross_total: float, id: int, invoice_date: string, invoice_number: string, items: table<gross_amount: float, name: string, net_amount: float, net_unit_amount: float, product_id: int, quantity: float, vat: string, vat_amount: float>, language: string, notification_status: string, organization: record<address: record<address: string, city: string, country_code: string, post_code: string>, bank_account: record<account_number: string, account_number_iban: string, id: int, name: string, swift: string>, cash_settled: bool, eu_tax_number: string, ev_number: string, name: string, small_taxpayer: bool, tax_number: string>, paid_date: string, partner: record<account_number: string, address: record<address: string, city: string, country_code: string, post_code: string>, emails: list<string>, general_ledger_number: string, iban: string, name: string, phone: string, swift: string, taxcode: string, id: int>, payment_method: string, payment_status: string, settings: record<mediated_service: bool, online_payment: string, place_id: int, round: string, without_financial_fulfillment: bool>, summary: record<gross_amount_local: float, net_amount: float, net_amount_local: float, vat_amount: float, vat_amount_local: float, vat_rate_summary: list<record>>, tags: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/documents/{id}/create-from-proforma"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Download a document in PDF format.
#
# GET /documents/{id}/download
# operationId: DownloadDocument
export def "documents-download download" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/documents/{id}/download"))
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a document Online Számla status
#
# GET /documents/{id}/online-szamla
# operationId: GetOnlineSzamlaStatus
export def "documents-online-szamla get-status" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<messages: table<human_readable_message: string, validation_error_code: string, validation_result_code: string>, status: string, transaction_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/documents/{id}/online-szamla"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete all payment history on document
#
# DELETE /documents/{id}/payments
# operationId: DeletePayment
export def "documents-payments delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<conversion_rate: float, date: string, payment_method: string, price: float, voucher_number: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/documents/{id}/payments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a payment histroy
#
# GET /documents/{id}/payments
# operationId: GetPayment
export def "documents-payments get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<conversion_rate: float, date: string, payment_method: string, price: float, voucher_number: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/documents/{id}/payments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update payment history
#
# PUT /documents/{id}/payments
# operationId: UpdatePayment
export def "documents-payments update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> table<conversion_rate: float, date: string, payment_method: string, price: float, voucher_number: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/documents/{id}/payments"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a document download public url.
#
# GET /documents/{id}/public-url
# operationId: GetPublicUrl
export def "documents-public-url get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<public_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/documents/{id}/public-url"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Send invoice to given email adresses.
#
# POST /documents/{id}/send
# operationId: SendDocument
export def "documents-send send" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --emails: list<string>
]: any -> record<emails: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/documents/{id}/send"))
  let req_body = {"emails": $emails} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a organization data.
#
# GET /organization
# operationId: GetOrganizationData
export def "organization get-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tax_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organization")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all partners
#
# GET /partners
# operationId: ListPartner
export def "partners list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # default: 1
  --per-page: int # default: 25
]: nothing -> record<current_page: int, data: table<account_number: string, address: record, emails: list, general_ledger_number: string, iban: string, name: string, phone: string, swift: string, taxcode: string, id: int>, last_page: int, next_page_url: string, per_page: int, prev_page_url: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/partners" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Create a partner
#
# POST /partners
# operationId: CreatePartner
# --address shape: {address: string, city: string, ... (2 more fields)}
export def "partners create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-number: string
  address: record # shape: {address: string, city: string, ... (2 more fields)}
  --emails: list<string>
  --general-ledger-number: string
  --iban: string
  name: string
  --phone: string
  --swift: string
  --taxcode: string
]: any -> record<account_number: string, address: record<address: string, city: string, country_code: string, post_code: string>, emails: list<string>, general_ledger_number: string, iban: string, name: string, phone: string, swift: string, taxcode: string, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/partners")
  let req_body = {"account_number": $account_number, "address": $address, "emails": $emails, "general_ledger_number": $general_ledger_number, "iban": $iban, "name": $name, "phone": $phone, "swift": $swift, "taxcode": $taxcode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a partner
#
# DELETE /partners/{id}
# operationId: DeletePartner
export def "partners delete" [
  id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/partners/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a partner
#
# GET /partners/{id}
# operationId: GetPartner
export def "partners get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_number: string, address: record<address: string, city: string, country_code: string, post_code: string>, emails: list<string>, general_ledger_number: string, iban: string, name: string, phone: string, swift: string, taxcode: string, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/partners/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a partner
#
# PUT /partners/{id}
# operationId: UpdatePartner
# --address shape: {address: string, city: string, ... (2 more fields)}
export def "partners update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-number: string
  address: record # shape: {address: string, city: string, ... (2 more fields)}
  --emails: list<string>
  --general-ledger-number: string
  --iban: string
  name: string
  --phone: string
  --swift: string
  --taxcode: string
]: any -> record<account_number: string, address: record<address: string, city: string, country_code: string, post_code: string>, emails: list<string>, general_ledger_number: string, iban: string, name: string, phone: string, swift: string, taxcode: string, id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/partners/{id}"))
  let req_body = {"account_number": $account_number, "address": $address, "emails": $emails, "general_ledger_number": $general_ledger_number, "iban": $iban, "name": $name, "phone": $phone, "swift": $swift, "taxcode": $taxcode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List all product
#
# GET /products
# operationId: ListProduct
export def "products list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # default: 1
  --per-page: int # default: 25
]: nothing -> record<current_page: int, data: table<comment: string, currency: string, general_ledger_number: string, general_ledger_taxcode: string, id: int, name: string, net_unit_price: float, unit: string, vat: string>, last_page: int, next_page_url: string, per_page: int, prev_page_url: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/products" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Create a product
#
# POST /products
# operationId: CreateProduct
export def "products create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
  currency: string@currency-completer
  --general-ledger-number: string
  --general-ledger-taxcode: string
  name: string
  --net-unit-price: float # format: float
  unit: string
  vat: string@vat-completer
]: any -> record<comment: string, currency: string, general_ledger_number: string, general_ledger_taxcode: string, id: int, name: string, net_unit_price: float, unit: string, vat: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/products")
  let req_body = {"comment": $comment, "currency": $currency, "general_ledger_number": $general_ledger_number, "general_ledger_taxcode": $general_ledger_taxcode, "name": $name, "net_unit_price": $net_unit_price, "unit": $unit, "vat": $vat} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a product
#
# DELETE /products/{id}
# operationId: DeleteProduct
export def "products delete" [
  id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a product
#
# GET /products/{id}
# operationId: GetProduct
export def "products get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<comment: string, currency: string, general_ledger_number: string, general_ledger_taxcode: string, id: int, name: string, net_unit_price: float, unit: string, vat: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a product
#
# PUT /products/{id}
# operationId: UpdateProduct
export def "products update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string
  currency: string@currency-completer
  --general-ledger-number: string
  --general-ledger-taxcode: string
  name: string
  --net-unit-price: float # format: float
  unit: string
  vat: string@vat-completer
]: any -> record<comment: string, currency: string, general_ledger_number: string, general_ledger_taxcode: string, id: int, name: string, net_unit_price: float, unit: string, vat: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/products/{id}"))
  let req_body = {"comment": $comment, "currency": $currency, "general_ledger_number": $general_ledger_number, "general_ledger_taxcode": $general_ledger_taxcode, "name": $name, "net_unit_price": $net_unit_price, "unit": $unit, "vat": $vat} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Convert legacy ID to v3 ID.
#
# GET /utils/convert-legacy-id/{id}
# operationId: GetId
export def "utils-convert-legacy-id get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, legacy_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/utils/convert-legacy-id/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
