# Auto-generated client for Paystack v1.0.0
# Source: https://raw.githubusercontent.com/PaystackOSS/openapi/main/dist/paystack.yaml
# Auth: --token flag or $env.PAYSTACK_TOKEN

const BASE_URL = "https://api.paystack.co"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PAYSTACK_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.paystack.co"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def currency-completer [] { ["GHS" "KES" "NGN" "USD" "ZAR"] }
def bearer-completer [] { ["account" "subaccount"] }
def status-completer [] { ["abandoned" "failed" "reversed" "success"] }
def source-completer [] { ["checkout" "merchantApi" "pos" "virtualTerminal"] }
def channel-completer [] { ["bank" "bank_transfer" "card" "dedicated_nuban" "pos" "ussd"] }
def status-completer-1 [] { ["abandoned" "all" "failed" "reversed" "success"] }
def status-completer-2 [] { ["active" "complete" "paused"] }
def status-completer-3 [] { ["error" "failed" "inactive_authorization" "pending" "success"] }
def type-completer [] { ["flat" "percentage"] }
def currency-completer-1 [] { ["GHS" "NGN" "USD" "ZAR"] }
def bearer-type-completer [] { ["account" "all" "all-proportional" "subaccount"] }
def type-completer-1 [] { ["invoice" "transaction"] }
def action-completer [] { ["print" "process" "view"] }
def risk-action-completer [] { ["allow" "default" "deny"] }
def channel-completer-1 [] { ["direct_debit"] }
def status-completer-4 [] { ["active" "pending" "revoked"] }
def currency-completer-2 [] { ["GHS" "NGN"] }
def country-completer [] { ["GH" "NG"] }
def interval-completer [] { ["annually" "biannually" "daily" "monthly" "weekly"] }
def type-completer-2 [] { ["authorization" "basa" "ghipss" "mobile_money" "nuban"] }
def currency-completer-3 [] { ["GHS" "KES" "NGN" "ZAR"] }
def status-completer-5 [] { ["abandoned" "blocked" "failed" "otp" "pending" "received" "rejected" "reversed" "success"] }
def reason-completer [] { ["disable_otp" "resend_otp" "transfer"] }
def status-completer-6 [] { ["draft" "failed" "pending" "success"] }
def status-completer-7 [] { ["active" "inactive"] }
def type-completer-3 [] { ["payment" "plan" "product" "subscription"] }
def status-completer-8 [] { ["awaiting-bank-feedback" "awaiting-merchant-feedback" "pending" "resolved"] }
def country-completer-1 [] { ["ghana" "kenya" "nigeria" "south africa"] }
def gateway-completer [] { ["digitalbankmandate" "emandate"] }
def type-completer-4 [] { ["basa" "ghipps" "kepss" "mobile_money" "nuban"] }
def account-type-completer [] { ["business" "personal"] }
def document-type-completer [] { ["businessRegistrationNumber" "identityNumber" "passportNumber"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "transaction-initialize initialize" } } | get name | first)
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

# Initialize Transaction
#
# POST /transaction/initialize
# operationId: transaction_initialize
# --split shape: {name: string, type: "percentage"|"flat", subaccounts: list, currency: "NGN"|"GHS"|"ZAR"|"USD", bearer_type?: "subaccount"|"account"|"all-proportional"|"all", bearer_subaccount?: string}
export def "transaction-initialize initialize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # Customer's email address
  amount: int # Amount should be in smallest denomination of the currency.
  --currency: string@currency-completer # List of all support currencies (e.g. GHS)
  --reference: string # Unique transaction reference. Only -, ., = and alphanumeric characters allowed.
  --channels: list # An array of payment channels to control what channels you want to make available to the user to make a payment with
  --callback-url: string # Fully qualified url, e.g. https://example.com/ to redirect your customers to after a successful payment. Use this to override the callback url provided on the dashboard for this transaction
  --plan: string # If transaction is to create a subscription to a predefined plan, provide plan code here.  This would invalidate the value provided in amount
  --invoice-limit: int # Number of times to charge customer during subscription to plan
  --split-code: string # The split code of the transaction split
  --body-split: record # Split configuration for transactions  (e.g. {name: Halfsies, type: percentage, currency: NGN, subaccounts: [{subaccount: ACCT_6uujpqtzmnufzkw, share: 50}]}) — shape: {name: string, type: "percentage"|"flat", subaccounts: list, currency: "NGN"|"GHS"|"ZAR"|"USD", bearer_type?: "subaccount"|"account"|"all-proportional"|"all", bearer_subaccount?: string}
  --subaccount: string # The code for the subaccount that owns the payment
  --transaction-charge: string # A flat fee to charge the subaccount for a transaction.  This overrides the split percentage set when the subaccount was created
  --bearer: string@bearer-completer # The bearer of the transaction charge
  --label: string # Used to replace the email address shown on the Checkout
  --metadata: record # JSON object of custom data
]: any -> record<status: bool, message: string, data: record<authorization_url: string, access_code: string, reference: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transaction/initialize")
  let body = {email: $email, amount: $amount, currency: $currency, reference: $reference, channels: $channels, callback_url: $callback_url, plan: $plan, invoice_limit: $invoice_limit, split_code: $split_code, split: $body_split, subaccount: $subaccount, transaction_charge: $transaction_charge, bearer: $bearer, label: $label, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Charge Authorization
#
# POST /transaction/charge_authorization
# operationId: transaction_chargeAuthorization
# --split shape: {name: string, type: "percentage"|"flat", subaccounts: list, currency: "NGN"|"GHS"|"ZAR"|"USD", bearer_type?: "subaccount"|"account"|"all-proportional"|"all", bearer_subaccount?: string}
export def "transaction-charge-authorization chargeAuthorization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # Customer's email address
  amount: int # Amount in the lower denomination of your currency
  authorization_code: string # Valid authorization code to charge
  --reference: string # Unique transaction reference. Only -, ., = and alphanumeric characters allowed.
  --currency: string@currency-completer # List of all support currencies (e.g. GHS)
  --split-code: string # The split code of the transaction split
  --body-split: record # Split configuration for transactions  (e.g. {name: Halfsies, type: percentage, currency: NGN, subaccounts: [{subaccount: ACCT_6uujpqtzmnufzkw, share: 50}]}) — shape: {name: string, type: "percentage"|"flat", subaccounts: list, currency: "NGN"|"GHS"|"ZAR"|"USD", bearer_type?: "subaccount"|"account"|"all-proportional"|"all", bearer_subaccount?: string}
  --subaccount: string # The code for the subaccount that owns the payment
  --transaction-charge: string # A flat fee to charge the subaccount for a transaction.  This overrides the split percentage set when the subaccount was created
  --bearer: string@bearer-completer # The bearer of the transaction charge
  --metadata: string # Stringified JSON object of custom data
  --queue: oneof<nothing, bool> # If you are making a scheduled charge call, it is a good idea to queue them so the processing system does not get overloaded causing transaction processing errors.
]: any -> record<status: bool, message: string, data: record<amount: int, currency: string, transaction_date: string, status: string, reference: string, domain: string, metadata: string, gateway_response: string, message: string, channel: string, ip_address: any, log: record<start_time: int, time_spent: int, attempts: int, errors: int, success: bool, mobile: bool, input: list, history: list>, fees: int, authorization: record<authorization_code: string, bin: string, last4: string, exp_month: string, exp_year: string, channel: string, card_type: string, bank: string, country_code: string, brand: string, reusable: bool, signature: string, account_name: any>, customer: record<id: int, first_name: string, last_name: string, email: string, customer_code: string, phone: string, metadata: record, risk_action: string, international_format_phone: string>, plan: any, id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transaction/charge_authorization")
  let body = {email: $email, amount: $amount, authorization_code: $authorization_code, reference: $reference, currency: $currency, split_code: $split_code, split: $body_split, subaccount: $subaccount, transaction_charge: $transaction_charge, bearer: $bearer, metadata: $metadata, queue: $queue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partial Debit
#
# POST /transaction/partial_debit
# operationId: transaction_partialDebit
export def "transaction-partial-debit partialDebit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # Customer's email address
  amount: int # Specified in the lowest denomination of your currency (format: int64)
  authorization_code: string # Valid authorization code to charge
  currency: string@currency-completer # List of all support currencies (e.g. GHS)
  --at-least: string # Minimum amount to charge
  --reference: string # Unique transaction reference. Only -, ., = and alphanumeric characters allowed.
]: any -> record<status: bool, message: string, data: record<amount: int, currency: string, transaction_date: string, status: string, reference: string, domain: string, metadata: string, gateway_response: string, message: any, channel: string, ip_address: any, log: record<start_time: int, time_spent: int, attempts: int, errors: int, success: bool, mobile: bool, input: list, history: list>, fees: int, authorization: record<authorization_code: string, bin: string, last4: string, exp_month: string, exp_year: string, channel: string, card_type: string, bank: string, country_code: string, brand: string, reusable: bool, signature: string, account_name: any>, customer: record<id: int, first_name: string, last_name: string, email: string, customer_code: string, phone: string, metadata: record, risk_action: string, international_format_phone: string>, plan: int, requested_amount: int, id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transaction/partial_debit")
  let body = {email: $email, amount: $amount, authorization_code: $authorization_code, currency: $currency, at_least: $at_least, reference: $reference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Verify Transaction
#
# GET /transaction/verify/{reference}
# operationId: transaction_verify
export def "transaction-verify verify" [
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: bool, message: string, data: record<id: int, domain: string, status: string, reference: string, receipt_number: string, amount: int, message: string, gateway_response: string, paid_at: string, created_at: string, channel: string, currency: string, ip_address: string, metadata: any, log: record<start_time: int, time_spent: int, attempts: int, errors: int, success: bool, mobile: bool, input: list, history: list>, fees: int, fees_split: any, authorization: record<authorization_code: string, bin: any, last4: string, exp_month: string, exp_year: string, channel: string, card_type: string, bank: string, country_code: string, brand: string, reusable: bool, signature: string, account_name: any, receiver_bank_account_number: any, receiver_bank: any>, customer: record<id: int, first_name: string, last_name: string, email: string, customer_code: string, phone: string, metadata: any, risk_action: string, international_format_phone: string>, plan: string, split: record, order_id: any, paidAt: string, createdAt: string, requested_amount: int, pos_transaction_data: any, source: any, fees_breakdown: any, connect: any, transaction_date: string, plan_object: record<id: int, name: string, plan_code: string, description: any, amount: int, interval: string, send_invoices: bool, send_sms: bool, currency: string>, subaccount: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transaction/verify/($reference)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Transactions
#
# GET /transaction
# operationId: transaction_list
export def "transaction list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --use-cursor: oneof<nothing, bool> # A flag to indicate if cursor based pagination should be used (e.g. true)
  --next: string # An alphanumeric value returned for every cursor based retrieval, used to retrieve the next set of data
  --previous: string # An alphanumeric value returned for every cursor based retrieval, used to retrieve the previous set of data
  --per-page: int # The number of records to fetch per request
  --page: int # The offset to retrieve data from
  --qp-from: string # The start date (format: date-time)
  --qp-to: string # The end date (format: date-time)
  --status: string@status-completer # Filter transaction by status
  --qp-source: string@source-completer # The origin of the payment
  --terminal-id: string # Filter transactions by a terminal ID
  --virtual-account-number: string # Filter transactions by a virtual account number
  --customer-code: string # Filter transactions by a customer code
  --amount: int # Filter transactions by a specific amount (format: int64)
  --settlement: int # The settlement ID to filter for settled transactions (format: int64)
  --channel: string@channel-completer # The payment method the customer used to complete the transaction
  --subaccount-code: string # Filter transaction by subaccount code
  --split-code: string # Filter transaction by split code
]: nothing -> record<status: bool, message: string, data: table<id: int, domain: string, status: string, reference: string, amount: int, message: any, gateway_response: string, paid_at: string, created_at: string, channel: string, currency: string, ip_address: string, metadata: record, log: record, fees: int, fees_split: int, customer: record, authorization: record, plan: record, split: record, subaccount: record, order_id: any, paidAt: string, createdAt: string, requested_amount: int, source: record, connect: record, pos_transaction_data: any>, meta: record<total: int, total_volume: float, skipped: int, perPage: any, page: int, pageCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "use_cursor" $use_cursor "scalar") (serialize-qp "next" $next "scalar") (serialize-qp "previous" $previous "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "terminal_id" $terminal_id "scalar") (serialize-qp "virtual_account_number" $virtual_account_number "scalar") (serialize-qp "customer_code" $customer_code "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "settlement" $settlement "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "subaccount_code" $subaccount_code "scalar") (serialize-qp "split_code" $split_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transaction" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Transaction
#
# GET /transaction/{id}
# operationId: transaction_fetch
export def "transaction fetch" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: bool, message: string, data: record<id: int, domain: string, status: string, reference: string, receipt_number: any, amount: int, message: any, gateway_response: string, helpdesk_link: any, paid_at: string, created_at: string, channel: string, currency: string, ip_address: string, metadata: record<custom_fields: list>, log: record<start_time: int, time_spent: int, attempts: int, errors: int, success: bool, mobile: bool, input: list, history: list>, fees: int, fees_split: int, authorization: record<authorization_code: string, bin: string, last4: string, exp_month: string, exp_year: string, channel: string, card_type: string, bank: string, country_code: string, brand: string, reusable: bool, signature: string, account_name: any, receiver_bank_account_number: any, receiver_bank: any>, customer: record<id: int, first_name: string, last_name: string, email: string, customer_code: string, phone: string, metadata: record, risk_action: string, international_format_phone: string>, plan: record, subaccount: record, split: record, order_id: any, paidAt: string, createdAt: string, requested_amount: int, pos_transaction_data: any, source: record<type: string, source: string, identifier: any>, fees_breakdown: any, connect: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transaction/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Transaction Timeline
#
# GET /transaction/timeline/{id}
# operationId: transaction_timeline
export def "transaction-timeline timeline" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: bool, message: string, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transaction/timeline/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Transaction Totals
#
# GET /transaction/totals
# operationId: transaction_totals
export def "transaction-totals totals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # The start date (format: date-time, e.g. 2024-06-01T00:00:01Z)
  --qp-to: string # The end date (format: date-time, e.g. 2024-06-30T13:36:54Z)
]: nothing -> record<status: bool, message: string, data: record<total_transactions: int, total_volume: int, total_volume_by_currency: list<record>, pending_transfers: int, pending_transfers_by_currency: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transaction/totals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export Transactions
#
# GET /transaction/export
# operationId: transaction_export
export def "transaction-export export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # The start date (format: date-time, e.g. 2024-06-01T00:00:01Z)
  --qp-to: string # The end date (format: date-time, e.g. 2024-06-30T13:36:54Z)
  --status: string@status-completer-1 # Filter by the status of the transaction (e.g. success)
  --customer: float # Filter by customer ID (e.g. 123172416)
  --subaccount-code: string # Filter by subaccount code (e.g. ACCT_dskvlw3y3dMukmt)
  --settlement: int # Filter by the settlement ID (format: int64, e.g. 5687910)
]: nothing -> record<status: bool, message: string, data: record<path: string, expiresAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "customer" $customer "scalar") (serialize-qp "subaccount_code" $subaccount_code "scalar") (serialize-qp "settlement" $settlement "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transaction/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Charge
#
# POST /charge
# operationId: charge_create
# --bank shape: {code?: string, account_number?: string}
# --mobile_money shape: {phone?: string, provider?: string}
# --ussd shape: {type?: "737"|"919"|"822"|"966"}
# --eft shape: {provider?: string}
export def "charge create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # Customer's email address
  amount: int # Amount should be in kobo if currency is NGN, pesewas, if currency is GHS, and cents, if currency is ZAR
  --authorization-code: string # An authorization code to charge.
  --pin: string # 4-digit PIN (send with a non-reusable authorization code)
  --reference: string # Unique transaction reference. Only -, .`, = and alphanumeric characters allowed.
  --birthday: string # The customer's birthday in the format YYYY-MM-DD e.g 2017-05-16 (format: date)
  --device-id: string # This is the unique identifier of the device a user uses in making payment.  Only -, .`, = and alphanumeric characters are allowed.
  --metadata: record # JSON object of custom data
  --bank: record # The bank object if charging a bank account — shape: {code?: string, account_number?: string}
  --mobile-money: record # Details of the mobile service provider — shape: {phone?: string, provider?: string}
  --ussd: record # The USSD code for the provider to charge — shape: {type?: "737"|"919"|"822"|"966"}
  --eft: record # Details of the EFT provider — shape: {provider?: string}
]: any -> record<status: bool, message: string, data: record<id: int, domain: string, status: string, reference: string, receipt_number: any, amount: int, message: string, gateway_response: string, paid_at: string, created_at: string, channel: string, currency: string, ip_address: string, metadata: record<custom_fields: list>, log: record<start_time: int, time_spent: int, attempts: int, errors: int, success: bool, mobile: bool, input: list, history: list>, fees: int, fees_split: int, authorization: record<authorization_code: string, bin: string, last4: string, exp_month: string, exp_year: string, channel: string, card_type: string, bank: string, country_code: string, brand: string, reusable: bool, signature: string, account_name: any, receiver_bank_account_number: any, receiver_bank: any>, customer: record<id: int, first_name: string, last_name: string, email: string, customer_code: string, phone: string, metadata: record, risk_action: string, international_format_phone: string>, plan: any, split: record, order_id: any, paidAt: string, createdAt: string, requested_amount: int, pos_transaction_data: any, source: any, fees_breakdown: any, connect: any, transaction_date: string, plan_object: record, subaccount: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charge")
  let body = {email: $email, amount: $amount, authorization_code: $authorization_code, pin: $pin, reference: $reference, birthday: $birthday, device_id: $device_id, metadata: $metadata, bank: $bank, mobile_money: $mobile_money, ussd: $ussd, eft: $eft} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Submit PIN
#
# POST /charge/submit_pin
# operationId: charge_submitPin
export def "charge-submit-pin submitPin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  pin: string # Customer's PIN for the ongoing transaction
  reference: string # Transaction reference that requires the PIN
]: any -> record<status: bool, message: string, data: record<status: string, amount: int, currency: string, transaction_date: string, reference: string, domain: string, redirect_url: string, metadata: record, gateway_response: string, message: string, channel: string, fees: int, authorization: record<authorization_code: string, bin: string, last4: string, exp_month: string, exp_year: string, channel: string, card_type: string, bank: string, country_code: string, brand: string, reusable: bool, signature: string>, customer: record<first_name: string, last_name: string, email: string, customer_code: string, phone: string, risk_action: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charge/submit_pin")
  let body = {pin: $pin, reference: $reference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Submit OTP
#
# POST /charge/submit_otp
# operationId: charge_submitOtp
export def "charge-submit-otp submitOtp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  otp: string # Customer's OTP for ongoing transaction
  reference: string # The reference of the ongoing transaction
]: any -> record<status: bool, message: string, data: record<status: string, amount: int, currency: string, transaction_date: string, reference: string, domain: string, redirect_url: string, metadata: record, gateway_response: string, message: string, channel: string, fees: int, authorization: record<authorization_code: string, bin: string, last4: string, exp_month: string, exp_year: string, channel: string, card_type: string, bank: string, country_code: string, brand: string, reusable: bool, signature: string>, customer: record<first_name: string, last_name: string, email: string, customer_code: string, phone: string, risk_action: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charge/submit_otp")
  let body = {otp: $otp, reference: $reference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Submit Phone
#
# POST /charge/submit_phone
# operationId: charge_submitPhone
export def "charge-submit-phone submitPhone" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  phone: string # Customer's mobile number
  reference: string # The reference of the ongoing transaction
]: any -> record<status: bool, message: string, data: record<status: string, amount: int, currency: string, transaction_date: string, reference: string, domain: string, redirect_url: string, metadata: record, gateway_response: string, message: string, channel: string, fees: int, authorization: record<authorization_code: string, bin: string, last4: string, exp_month: string, exp_year: string, channel: string, card_type: string, bank: string, country_code: string, brand: string, reusable: bool, signature: string>, customer: record<first_name: string, last_name: string, email: string, customer_code: string, phone: string, risk_action: string>, display_text: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charge/submit_phone")
  let body = {phone: $phone, reference: $reference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Submit Birthday
#
# POST /charge/submit_birthday
# operationId: charge_submitBirthday
export def "charge-submit-birthday submitBirthday" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  birthday: string # Customer's birthday in the format YYYY-MM-DD e.g 2016-09-21 (format: date)
  reference: string # The reference of the ongoing transaction
]: any -> record<status: bool, message: string, data: record<status: string, display_text: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charge/submit_birthday")
  let body = {birthday: $birthday, reference: $reference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Submit Address
#
# POST /charge/submit_address
# operationId: charge_submitAddress
export def "charge-submit-address submitAddress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  address: string # Customer's address
  city: string # Customer's city
  state: string # Customer's state
  zip_code: string # Customer's zipcode
  reference: string # The reference of the ongoing transaction
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/charge/submit_address")
  let body = {address: $address, city: $city, state: $state, zip_code: $zip_code, reference: $reference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check pending charge
#
# GET /charge/{reference}
# operationId: charge_check
export def "charge check" [
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: bool, message: string, data: record<status: string, amount: int, currency: string, transaction_date: string, reference: string, domain: string, redirect_url: string, metadata: record, gateway_response: string, message: string, channel: string, fees: int, authorization: record<authorization_code: string, bin: string, last4: string, exp_month: string, exp_year: string, channel: string, card_type: string, bank: string, country_code: string, brand: string, reusable: bool, signature: string>, customer: record<first_name: string, last_name: string, email: string, customer_code: string, phone: string, risk_action: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/charge/($reference)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initiate Bulk Charge
#
# POST /bulkcharge
# operationId: bulkCharge_initiate
export def "bulkcharge initiate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<status: bool, message: string, data: record<batch_code: string, reference: string, id: int, integration: int, domain: string, status: string, total_charges: int, pending_charges: int, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bulkcharge")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Bulk Charge Batches
#
# GET /bulkcharge
# operationId: bulkCharge_list
export def "bulkcharge list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --perPage: int # Number of records to fetch per page
  --page: int # The offset to retrieve data from
  --status: string@status-completer-2 # Filter by the status of the charges
]: nothing -> record<status: bool, message: string, data: table<integration: int, domain: string, batch_code: string, status: string, easy_cron_id: any, reference: string, id: int, createdAt: string, updatedAt: string>, meta: record<total: int, skipped: int, perPage: any, page: int, pageCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bulkcharge" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Bulk Charge Batch
#
# GET /bulkcharge/{code}
# operationId: bulkCharge_fetch
export def "bulkcharge fetch" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: bool, message: string, data: record<batch_code: string, reference: string, id: int, integration: int, domain: string, status: string, total_charges: int, pending_charges: int, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bulkcharge/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Charges in a Batch
#
# GET /bulkcharge/{code}/charges
# operationId: bulkCharge_charges
export def "bulkcharge-charges charges" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --perPage: int # Number of records to fetch per page
  --page: int # The offset to retrieve data from
  --status: string@status-completer-3 # Filter by the status of the charges
]: nothing -> record<status: bool, message: string, data: table<integration: int, bulkcharge: int, customer: record, authorization: record, domain: string, amount: int, at_least: int, currency: string, reference: string, metadata: record, status: string, message: string, attempt_partial_debit: bool, id: int, createdAt: string, updatedAt: string>, meta: record<perPage: string, total: int, skipped: int, page: int, pageCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/bulkcharge/($code)/charges" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pause Bulk Charge Batch
#
# GET /bulkcharge/pause/{code}
# operationId: bulkCharge_pause
export def "bulkcharge-pause pause" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: bool, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bulkcharge/pause/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resume Bulk Charge Batch
#
# GET /bulkcharge/resume/{code}
# operationId: bulkCharge_resume
export def "bulkcharge-resume resume" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: bool, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bulkcharge/resume/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Subaccount
#
# POST /subaccount
# operationId: subaccount_create
export def "subaccount create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  business_name: string # Name of business for subaccount
  settlement_bank: string # Bank code for the bank. You can get the list of Bank Codes by calling the List Banks endpoint.
  account_number: string # Bank account number
  percentage_charge: float # Customer's phone number (format: float)
  --description: string # A description for this subaccount
  --primary-contact-email: string # A contact email for the subaccount
  --primary-contact-name: string # The name of the contact person for this subaccount
  --primary-contact-phone: string # A phone number to call for this subaccount
  --metadata: string # Stringified JSON object of custom data
]: any -> record<status: bool, message: string, data: record<business_name: string, account_name: string, description: string, primary_contact_name: string, primary_contact_email: string, primary_contact_phone: string, metadata: string, account_number: string, percentage_charge: float, settlement_bank: string, currency: string, bank: int, integration: int, domain: string, product: string, managed_by_integration: int, subaccount_code: string, is_verified: bool, settlement_schedule: string, active: bool, migrate: bool, id: int, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subaccount")
  let body = {business_name: $business_name, settlement_bank: $settlement_bank, account_number: $account_number, percentage_charge: $percentage_charge, description: $description, primary_contact_email: $primary_contact_email, primary_contact_name: $primary_contact_name, primary_contact_phone: $primary_contact_phone, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Subaccounts
#
# GET /subaccount
# operationId: subaccount_list
export def "subaccount list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --perPage: int # Number of records to fetch per request (default: 50)
  --page: int # The offset to retrieve data from (default: 1)
  --active: oneof<nothing, bool> # Filter by the state of the subaccounts
]: nothing -> record<status: bool, message: string, data: table<id: int, subaccount_code: string, business_name: string, description: string, primary_contact_name: string, primary_contact_email: string, primary_contact_phone: string, metadata: string, percentage_charge: float, settlement_bank: string, bank_id: int, account_number: string, currency: string, active: int, is_verified: bool>, meta: record<total: int, skipped: int, perPage: int, page: int, pageCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subaccount" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Subaccount
#
# GET /subaccount/{code}
# operationId: subaccount_fetch
export def "subaccount fetch" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: bool, message: string, data: record<integration: int, account_name: string, bank: int, managed_by_integration: int, domain: string, subaccount_code: string, business_name: string, description: string, primary_contact_name: string, primary_contact_email: string, primary_contact_phone: string, metadata: string, percentage_charge: float, is_verified: bool, settlement_bank: string, account_number: string, settlement_schedule: string, active: bool, migrate: bool, currency: string, product: string, id: int, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subaccount/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Subaccount
#
# PUT /subaccount/{code}
# operationId: subaccount_update
export def "subaccount update" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --business-name: string # Name of business for subaccount
  --settlement-bank: string # Bank code for the bank. You can get the list of Bank Codes by calling the List Banks endpoint.
  --account-number: string # Bank account number
  --active: oneof<nothing, bool> # Activate or deactivate a subaccount
  --percentage-charge: float # Customer's phone number (format: float)
  --description: string # A description for this subaccount
  --primary-contact-email: string # A contact email for the subaccount
  --primary-contact-name: string # The name of the contact person for this subaccount
  --primary-contact-phone: string # A phone number to call for this subaccount
  --metadata: string # Stringified JSON object of custom data
]: any -> record<status: bool, message: string, data: record<domain: string, subaccount_code: string, account_name: string, business_name: string, description: string, primary_contact_name: string, primary_contact_email: string, primary_contact_phone: string, metadata: string, percentage_charge: float, is_verified: bool, settlement_bank: string, account_number: string, settlement_schedule: string, active: bool, migrate: bool, currency: string, product: string, id: int, integration: int, bank: int, managed_by_integration: int, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subaccount/($code)")
  let body = {business_name: $business_name, settlement_bank: $settlement_bank, account_number: $account_number, active: $active, percentage_charge: $percentage_charge, description: $description, primary_contact_email: $primary_contact_email, primary_contact_name: $primary_contact_name, primary_contact_phone: $primary_contact_phone, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Split
#
# POST /split
# operationId: split_create
# --subaccounts item shape: {subaccount?: string, share?: int}
export def "split create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the transaction split
  type: string@type-completer # The type of transaction split you want to create.
  subaccounts: list # A list of object containing subaccount code and number of shares — item shape: {subaccount?: string, share?: int}
  currency: string@currency-completer-1 # The transaction currency
  --bearer-type: string@bearer-type-completer # This allows you specify how the transaction charge should be processed
  --bearer-subaccount: string # This is the subaccount code of the customer or partner that would bear the transaction charge if you specified subaccount as the bearer type
]: any -> record<status: bool, message: string, data: record<id: int, name: string, type: string, currency: string, integration: int, domain: string, split_code: string, active: bool, bearer_type: string, bearer_subaccount: int, createdAt: string, updatedAt: string, is_dynamic: bool, subaccounts: list<record>, total_subaccounts: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/split")
  let body = {name: $name, type: $type, subaccounts: $subaccounts, currency: $currency, bearer_type: $bearer_type, bearer_subaccount: $bearer_subaccount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Splits
#
# GET /split
# operationId: split_list
export def "split list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subaccount-code: string # Filter by subaccount code (e.g. ACCT_dskvlw3y3dMukmt)
  --name: string # The name of the split
  --active: oneof<nothing, bool> # The status of the split
  --per-page: int # The number of records to fetch per request
  --page: int # The offset to retrieve data from
  --qp-from: string # The start date (format: date-time)
  --qp-to: string # The end date (format: date-time)
]: nothing -> record<status: bool, message: string, data: table<id: int, name: string, type: string, currency: string, integration: int, domain: string, split_code: string, active: bool, bearer_type: string, bearer_subaccount: int, createdAt: string, updatedAt: string, is_dynamic: bool, subaccounts: list, total_subaccounts: int>, meta: record<total: int, skipped: int, perPage: int, page: int, pageCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subaccount_code" $subaccount_code "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/split" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Split
#
# GET /split/{id}
# operationId: split_fetch
export def "split fetch" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: bool, message: string, data: record<id: int, name: string, type: string, currency: string, integration: int, domain: string, split_code: string, active: bool, bearer_type: string, bearer_subaccount: int, createdAt: string, updatedAt: string, is_dynamic: bool, subaccounts: list<record>, total_subaccounts: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/split/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Split
#
# PUT /split/{id}
# operationId: split_update
export def "split update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the transaction split
  --active: oneof<nothing, bool> # Toggle status of split. When true, the split is active, else it's inactive
  --bearer-type: string@bearer-type-completer # This allows you specify how the transaction charge should be processed
  --bearer-subaccount: string # This is the subaccount code of the customer or partner that would bear the transaction charge if you specified subaccount as the bearer type
]: any -> record<status: bool, message: string, data: record<id: int, name: string, type: string, currency: string, integration: int, domain: string, split_code: string, active: bool, bearer_type: string, bearer_subaccount: int, createdAt: string, updatedAt: string, is_dynamic: bool, subaccounts: list<record>, total_subaccounts: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/split/($id)")
  let body = {name: $name, active: $active, bearer_type: $bearer_type, bearer_subaccount: $bearer_subaccount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Subaccount to Split
#
# POST /split/{id}/subaccount/add
# operationId: split_addSubaccount
export def "split-subaccount-add addSubaccount" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subaccount: string # Subaccount code of the customer or partner
  --share: int # The percentage or flat quota of the customer or partner
]: any -> record<status: bool, message: string, data: record<id: int, name: string, type: string, currency: string, integration: int, domain: string, split_code: string, active: bool, bearer_type: string, bearer_subaccount: int, createdAt: string, updatedAt: string, is_dynamic: bool, subaccounts: list<record>, total_subaccounts: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/split/($id)/subaccount/add")
  let body = {subaccount: $subaccount, share: $share} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Subaccount from split
#
# POST /split/{id}/subaccount/remove
# operationId: split_removeSubaccount
export def "split-subaccount-remove removeSubaccount" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subaccount: string # Subaccount code of the customer or partner
  --share: int # The percentage or flat quota of the customer or partner
]: any -> record<status: bool, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/split/($id)/subaccount/remove")
  let body = {subaccount: $subaccount, share: $share} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send Event
#
# POST /terminal/{id}/event
# operationId: terminal_sendEvent
# --data shape: {id?: int, reference?: string}
export def "terminal-event sendEvent" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-1 # The type of event to push
  --action: string@action-completer # The action the Terminal needs to perform. For the invoice type, the action can either be process or view.  For the transaction type, the action can either be process or print.
  --data: record # The parameters needed to perform the specified action (e.g. {id: 7895939, reference: 4634337895939}) — shape: {id?: int, reference?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/terminal/($id)/event")
  let body = {type: $type, action: $action, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch Event Status
#
# GET /terminal/{terminal_id}/event/{event_id}
# operationId: terminal_fetchEventStatus
export def "terminal-event fetchEventStatus" [
  terminal_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/terminal/($terminal_id)/event/($event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Terminal Status
#
# GET /terminal/{terminal_id}/presence
# operationId: terminal_fetchTerminalStatus
export def "terminal-presence fetchTerminalStatus" [
  terminal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/terminal/($terminal_id)/presence")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Terminals
#
# GET /terminal
# operationId: terminal_list
export def "terminal list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --next: string # A cursor that indicates your place in the list. It can be used to fetch the next page of the list
  --previous: string # A cursor that indicates your place in the list. It should be used to fetch the previous page of the list after an intial next request
  --per-page: int # Specify how many records you want to retrieve per page (default: 50)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "next" $next "scalar") (serialize-qp "previous" $previous "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/terminal" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Terminal
#
# GET /terminal/{terminal_id}
# operationId: terminal_fetch
export def "terminal fetch" [
  terminal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/terminal/($terminal_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Terminal
#
# PUT /terminal/{terminal_id}
# operationId: terminal_update
export def "terminal update" [
  terminal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The new name for the Terminal
  --address: string # The new address for the Terminal
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/terminal/($terminal_id)")
  let body = {name: $name, address: $address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Commission Terminal
#
# POST /terminal/commission_device
# operationId: terminal_commission
export def "terminal-commission-device commission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  serial_number: string # Device Serial Number
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/terminal/commission_device")
  let body = {serial_number: $serial_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Decommission Terminal
#
# POST /terminal/decommission_device
# operationId: terminal_decommission
export def "terminal-decommission-device decommission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  serial_number: string # Device Serial Number
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/terminal/decommission_device")
  let body = {serial_number: $serial_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Virtual Terminal
#
# POST /virtual_terminal
# operationId: virtualTerminal_create
# --destinations item shape: {target?: string, name?: string}
export def "virtual-terminal create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the virtual terminal
  destinations: list # Array of objects containing recipients for payment notifications for the Virtual Terminal. — item shape: {target?: string, name?: string}
  --split-code: string # Split code to associate with the virtual terminal
  --metadata: record # Additional custom data as key-value pairs
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/virtual_terminal")
  let body = {name: $name, destinations: $destinations, split_code: $split_code, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Virtual Terminals
#
# GET /virtual_terminal
# operationId: virtualTerminal_list
export def "virtual-terminal list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --perPage: int # The number of records to fetch per request (e.g. 75)
  --page: int # The offset to retrieve data from
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/virtual_terminal" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Virtual Terminal
#
# GET /virtual_terminal/{code}
# operationId: virtualTerminal_fetch
export def "virtual-terminal fetch" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/virtual_terminal/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Virtual Terminal
#
# PUT /virtual_terminal/{code}
# operationId: virtualTerminal_update
export def "virtual-terminal update" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the virtual terminal
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/virtual_terminal/($code)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deactivate Virtual Terminal
#
# PUT /virtual_terminal/{code}/deactivate
# operationId: virtualTerminal_deactivate
export def "virtual-terminal-deactivate deactivate" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/virtual_terminal/($code)/deactivate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign Destination to Virtual Terminal
#
# POST /virtual_terminal/{code}/destination/assign
# operationId: virtualTerminal_destinationAssign
# --destinations item shape: {target?: string, name?: string}
export def "virtual-terminal-destination-assign destinationAssign" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  destinations: list # Array of objects containing recipients for payment notifications for the Virtual Terminal. — item shape: {target?: string, name?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/virtual_terminal/($code)/destination/assign")
  let body = {destinations: $destinations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unassign Destination from Virtual Terminal
#
# POST /virtual_terminal/{code}/destination/unassign
# operationId: virtualTerminal_destinationUnassign
export def "virtual-terminal-destination-unassign destinationUnassign" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  targets: list # Array of destination targets to unassign
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/virtual_terminal/($code)/destination/unassign")
  let body = {targets: $targets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Split Code to Virtual Terminal
#
# PUT /virtual_terminal/{code}/split_code
# operationId: virtualTerminal_addSplitCode
export def "virtual-terminal-split-code addSplitCode" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  split_code: string # The split code to assign to the virtual terminal
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/virtual_terminal/($code)/split_code")
  let body = {split_code: $split_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Split Code from Virtual Terminal
#
# DELETE /virtual_terminal/{code}/split_code
# operationId: virtualTerminal_deleteSplitCode
export def "virtual-terminal-split-code delete" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  split_code: string # The split code to assign to the virtual terminal
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/virtual_terminal/($code)/split_code")
  let body = {split_code: $split_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Customer
#
# POST /customer
# operationId: customer_create
export def "customer create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # Customer's email address
  --first-name: string # Customer's first name
  --last-name: string # Customer's last name
  --phone: string # Customer's phone number
  --metadata: string # Stringified JSON object of custom data
]: any -> record<status: bool, message: string, data: record<transactions: list<any>, subscriptions: list<any>, authorizations: list<any>, email: string, first_name: string, last_name: string, phone: string, integration: int, domain: string, metadata: record<calling_code: string>, customer_code: string, risk_action: string, id: int, createdAt: string, updatedAt: string, identified: bool, identifications: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customer")
  let body = {email: $email, first_name: $first_name, last_name: $last_name, phone: $phone, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Customers
#
# GET /customer
# operationId: customer_list
export def "customer list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --use-cursor: oneof<nothing, bool> # A flag to indicate if cursor based pagination should be used
  --next: string # An alphanumeric value returned for every cursor based retrieval, used to retrieve the next set of data
  --previous: string # An alphanumeric value returned for every cursor based retrieval, used to retrieve the previous set of data
  --qp-from: string # The start date (format: date-time)
  --qp-to: string # The end date (format: date-time)
  --perPage: string # The number of records to fetch per request
  --page: string # The offset to retrieve data from
]: nothing -> record<status: bool, message: string, data: table<integration: int, first_name: string, last_name: string, email: string, phone: string, metadata: record, domain: string, customer_code: string, risk_action: string, id: int, createdAt: string, updatedAt: string>, meta: record<total: int, skipped: int, perPage: any, page: int, pageCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "use_cursor" $use_cursor "scalar") (serialize-qp "next" $next "scalar") (serialize-qp "previous" $previous "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Customer
#
# GET /customer/{code}
# operationId: customer_fetch
export def "customer fetch" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: bool, message: string, data: record<transactions: list<any>, subscriptions: list<any>, authorizations: list<any>, first_name: string, last_name: string, email: string, phone: string, metadata: record<calling_code: string>, domain: string, customer_code: string, risk_action: string, id: int, integration: int, createdAt: string, updatedAt: string, created_at: string, updated_at: string, total_transactions: int, total_transaction_value: list<any>, dedicated_account: any, dedicated_accounts: list<any>, identified: bool, identifications: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customer/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Customer
#
# PUT /customer/{code}
# operationId: customer_update
export def "customer update" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --first-name: string # Customer's first name
  --last-name: string # Customer's last name
  --phone: string # Customer's phone number
  --metadata: string # Stringified JSON object of custom data
]: any -> record<status: bool, message: string, data: record<first_name: string, last_name: string, email: string, phone: string, metadata: record, domain: string, customer_code: string, risk_action: string, id: int, integration: int, createdAt: string, updatedAt: string, identified: bool, identifications: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customer/($code)")
  let body = {first_name: $first_name, last_name: $last_name, phone: $phone, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set Risk Action
#
# POST /customer/set_risk_action
# operationId: customer_riskAction
export def "customer-set-risk-action riskAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  customer: string # The customer code from the response of the customer creation
  --risk-action: string@risk-action-completer # This determines the fraud rules that should be applied to the customer (default: default)
]: any -> record<status: bool, message: string, data: record<transactions: list<any>, subscriptions: list<any>, authorizations: list<any>, first_name: string, last_name: string, email: string, phone: string, metadata: record, domain: string, customer_code: string, risk_action: string, id: int, integration: int, createdAt: string, updatedAt: string, identified: bool, identifications: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customer/set_risk_action")
  let body = {customer: $customer, risk_action: $risk_action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate Customer
#
# POST /customer/{code}/identification
# operationId: customer_validate
export def "customer-identification validate" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  first_name: string # Customer's first name
  --middle-name: string # Customer's middle name
  last_name: string # Customer's last name
  type: string # Predefined types of identification. (default: bank_account)
  --value: string # Customer's identification number.
  country: string # Two-letter country code of identification issuer
  bvn: string # Customer's Bank Verification Number
  bank_code: string # You can get the list of bank codes by calling the List Banks endpoint (https://api.paystack.co/bank).
  account_number: string # Customer's bank account number.
]: any -> record<status: bool, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customer/($code)/identification")
  let body = {first_name: $first_name, middle_name: $middle_name, last_name: $last_name, type: $type, value: $value, country: $country, bvn: $bvn, bank_code: $bank_code, account_number: $account_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Initialize Authorization
#
# POST /customer/authorization/initialize
# operationId: customer_initializeAuthorization
# --account shape: {number: string, bank_code: string}
# --address shape: {street: string, city: string, state: string}
export def "customer-authorization-initialize initializeAuthorization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # Customer's email address (e.g. ravi@demo.com)
  channel: string@channel-completer-1 # direct_debit is the only supported option for now (e.g. direct_debit)
  --callback-url: string # Fully qualified url (e.g. https://example.com/) to redirect your customer to (e.g. http://test.url.com)
  --account: record # shape: {number: string, bank_code: string}
  --address: record # shape: {street: string, city: string, state: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customer/authorization/initialize")
  let body = {email: $email, channel: $channel, callback_url: $callback_url, account: $account, address: $address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Verify Authorization
#
# GET /customer/authorization/verify/{reference}
# operationId: customer_verifyAuthorization
export def "customer-authorization-verify verifyAuthorization" [
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customer/authorization/verify/($reference)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deactivate Authorization
#
# POST /customer/authorization/deactivate
# operationId: customer_deactivateAuthorization
export def "customer-authorization-deactivate deactivateAuthorization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  authorization_code: string # Authorization code to be deactivated
]: any -> record<status: bool, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customer/authorization/deactivate")
  let body = {authorization_code: $authorization_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Initialize Direct Debit
#
# POST /customer/{id}/initialize-direct-debit
# operationId: customer_initializeDirectDebit
# --account shape: {number: string, bank_code: string}
# --address shape: {street: string, city: string, state: string}
export def "customer-initialize-direct-debit initializeDirectDebit" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  account: record # shape: {number: string, bank_code: string}
  address: record # shape: {street: string, city: string, state: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customer/($id)/initialize-direct-debit")
  let body = {account: $account, address: $address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Direct Debit Activation Charge
#
# PUT /customer/{id}/directdebit-activation-charge
# operationId: customer_directDebitActivationCharge
export def "customer-directdebit-activation-charge directDebitActivationCharge" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  authorization_id: int # The authorization ID gotten from the initiation response (e.g. 1069309917)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customer/($id)/directdebit-activation-charge")
  let body = {authorization_id: $authorization_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch Mandate Authorizations
#
# GET /customer/{id}/directdebit-mandate-authorizations
# operationId: customer_fetchMandateAuthorizations
export def "customer-directdebit-mandate-authorizations fetchMandateAuthorizations" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customer/($id)/directdebit-mandate-authorizations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger Activation Charge
#
# PUT /directdebit/activation-charge
# operationId: directdebit_triggerActivationCharge
export def "directdebit-activation-charge triggerActivationCharge" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  customer_ids: list # Array of customer IDs to trigger activation charge for (e.g. [28958104, 983697220])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/directdebit/activation-charge")
  let body = {customer_ids: $customer_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Mandate Authorizations
#
# GET /directdebit/mandate-authorizations
# operationId: directdebit_listMandateAuthorizations
export def "directdebit-mandate-authorizations listMandateAuthorizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # The cursor value of the next set of authorizations to fetch. You can get this from the meta object of the response
  --status: string@status-completer-4 # Filter by the authorization status
  --per-page: int # The number of authorizations to fetch per request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/directdebit/mandate-authorizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Dedicated Account
#
# POST /dedicated_account
# operationId: dedicatedAccount_create
export def "dedicated-account create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  customer: string # The code for the previously created customer
  --preferred-bank: string # The bank slug for preferred bank. To get a list of available banks, use the List Providers endpoint
  --subaccount: string # Subaccount code of the account you want to split the transaction with
  --split-code: string # Split code consisting of the lists of accounts you want to split the transaction with
]: any -> record<status: bool, message: string, data: record<bank: record<name: string, id: int, slug: string>, account_name: string, account_number: string, assigned: bool, currency: string, metadata: any, active: bool, id: int, created_at: string, updated_at: string, assignment: record<integration: int, assignee_id: int, assignee_type: string, expired: bool, account_type: string, assigned_at: string, expired_at: any>, customer: record<id: int, first_name: string, last_name: string, email: string, customer_code: string, phone: string, metadata: record, risk_action: string, international_format_phone: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dedicated_account")
  let body = {customer: $customer, preferred_bank: $preferred_bank, subaccount: $subaccount, split_code: $split_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Dedicated Accounts
#
# GET /dedicated_account
# operationId: dedicatedAccount_list
export def "dedicated-account list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: oneof<nothing, bool> # Status of the dedicated virtual account (e.g. true)
  --customer: int # The customer's ID (e.g. 297346561)
  --currency: string@currency-completer-2 # The currency of the dedicated virtual account
  --provider-slug: string # The bank's slug in lowercase, without spaces (e.g. titan-paystack)
  --bank-id: string # The bank's ID (e.g. 035)
  --perPage: int # The number of records to fetch per request (default: 50)
  --page: int # The offset to retrieve data from (default: 1)
]: nothing -> record<status: bool, message: string, data: table<customer: record, bank: record, id: int, account_name: string, account_number: string, created_at: string, updated_at: string, currency: string, split_config: record, active: bool, assigned: bool>, meta: record<total: int, skipped: int, perPage: int, page: int, pageCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar") (serialize-qp "customer" $customer "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "provider_slug" $provider_slug "scalar") (serialize-qp "bank_id" $bank_id "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dedicated_account" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Assign Dedicated Account
#
# POST /dedicated_account/assign
# operationId: dedicatedAccount_assign
export def "dedicated-account-assign assign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # Customer's email address
  first_name: string # Customer's first name
  last_name: string # Customer's last name
  phone: string # Customer's phone name
  preferred_bank: string # The bank slug for preferred bank. To get a list of available banks,  use the List Banks endpoint, passing `pay_with_bank_transfer=true` query parameter
  country: string@country-completer # The two letter code country
  --account-number: string # Customer's account number
  --bvn: string # Customer's Bank Verification Number
  --bank-code: string # Customer's bank code
  --subaccount: string # Subaccount code of the account you want to split the transaction with
  --split-code: string # Split code consisting of the lists of accounts you want to split the transaction with
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dedicated_account/assign")
  let body = {email: $email, first_name: $first_name, last_name: $last_name, phone: $phone, preferred_bank: $preferred_bank, country: $country, account_number: $account_number, bvn: $bvn, bank_code: $bank_code, subaccount: $subaccount, split_code: $split_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch Dedicated Account
#
# GET /dedicated_account/{id}
# operationId: dedicatedAccount_fetch
export def "dedicated-account fetch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: bool, message: string, data: record<customer: record<id: int, first_name: string, last_name: string, email: string, customer_code: string, phone: string, metadata: record, risk_action: string, international_format_phone: string>, bank: record<name: string, id: int, slug: string>, id: int, account_name: string, account_number: string, created_at: string, updated_at: string, currency: string, split_config: any, active: bool, assigned: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dedicated_account/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deactivate Dedicated Account
#
# DELETE /dedicated_account/{id}
# operationId: dedicatedAccount_deactivate
export def "dedicated-account deactivate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: bool, message: string, data: record<bank: record<name: string, id: int, slug: string>, account_name: string, account_number: string, assigned: bool, currency: string, metadata: any, active: bool, id: int, created_at: string, updated_at: string, assignment: record<assignee_id: int, assignee_type: string, assigned_at: string, integration: int, account_type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dedicated_account/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Requery Dedicated Account
#
# GET /dedicated_account/requery
# operationId: dedicatedAccount_requery
export def "dedicated-account-requery requery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account-number: string # Virtual account number to requery (e.g. 0033322211)
  --provider-slug: string # The bank's slug in lowercase, without spaces. (e.g. titan-paystack)
  --date: string # The day the transfer was made (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account_number" $account_number "scalar") (serialize-qp "provider_slug" $provider_slug "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dedicated_account/requery" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Split Dedicated Account Transaction
#
# POST /dedicated_account/split
# operationId: dedicatedAccount_addSplit
export def "dedicated-account-split addSplit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  account_number: string # Valid Dedicated virtual account
  --subaccount: string # Subaccount code of the account you want to split the transaction with
  --split-code: string # Split code consisting of the lists of accounts you want to split the transaction with
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dedicated_account/split")
  let body = {account_number: $account_number, subaccount: $subaccount, split_code: $split_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Split from Dedicated Account
#
# DELETE /dedicated_account/split
# operationId: dedicatedAccount_removeSplit
export def "dedicated-account-split removeSplit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  account_number: string # Valid Dedicated virtual account
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dedicated_account/split")
  let body = {account_number: $account_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch Bank Providers
#
# GET /dedicated_account/available_providers
# operationId: dedicatedAccount_availableProviders
export def "dedicated-account-available-providers availableProviders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dedicated_account/available_providers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Register Domain
#
# POST /apple-pay/domain
# operationId: applePay_registerDomain
export def "apple-pay-domain registerDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domainName: string # The domain or subdomain for your application
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apple-pay/domain")
  let body = {domainName: $domainName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Domains
#
# GET /apple-pay/domain
# operationId: applePay_listDomain
export def "apple-pay-domain listDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --use-cursor: oneof<nothing, bool> # A flag to indicate if cursor based pagination should be used (e.g. true)
  --next: string # An alphanumeric value returned for every cursor based retrieval, used to retrieve the next set of data
  --previous: string # An alphanumeric value returned for every cursor based retrieval, used to retrieve the previous set of data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "use_cursor" $use_cursor "scalar") (serialize-qp "next" $next "scalar") (serialize-qp "previous" $previous "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apple-pay/domain" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unregister Domain
#
# DELETE /apple-pay/domain
# operationId: applePay_unregisterDomain
export def "apple-pay-domain unregisterDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domainName: string # The domain or subdomain for your application
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/apple-pay/domain")
  let body = {domainName: $domainName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Plan
#
# POST /plan
# operationId: plan_create
export def "plan create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of plan
  amount: int # Amount should be in kobo if currency is NGN, pesewas, if currency is GHS, and cents, if currency is ZAR
  interval: string@interval-completer # Payment interval
  --description: string # A description for this plan
  --send-invoices: oneof<nothing, bool> # Set to false if you don't want invoices to be sent to your customers
  --send-sms: oneof<nothing, bool> # Set to false if you don't want text messages to be sent to your customers
  --currency: string # Currency in which amount is set. Allowed values are NGN, GHS, ZAR or USD
  --invoice-limit: int # Number of invoices to raise during subscription to this plan.  Can be overridden by specifying an invoice_limit while subscribing.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/plan")
  let body = {name: $name, amount: $amount, interval: $interval, description: $description, send_invoices: $send_invoices, send_sms: $send_sms, currency: $currency, invoice_limit: $invoice_limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Plans
#
# GET /plan
# operationId: plan_list
export def "plan list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --perPage: int # Number of records to fetch per page
  --page: int # The section to retrieve
  --interval: string@interval-completer # Specify interval of the plan
  --amount: int # The amount on the plans to retrieve
  --qp-from: string # The start date (format: date-time)
  --qp-to: string # The end date (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "amount" $amount "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/plan" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Plan
#
# GET /plan/{code}
# operationId: plan_fetch
export def "plan fetch" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plan/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Plan
#
# PUT /plan/{code}
# operationId: plan_update
export def "plan update" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of plan
  --amount: int # Amount should be in kobo if currency is NGN, pesewas, if currency is GHS, and cents, if currency is ZAR
  --interval: string@interval-completer # Payment interval
  --description: oneof<nothing, bool> # A description for this plan
  --send-invoices: oneof<nothing, bool> # Set to false if you don't want invoices to be sent to your customers
  --send-sms: oneof<nothing, bool> # Set to false if you don't want text messages to be sent to your customers
  --currency: string # Currency in which amount is set. Allowed values are NGN, GHS, ZAR or USD
  --invoice-limit: int # Number of invoices to raise during subscription to this plan.  Can be overridden by specifying an invoice_limit while subscribing.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/plan/($code)")
  let body = {name: $name, amount: $amount, interval: $interval, description: $description, send_invoices: $send_invoices, send_sms: $send_sms, currency: $currency, invoice_limit: $invoice_limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Subscription
#
# POST /subscription
# operationId: subscription_create
export def "subscription create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  customer: string # Customer's email address or customer code
  plan: string # Plan code
  --authorization: string # If customer has multiple authorizations, you can set the desired authorization you wish to use for this subscription here.  If this is not supplied, the customer's most recent authorization would be used
  --start-date: string # Set the date for the first debit. (ISO 8601 format) e.g. 2017-05-16T00:30:13+01:00 (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscription")
  let body = {customer: $customer, plan: $plan, authorization: $authorization, start_date: $start_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Subscriptions
#
# GET /subscription
# operationId: subscription_list
export def "subscription list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --perPage: int # Number of records to fetch per page
  --page: int # The section to retrieve
  --plan: int # Plan ID (e.g. 2697466)
  --customer: string # Customer ID
  --qp-from: string # The start date (format: date-time)
  --qp-to: string # The end date (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "plan" $plan "scalar") (serialize-qp "customer" $customer "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/subscription" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Subscription
#
# GET /subscription/{code}
# operationId: subscription_fetch
export def "subscription fetch" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscription/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable Subscription
#
# POST /subscription/disable
# operationId: subscription_disable
export def "subscription-disable disable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  code: string # Subscription code
  --body-token: string # Email token
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscription/disable")
  let body = {code: $code, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enable Subscription
#
# POST /subscription/enable
# operationId: subscription_enable
export def "subscription-enable enable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  code: string # Subscription code
  --body-token: string # Email token
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscription/enable")
  let body = {code: $code, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate Update Subscription Link
#
# GET /subscription/{code}/manage/link
# operationId: subscription_manageLink
export def "subscription-manage-link manageLink" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscription/($code)/manage/link")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send Update Subscription Link
#
# POST /subscription/{code}/manage/email
# operationId: subscription_manageEmail
export def "subscription-manage-email manageEmail" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/subscription/($code)/manage/email")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Transfer Recipient
#
# POST /transferrecipient
# operationId: transferrecipient_create
export def "transferrecipient create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-2 # Recipient Type
  name: string # The recipient's name according to their account registration.
  account_number: string # Recipient's bank account number
  bank_code: string # Recipient's bank code. You can get the list of Bank Codes by calling the List Banks endpoint
  --description: string # A description for this recipient
  --currency: string # Currency for the account receiving the transfer
  --authorization-code: string # An authorization code from a previous transaction
  --metadata: record # JSON object of custom data
]: any -> record<status: bool, message: string, data: record<active: bool, createdAt: string, currency: string, description: string, domain: string, email: string, id: int, integration: int, metadata: record, name: string, recipient_code: string, type: string, updatedAt: string, is_deleted: bool, isDeleted: bool, details: record<authorization_code: string, account_number: string, account_name: string, bank_code: string, bank_name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transferrecipient")
  let body = {type: $type, name: $name, account_number: $account_number, bank_code: $bank_code, description: $description, currency: $currency, authorization_code: $authorization_code, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Transfer Recipients
#
# GET /transferrecipient
# operationId: transferrecipient_list
export def "transferrecipient list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --use-cursor: oneof<nothing, bool> # A flag to indicate if cursor based pagination should be used
  --next: string # An alphanumeric value returned for every cursor based retrieval, used to retrieve the next set of data
  --previous: string # An alphanumeric value returned for every cursor based retrieval, used to retrieve the previous set of data
  --per-page: int # The number of records to fetch per request
  --page: int # The offset to retrieve data from
]: nothing -> record<status: bool, message: string, data: table<active: bool, createdAt: string, currency: string, description: string, domain: string, email: string, id: int, integration: int, metadata: record, name: string, recipient_code: string, type: string, updatedAt: string, is_deleted: bool, isDeleted: bool, details: record>, meta: record<total: int, skipped: int, perPage: int, page: int, pageCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "use_cursor" $use_cursor "scalar") (serialize-qp "next" $next "scalar") (serialize-qp "previous" $previous "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transferrecipient" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk Create Transfer Recipient
#
# POST /transferrecipient/bulk
# operationId: transferrecipient_bulk
# --batch item shape: {type: "nuban"|"ghipss"|"mobile_money"|"basa"|"authorization", name: string, account_number: string, bank_code: string, description?: string, currency?: string, authorization_code?: string, metadata?: record}
export def "transferrecipient-bulk bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  batch: list # A list of transfer recipient object. — item shape: {type: "nuban"|"ghipss"|"mobile_money"|"basa"|"authorization", name: string, account_number: string, bank_code: string, description?: string, currency?: string, authorization_code?: string, metadata?: record}
]: any -> record<status: bool, message: string, data: record<success: list<any>, errors: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transferrecipient/bulk")
  let body = {batch: $batch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch Transfer recipient
#
# GET /transferrecipient/{code}
# operationId: transferrecipient_fetch
export def "transferrecipient fetch" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: bool, message: string, data: record<integration: int, domain: string, type: string, currency: string, name: string, details: record<account_number: string, account_name: string, bank_code: string, bank_name: string>, description: string, metadata: record, recipient_code: string, active: bool, recipient_account: string, institution_code: string, email: string, id: int, isDeleted: bool, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transferrecipient/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Transfer Recipient
#
# PUT /transferrecipient/{code}
# operationId: transferrecipient_update
export def "transferrecipient update" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Recipient's name
  --email: string # Recipient's email address
]: any -> record<status: bool, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transferrecipient/($code)")
  let body = {name: $name, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Transfer Recipient
#
# DELETE /transferrecipient/{code}
# operationId: transferrecipient_delete
export def "transferrecipient delete" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: bool, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transferrecipient/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Initiate Transfer
#
# POST /transfer
# operationId: transfer_initiate
export def "transfer initiate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  amount: int # Amount to transfer in kobo if currency is NGN and pesewas if currency is GHS.
  recipient: string # The transfer recipient's code
  reference: string # To ensure idempotency, you need to provide e a unique identifier for the request.  The identifier should be a lowercase alphanumeric string with only -,_  symbols allowed.
  --reason: string # The reason or narration for the transfer.
  --body-source: string # The source of funds to send from (default: balance)
  --currency: string@currency-completer-3 # Specify the currency of the transfer. (default: NGN)
]: any -> record<status: bool, message: string, data: record<transfersessionid: list<any>, transfertrials: list<any>, domain: string, amount: int, currency: string, reference: string, source: string, source_details: any, reason: string, status: string, failures: any, transfer_code: string, titan_code: any, transferred_at: any, id: int, integration: int, request: int, recipient: int, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer")
  let body = {amount: $amount, recipient: $recipient, reference: $reference, reason: $reason, source: $body_source, currency: $currency} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Transfers
#
# GET /transfer
# operationId: transfer_list
export def "transfer list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --use-cursor: oneof<nothing, bool> # A flag to indicate if cursor based pagination should be used (e.g. true)
  --next: string # An alphanumeric value returned for every cursor based retrieval, used to retrieve the next set of data
  --previous: string # An alphanumeric value returned for every cursor based retrieval, used to retrieve the previous set of data
  --per-page: int # The number of records to fetch per request
  --page: int # The offset to retrieve data from
  --qp-from: string # The start date (format: date-time)
  --qp-to: string # The end date (format: date-time)
  --recipient: string # Filter transfer by the recipient code
  --status: string@status-completer-5 # Filter transfer by status (default: pending)
]: nothing -> record<status: bool, message: string, data: table<amount: int, createdAt: string, currency: string, domain: string, failures: any, id: int, integration: int, reason: string, reference: string, source: string, source_details: any, status: string, titan_code: any, transfer_code: string, request: int, transferred_at: any, updatedAt: string, recipient: record, session: record, fee_charged: int, fees_breakdown: int>, meta: record<total: int, skipped: int, perPage: int, page: int, pageCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "use_cursor" $use_cursor "scalar") (serialize-qp "next" $next "scalar") (serialize-qp "previous" $previous "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "recipient" $recipient "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transfer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Finalize Transfer
#
# POST /transfer/finalize_transfer
# operationId: transfer_finalize
export def "transfer-finalize-transfer finalize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  transfer_code: string # The transfer code you want to finalize
  otp: string # OTP sent to business phone to verify transfer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/finalize_transfer")
  let body = {transfer_code: $transfer_code, otp: $otp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Initiate Bulk Transfer
#
# POST /transfer/bulk
# operationId: transfer_bulk
# --transfers item shape: {amount: int, recipient: string, reference: string, reason?: string}
export def "transfer-bulk bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-source: string # The source of funds for the transfer. (default: balance)
  --currency: string@currency-completer-3 # Specify the currency of the transfer. (default: NGN)
  transfers: list # A list of transfer object — item shape: {amount: int, recipient: string, reference: string, reason?: string}
]: any -> record<status: bool, message: string, data: table<reference: string, recipient: string, amount: int, transfer_code: string, currency: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/bulk")
  let body = {source: $body_source, currency: $currency, transfers: $transfers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch Transfer
#
# GET /transfer/{code}
# operationId: transfer_fetch
export def "transfer fetch" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: bool, message: string, data: record<amount: int, createdAt: string, currency: string, domain: string, failures: any, id: int, integration: int, reason: string, reference: string, source: string, source_details: any, status: string, titan_code: any, transfer_code: string, request: int, transferred_at: any, updatedAt: string, recipient: record<active: bool, createdAt: string, currency: string, description: string, domain: string, email: string, id: int, integration: int, metadata: record, name: string, recipient_code: string, type: string, updatedAt: string, is_deleted: bool, isDeleted: bool, details: record>, session: record<provider: any, id: any>, fee_charged: int, fees_breakdown: list<record>, gateway_response: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transfer/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify Transfer
#
# GET /transfer/verify/{reference}
# operationId: transfer_verify
export def "transfer-verify verify" [
  reference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: bool, message: string, data: record<amount: int, createdAt: string, currency: string, domain: string, failures: any, id: int, integration: int, reason: string, reference: string, source: string, source_details: any, status: string, titan_code: any, transfer_code: string, transferred_at: any, updatedAt: string, recipient: record<active: bool, createdAt: string, currency: string, description: string, domain: string, email: string, id: int, integration: int, metadata: record, name: string, recipient_code: string, type: string, updatedAt: string, is_deleted: bool, details: record>, session: record<provider: any, id: any>, gateway_response: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transfer/verify/($reference)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export Transfers
#
# GET /transfer/export
# operationId: transfer_exportTransfer
export def "transfer-export exportTransfer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recipient: string # Export transfer by the recipient code
  --status: string@status-completer-5 # Export transfer by status (default: pending, e.g. success)
  --qp-from: string # The start date (format: date-time)
  --qp-to: string # The end date (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recipient" $recipient "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transfer/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resend OTP for Transfer
#
# POST /transfer/resend_otp
# operationId: transfer_resendOtp
export def "transfer-resend-otp resendOtp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  transfer_code: string # The transfer code that requires an OTP validation
  reason: string@reason-completer # Specify the flag to indicate the purpose of the OTP (default: transfer)
]: any -> record<status: bool, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/resend_otp")
  let body = {transfer_code: $transfer_code, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disable OTP for Transfers
#
# POST /transfer/disable_otp
# operationId: transfer_disableOtp
export def "transfer-disable-otp disableOtp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: bool, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/disable_otp")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Finalize Disabling OTP for Transfers
#
# POST /transfer/disable_otp_finalize
# operationId: transfer_disableOtpFinalize
export def "transfer-disable-otp-finalize disableOtpFinalize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  otp: string # OTP sent to business phone to verify disabling OTP requirement
]: any -> record<status: bool, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/disable_otp_finalize")
  let body = {otp: $otp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enable OTP requirement for Transfers
#
# POST /transfer/enable_otp
# operationId: transfer_enableOtp
export def "transfer-enable-otp enableOtp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: bool, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/enable_otp")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Balance
#
# GET /balance
# operationId: balance_fetch
export def "balance fetch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: bool, message: string, data: table<currency: string, balance: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/balance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Balance Ledger
#
# GET /balance/ledger
# operationId: balance_ledger
export def "balance-ledger ledger" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --perPage: int # Number of records to fetch per page
  --page: int # The section to retrieve
  --qp-from: string # The start date (format: date-time)
  --qp-to: string # The end date (format: date-time)
]: nothing -> record<status: bool, message: string, data: table<integration: int, domain: string, balance: int, currency: string, difference: int, reason: string, model_responsible: string, model_row: int, id: int, createdAt: string, updatedAt: string>, meta: record<total: int, skipped: int, perPage: int, page: int, pageCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/balance/ledger" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Payment Request
#
# POST /paymentrequest
# operationId: paymentRequest_create
export def "paymentrequest create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  customer: string # Customer id or code
  amount: int # Payment request amount. Only useful if line items and tax values are ignored.  The endpoint will throw a friendly warning if neither is available.
  --currency: string # Specify the currency of the invoice. Allowed values are NGN, GHS, ZAR and USD. Defaults to NGN
  --due-date: string # ISO 8601 representation of request due date (format: date-time)
  --description: string # A short description of the payment request
  --line-items: list # Array of line items
  --tax: list # Array of taxes
  --send-notification: oneof<nothing, bool> # Indicates whether Paystack sends an email notification to customer. Defaults to true
  --draft: oneof<nothing, bool> # Indicate if request should be saved as draft. Defaults to false and overrides send_notification
  --has-invoice: oneof<nothing, bool> # Set to true to create a draft invoice (adds an auto incrementing invoice number if none is provided) even if there are no line_items or tax passed
  --invoice-number: int # Numeric value of invoice. Invoice will start from 1 and auto increment from there.  This field is to help override whatever value Paystack decides. Auto increment for  subsequent invoices continue from this point.
  --split-code: string # The split code of the transaction split.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/paymentrequest")
  let body = {customer: $customer, amount: $amount, currency: $currency, due_date: $due_date, description: $description, line_items: $line_items, tax: $tax, send_notification: $send_notification, draft: $draft, has_invoice: $has_invoice, invoice_number: $invoice_number, split_code: $split_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Payment Request
#
# GET /paymentrequest
# operationId: paymentRequest_list
export def "paymentrequest list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --perPage: int # Number of records to fetch per page
  --page: int # The section to retrieve
  --customer: string # Customer ID
  --status: string@status-completer-6 # Invoice status to filter (e.g. success)
  --currency: string # If your integration supports more than one currency, choose the one to filter
  --qp-from: string # The start date (format: date-time)
  --qp-to: string # The end date (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "customer" $customer "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/paymentrequest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Payment Request
#
# GET /paymentrequest/{id}
# operationId: paymentRequest_fetch
export def "paymentrequest fetch" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/paymentrequest/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Payment Request
#
# PUT /paymentrequest/{id}
# operationId: paymentRequest_update
export def "paymentrequest update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --customer: string # Customer id or code
  --amount: int # Payment request amount. Only useful if line items and tax values are ignored.  The endpoint will throw a friendly warning if neither is available.
  --currency: string # Specify the currency of the invoice. Allowed values are NGN, GHS, ZAR and USD. Defaults to NGN
  --due-date: string # ISO 8601 representation of request due date (format: date-time)
  --description: string # A short description of the payment request
  --line-items: list # Array of line items
  --tax: list # Array of taxes
  --send-notification: oneof<nothing, bool> # Indicates whether Paystack sends an email notification to customer. Defaults to true
  --draft: oneof<nothing, bool> # Indicate if request should be saved as draft. Defaults to false and overrides send_notification
  --has-invoice: oneof<nothing, bool> # Set to true to create a draft invoice (adds an auto incrementing invoice number if none is provided) even if there are no line_items or tax passed
  --invoice-number: int # Numeric value of invoice. Invoice will start from 1 and auto increment from there. This field is to help override whatever value Paystack decides.  Auto increment for subsequent invoices continue from this point.
  --split-code: string # The split code of the transaction split.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/paymentrequest/($id)")
  let body = {customer: $customer, amount: $amount, currency: $currency, due_date: $due_date, description: $description, line_items: $line_items, tax: $tax, send_notification: $send_notification, draft: $draft, has_invoice: $has_invoice, invoice_number: $invoice_number, split_code: $split_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Verify Payment Request
#
# GET /paymentrequest/verify/{id}
# operationId: paymentRequest_verify
export def "paymentrequest-verify verify" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/paymentrequest/verify/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send Notification
#
# POST /paymentrequest/notify/{id}
# operationId: paymentRequest_notify
export def "paymentrequest-notify notify" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/paymentrequest/notify/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Payment Request Total
#
# GET /paymentrequest/totals
# operationId: paymentRequest_totals
export def "paymentrequest-totals totals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/paymentrequest/totals")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Finalize Payment Request
#
# POST /paymentrequest/finalize/{id}
# operationId: paymentRequest_finalize
export def "paymentrequest-finalize finalize" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/paymentrequest/finalize/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive Payment Request
#
# POST /paymentrequest/archive/{id}
# operationId: paymentRequest_archive
export def "paymentrequest-archive archive" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/paymentrequest/archive/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Product
#
# POST /product
# operationId: product_create
export def "product create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of product
  description: string # The description of the product
  price: int # Price should be in kobo if currency is NGN, pesewas, if currency is GHS, and cents, if currency is ZAR
  currency: string # Currency in which price is set. Allowed values are: NGN, GHS, ZAR or USD
  --unlimited: oneof<nothing, bool> # Set to true if the product has unlimited stock. Leave as false if the product has limited stock
  --quantity: int # Number of products in stock. Use if limited is true
  --split-code: string # The split code if sharing the transaction with partners
  --metadata: string # Stringified JSON object of custom data
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/product")
  let body = {name: $name, description: $description, price: $price, currency: $currency, unlimited: $unlimited, quantity: $quantity, split_code: $split_code, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Products
#
# GET /product
# operationId: product_list
export def "product list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --perPage: int # Number of records to fetch per page
  --page: int # The section to retrieve
  --active: oneof<nothing, bool> # The state of the product (e.g. true)
  --qp-from: string # The start date (format: date-time)
  --qp-to: string # The end date (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/product" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Product
#
# GET /product/{id}
# operationId: product_fetch
export def "product fetch" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/product/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update product
#
# PUT /product/{id}
# operationId: product_update
export def "product update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of product
  --description: string # The description of the product
  --price: int # Price should be in kobo if currency is NGN, pesewas, if currency is GHS, and cents, if currency is ZAR
  --currency: string # Currency in which price is set. Allowed values are: NGN, GHS, ZAR or USD
  --unlimited: oneof<nothing, bool> # Set to true if the product has unlimited stock. Leave as false if the product has limited stock
  --quantity: int # Number of products in stock. Use if limited is true
  --split-code: string # The split code if sharing the transaction with partners
  --metadata: record # JSON object of custom data
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/product/($id)")
  let body = {name: $name, description: $description, price: $price, currency: $currency, unlimited: $unlimited, quantity: $quantity, split_code: $split_code, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Product
#
# DELETE /product/{id}
# operationId: product_delete
export def "product delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/product/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Storefront
#
# POST /storefront
# operationId: storefront_create
export def "storefront create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the storefront
  slug: string # A unique identifier to access your store. Once the storefront is created, it can be accessed from https://paystack.shop/your-slug
  currency: string@currency-completer # Currency for prices of products in your storefront.
  --description: string # The description of the storefront
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/storefront")
  let body = {name: $name, slug: $slug, currency: $currency, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Storefronts
#
# GET /storefront
# operationId: storefront_list
export def "storefront list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --perPage: int # Number of records to fetch per request (default: 50)
  --page: int # The offset to retrieve data from (default: 1)
  --status: string@status-completer-7 # e.g. active
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/storefront" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Storefront
#
# GET /storefront/{id}
# operationId: storefront_fetch
export def "storefront fetch" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/storefront/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Storefront
#
# PUT /storefront/{id}
# operationId: storefront_update
export def "storefront update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the storefront
  --slug: string # A unique identifier to access your store. Once the storefront is created, it can be accessed from https://paystack.shop/your-slug
  --description: string # The description of the storefront
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/storefront/($id)")
  let body = {name: $name, slug: $slug, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Storefront
#
# DELETE /storefront/{id}
# operationId: storefront_delete
export def "storefront delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/storefront/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify Storefront Slug
#
# GET /storefront/verify/{slug}
# operationId: storefront_verifySlug
export def "storefront-verify verifySlug" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/storefront/verify/($slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Storefront Orders
#
# GET /storefront/{id}/order
# operationId: storefront_fetchOrders
export def "storefront-order fetchOrders" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/storefront/($id)/order")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Products to Storefront
#
# POST /storefront/{id}/product
# operationId: storefront_addProducts
export def "storefront-product addProducts" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  products: list # An array of product IDs
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/storefront/($id)/product")
  let body = {products: $products} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Storefront Products
#
# GET /storefront/{id}/product
# operationId: storefront_listProducts
export def "storefront-product listProducts" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/storefront/($id)/product")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Publish Storefront
#
# POST /storefront/{id}/publish
# operationId: storefront_publish
export def "storefront-publish publish" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/storefront/($id)/publish")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Duplicate Storefront
#
# POST /storefront/{id}/duplicate
# operationId: storefront_duplicate
export def "storefront-duplicate duplicate" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/storefront/($id)/duplicate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Order
#
# POST /order
# operationId: order_create
# --items item shape: {item: int, type: string, quantity: int, amount: int}
# --shipping shape: {street_line: string, city: string, state: string, country: string, shipping_fee: int, delivery_note?: string}
export def "order create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email of the customer placing the order
  first_name: string # The customer's first name
  last_name: string # The customer's last name
  phone: string # The customer's mobile number
  currency: string@currency-completer # Currency in which amount is set
  items: list # item shape: {item: int, type: string, quantity: int, amount: int}
  shipping: record # The shipping details of the order (e.g. {street_line: Somewhere on Earth, city: Atlantic, state: Pacific, country: Equator, shipping_fee: 10000}) — shape: {street_line: string, city: string, state: string, country: string, shipping_fee: int, delivery_note?: string}
  --is-gift: oneof<nothing, bool> # A flag to indicate if the order is for someone else
  --pay-for-me: oneof<nothing, bool> # A flag to indicate if the someone else should pay for the order
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order")
  let body = {email: $email, first_name: $first_name, last_name: $last_name, phone: $phone, currency: $currency, items: $items, shipping: $shipping, is_gift: $is_gift, pay_for_me: $pay_for_me} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Orders
#
# GET /order
# operationId: order_list
export def "order list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --perPage: int # Number of records to fetch per page
  --page: int # The section to retrieve
  --qp-from: string # The start date (format: date-time)
  --qp-to: string # The end date (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/order" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Order
#
# GET /order/{id}
# operationId: order_fetch
export def "order fetch" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/order/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Product Orders
#
# GET /order/product/{id}
# operationId: order_product
export def "order-product product" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/order/product/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate Order
#
# GET /order/{code}/validate
# operationId: order_validate
export def "order-validate validate" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/order/($code)/validate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Page
#
# POST /page
# operationId: page_create
export def "page create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of page
  --description: string # The description of the page
  --amount: int # Amount should be in kobo if currency is NGN, pesewas, if currency is GHS, and cents, if currency is ZAR
  --currency: string@currency-completer # The transaction currency. Defaults to your integration currency.
  --slug: string # URL slug you would like to be associated with this page. Page will be accessible at `https://paystack.com/pay/[slug]`
  --type: string@type-completer-3 # The type of payment page to create. Defaults to `payment` if no type is specified.
  --plan: string # The ID of the plan to subscribe customers on this payment page to when `type` is set to `subscription`.
  --fixed-amount: oneof<nothing, bool> # Specifies whether to collect a fixed amount on the payment page. If true, `amount` must be passed.
  --split-code: string # The split code of the transaction split. e.g. `SPL_98WF13Eb3w`
  --metadata: record # JSON object of custom data
  --redirect-url: string # If you would like Paystack to redirect to a URL upon successful payment, specify the URL here.
  --success-message: string # A success message to display to the customer after a successful transaction
  --notification-email: string # An email address that will receive transaction notifications for this payment page
  --collect-phone: oneof<nothing, bool> # Specify whether to collect phone numbers on the payment page
  --custom-fields: list # If you would like to accept custom fields, specify them here.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/page")
  let body = {name: $name, description: $description, amount: $amount, currency: $currency, slug: $slug, type: $type, plan: $plan, fixed_amount: $fixed_amount, split_code: $split_code, metadata: $metadata, redirect_url: $redirect_url, success_message: $success_message, notification_email: $notification_email, collect_phone: $collect_phone, custom_fields: $custom_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Pages
#
# GET /page
# operationId: page_list
export def "page list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --perPage: int # Number of records to fetch per page (default: 50, e.g. 10)
  --page: int # The section to retrieve
  --qp-from: string # The start date (format: date-time)
  --qp-to: string # The end date (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/page" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Page
#
# GET /page/{id}
# operationId: page_fetch
export def "page fetch" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/page/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Page
#
# PUT /page/{id}
# operationId: page_update
export def "page update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of page
  --description: string # The description of the page
  --amount: int # Amount should be in the subunit of the currency
  --active: oneof<nothing, bool> # Set to false to deactivate page url
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/page/($id)")
  let body = {name: $name, description: $description, amount: $amount, active: $active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check Slug Availability
#
# GET /page/check_slug_availability/{slug}
# operationId: page_checkSlugAvailability
export def "page-check-slug-availability checkSlugAvailability" [
  slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/page/check_slug_availability/($slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Products
#
# POST /page/{id}/product
# operationId: page_addProducts
export def "page-product addProducts" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  products: list # A list of IDs of products to add to a page.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/page/($id)/product")
  let body = {products: $products} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Settlements
#
# GET /settlement
# operationId: settlements_fetch
export def "settlement fetch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --perPage: int # The number of records to fetch per request (e.g. 50)
  --page: int # The offset to retrieve data from (e.g. 2)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/settlement" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Settlement Transactions
#
# GET /settlement/{id}/transactions
# operationId: settlements_transaction
export def "settlement-transactions transaction" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/settlement/($id)/transactions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Payment Session Timeout
#
# GET /integration/payment_session_timeout
# operationId: integration_fetchPaymentSessionTimeout
export def "integration-payment-session-timeout fetchPaymentSessionTimeout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: bool, message: string, data: record<payment_session_timeout: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integration/payment_session_timeout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Payment Session Timeout
#
# PUT /integration/payment_session_timeout
# operationId: integration_updatePaymentSessionTimeout
export def "integration-payment-session-timeout updatePaymentSessionTimeout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  timeout: int # Time in seconds before a transaction becomes invalid (e.g. 30)
]: any -> record<status: bool, message: string, data: record<payment_session_timeout: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integration/payment_session_timeout")
  let body = {timeout: $timeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Refund
#
# POST /refund
# operationId: refund_create
export def "refund create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  transaction: string # The reference of a previosuly completed transaction
  --amount: int # Amount to be refunded to the customer. It cannot be more than the original transaction amount
  --currency: string@currency-completer # Three-letter ISO currency
  --customer-note: string # Customer reason
  --merchant-note: string # Merchant reason
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/refund")
  let body = {transaction: $transaction, amount: $amount, currency: $currency, customer_note: $customer_note, merchant_note: $merchant_note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Refunds
#
# GET /refund
# operationId: refund_list
export def "refund list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --perPage: int # Number of records to fetch per page (default: 50, e.g. 10)
  --page: int # The section to retrieve
  --qp-from: string # The start date (format: date-time)
  --qp-to: string # The end date (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/refund" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retry Refund
#
# POST /refund/retry_with_customer_details/{id}
# operationId: refund_retry
# --refund_account_details shape: {currency: string, account_number: string, bank_id: string}
export def "refund-retry-with-customer-details retry" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  refund_account_details: record # An object that contains the customer’s account details for refund (e.g. {currency: NGN, account_number: 1234567890, bank_id: 9}) — shape: {currency: string, account_number: string, bank_id: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/refund/retry_with_customer_details/($id)")
  let body = {refund_account_details: $refund_account_details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch Refund
#
# GET /refund/{id}
# operationId: refund_fetch
export def "refund fetch" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/refund/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Disputes
#
# GET /dispute
# operationId: dispute_list
export def "dispute list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --perPage: int # Number of records to fetch per page
  --page: int # The section to retrieve
  --status: string@status-completer-8 # Dispute status (e.g. awaiting-merchant-feedback)
  --transaction: string # Transaction ID
  --qp-from: string # The start date (format: date-time)
  --qp-to: string # The end date (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "transaction" $transaction "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dispute" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch Dispute
#
# GET /dispute/{id}
# operationId: dispute_fetch
export def "dispute fetch" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dispute/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Dispute
#
# PUT /dispute/{id}
# operationId: dispute_update
export def "dispute update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  refund_amount: int # The amount to refund, in the subunit of your currency
  --uploaded-filename: string # Filename of attachment returned via response from the Dispute upload URL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dispute/($id)")
  let body = {refund_amount: $refund_amount, uploaded_filename: $uploaded_filename} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch Upload URL
#
# GET /dispute/{id}/upload_url
# operationId: dispute_uploadUrl
export def "dispute-upload-url uploadUrl" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dispute/($id)/upload_url")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export Disputes
#
# GET /dispute/export
# operationId: dispute_download
export def "dispute-export download" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --perPage: int # Number of records to fetch per page
  --page: int # The section to retrieve
  --status: string@status-completer-8 # e.g. awaiting-merchant-feedback
  --qp-from: string # The start date (format: date-time)
  --qp-to: string # The end date (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dispute/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Transaction Disputes
#
# GET /dispute/transaction/{id}
# operationId: dispute_transaction
export def "dispute-transaction transaction" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dispute/transaction/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve Dispute
#
# PUT /dispute/{id}/resolve
# operationId: dispute_resolve
export def "dispute-resolve resolve" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  resolution: string # Dispute resolution. Accepted values, merchant-accepted, declined
  message: string # Reason for resolving
  refund_amount: int # The amount to refund, in the subunit of your integration currency
  uploaded_filename: string # Filename of attachment returned via response from the Dispute upload URL
  --evidence: int # Evidence Id for fraud claims
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dispute/($id)/resolve")
  let body = {resolution: $resolution, message: $message, refund_amount: $refund_amount, uploaded_filename: $uploaded_filename, evidence: $evidence} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add Evidence
#
# POST /dispute/{id}/evidence
# operationId: dispute_evidence
export def "dispute-evidence evidence" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  customer_email: string # Customer email
  customer_name: string # Customer name
  customer_phone: string # Customer mobile number
  service_details: string # Details of service offered
  --delivery-address: string # Delivery address
  --delivery-date: string # ISO 8601 representation of delivery date (YYYY-MM-DD) (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dispute/($id)/evidence")
  let body = {customer_email: $customer_email, customer_name: $customer_name, customer_phone: $customer_phone, service_details: $service_details, delivery_address: $delivery_address, delivery_date: $delivery_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Banks
#
# GET /bank
# operationId: bank_list
export def "bank list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --country: string@country-completer-1 # The country from which to obtain the list of supported banks (e.g. nigeria)
  --currency: string@currency-completer-3 # The country from which to obtain the list of supported banks (e.g. NGN)
  --use-cursor: oneof<nothing, bool> # A flag to indicate if cursor based pagination should be used
  --perPage: int # The number of records to fetch per request
  --page: int # The offset to retrieve data from
  --next: string # An alphanumeric value returned for every cursor based retrieval, used to retrieve the next set of data
  --previous: string # An alphanumeric value returned for every cursor based retrieval, used to retrieve the previous set of data
  --pay-with-bank-transfer: oneof<nothing, bool> # A flag to filter for available banks a customer can make a transfer to complete a payment
  --pay-with-bank: oneof<nothing, bool> # A flag to filter for banks a customer can pay directly from
  --enabled-for-verification: oneof<nothing, bool> # A flag to filter the banks that are supported for account verification in South Africa. You need to combine this with either the `currency` or `country` filter.
  --gateway: string@gateway-completer # The type of gateway for a Nigerian bank
  --type: string@type-completer-4 # Type of financial channel
  --include-nip-sort-code: oneof<nothing, bool> # A flag that returns Nigerian banks with their NIP institution code.  The returned value can be used in identifying institutions on NIP.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "use_cursor" $use_cursor "scalar") (serialize-qp "perPage" $perPage "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "next" $next "scalar") (serialize-qp "previous" $previous "scalar") (serialize-qp "pay_with_bank_transfer" $pay_with_bank_transfer "scalar") (serialize-qp "pay_with_bank" $pay_with_bank "scalar") (serialize-qp "enabled_for_verification" $enabled_for_verification "scalar") (serialize-qp "gateway" $gateway "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "include_nip_sort_code" $include_nip_sort_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bank" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve Account Number
#
# GET /bank/resolve
# operationId: bank_resolveAccountNumber
export def "bank-resolve resolveAccountNumber" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account-number: int # The account number of interest (e.g. 22728151)
  --bank-code: int # The bank code associated with the account number (e.g. 63)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account_number" $account_number "scalar") (serialize-qp "bank_code" $bank_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bank/resolve" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate Bank Account
#
# POST /bank/validate
# operationId: bank_validateAccountNumber
export def "bank-validate validateAccountNumber" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  account_name: string # Customer's first and last name registered with their bank
  account_number: string # Customer's account number
  account_type: string@account-type-completer # The type of the customer's account number
  bank_code: string # The bank code of the customer’s bank. You can fetch the bank codes by using our List Banks endpoint
  country_code: string # The two digit ISO code of the customer’s bank
  document_type: string@document-type-completer # Customer’s mode of identity
  --document-number: string # Customer’s mode of identity number
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank/validate")
  let body = {account_name: $account_name, account_number: $account_number, account_type: $account_type, bank_code: $bank_code, country_code: $country_code, document_type: $document_type, document_number: $document_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resolve Card BIN
#
# GET /decision/bin/{bin}
# operationId: miscellaneous_resolveCardBin
export def "decision-bin resolveCardBin" [
  bin: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/decision/bin/($bin)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Countries
#
# GET /country
# operationId: miscellaneous_listCountries
export def "country listCountries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/country")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List States (AVS)
#
# GET /address_verification/states
# operationId: miscellaneous_avs
export def "address-verification-states avs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --country: string # The country code of the states to list. It is gotten after the charge request (e.g. CA)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/address_verification/states" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
