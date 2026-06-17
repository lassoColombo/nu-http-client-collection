# Auto-generated client for Billingo API v3 v3.0.7
# Source: https://api.apis.guru/v2/specs/billingo.hu/3.0.7/openapi.json
# Auth: --token flag or $env.BILLINGO_API_V3_TOKEN

const BASE_URL = "https://api.billingo.hu/v3"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BILLINGO_API_V3_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {X-API-KEY: $token_val}, query: ""} }
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
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let body = {"account_number": $account_number, "account_number_iban": $account_number_iban, "currency": $currency, "name": $name, "need_qr": $need_qr, "swift": $swift} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/bank-accounts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_number: string, account_number_iban: string, currency: string, id: int, name: string, need_qr: bool, swift: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/bank-accounts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base ({id: $id} | format pattern "/bank-accounts/{id}"))
  let body = {"account_number": $account_number, "account_number_iban": $account_number_iban, "currency": $currency, "name": $name, "need_qr": $need_qr, "swift": $swift} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let body = {"bank_account_id": $bank_account_id, "block_id": $block_id, "comment": $comment, "conversion_rate": $conversion_rate, "currency": $currency, "due_date": $due_date, "electronic": $electronic, "fulfillment_date": $fulfillment_date, "items": $items, "language": $language, "paid": $paid, "partner_id": $partner_id, "payment_method": $payment_method, "settings": $settings, "type": $type, "vendor_id": $vendor_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<block_id: int, cancelled: bool, comment: string, conversion_rate: float, currency: string, due_date: string, electronic: bool, fulfillment_date: string, gross_total: float, id: int, invoice_date: string, invoice_number: string, items: table<gross_amount: float, name: string, net_amount: float, net_unit_amount: float, product_id: int, quantity: float, vat: string, vat_amount: float>, language: string, notification_status: string, organization: record<address: record<address: string, city: string, country_code: string, post_code: string>, bank_account: record<account_number: string, account_number_iban: string, id: int, name: string, swift: string>, cash_settled: bool, eu_tax_number: string, ev_number: string, name: string, small_taxpayer: bool, tax_number: string>, paid_date: string, partner: record<account_number: string, address: record<address: string, city: string, country_code: string, post_code: string>, emails: list<string>, general_ledger_number: string, iban: string, name: string, phone: string, swift: string, taxcode: string, id: int>, payment_method: string, payment_status: string, settings: record<mediated_service: bool, online_payment: string, place_id: int, round: string, without_financial_fulfillment: bool>, summary: record<gross_amount_local: float, net_amount: float, net_amount_local: float, vat_amount: float, vat_amount_local: float, vat_rate_summary: list<record>>, tags: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/documents/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<block_id: int, cancelled: bool, comment: string, conversion_rate: float, currency: string, due_date: string, electronic: bool, fulfillment_date: string, gross_total: float, id: int, invoice_date: string, invoice_number: string, items: table<gross_amount: float, name: string, net_amount: float, net_unit_amount: float, product_id: int, quantity: float, vat: string, vat_amount: float>, language: string, notification_status: string, organization: record<address: record<address: string, city: string, country_code: string, post_code: string>, bank_account: record<account_number: string, account_number_iban: string, id: int, name: string, swift: string>, cash_settled: bool, eu_tax_number: string, ev_number: string, name: string, small_taxpayer: bool, tax_number: string>, paid_date: string, partner: record<account_number: string, address: record<address: string, city: string, country_code: string, post_code: string>, emails: list<string>, general_ledger_number: string, iban: string, name: string, phone: string, swift: string, taxcode: string, id: int>, payment_method: string, payment_status: string, settings: record<mediated_service: bool, online_payment: string, place_id: int, round: string, without_financial_fulfillment: bool>, summary: record<gross_amount_local: float, net_amount: float, net_amount_local: float, vat_amount: float, vat_amount_local: float, vat_rate_summary: list<record>>, tags: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/documents/{id}/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<block_id: int, cancelled: bool, comment: string, conversion_rate: float, currency: string, due_date: string, electronic: bool, fulfillment_date: string, gross_total: float, id: int, invoice_date: string, invoice_number: string, items: table<gross_amount: float, name: string, net_amount: float, net_unit_amount: float, product_id: int, quantity: float, vat: string, vat_amount: float>, language: string, notification_status: string, organization: record<address: record<address: string, city: string, country_code: string, post_code: string>, bank_account: record<account_number: string, account_number_iban: string, id: int, name: string, swift: string>, cash_settled: bool, eu_tax_number: string, ev_number: string, name: string, small_taxpayer: bool, tax_number: string>, paid_date: string, partner: record<account_number: string, address: record<address: string, city: string, country_code: string, post_code: string>, emails: list<string>, general_ledger_number: string, iban: string, name: string, phone: string, swift: string, taxcode: string, id: int>, payment_method: string, payment_status: string, settings: record<mediated_service: bool, online_payment: string, place_id: int, round: string, without_financial_fulfillment: bool>, summary: record<gross_amount_local: float, net_amount: float, net_amount_local: float, vat_amount: float, vat_amount_local: float, vat_rate_summary: list<record>>, tags: list<string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/documents/{id}/create-from-proforma"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/documents/{id}/download"))
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a document Online Számla status
#
# GET /documents/{id}/online-szamla
# operationId: GetOnlineSzamlaStatus
export def "documents-online-szamla get-online-szamla-status" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<messages: table<human_readable_message: string, validation_error_code: string, validation_result_code: string>, status: string, transaction_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/documents/{id}/online-szamla"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<conversion_rate: float, date: string, payment_method: string, price: float, voucher_number: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/documents/{id}/payments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<conversion_rate: float, date: string, payment_method: string, price: float, voucher_number: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/documents/{id}/payments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<conversion_rate: float, date: string, payment_method: string, price: float, voucher_number: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/documents/{id}/payments"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<public_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/documents/{id}/public-url"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --emails: list
]: any -> record<emails: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/documents/{id}/send"))
  let body = {"emails": $emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a organization data.
#
# GET /organization
# operationId: GetOrganizationData
export def "organization get-organization-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<tax_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organization")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a partner
#
# POST /partners
# operationId: CreatePartner
# --address shape: {address: string, city: string, country_code: ""|"AC"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DG"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EA"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HN"|"HR"|"HT"|"HU"|"IC"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TA"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"XA"|"XB"|"XK"|"YE"|"YT"|"ZA"|"ZM"|"ZW", post_code: string}
export def "partners create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-number: string
  address: record # shape: {address: string, city: string, country_code: ""|"AC"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DG"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EA"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HN"|"HR"|"HT"|"HU"|"IC"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TA"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"XA"|"XB"|"XK"|"YE"|"YT"|"ZA"|"ZM"|"ZW", post_code: string}
  --emails: list
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
  let body = {"account_number": $account_number, "address": $address, "emails": $emails, "general_ledger_number": $general_ledger_number, "iban": $iban, "name": $name, "phone": $phone, "swift": $swift, "taxcode": $taxcode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/partners/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_number: string, address: record<address: string, city: string, country_code: string, post_code: string>, emails: list<string>, general_ledger_number: string, iban: string, name: string, phone: string, swift: string, taxcode: string, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/partners/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a partner
#
# PUT /partners/{id}
# operationId: UpdatePartner
# --address shape: {address: string, city: string, country_code: ""|"AC"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DG"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EA"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HN"|"HR"|"HT"|"HU"|"IC"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TA"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"XA"|"XB"|"XK"|"YE"|"YT"|"ZA"|"ZM"|"ZW", post_code: string}
export def "partners update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-number: string
  address: record # shape: {address: string, city: string, country_code: ""|"AC"|"AD"|"AE"|"AF"|"AG"|"AI"|"AL"|"AM"|"AO"|"AQ"|"AR"|"AS"|"AT"|"AU"|"AW"|"AX"|"AZ"|"BA"|"BB"|"BD"|"BE"|"BF"|"BG"|"BH"|"BI"|"BJ"|"BL"|"BM"|"BN"|"BO"|"BQ"|"BR"|"BS"|"BT"|"BW"|"BY"|"BZ"|"CA"|"CC"|"CD"|"CF"|"CG"|"CH"|"CI"|"CK"|"CL"|"CM"|"CN"|"CO"|"CR"|"CU"|"CV"|"CW"|"CX"|"CY"|"CZ"|"DE"|"DG"|"DJ"|"DK"|"DM"|"DO"|"DZ"|"EA"|"EC"|"EE"|"EG"|"EH"|"ER"|"ES"|"ET"|"FI"|"FJ"|"FK"|"FM"|"FO"|"FR"|"GA"|"GB"|"GD"|"GE"|"GF"|"GG"|"GH"|"GI"|"GL"|"GM"|"GN"|"GP"|"GQ"|"GR"|"GS"|"GT"|"GU"|"GW"|"GY"|"HK"|"HN"|"HR"|"HT"|"HU"|"IC"|"ID"|"IE"|"IL"|"IM"|"IN"|"IO"|"IQ"|"IR"|"IS"|"IT"|"JE"|"JM"|"JO"|"JP"|"KE"|"KG"|"KH"|"KI"|"KM"|"KN"|"KP"|"KR"|"KW"|"KY"|"KZ"|"LA"|"LB"|"LC"|"LI"|"LK"|"LR"|"LS"|"LT"|"LU"|"LV"|"LY"|"MA"|"MC"|"MD"|"ME"|"MF"|"MG"|"MH"|"MK"|"ML"|"MM"|"MN"|"MO"|"MP"|"MQ"|"MR"|"MS"|"MT"|"MU"|"MV"|"MW"|"MX"|"MY"|"MZ"|"NA"|"NC"|"NE"|"NF"|"NG"|"NI"|"NL"|"NO"|"NP"|"NR"|"NU"|"NZ"|"OM"|"PA"|"PE"|"PF"|"PG"|"PH"|"PK"|"PL"|"PM"|"PN"|"PR"|"PS"|"PT"|"PW"|"PY"|"QA"|"RE"|"RO"|"RS"|"RU"|"RW"|"SA"|"SB"|"SC"|"SD"|"SE"|"SG"|"SH"|"SI"|"SJ"|"SK"|"SL"|"SM"|"SN"|"SO"|"SR"|"SS"|"ST"|"SV"|"SX"|"SY"|"SZ"|"TA"|"TC"|"TD"|"TF"|"TG"|"TH"|"TJ"|"TK"|"TL"|"TM"|"TN"|"TO"|"TR"|"TT"|"TV"|"TW"|"TZ"|"UA"|"UG"|"UM"|"US"|"UY"|"UZ"|"VA"|"VC"|"VE"|"VG"|"VI"|"VN"|"VU"|"WF"|"WS"|"XA"|"XB"|"XK"|"YE"|"YT"|"ZA"|"ZM"|"ZW", post_code: string}
  --emails: list
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
  let full_url = (build-url $base ({id: $id} | format pattern "/partners/{id}"))
  let body = {"account_number": $account_number, "address": $address, "emails": $emails, "general_ledger_number": $general_ledger_number, "iban": $iban, "name": $name, "phone": $phone, "swift": $swift, "taxcode": $taxcode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let body = {"comment": $comment, "currency": $currency, "general_ledger_number": $general_ledger_number, "general_ledger_taxcode": $general_ledger_taxcode, "name": $name, "net_unit_price": $net_unit_price, "unit": $unit, "vat": $vat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<comment: string, currency: string, general_ledger_number: string, general_ledger_taxcode: string, id: int, name: string, net_unit_price: float, unit: string, vat: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base ({id: $id} | format pattern "/products/{id}"))
  let body = {"comment": $comment, "currency": $currency, "general_ledger_number": $general_ledger_number, "general_ledger_taxcode": $general_ledger_taxcode, "name": $name, "net_unit_price": $net_unit_price, "unit": $unit, "vat": $vat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, legacy_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/utils/convert-legacy-id/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
