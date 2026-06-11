# Auto-generated client for Accounting API v9.3.0
# Source: https://api.apis.guru/v2/specs/apideck.com/accounting/9.3.0/openapi.json
# Auth: --token flag or $env.ACCOUNTING_API_TOKEN

const BASE_URL = "https://unify.apideck.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ACCOUNTING_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://unify.apideck.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def currency-completer [] { ["AED" "AFN" "ALL" "AMD" "ANG" "AOA" "ARS" "AUD" "AWG" "AZN" "BAM" "BBD" "BDT" "BGN" "BHD" "BIF" "BMD" "BND" "BOB" "BOV" "BRL" "BSD" "BTC" "BTN" "BWP" "BYR" "BZD" "CAD" "CDF" "CHE" "CHF" "CHW" "CLF" "CLP" "CNY" "COP" "COU" "CRC" "CUC" "CUP" "CVE" "CZK" "DJF" "DKK" "DOP" "DZD" "EGP" "ERN" "ETB" "ETH" "EUR" "FJD" "FKP" "GBP" "GEL" "GHS" "GIP" "GMD" "GNF" "GTQ" "GYD" "HKD" "HNL" "HRK" "HTG" "HUF" "IDR" "ILS" "INR" "IQD" "IRR" "ISK" "JMD" "JOD" "JPY" "KES" "KGS" "KHR" "KMF" "KPW" "KRW" "KWD" "KYD" "KZT" "LAK" "LBP" "LKR" "LRD" "LSL" "LTL" "LVL" "LYD" "MAD" "MDL" "MGA" "MKD" "MMK" "MNT" "MOP" "MRO" "MUR" "MVR" "MWK" "MXN" "MXV" "MYR" "MZN" "NAD" "NGN" "NIO" "NOK" "NPR" "NZD" "OMR" "PAB" "PEN" "PGK" "PHP" "PKR" "PLN" "PYG" "QAR" "RON" "RSD" "RUB" "RWF" "SAR" "SBD" "SCR" "SDG" "SEK" "SGD" "SHP" "SLL" "SOS" "SRD" "SSP" "STD" "SVC" "SYP" "SZL" "THB" "TJS" "TMT" "TND" "TOP" "TRC" "TRY" "TTD" "TWD" "TZS" "UAH" "UGX" "UNKNOWN_CURRENCY" "USD" "USN" "USS" "UYI" "UYU" "UZS" "VEF" "VND" "VUV" "WST" "XAF" "XAG" "XAU" "XBA" "XBB" "XBC" "XBD" "XCD" "XDR" "XOF" "XPD" "XPF" "XPT" "XTS" "XXX" "YER" "ZAR" "ZMK" "ZMW"] }
def status-completer [] { ["authorised" "credit" "deleted" "draft" "paid" "partially_paid" "submitted" "void"] }
def status-completer-1 [] { ["authorised" "deleted" "draft" "paid" "voided"] }
def type-completer [] { ["accounts_payable_credit" "accounts_receivable_credit"] }
def status-completer-2 [] { ["active" "archived" "gdpr-erasure-request" "inactive" "unknown"] }
def type-completer-1 [] { ["inventory" "other" "service"] }
def type-completer-2 [] { ["credit" "other" "product" "service" "standard" "supplier"] }
def classification-completer [] { ["asset" "costs_of_sales" "equity" "expense" "income" "liability" "other_expense" "other_income" "revenue"] }
def status-completer-3 [] { ["active" "archived" "inactive"] }
def type-completer-3 [] { ["accounts_payable" "accounts_receivable" "balancesheet" "bank" "costs_of_sales" "credit_card" "current_asset" "current_liability" "equity" "expense" "fixed_asset" "non_current_asset" "non_current_liability" "other_asset" "other_expense" "other_income" "other_liability" "revenue" "sales"] }
def status-completer-4 [] { ["authorised" "deleted" "paid" "voided"] }
def type-completer-4 [] { ["accounts_payable" "accounts_payable_credit" "accounts_payable_overpayment" "accounts_payable_prepayment" "accounts_receivable" "accounts_receivable_credit" "accounts_receivable_overpayment" "accounts_receivable_prepayment"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounting-balance-sheet balanceSheetOne" } } | get name | first)
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

# Get BalanceSheet
#
# GET /accounting/balance-sheet
# operationId: balanceSheetOne
export def "accounting-balance-sheet balanceSheetOne" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --filter: record # Apply filters (e.g. {end_date: 2021-12-31, start_date: 2021-01-01})
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pass_through" $pass_through "deepObject") (serialize-qp "filter" $filter "deepObject") (serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/balance-sheet" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Bills
#
# GET /accounting/bills
# operationId: billsAll
export def "accounting-bills billsAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --qp-sort: record # Apply sorting (e.g. {by: updated_at, direction: desc})
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "deepObject") (serialize-qp "pass_through" $pass_through "deepObject") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/bills" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Bill
#
# POST /accounting/bills
# operationId: billsAdd
# --ledger_account shape: {code?: string, id?: string, nominal_code?: string}
# --line_items item shape: {code?: string, department_id?: string, description?: string, discount_percentage?: float, item?: record, ledger_account?: record, line_number?: int, location_id?: string, quantity?: float, row_id?: string, row_version?: string, tax_amount?: float, tax_rate?: record, total_amount?: float, type?: "expense_item"|"expense_account", unit_of_measure?: string, unit_price?: float}
# --supplier shape: {address?: record, display_name?: string, id: string}
export def "accounting-bills billsAdd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --balance: float # Balance of bill due. (nullable, e.g. 27500)
  --bill-date: string # Date bill was issued - YYYY-MM-DD. (format: date, e.g. 2020-09-30)
  --bill-number: string # nullable, e.g. 10001
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --currency-rate: float # Currency Exchange Rate at the time entity was recorded/generated. (nullable, e.g. 0.69)
  --deposit: float # Amount of deposit made to this bill. (nullable, e.g. 0)
  --due-date: string # The due date is the date on which a payment is scheduled to be received by the supplier - YYYY-MM-DD. (format: date, e.g. 2020-10-30)
  --ledger-account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --line-items: list # item shape: {code?: string, department_id?: string, description?: string, discount_percentage?: float, item?: record, ledger_account?: record, line_number?: int, location_id?: string, quantity?: float, row_id?: string, row_version?: string, tax_amount?: float, tax_rate?: record, total_amount?: float, type?: "expense_item"|"expense_account", unit_of_measure?: string, unit_price?: float}
  --notes: string # nullable, e.g. Some notes about this bill.
  --paid-date: string # The paid date is the date on which a payment was sent to the supplier - YYYY-MM-DD. (nullable, format: date, e.g. 2020-10-30)
  --po-number: string # A PO Number uniquely identifies a purchase order and is generally defined by the buyer. The buyer will match the PO number in the invoice to the Purchase Order. (nullable, e.g. 90000117)
  --reference: string # Optional bill reference. (nullable, e.g. 123456)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer # Invoice status (nullable, e.g. draft)
  --sub-total: float # Sub-total amount, normally before tax. (nullable, e.g. 27500)
  --supplier: record # The supplier this entity is linked to. (nullable) — shape: {address?: record, display_name?: string, id: string}
  --tax-code: string # Applicable tax id/code override if tax is not supplied on a line item basis. (nullable, e.g. 1234)
  --tax-inclusive: string@bool-completer # Amounts are including tax (nullable, e.g. true)
  --terms: string # Terms of payment. (nullable, e.g. Net 30 days)
  --total: float # Total amount of bill, including tax. (nullable, e.g. 27500)
  --total-tax: float # Total tax amount applied to this bill. (nullable, e.g. 2500)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/bills" $qp)
  let body = {balance: $balance, bill_date: $bill_date, bill_number: $bill_number, currency: $currency, currency_rate: $currency_rate, deposit: $deposit, due_date: $due_date, ledger_account: $ledger_account, line_items: $line_items, notes: $notes, paid_date: $paid_date, po_number: $po_number, reference: $reference, row_version: $row_version, status: $status, sub_total: $sub_total, supplier: $supplier, tax_code: $tax_code, tax_inclusive: $tax_inclusive, terms: $terms, total: $total, total_tax: $total_tax} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Bill
#
# DELETE /accounting/bills/{id}
# operationId: billsDelete
export def "accounting-bills billsDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/bills/($id)" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Bill
#
# GET /accounting/bills/{id}
# operationId: billsOne
export def "accounting-bills billsOne" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/bills/($id)" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Bill
#
# PATCH /accounting/bills/{id}
# operationId: billsUpdate
# --ledger_account shape: {code?: string, id?: string, nominal_code?: string}
# --line_items item shape: {code?: string, department_id?: string, description?: string, discount_percentage?: float, item?: record, ledger_account?: record, line_number?: int, location_id?: string, quantity?: float, row_id?: string, row_version?: string, tax_amount?: float, tax_rate?: record, total_amount?: float, type?: "expense_item"|"expense_account", unit_of_measure?: string, unit_price?: float}
# --supplier shape: {address?: record, display_name?: string, id: string}
export def "accounting-bills billsUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --balance: float # Balance of bill due. (nullable, e.g. 27500)
  --bill-date: string # Date bill was issued - YYYY-MM-DD. (format: date, e.g. 2020-09-30)
  --bill-number: string # nullable, e.g. 10001
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --currency-rate: float # Currency Exchange Rate at the time entity was recorded/generated. (nullable, e.g. 0.69)
  --deposit: float # Amount of deposit made to this bill. (nullable, e.g. 0)
  --due-date: string # The due date is the date on which a payment is scheduled to be received by the supplier - YYYY-MM-DD. (format: date, e.g. 2020-10-30)
  --ledger-account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --line-items: list # item shape: {code?: string, department_id?: string, description?: string, discount_percentage?: float, item?: record, ledger_account?: record, line_number?: int, location_id?: string, quantity?: float, row_id?: string, row_version?: string, tax_amount?: float, tax_rate?: record, total_amount?: float, type?: "expense_item"|"expense_account", unit_of_measure?: string, unit_price?: float}
  --notes: string # nullable, e.g. Some notes about this bill.
  --paid-date: string # The paid date is the date on which a payment was sent to the supplier - YYYY-MM-DD. (nullable, format: date, e.g. 2020-10-30)
  --po-number: string # A PO Number uniquely identifies a purchase order and is generally defined by the buyer. The buyer will match the PO number in the invoice to the Purchase Order. (nullable, e.g. 90000117)
  --reference: string # Optional bill reference. (nullable, e.g. 123456)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer # Invoice status (nullable, e.g. draft)
  --sub-total: float # Sub-total amount, normally before tax. (nullable, e.g. 27500)
  --supplier: record # The supplier this entity is linked to. (nullable) — shape: {address?: record, display_name?: string, id: string}
  --tax-code: string # Applicable tax id/code override if tax is not supplied on a line item basis. (nullable, e.g. 1234)
  --tax-inclusive: string@bool-completer # Amounts are including tax (nullable, e.g. true)
  --terms: string # Terms of payment. (nullable, e.g. Net 30 days)
  --total: float # Total amount of bill, including tax. (nullable, e.g. 27500)
  --total-tax: float # Total tax amount applied to this bill. (nullable, e.g. 2500)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/bills/($id)" $qp)
  let body = {balance: $balance, bill_date: $bill_date, bill_number: $bill_number, currency: $currency, currency_rate: $currency_rate, deposit: $deposit, due_date: $due_date, ledger_account: $ledger_account, line_items: $line_items, notes: $notes, paid_date: $paid_date, po_number: $po_number, reference: $reference, row_version: $row_version, status: $status, sub_total: $sub_total, supplier: $supplier, tax_code: $tax_code, tax_inclusive: $tax_inclusive, terms: $terms, total: $total, total_tax: $total_tax} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get company info
#
# GET /accounting/company-info
# operationId: companyInfoOne
export def "accounting-company-info companyInfoOne" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/company-info" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Credit Notes
#
# GET /accounting/credit-notes
# operationId: creditNotesAll
export def "accounting-credit-notes creditNotesAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pass_through" $pass_through "deepObject") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/credit-notes" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Credit Note
#
# POST /accounting/credit-notes
# operationId: creditNotesAdd
# --account shape: {code?: string, id?: string, nominal_code?: string}
# --allocations item shape: {amount?: float, id?: string, type?: "invoice"|"order"|"expense"|"credit_memo"|"over_payment"|"pre_payment"}
# --customer shape: {display_name?: string, id: string, name?: string}
# --line_items item shape: {code?: string, department_id?: string, description?: string, discount_amount?: float, discount_percentage?: float, item?: record, ledger_account?: record, line_number?: int, location_id?: string, quantity?: float, row_id?: string, row_version?: string, tax_amount?: float, tax_rate?: record, total_amount?: float, type?: "sales_item"|"discount"|"info"|"sub_total", unit_of_measure?: string, unit_price?: float}
export def "accounting-credit-notes creditNotesAdd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --allocations: list # item shape: {amount?: float, id?: string, type?: "invoice"|"order"|"expense"|"credit_memo"|"over_payment"|"pre_payment"}
  --balance: float # The balance reflecting any payments made against the transaction. (nullable, e.g. 27500)
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --currency-rate: float # Currency Exchange Rate at the time entity was recorded/generated. (nullable, e.g. 0.69)
  --customer: record # The customer this entity is linked to. (nullable) — shape: {display_name?: string, id: string, name?: string}
  --date-issued: string # Date credit note issued - YYYY:MM::DDThh:mm:ss.sTZD (format: date-time, e.g. 2021-05-01T12:00:00.000Z)
  --date-paid: string # Date credit note paid - YYYY:MM::DDThh:mm:ss.sTZD (nullable, format: date-time, e.g. 2021-05-01T12:00:00.000Z)
  --line-items: list # item shape: {code?: string, department_id?: string, description?: string, discount_amount?: float, discount_percentage?: float, item?: record, ledger_account?: record, line_number?: int, location_id?: string, quantity?: float, row_id?: string, row_version?: string, tax_amount?: float, tax_rate?: record, total_amount?: float, type?: "sales_item"|"discount"|"info"|"sub_total", unit_of_measure?: string, unit_price?: float}
  --note: string # Optional note to be associated with the credit note. (nullable, e.g. Some notes about this credit note)
  --number: string # Credit note number. (nullable, e.g. OIT00546)
  --reference: string # Optional reference message ie: Debit remittance detail. (nullable, e.g. 123456)
  --remaining-credit: float # Indicates the total credit amount still available to apply towards the payment. (nullable, e.g. 27500)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-1 # Status of credit notes (e.g. authorised)
  --sub-total: float # Sub-total amount, normally before tax. (nullable, e.g. 27500)
  --tax-code: string # Applicable tax id/code override if tax is not supplied on a line item basis. (nullable, e.g. 1234)
  --tax-inclusive: string@bool-completer # Amounts are including tax (nullable, e.g. true)
  --terms: string # Optional terms to be associated with the credit note. (nullable, e.g. Some terms about this credit note)
  total_amount: float # Amount of transaction (e.g. 49.99)
  --total-tax: float # Total tax amount applied to this invoice. (nullable, e.g. 2500)
  --type: string@type-completer # Type of payment (e.g. accounts_receivable_credit)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/credit-notes" $qp)
  let body = {account: $account, allocations: $allocations, balance: $balance, currency: $currency, currency_rate: $currency_rate, customer: $customer, date_issued: $date_issued, date_paid: $date_paid, line_items: $line_items, note: $note, number: $number, reference: $reference, remaining_credit: $remaining_credit, row_version: $row_version, status: $status, sub_total: $sub_total, tax_code: $tax_code, tax_inclusive: $tax_inclusive, terms: $terms, total_amount: $total_amount, total_tax: $total_tax, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Credit Note
#
# DELETE /accounting/credit-notes/{id}
# operationId: creditNotesDelete
export def "accounting-credit-notes creditNotesDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/credit-notes/($id)" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Credit Note
#
# GET /accounting/credit-notes/{id}
# operationId: creditNotesOne
export def "accounting-credit-notes creditNotesOne" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/credit-notes/($id)" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Credit Note
#
# PATCH /accounting/credit-notes/{id}
# operationId: creditNotesUpdate
# --account shape: {code?: string, id?: string, nominal_code?: string}
# --allocations item shape: {amount?: float, id?: string, type?: "invoice"|"order"|"expense"|"credit_memo"|"over_payment"|"pre_payment"}
# --customer shape: {display_name?: string, id: string, name?: string}
# --line_items item shape: {code?: string, department_id?: string, description?: string, discount_amount?: float, discount_percentage?: float, item?: record, ledger_account?: record, line_number?: int, location_id?: string, quantity?: float, row_id?: string, row_version?: string, tax_amount?: float, tax_rate?: record, total_amount?: float, type?: "sales_item"|"discount"|"info"|"sub_total", unit_of_measure?: string, unit_price?: float}
export def "accounting-credit-notes creditNotesUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --allocations: list # item shape: {amount?: float, id?: string, type?: "invoice"|"order"|"expense"|"credit_memo"|"over_payment"|"pre_payment"}
  --balance: float # The balance reflecting any payments made against the transaction. (nullable, e.g. 27500)
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --currency-rate: float # Currency Exchange Rate at the time entity was recorded/generated. (nullable, e.g. 0.69)
  --customer: record # The customer this entity is linked to. (nullable) — shape: {display_name?: string, id: string, name?: string}
  --date-issued: string # Date credit note issued - YYYY:MM::DDThh:mm:ss.sTZD (format: date-time, e.g. 2021-05-01T12:00:00.000Z)
  --date-paid: string # Date credit note paid - YYYY:MM::DDThh:mm:ss.sTZD (nullable, format: date-time, e.g. 2021-05-01T12:00:00.000Z)
  --line-items: list # item shape: {code?: string, department_id?: string, description?: string, discount_amount?: float, discount_percentage?: float, item?: record, ledger_account?: record, line_number?: int, location_id?: string, quantity?: float, row_id?: string, row_version?: string, tax_amount?: float, tax_rate?: record, total_amount?: float, type?: "sales_item"|"discount"|"info"|"sub_total", unit_of_measure?: string, unit_price?: float}
  --note: string # Optional note to be associated with the credit note. (nullable, e.g. Some notes about this credit note)
  --number: string # Credit note number. (nullable, e.g. OIT00546)
  --reference: string # Optional reference message ie: Debit remittance detail. (nullable, e.g. 123456)
  --remaining-credit: float # Indicates the total credit amount still available to apply towards the payment. (nullable, e.g. 27500)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-1 # Status of credit notes (e.g. authorised)
  --sub-total: float # Sub-total amount, normally before tax. (nullable, e.g. 27500)
  --tax-code: string # Applicable tax id/code override if tax is not supplied on a line item basis. (nullable, e.g. 1234)
  --tax-inclusive: string@bool-completer # Amounts are including tax (nullable, e.g. true)
  --terms: string # Optional terms to be associated with the credit note. (nullable, e.g. Some terms about this credit note)
  total_amount: float # Amount of transaction (e.g. 49.99)
  --total-tax: float # Total tax amount applied to this invoice. (nullable, e.g. 2500)
  --type: string@type-completer # Type of payment (e.g. accounts_receivable_credit)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/credit-notes/($id)" $qp)
  let body = {account: $account, allocations: $allocations, balance: $balance, currency: $currency, currency_rate: $currency_rate, customer: $customer, date_issued: $date_issued, date_paid: $date_paid, line_items: $line_items, note: $note, number: $number, reference: $reference, remaining_credit: $remaining_credit, row_version: $row_version, status: $status, sub_total: $sub_total, tax_code: $tax_code, tax_inclusive: $tax_inclusive, terms: $terms, total_amount: $total_amount, total_tax: $total_tax, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Customers
#
# GET /accounting/customers
# operationId: customersAll
export def "accounting-customers customersAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --filter: record # Apply filters (e.g. {company_name: SpaceX, display_name: Elon Musk, email: elon@musk.com, first_name: Elon, last_name: Musk})
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "pass_through" $pass_through "deepObject") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/customers" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Customer
#
# POST /accounting/customers
# operationId: customersAdd
# --account shape: {code?: string, id?: string, nominal_code?: string}
# --addresses item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
# --bank_accounts item shape: {account_name?: string, account_number?: string, account_type?: "bank_account"|"credit_card"|"other", bank_code?: string, bic?: string, branch_identifier?: string, bsb_number?: string, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH", iban?: string}
# --emails item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
# --parent shape: {id: string, name?: string}
# --phone_numbers item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
# --tax_rate shape: {id?: string}
# --websites item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
export def "accounting-customers customersAdd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --addresses: list # item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --bank-accounts: list # item shape: {account_name?: string, account_number?: string, account_type?: "bank_account"|"credit_card"|"other", bank_code?: string, bic?: string, branch_identifier?: string, bsb_number?: string, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH", iban?: string}
  --company-name: string # The name of the company. (nullable, e.g. SpaceX)
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --display-id: string # Display ID (nullable, e.g. EMP00101)
  --display-name: string # Display name (nullable, e.g. Windsurf Shop)
  --emails: list # item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
  --first-name: string # The first name of the person. (nullable, e.g. Elon)
  --individual: string@bool-completer # Is this an individual or business customer (nullable, e.g. true)
  --last-name: string # The last name of the person. (nullable, e.g. Musk)
  --middle-name: string # Middle name of the person. (nullable, e.g. D.)
  --notes: string # Some notes about this customer (nullable, e.g. Some notes about this customer)
  --parent: record # The parent customer this entity is linked to. (nullable) — shape: {id: string, name?: string}
  --phone-numbers: list # item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
  --project: string@bool-completer # If true, indicates this is a Project. (nullable, e.g. false)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-2 # Customer status (nullable, e.g. active)
  --suffix: string # nullable, e.g. Jr.
  --tax-number: string # nullable, e.g. US123945459
  --tax-rate: record # shape: {id?: string}
  --title: string # The job title of the person. (nullable, e.g. CEO)
  --websites: list # item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/customers" $qp)
  let body = {account: $account, addresses: $addresses, bank_accounts: $bank_accounts, company_name: $company_name, currency: $currency, display_id: $display_id, display_name: $display_name, emails: $emails, first_name: $first_name, individual: $individual, last_name: $last_name, middle_name: $middle_name, notes: $notes, parent: $parent, phone_numbers: $phone_numbers, project: $project, row_version: $row_version, status: $status, suffix: $suffix, tax_number: $tax_number, tax_rate: $tax_rate, title: $title, websites: $websites} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Customer
#
# DELETE /accounting/customers/{id}
# operationId: customersDelete
export def "accounting-customers customersDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/customers/($id)" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Customer
#
# GET /accounting/customers/{id}
# operationId: customersOne
export def "accounting-customers customersOne" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/customers/($id)" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Customer
#
# PATCH /accounting/customers/{id}
# operationId: customersUpdate
# --account shape: {code?: string, id?: string, nominal_code?: string}
# --addresses item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
# --bank_accounts item shape: {account_name?: string, account_number?: string, account_type?: "bank_account"|"credit_card"|"other", bank_code?: string, bic?: string, branch_identifier?: string, bsb_number?: string, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH", iban?: string}
# --emails item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
# --parent shape: {id: string, name?: string}
# --phone_numbers item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
# --tax_rate shape: {id?: string}
# --websites item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
export def "accounting-customers customersUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --addresses: list # item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --bank-accounts: list # item shape: {account_name?: string, account_number?: string, account_type?: "bank_account"|"credit_card"|"other", bank_code?: string, bic?: string, branch_identifier?: string, bsb_number?: string, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH", iban?: string}
  --company-name: string # The name of the company. (nullable, e.g. SpaceX)
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --display-id: string # Display ID (nullable, e.g. EMP00101)
  --display-name: string # Display name (nullable, e.g. Windsurf Shop)
  --emails: list # item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
  --first-name: string # The first name of the person. (nullable, e.g. Elon)
  --individual: string@bool-completer # Is this an individual or business customer (nullable, e.g. true)
  --last-name: string # The last name of the person. (nullable, e.g. Musk)
  --middle-name: string # Middle name of the person. (nullable, e.g. D.)
  --notes: string # Some notes about this customer (nullable, e.g. Some notes about this customer)
  --parent: record # The parent customer this entity is linked to. (nullable) — shape: {id: string, name?: string}
  --phone-numbers: list # item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
  --project: string@bool-completer # If true, indicates this is a Project. (nullable, e.g. false)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-2 # Customer status (nullable, e.g. active)
  --suffix: string # nullable, e.g. Jr.
  --tax-number: string # nullable, e.g. US123945459
  --tax-rate: record # shape: {id?: string}
  --title: string # The job title of the person. (nullable, e.g. CEO)
  --websites: list # item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/customers/($id)" $qp)
  let body = {account: $account, addresses: $addresses, bank_accounts: $bank_accounts, company_name: $company_name, currency: $currency, display_id: $display_id, display_name: $display_name, emails: $emails, first_name: $first_name, individual: $individual, last_name: $last_name, middle_name: $middle_name, notes: $notes, parent: $parent, phone_numbers: $phone_numbers, project: $project, row_version: $row_version, status: $status, suffix: $suffix, tax_number: $tax_number, tax_rate: $tax_rate, title: $title, websites: $websites} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Invoice Items
#
# GET /accounting/invoice-items
# operationId: invoiceItemsAll
export def "accounting-invoice-items invoiceItemsAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --filter: record # Apply filters (e.g. {name: Widgets Large})
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "pass_through" $pass_through "deepObject") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/invoice-items" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Invoice Item
#
# POST /accounting/invoice-items
# operationId: invoiceItemsAdd
# --asset_account shape: {code?: string, id?: string, nominal_code?: string}
# --expense_account shape: {code?: string, id?: string, nominal_code?: string}
# --income_account shape: {code?: string, id?: string, nominal_code?: string}
# --purchase_details shape: {tax_inclusive?: bool, tax_rate?: record, unit_of_measure?: string, unit_price?: float}
# --sales_details shape: {tax_inclusive?: bool, tax_rate?: record, unit_of_measure?: string, unit_price?: float}
export def "accounting-invoice-items invoiceItemsAdd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --active: string@bool-completer # nullable, e.g. true
  --asset-account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --code: string # User defined item code (nullable, e.g. 120-C)
  --description: string # A short description of the item (nullable, e.g. Model Y is a fully electric, mid-size SUV, with seating for up to seven, dual motor AWD and unparalleled protection.)
  --expense-account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --income-account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --inventory-date: string # The date of opening balance if inventory item is tracked - YYYY-MM-DD. (nullable, format: date, e.g. 2020-10-30)
  --name: string # Item name (nullable, e.g. Model Y)
  --purchase-details: record # shape: {tax_inclusive?: bool, tax_rate?: record, unit_of_measure?: string, unit_price?: float}
  --purchased: string@bool-completer # Item is available for purchase transactions (nullable, e.g. true)
  --quantity: float # nullable, e.g. 1
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --sales-details: record # shape: {tax_inclusive?: bool, tax_rate?: record, unit_of_measure?: string, unit_price?: float}
  --sold: string@bool-completer # Item will be available on sales transactions (nullable, e.g. true)
  --taxable: string@bool-completer # If true, transactions for this item are taxable (nullable, e.g. true)
  --tracked: string@bool-completer # Item is inventoried (nullable, e.g. true)
  --type: string@type-completer-1 # Item type (nullable, e.g. inventory)
  --unit-price: float # nullable, e.g. 27500.5
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/invoice-items" $qp)
  let body = {active: $active, asset_account: $asset_account, code: $code, description: $description, expense_account: $expense_account, income_account: $income_account, inventory_date: $inventory_date, name: $name, purchase_details: $purchase_details, purchased: $purchased, quantity: $quantity, row_version: $row_version, sales_details: $sales_details, sold: $sold, taxable: $taxable, tracked: $tracked, type: $type, unit_price: $unit_price} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Invoice Item
#
# DELETE /accounting/invoice-items/{id}
# operationId: invoiceItemsDelete
export def "accounting-invoice-items invoiceItemsDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/invoice-items/($id)" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Invoice Item
#
# GET /accounting/invoice-items/{id}
# operationId: invoiceItemsOne
export def "accounting-invoice-items invoiceItemsOne" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/invoice-items/($id)" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Invoice Item
#
# PATCH /accounting/invoice-items/{id}
# operationId: invoiceItemsUpdate
# --asset_account shape: {code?: string, id?: string, nominal_code?: string}
# --expense_account shape: {code?: string, id?: string, nominal_code?: string}
# --income_account shape: {code?: string, id?: string, nominal_code?: string}
# --purchase_details shape: {tax_inclusive?: bool, tax_rate?: record, unit_of_measure?: string, unit_price?: float}
# --sales_details shape: {tax_inclusive?: bool, tax_rate?: record, unit_of_measure?: string, unit_price?: float}
export def "accounting-invoice-items invoiceItemsUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --active: string@bool-completer # nullable, e.g. true
  --asset-account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --code: string # User defined item code (nullable, e.g. 120-C)
  --description: string # A short description of the item (nullable, e.g. Model Y is a fully electric, mid-size SUV, with seating for up to seven, dual motor AWD and unparalleled protection.)
  --expense-account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --income-account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --inventory-date: string # The date of opening balance if inventory item is tracked - YYYY-MM-DD. (nullable, format: date, e.g. 2020-10-30)
  --name: string # Item name (nullable, e.g. Model Y)
  --purchase-details: record # shape: {tax_inclusive?: bool, tax_rate?: record, unit_of_measure?: string, unit_price?: float}
  --purchased: string@bool-completer # Item is available for purchase transactions (nullable, e.g. true)
  --quantity: float # nullable, e.g. 1
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --sales-details: record # shape: {tax_inclusive?: bool, tax_rate?: record, unit_of_measure?: string, unit_price?: float}
  --sold: string@bool-completer # Item will be available on sales transactions (nullable, e.g. true)
  --taxable: string@bool-completer # If true, transactions for this item are taxable (nullable, e.g. true)
  --tracked: string@bool-completer # Item is inventoried (nullable, e.g. true)
  --type: string@type-completer-1 # Item type (nullable, e.g. inventory)
  --unit-price: float # nullable, e.g. 27500.5
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/invoice-items/($id)" $qp)
  let body = {active: $active, asset_account: $asset_account, code: $code, description: $description, expense_account: $expense_account, income_account: $income_account, inventory_date: $inventory_date, name: $name, purchase_details: $purchase_details, purchased: $purchased, quantity: $quantity, row_version: $row_version, sales_details: $sales_details, sold: $sold, taxable: $taxable, tracked: $tracked, type: $type, unit_price: $unit_price} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Invoices
#
# GET /accounting/invoices
# operationId: invoicesAll
export def "accounting-invoices invoicesAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --qp-sort: record # Apply sorting (e.g. {by: updated_at, direction: desc})
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "deepObject") (serialize-qp "pass_through" $pass_through "deepObject") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/invoices" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Invoice
#
# POST /accounting/invoices
# operationId: invoicesAdd
# --billing_address shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
# --customer shape: {display_name?: string, id: string, name?: string}
# --line_items item shape: {code?: string, department_id?: string, description?: string, discount_amount?: float, discount_percentage?: float, item?: record, ledger_account?: record, line_number?: int, location_id?: string, quantity?: float, row_id?: string, row_version?: string, tax_amount?: float, tax_rate?: record, total_amount?: float, type?: "sales_item"|"discount"|"info"|"sub_total", unit_of_measure?: string, unit_price?: float}
# --shipping_address shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
export def "accounting-invoices invoicesAdd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --balance: float # Balance of invoice due. (nullable, e.g. 27500)
  --billing-address: record # shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --currency-rate: float # Currency Exchange Rate at the time entity was recorded/generated. (nullable, e.g. 0.69)
  --customer: record # The customer this entity is linked to. (nullable) — shape: {display_name?: string, id: string, name?: string}
  --customer-memo: string # Customer memo (nullable, e.g. Thank you for your business and have a great day!)
  --deposit: float # Amount of deposit made to this invoice. (nullable, e.g. 0)
  --discount-amount: float # Discount amount applied to this invoice. (nullable, e.g. 25)
  --discount-percentage: float # Discount percentage applied to this invoice. (nullable, e.g. 5.5)
  --due-date: string # The invoice due date is the date on which a payment or invoice is scheduled to be received by the seller - YYYY-MM-DD. (nullable, format: date, e.g. 2020-09-30)
  --invoice-date: string # Date invoice was issued - YYYY-MM-DD. (nullable, format: date, e.g. 2020-09-30)
  --invoice-sent: string@bool-completer # Invoice sent to contact/customer. (e.g. true)
  --line-items: list # item shape: {code?: string, department_id?: string, description?: string, discount_amount?: float, discount_percentage?: float, item?: record, ledger_account?: record, line_number?: int, location_id?: string, quantity?: float, row_id?: string, row_version?: string, tax_amount?: float, tax_rate?: record, total_amount?: float, type?: "sales_item"|"discount"|"info"|"sub_total", unit_of_measure?: string, unit_price?: float}
  --number: string # Invoice number. (nullable, e.g. OIT00546)
  --po-number: string # A PO Number uniquely identifies a purchase order and is generally defined by the buyer. The buyer will match the PO number in the invoice to the Purchase Order. (nullable, e.g. 90000117)
  --reference: string # Optional invoice reference. (nullable, e.g. 123456)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --shipping-address: record # shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --source-document-url: string # URL link to a source document - shown as 'Go to [appName]' in the downstream app. Currently only supported for Xero. (nullable, e.g. https://www.invoicesolution.com/invoice/123456)
  --status: string@status-completer # Invoice status (nullable, e.g. draft)
  --sub-total: float # Sub-total amount, normally before tax. (nullable, e.g. 27500)
  --tax-code: string # Applicable tax id/code override if tax is not supplied on a line item basis. (nullable, e.g. 1234)
  --tax-inclusive: string@bool-completer # Amounts are including tax (nullable, e.g. true)
  --template-id: string # Optional invoice template (nullable, e.g. 123456)
  --terms: string # Terms of payment. (nullable, e.g. Net 30 days)
  --total: float # Total amount of invoice, including tax. (nullable, e.g. 27500)
  --total-tax: float # Total tax amount applied to this invoice. (nullable, e.g. 2500)
  --type: string@type-completer-2 # Invoice type (nullable, e.g. service)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/invoices" $qp)
  let body = {balance: $balance, billing_address: $billing_address, currency: $currency, currency_rate: $currency_rate, customer: $customer, customer_memo: $customer_memo, deposit: $deposit, discount_amount: $discount_amount, discount_percentage: $discount_percentage, due_date: $due_date, invoice_date: $invoice_date, invoice_sent: $invoice_sent, line_items: $line_items, number: $number, po_number: $po_number, reference: $reference, row_version: $row_version, shipping_address: $shipping_address, source_document_url: $source_document_url, status: $status, sub_total: $sub_total, tax_code: $tax_code, tax_inclusive: $tax_inclusive, template_id: $template_id, terms: $terms, total: $total, total_tax: $total_tax, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Invoice
#
# DELETE /accounting/invoices/{id}
# operationId: invoicesDelete
export def "accounting-invoices invoicesDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/invoices/($id)" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Invoice
#
# GET /accounting/invoices/{id}
# operationId: invoicesOne
export def "accounting-invoices invoicesOne" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/invoices/($id)" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Invoice
#
# PATCH /accounting/invoices/{id}
# operationId: invoicesUpdate
# --billing_address shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
# --customer shape: {display_name?: string, id: string, name?: string}
# --line_items item shape: {code?: string, department_id?: string, description?: string, discount_amount?: float, discount_percentage?: float, item?: record, ledger_account?: record, line_number?: int, location_id?: string, quantity?: float, row_id?: string, row_version?: string, tax_amount?: float, tax_rate?: record, total_amount?: float, type?: "sales_item"|"discount"|"info"|"sub_total", unit_of_measure?: string, unit_price?: float}
# --shipping_address shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
export def "accounting-invoices invoicesUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --balance: float # Balance of invoice due. (nullable, e.g. 27500)
  --billing-address: record # shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --currency-rate: float # Currency Exchange Rate at the time entity was recorded/generated. (nullable, e.g. 0.69)
  --customer: record # The customer this entity is linked to. (nullable) — shape: {display_name?: string, id: string, name?: string}
  --customer-memo: string # Customer memo (nullable, e.g. Thank you for your business and have a great day!)
  --deposit: float # Amount of deposit made to this invoice. (nullable, e.g. 0)
  --discount-amount: float # Discount amount applied to this invoice. (nullable, e.g. 25)
  --discount-percentage: float # Discount percentage applied to this invoice. (nullable, e.g. 5.5)
  --due-date: string # The invoice due date is the date on which a payment or invoice is scheduled to be received by the seller - YYYY-MM-DD. (nullable, format: date, e.g. 2020-09-30)
  --invoice-date: string # Date invoice was issued - YYYY-MM-DD. (nullable, format: date, e.g. 2020-09-30)
  --invoice-sent: string@bool-completer # Invoice sent to contact/customer. (e.g. true)
  --line-items: list # item shape: {code?: string, department_id?: string, description?: string, discount_amount?: float, discount_percentage?: float, item?: record, ledger_account?: record, line_number?: int, location_id?: string, quantity?: float, row_id?: string, row_version?: string, tax_amount?: float, tax_rate?: record, total_amount?: float, type?: "sales_item"|"discount"|"info"|"sub_total", unit_of_measure?: string, unit_price?: float}
  --number: string # Invoice number. (nullable, e.g. OIT00546)
  --po-number: string # A PO Number uniquely identifies a purchase order and is generally defined by the buyer. The buyer will match the PO number in the invoice to the Purchase Order. (nullable, e.g. 90000117)
  --reference: string # Optional invoice reference. (nullable, e.g. 123456)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --shipping-address: record # shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --source-document-url: string # URL link to a source document - shown as 'Go to [appName]' in the downstream app. Currently only supported for Xero. (nullable, e.g. https://www.invoicesolution.com/invoice/123456)
  --status: string@status-completer # Invoice status (nullable, e.g. draft)
  --sub-total: float # Sub-total amount, normally before tax. (nullable, e.g. 27500)
  --tax-code: string # Applicable tax id/code override if tax is not supplied on a line item basis. (nullable, e.g. 1234)
  --tax-inclusive: string@bool-completer # Amounts are including tax (nullable, e.g. true)
  --template-id: string # Optional invoice template (nullable, e.g. 123456)
  --terms: string # Terms of payment. (nullable, e.g. Net 30 days)
  --total: float # Total amount of invoice, including tax. (nullable, e.g. 27500)
  --total-tax: float # Total tax amount applied to this invoice. (nullable, e.g. 2500)
  --type: string@type-completer-2 # Invoice type (nullable, e.g. service)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/invoices/($id)" $qp)
  let body = {balance: $balance, billing_address: $billing_address, currency: $currency, currency_rate: $currency_rate, customer: $customer, customer_memo: $customer_memo, deposit: $deposit, discount_amount: $discount_amount, discount_percentage: $discount_percentage, due_date: $due_date, invoice_date: $invoice_date, invoice_sent: $invoice_sent, line_items: $line_items, number: $number, po_number: $po_number, reference: $reference, row_version: $row_version, shipping_address: $shipping_address, source_document_url: $source_document_url, status: $status, sub_total: $sub_total, tax_code: $tax_code, tax_inclusive: $tax_inclusive, template_id: $template_id, terms: $terms, total: $total, total_tax: $total_tax, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Journal Entries
#
# GET /accounting/journal-entries
# operationId: journalEntriesAll
export def "accounting-journal-entries journalEntriesAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pass_through" $pass_through "deepObject") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/journal-entries" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Journal Entry
#
# POST /accounting/journal-entries
# operationId: journalEntriesAdd
# --line_items item shape: {description?: string, ledger_account: record, tax_amount?: float, tax_rate?: record, total_amount: float, tracking_category?: record, type: "debit"|"credit"}
export def "accounting-journal-entries journalEntriesAdd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --currency-rate: float # Currency Exchange Rate at the time entity was recorded/generated. (nullable, e.g. 0.69)
  --journal-symbol: string # Journal symbol of the entry. For example IND for indirect costs (nullable, e.g. IND)
  --line-items: list # Requires a minimum of 2 line items that sum to 0 — item shape: {description?: string, ledger_account: record, tax_amount?: float, tax_rate?: record, total_amount: float, tracking_category?: record, type: "debit"|"credit"}
  --memo: string # Reference for the journal entry. (nullable, e.g. Thank you for your business and have a great day!)
  --posted-at: string # This is the date on which the journal entry was added. This can be different from the creation date and can also be backdated. (format: date-time, e.g. 2020-09-30T07:43:32.000Z)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --title: string # Journal entry title (nullable, e.g. Purchase Invoice-Inventory (USD): 2019/02/01 Batch Summary Entry)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/journal-entries" $qp)
  let body = {currency: $currency, currency_rate: $currency_rate, journal_symbol: $journal_symbol, line_items: $line_items, memo: $memo, posted_at: $posted_at, row_version: $row_version, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Journal Entry
#
# DELETE /accounting/journal-entries/{id}
# operationId: journalEntriesDelete
export def "accounting-journal-entries journalEntriesDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/journal-entries/($id)" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Journal Entry
#
# GET /accounting/journal-entries/{id}
# operationId: journalEntriesOne
export def "accounting-journal-entries journalEntriesOne" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/journal-entries/($id)" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Journal Entry
#
# PATCH /accounting/journal-entries/{id}
# operationId: journalEntriesUpdate
# --line_items item shape: {description?: string, ledger_account: record, tax_amount?: float, tax_rate?: record, total_amount: float, tracking_category?: record, type: "debit"|"credit"}
export def "accounting-journal-entries journalEntriesUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --currency-rate: float # Currency Exchange Rate at the time entity was recorded/generated. (nullable, e.g. 0.69)
  --journal-symbol: string # Journal symbol of the entry. For example IND for indirect costs (nullable, e.g. IND)
  --line-items: list # Requires a minimum of 2 line items that sum to 0 — item shape: {description?: string, ledger_account: record, tax_amount?: float, tax_rate?: record, total_amount: float, tracking_category?: record, type: "debit"|"credit"}
  --memo: string # Reference for the journal entry. (nullable, e.g. Thank you for your business and have a great day!)
  --posted-at: string # This is the date on which the journal entry was added. This can be different from the creation date and can also be backdated. (format: date-time, e.g. 2020-09-30T07:43:32.000Z)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --title: string # Journal entry title (nullable, e.g. Purchase Invoice-Inventory (USD): 2019/02/01 Batch Summary Entry)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/journal-entries/($id)" $qp)
  let body = {currency: $currency, currency_rate: $currency_rate, journal_symbol: $journal_symbol, line_items: $line_items, memo: $memo, posted_at: $posted_at, row_version: $row_version, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Ledger Accounts
#
# GET /accounting/ledger-accounts
# operationId: ledgerAccountsAll
export def "accounting-ledger-accounts ledgerAccountsAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pass_through" $pass_through "deepObject") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/ledger-accounts" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Ledger Account
#
# POST /accounting/ledger-accounts
# operationId: ledgerAccountsAdd
# --bank_account shape: {account_name?: string, account_number?: string, account_type?: "bank_account"|"credit_card"|"other", bank_code?: string, bic?: string, branch_identifier?: string, bsb_number?: string, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH", iban?: string}
# --parent_account shape: {display_id?: string, id?: string, name?: string}
# --tax_rate shape: {id?: string}
@deprecated --flag nominal-code
export def "accounting-ledger-accounts ledgerAccountsAdd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --active: string@bool-completer # Whether the account is active or not. (nullable, e.g. true)
  --bank-account: record # shape: {account_name?: string, account_number?: string, account_type?: "bank_account"|"credit_card"|"other", bank_code?: string, bic?: string, branch_identifier?: string, bsb_number?: string, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH", iban?: string}
  --classification: string@classification-completer # The classification of account. (nullable, e.g. asset)
  --code: string # The code assigned to the account. (nullable, e.g. 453)
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --current-balance: float # The current balance of the account. (nullable, e.g. 20000)
  --description: string # The description of the account. (nullable, e.g. Main checking account)
  --display-id: string # The human readable display ID used when displaying the account (e.g. 1-12345)
  --fully-qualified-name: string # The fully qualified name of the account. (nullable, e.g. Asset.Bank.Checking_Account)
  --header: string@bool-completer # Whether the account is a header or not. (nullable, e.g. true)
  --last-reconciliation-date: string # Reconciliation Date means the last calendar day of each Reconciliation Period. (nullable, format: date, e.g. 2020-09-30)
  --level: float # nullable, e.g. 1
  --name: string # The name of the account. (nullable, e.g. Bank account)
  --nominal-code: string # The nominal code of the ledger account. (DEPRECATED, nullable, e.g. N091)
  --opening-balance: float # The opening balance of the account. (nullable, e.g. 75000)
  --parent-account: record # shape: {display_id?: string, id?: string, name?: string}
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-3 # The status of the account. (nullable, e.g. active)
  --sub-account: string@bool-completer # Whether the account is a sub account or not. (nullable, e.g. false)
  --sub-type: string # The sub type of account. (nullable, e.g. CHECKING_ACCOUNT)
  --tax-rate: record # shape: {id?: string}
  --tax-type: string # The tax type of the account. (nullable, e.g. NONE)
  --type: string@type-completer-3 # The type of account. (e.g. bank)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/ledger-accounts" $qp)
  let body = {active: $active, bank_account: $bank_account, classification: $classification, code: $code, currency: $currency, current_balance: $current_balance, description: $description, display_id: $display_id, fully_qualified_name: $fully_qualified_name, header: $header, last_reconciliation_date: $last_reconciliation_date, level: $level, name: $name, nominal_code: $nominal_code, opening_balance: $opening_balance, parent_account: $parent_account, row_version: $row_version, status: $status, sub_account: $sub_account, sub_type: $sub_type, tax_rate: $tax_rate, tax_type: $tax_type, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Ledger Account
#
# DELETE /accounting/ledger-accounts/{id}
# operationId: ledgerAccountsDelete
export def "accounting-ledger-accounts ledgerAccountsDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/ledger-accounts/($id)" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Ledger Account
#
# GET /accounting/ledger-accounts/{id}
# operationId: ledgerAccountsOne
export def "accounting-ledger-accounts ledgerAccountsOne" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/ledger-accounts/($id)" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Ledger Account
#
# PATCH /accounting/ledger-accounts/{id}
# operationId: ledgerAccountsUpdate
# --bank_account shape: {account_name?: string, account_number?: string, account_type?: "bank_account"|"credit_card"|"other", bank_code?: string, bic?: string, branch_identifier?: string, bsb_number?: string, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH", iban?: string}
# --parent_account shape: {display_id?: string, id?: string, name?: string}
# --tax_rate shape: {id?: string}
@deprecated --flag nominal-code
export def "accounting-ledger-accounts ledgerAccountsUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --active: string@bool-completer # Whether the account is active or not. (nullable, e.g. true)
  --bank-account: record # shape: {account_name?: string, account_number?: string, account_type?: "bank_account"|"credit_card"|"other", bank_code?: string, bic?: string, branch_identifier?: string, bsb_number?: string, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH", iban?: string}
  --classification: string@classification-completer # The classification of account. (nullable, e.g. asset)
  --code: string # The code assigned to the account. (nullable, e.g. 453)
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --current-balance: float # The current balance of the account. (nullable, e.g. 20000)
  --description: string # The description of the account. (nullable, e.g. Main checking account)
  --display-id: string # The human readable display ID used when displaying the account (e.g. 1-12345)
  --fully-qualified-name: string # The fully qualified name of the account. (nullable, e.g. Asset.Bank.Checking_Account)
  --header: string@bool-completer # Whether the account is a header or not. (nullable, e.g. true)
  --last-reconciliation-date: string # Reconciliation Date means the last calendar day of each Reconciliation Period. (nullable, format: date, e.g. 2020-09-30)
  --level: float # nullable, e.g. 1
  --name: string # The name of the account. (nullable, e.g. Bank account)
  --nominal-code: string # The nominal code of the ledger account. (DEPRECATED, nullable, e.g. N091)
  --opening-balance: float # The opening balance of the account. (nullable, e.g. 75000)
  --parent-account: record # shape: {display_id?: string, id?: string, name?: string}
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-3 # The status of the account. (nullable, e.g. active)
  --sub-account: string@bool-completer # Whether the account is a sub account or not. (nullable, e.g. false)
  --sub-type: string # The sub type of account. (nullable, e.g. CHECKING_ACCOUNT)
  --tax-rate: record # shape: {id?: string}
  --tax-type: string # The tax type of the account. (nullable, e.g. NONE)
  --type: string@type-completer-3 # The type of account. (e.g. bank)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/ledger-accounts/($id)" $qp)
  let body = {active: $active, bank_account: $bank_account, classification: $classification, code: $code, currency: $currency, current_balance: $current_balance, description: $description, display_id: $display_id, fully_qualified_name: $fully_qualified_name, header: $header, last_reconciliation_date: $last_reconciliation_date, level: $level, name: $name, nominal_code: $nominal_code, opening_balance: $opening_balance, parent_account: $parent_account, row_version: $row_version, status: $status, sub_account: $sub_account, sub_type: $sub_type, tax_rate: $tax_rate, tax_type: $tax_type, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Payments
#
# GET /accounting/payments
# operationId: paymentsAll
export def "accounting-payments paymentsAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "pass_through" $pass_through "deepObject") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/payments" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Payment
#
# POST /accounting/payments
# operationId: paymentsAdd
# --account shape: {code?: string, id?: string, nominal_code?: string}
# --allocations item shape: {amount?: float, id?: string, type?: "invoice"|"order"|"expense"|"credit_memo"|"over_payment"|"pre_payment"}
# --customer shape: {display_name?: string, id: string, name?: string}
# --supplier shape: {address?: record, display_name?: string, id: string}
@deprecated --flag accounts-receivable-account-id
@deprecated --flag accounts-receivable-account-type
export def "accounting-payments paymentsAdd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --accounts-receivable-account-id: string # Unique identifier for the account to allocate payment to. (DEPRECATED, nullable, e.g. 123456)
  --accounts-receivable-account-type: string # Type of accounts receivable account. (DEPRECATED, nullable, e.g. Account)
  --allocations: list # item shape: {amount?: float, id?: string, type?: "invoice"|"order"|"expense"|"credit_memo"|"over_payment"|"pre_payment"}
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --currency-rate: float # Currency Exchange Rate at the time entity was recorded/generated. (nullable, e.g. 0.69)
  --customer: record # The customer this entity is linked to. (nullable) — shape: {display_name?: string, id: string, name?: string}
  --display-id: string # Payment id to be displayed. (nullable, e.g. 123456)
  --note: string # Optional note to be associated with the payment. (nullable, e.g. Some notes about this payment)
  --payment-method: string # Payment method name (nullable, e.g. Credit Card)
  --payment-method-id: string # Unique identifier for the payment method. (nullable, e.g. 123456)
  --payment-method-reference: string # Optional reference message returned by payment method on processing (nullable, e.g. 123456)
  --reconciled: string@bool-completer # Payment has been reconciled (e.g. true)
  --reference: string # Optional payment reference message ie: Debit remittance detail. (nullable, e.g. 123456)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-4 # Status of payment (e.g. authorised)
  --supplier: record # The supplier this entity is linked to. (nullable) — shape: {address?: record, display_name?: string, id: string}
  total_amount: float # Amount of payment (e.g. 49.99)
  transaction_date: string # Date transaction was entered - YYYY:MM::DDThh:mm:ss.sTZD (format: date-time, e.g. 2021-05-01T12:00:00.000Z)
  --type: string@type-completer-4 # Type of payment (e.g. accounts_receivable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/payments" $qp)
  let body = {account: $account, accounts_receivable_account_id: $accounts_receivable_account_id, accounts_receivable_account_type: $accounts_receivable_account_type, allocations: $allocations, currency: $currency, currency_rate: $currency_rate, customer: $customer, display_id: $display_id, note: $note, payment_method: $payment_method, payment_method_id: $payment_method_id, payment_method_reference: $payment_method_reference, reconciled: $reconciled, reference: $reference, row_version: $row_version, status: $status, supplier: $supplier, total_amount: $total_amount, transaction_date: $transaction_date, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Payment
#
# DELETE /accounting/payments/{id}
# operationId: paymentsDelete
export def "accounting-payments paymentsDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/payments/($id)" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Payment
#
# GET /accounting/payments/{id}
# operationId: paymentsOne
export def "accounting-payments paymentsOne" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/payments/($id)" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Payment
#
# PATCH /accounting/payments/{id}
# operationId: paymentsUpdate
# --account shape: {code?: string, id?: string, nominal_code?: string}
# --allocations item shape: {amount?: float, id?: string, type?: "invoice"|"order"|"expense"|"credit_memo"|"over_payment"|"pre_payment"}
# --customer shape: {display_name?: string, id: string, name?: string}
# --supplier shape: {address?: record, display_name?: string, id: string}
@deprecated --flag accounts-receivable-account-id
@deprecated --flag accounts-receivable-account-type
export def "accounting-payments paymentsUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --accounts-receivable-account-id: string # Unique identifier for the account to allocate payment to. (DEPRECATED, nullable, e.g. 123456)
  --accounts-receivable-account-type: string # Type of accounts receivable account. (DEPRECATED, nullable, e.g. Account)
  --allocations: list # item shape: {amount?: float, id?: string, type?: "invoice"|"order"|"expense"|"credit_memo"|"over_payment"|"pre_payment"}
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --currency-rate: float # Currency Exchange Rate at the time entity was recorded/generated. (nullable, e.g. 0.69)
  --customer: record # The customer this entity is linked to. (nullable) — shape: {display_name?: string, id: string, name?: string}
  --display-id: string # Payment id to be displayed. (nullable, e.g. 123456)
  --note: string # Optional note to be associated with the payment. (nullable, e.g. Some notes about this payment)
  --payment-method: string # Payment method name (nullable, e.g. Credit Card)
  --payment-method-id: string # Unique identifier for the payment method. (nullable, e.g. 123456)
  --payment-method-reference: string # Optional reference message returned by payment method on processing (nullable, e.g. 123456)
  --reconciled: string@bool-completer # Payment has been reconciled (e.g. true)
  --reference: string # Optional payment reference message ie: Debit remittance detail. (nullable, e.g. 123456)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-4 # Status of payment (e.g. authorised)
  --supplier: record # The supplier this entity is linked to. (nullable) — shape: {address?: record, display_name?: string, id: string}
  total_amount: float # Amount of payment (e.g. 49.99)
  transaction_date: string # Date transaction was entered - YYYY:MM::DDThh:mm:ss.sTZD (format: date-time, e.g. 2021-05-01T12:00:00.000Z)
  --type: string@type-completer-4 # Type of payment (e.g. accounts_receivable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/payments/($id)" $qp)
  let body = {account: $account, accounts_receivable_account_id: $accounts_receivable_account_id, accounts_receivable_account_type: $accounts_receivable_account_type, allocations: $allocations, currency: $currency, currency_rate: $currency_rate, customer: $customer, display_id: $display_id, note: $note, payment_method: $payment_method, payment_method_id: $payment_method_id, payment_method_reference: $payment_method_reference, reconciled: $reconciled, reference: $reference, row_version: $row_version, status: $status, supplier: $supplier, total_amount: $total_amount, transaction_date: $transaction_date, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Profit and Loss
#
# GET /accounting/profit-and-loss
# operationId: profitAndLossOne
export def "accounting-profit-and-loss profitAndLossOne" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --filter: record # Apply filters (e.g. {customer_id: 123abc, end_date: 2021-12-31, start_date: 2021-01-01})
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "pass_through" $pass_through "deepObject") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/profit-and-loss" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Suppliers
#
# GET /accounting/suppliers
# operationId: suppliersAll
export def "accounting-suppliers suppliersAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --filter: record # Apply filters (e.g. {company_name: SpaceX, email: elon@musk.com})
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "pass_through" $pass_through "deepObject") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/suppliers" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Supplier
#
# POST /accounting/suppliers
# operationId: suppliersAdd
# --account shape: {code?: string, id?: string, nominal_code?: string}
# --addresses item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
# --bank_accounts item shape: {account_name?: string, account_number?: string, account_type?: "bank_account"|"credit_card"|"other", bank_code?: string, bic?: string, branch_identifier?: string, bsb_number?: string, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH", iban?: string}
# --emails item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
# --phone_numbers item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
# --tax_rate shape: {id?: string}
# --websites item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
export def "accounting-suppliers suppliersAdd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --addresses: list # item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --bank-accounts: list # item shape: {account_name?: string, account_number?: string, account_type?: "bank_account"|"credit_card"|"other", bank_code?: string, bic?: string, branch_identifier?: string, bsb_number?: string, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH", iban?: string}
  --company-name: string # The name of the company. (nullable, e.g. SpaceX)
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --display-id: string # Display ID (nullable, e.g. EMP00101)
  --display-name: string # Display name (nullable, e.g. Windsurf Shop)
  --emails: list # item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
  --first-name: string # The first name of the person. (nullable, e.g. Elon)
  --individual: string@bool-completer # Is this an individual or business supplier (nullable, e.g. true)
  --last-name: string # The last name of the person. (nullable, e.g. Musk)
  --middle-name: string # Middle name of the person. (nullable, e.g. D.)
  --notes: string # Some notes about this supplier (nullable, e.g. Some notes about this supplier)
  --phone-numbers: list # item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-2 # Supplier status (nullable, e.g. active)
  --suffix: string # nullable, e.g. Jr.
  --tax-number: string # nullable, e.g. US123945459
  --tax-rate: record # shape: {id?: string}
  --title: string # The job title of the person. (nullable, e.g. CEO)
  --websites: list # item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/suppliers" $qp)
  let body = {account: $account, addresses: $addresses, bank_accounts: $bank_accounts, company_name: $company_name, currency: $currency, display_id: $display_id, display_name: $display_name, emails: $emails, first_name: $first_name, individual: $individual, last_name: $last_name, middle_name: $middle_name, notes: $notes, phone_numbers: $phone_numbers, row_version: $row_version, status: $status, suffix: $suffix, tax_number: $tax_number, tax_rate: $tax_rate, title: $title, websites: $websites} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Supplier
#
# DELETE /accounting/suppliers/{id}
# operationId: suppliersDelete
export def "accounting-suppliers suppliersDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/suppliers/($id)" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Supplier
#
# GET /accounting/suppliers/{id}
# operationId: suppliersOne
export def "accounting-suppliers suppliersOne" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/suppliers/($id)" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Supplier
#
# PATCH /accounting/suppliers/{id}
# operationId: suppliersUpdate
# --account shape: {code?: string, id?: string, nominal_code?: string}
# --addresses item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
# --bank_accounts item shape: {account_name?: string, account_number?: string, account_type?: "bank_account"|"credit_card"|"other", bank_code?: string, bic?: string, branch_identifier?: string, bsb_number?: string, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH", iban?: string}
# --emails item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
# --phone_numbers item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
# --tax_rate shape: {id?: string}
# --websites item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
export def "accounting-suppliers suppliersUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --account: record # nullable — shape: {code?: string, id?: string, nominal_code?: string}
  --addresses: list # item shape: {city?: string, contact_name?: string, country?: string, county?: string, email?: string, fax?: string, id?: string, latitude?: string, line1?: string, line2?: string, line3?: string, line4?: string, longitude?: string, name?: string, phone_number?: string, postal_code?: string, row_version?: string, salutation?: string, state?: string, street_number?: string, string?: string, type?: "primary"|"secondary"|"home"|"office"|"shipping"|"billing"|"other", website?: string}
  --bank-accounts: list # item shape: {account_name?: string, account_number?: string, account_type?: "bank_account"|"credit_card"|"other", bank_code?: string, bic?: string, branch_identifier?: string, bsb_number?: string, currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH", iban?: string}
  --company-name: string # The name of the company. (nullable, e.g. SpaceX)
  --currency: string@currency-completer # Indicates the associated currency for an amount of money. Values correspond to [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217). (nullable, e.g. USD)
  --display-id: string # Display ID (nullable, e.g. EMP00101)
  --display-name: string # Display name (nullable, e.g. Windsurf Shop)
  --emails: list # item shape: {email: string, id?: string, type?: "primary"|"secondary"|"work"|"personal"|"billing"|"other"}
  --first-name: string # The first name of the person. (nullable, e.g. Elon)
  --individual: string@bool-completer # Is this an individual or business supplier (nullable, e.g. true)
  --last-name: string # The last name of the person. (nullable, e.g. Musk)
  --middle-name: string # Middle name of the person. (nullable, e.g. D.)
  --notes: string # Some notes about this supplier (nullable, e.g. Some notes about this supplier)
  --phone-numbers: list # item shape: {area_code?: string, country_code?: string, extension?: string, id?: string, number: string, type?: "primary"|"secondary"|"home"|"work"|"office"|"mobile"|"assistant"|"fax"|"direct-dial-in"|"personal"|"other"}
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-2 # Supplier status (nullable, e.g. active)
  --suffix: string # nullable, e.g. Jr.
  --tax-number: string # nullable, e.g. US123945459
  --tax-rate: record # shape: {id?: string}
  --title: string # The job title of the person. (nullable, e.g. CEO)
  --websites: list # item shape: {id?: string, type?: "primary"|"secondary"|"work"|"personal"|"other", url: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/suppliers/($id)" $qp)
  let body = {account: $account, addresses: $addresses, bank_accounts: $bank_accounts, company_name: $company_name, currency: $currency, display_id: $display_id, display_name: $display_name, emails: $emails, first_name: $first_name, individual: $individual, last_name: $last_name, middle_name: $middle_name, notes: $notes, phone_numbers: $phone_numbers, row_version: $row_version, status: $status, suffix: $suffix, tax_number: $tax_number, tax_rate: $tax_rate, title: $title, websites: $websites} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Tax Rates
#
# GET /accounting/tax-rates
# operationId: taxRatesAll
export def "accounting-tax-rates taxRatesAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --filter: record # Apply filters (e.g. {assets: true, equity: true, expenses: true, liabilities: true, revenue: true})
  --pass-through: record # Optional unmapped key/values that will be passed through to downstream as query parameters
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "deepObject") (serialize-qp "pass_through" $pass_through "deepObject") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/tax-rates" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Tax Rate
#
# POST /accounting/tax-rates
# operationId: taxRatesAdd
# --components item shape: {compound?: bool, id?: string, name?: string, rate?: float}
export def "accounting-tax-rates taxRatesAdd" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --code: string # Tax code assigned to identify this tax rate. (nullable, e.g. ABN)
  --components: list # nullable — item shape: {compound?: bool, id?: string, name?: string, rate?: float}
  --description: string # Description of tax rate (nullable, e.g. Reduced rate GST Purchases)
  --effective-tax-rate: float # Effective tax rate (nullable, e.g. 10)
  --id: string # ID assigned to identify this tax rate. (nullable, e.g. 1234)
  --name: string # Name assigned to identify this tax rate. (e.g. GST on Purchases)
  --original-tax-rate-id: string # ID of the original tax rate from which the new tax rate is derived. Helps to understand the relationship between corresponding tax rate entities. (nullable, e.g. 12345)
  --report-tax-type: string # Report Tax type to aggregate tax collected or paid for reporting purposes (nullable, e.g. NONE)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-3 # Tax rate status (nullable, e.g. active)
  --tax-payable-account-id: string # Unique identifier for the account for tax collected. (nullable, e.g. 123456)
  --tax-remitted-account-id: string # Unique identifier for the account for tax remitted. (nullable, e.g. 123456)
  --total-tax-rate: float # Not compounded sum of the components of a tax rate (nullable, e.g. 10)
  --type: string # Tax type used to indicate the source of tax collected or paid (nullable, e.g. NONE)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/tax-rates" $qp)
  let body = {code: $code, components: $components, description: $description, effective_tax_rate: $effective_tax_rate, id: $id, name: $name, original_tax_rate_id: $original_tax_rate_id, report_tax_type: $report_tax_type, row_version: $row_version, status: $status, tax_payable_account_id: $tax_payable_account_id, tax_remitted_account_id: $tax_remitted_account_id, total_tax_rate: $total_tax_rate, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Tax Rate
#
# DELETE /accounting/tax-rates/{id}
# operationId: taxRatesDelete
export def "accounting-tax-rates taxRatesDelete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/tax-rates/($id)" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Tax Rate
#
# GET /accounting/tax-rates/{id}
# operationId: taxRatesOne
export def "accounting-tax-rates taxRatesOne" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --qp-fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. <br /><br />Example: `fields=name,email,addresses.city`<br /><br />In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/tax-rates/($id)" $qp)
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Tax Rate
#
# PATCH /accounting/tax-rates/{id}
# operationId: taxRatesUpdate
# --components item shape: {compound?: bool, id?: string, name?: string, rate?: float}
export def "accounting-tax-rates taxRatesUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-raw: string@bool-completer # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  --code: string # Tax code assigned to identify this tax rate. (nullable, e.g. ABN)
  --components: list # nullable — item shape: {compound?: bool, id?: string, name?: string, rate?: float}
  --description: string # Description of tax rate (nullable, e.g. Reduced rate GST Purchases)
  --effective-tax-rate: float # Effective tax rate (nullable, e.g. 10)
  --body-id: string # ID assigned to identify this tax rate. (nullable, e.g. 1234)
  --name: string # Name assigned to identify this tax rate. (e.g. GST on Purchases)
  --original-tax-rate-id: string # ID of the original tax rate from which the new tax rate is derived. Helps to understand the relationship between corresponding tax rate entities. (nullable, e.g. 12345)
  --report-tax-type: string # Report Tax type to aggregate tax collected or paid for reporting purposes (nullable, e.g. NONE)
  --row-version: string # A binary value used to detect updates to a object and prevent data conflicts. It is incremented each time an update is made to the object. (nullable, e.g. 1-12345)
  --status: string@status-completer-3 # Tax rate status (nullable, e.g. active)
  --tax-payable-account-id: string # Unique identifier for the account for tax collected. (nullable, e.g. 123456)
  --tax-remitted-account-id: string # Unique identifier for the account for tax remitted. (nullable, e.g. 123456)
  --total-tax-rate: float # Not compounded sum of the components of a tax rate (nullable, e.g. 10)
  --type: string # Tax type used to indicate the source of tax collected or paid (nullable, e.g. NONE)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounting/tax-rates/($id)" $qp)
  let body = {code: $code, components: $components, description: $description, effective_tax_rate: $effective_tax_rate, id: $body_id, name: $name, original_tax_rate_id: $original_tax_rate_id, report_tax_type: $report_tax_type, row_version: $row_version, status: $status, tax_payable_account_id: $tax_payable_account_id, tax_remitted_account_id: $tax_remitted_account_id, total_tax_rate: $total_tax_rate, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
