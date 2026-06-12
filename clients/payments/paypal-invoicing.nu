# Auto-generated client for Invoices v2.6
# Source: https://raw.githubusercontent.com/paypal/paypal-rest-api-specifications/main/openapi/invoicing_v2.json
# Auth: --token flag or $env.PAYPAL_TOKEN

const BASE_URL = "https://api-m.paypal.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PAYPAL_TOKEN | default "" }
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

def base-url-completer [] { ["https://api-m.paypal.com" "https://api-m.sandbox.paypal.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["AUTO_CANCELLED" "CANCELLED" "DRAFT" "MARKED_AS_PAID" "MARKED_AS_REFUNDED" "PAID" "PAID_EXTERNAL" "PARTIALLY_PAID" "PARTIALLY_REFUNDED" "PAYMENT_PENDING" "REFUNDED" "REFUNDED_EXTERNAL" "SCHEDULED" "SENT" "SHARED" "UNPAID"] }
def accept-completer [] { ["application/json" "multipart/mixed"] }
def type-completer [] { ["EXTERNAL" "PAYPAL"] }
def method-completer [] { ["BANK_TRANSFER" "CASH" "CHECK" "CREDIT_CARD" "DEBIT_CARD" "OTHER" "PAYPAL" "WIRE_TRANSFER"] }
def unit-of-measure-completer [] { ["AMOUNT" "HOURS" "QUANTITY"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "invoicing-invoices invoicescreate" } } | get name | first)
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

# Create draft invoice
#
# POST /v2/invoicing/invoices
# operationId: invoices.create
# --detail shape: {reference?: string, currency_code: string, note?: string, terms_and_conditions?: string, memo?: string, attachments?: list, invoice_number?: string, invoice_date?: string, payment_term?: record, metadata?: record}
# --invoicer shape: {email_address?: string, phones?: list, website?: string, tax_id?: string, additional_notes?: string, logo_url?: string}
# --primary_recipients item shape: {billing_info?: record, shipping_info?: record}
# --items item shape: {name: string, description?: string, quantity: string, unit_amount: record, tax?: record, item_date?: string, discount?: record, unit_of_measure?: "QUANTITY"|"HOURS"|"AMOUNT"}
# --configuration shape: {tax_calculated_after_discount?: bool, tax_inclusive?: bool, allow_tip?: bool, partial_payment?: record, has_conditional_rule?: bool, template_id?: string}
# --amount shape: {currency_code?: string, value?: string, breakdown?: record}
# --due_amount shape: {currency_code: string, value: string}
# --gratuity shape: {currency_code: string, value: string}
# --payments shape: {paid_amount?: record}
# --refunds shape: {refund_amount?: record}
# --links item shape: {href: string, rel: string, method?: "GET"|"POST"|"PUT"|"DELETE"|"HEAD"|"CONNECT"|"OPTIONS"|"PATCH"}
export def "invoicing-invoices invoicescreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --status: string@status-completer # The status of the invoice.
  detail: record # The details of the invoice. Includes invoice number, date, payment terms, and audit metadata. — shape: {reference?: string, currency_code: string, note?: string, terms_and_conditions?: string, memo?: string, attachments?: list, invoice_number?: string, invoice_date?: string, payment_term?: record, metadata?: record}
  --invoicer: record # The invoicer business information that appears on the invoice. — shape: {email_address?: string, phones?: list, website?: string, tax_id?: string, additional_notes?: string, logo_url?: string}
  --primary-recipients: list # The billing and shipping information. Includes name, email, address, phone and language. — item shape: {billing_info?: record, shipping_info?: record}
  --additional-recipients: list # An array of one or more CC: emails to which notifications are sent. If you omit this parameter, a notification is sent to all CC: email addresses that are part of the invoice.<blockquote><strong>Note:</strong> Valid values are email addresses in the `additional_recipients` value associated with the invoice.</blockquote>
  --items: list # An array of invoice line item information. — item shape: {name: string, description?: string, quantity: string, unit_amount: record, tax?: record, item_date?: string, discount?: record, unit_of_measure?: "QUANTITY"|"HOURS"|"AMOUNT"}
  --configuration: record # The invoice configuration details. Includes partial payment, tip, and tax calculated after discount. — shape: {tax_calculated_after_discount?: bool, tax_inclusive?: bool, allow_tip?: bool, partial_payment?: record, has_conditional_rule?: bool, template_id?: string}
  --amount: record # The invoice amount summary of item total, discount, tax total, and shipping. — shape: {currency_code?: string, value?: string, breakdown?: record}
  --due-amount: record # The currency and amount for a financial transaction, such as a balance or payment due. — shape: {currency_code: string, value: string}
  --gratuity: record # The currency and amount for a financial transaction, such as a balance or payment due. — shape: {currency_code: string, value: string}
  --payments: record # An array of payments registered against the invoice. — shape: {paid_amount?: record}
  --refunds: record # The invoicing refund details. Includes the refund type, date, amount, and method. — shape: {refund_amount?: record}
]: any -> record<id: string, parent_id: string, status: string, detail: record, invoicer: record, primary_recipients: table<billing_info: record, shipping_info: record>, additional_recipients: list<string>, items: table<id: string, name: string, description: string, quantity: string, unit_amount: record, tax: record, item_date: string, discount: record, unit_of_measure: string>, configuration: record, amount: record<currency_code: string, value: string, breakdown: record<item_total: record, discount: record, tax_total: record, shipping: record, custom: record>>, due_amount: record<currency_code: string, value: string>, gratuity: record<currency_code: string, value: string>, payments: record<paid_amount: record<currency_code: string, value: string>, transactions: list<record>>, refunds: record<refund_amount: record<currency_code: string, value: string>, transactions: list<record>>, links: table<href: string, rel: string, method: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/invoicing/invoices")
  let body = {status: $status, detail: $detail, invoicer: $invoicer, primary_recipients: $primary_recipients, additional_recipients: $additional_recipients, items: $items, configuration: $configuration, amount: $amount, due_amount: $due_amount, gratuity: $gratuity, payments: $payments, refunds: $refunds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List invoices
#
# GET /v2/invoicing/invoices
# operationId: invoices.list
export def "invoicing-invoices invoiceslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The page number to be retrieved, for the list of templates. So, a combination of `page=1` and `page_size=20` returns the first 20 templates. A combination of `page=2` and `page_size=20` returns the next 20 templates. (default: 1)
  --page-size: int # The maximum number of templates to return in the response. (default: 20)
  --total-required: oneof<nothing, bool> # Indicates whether the to show <code>total_pages</code> and <code>total_items</code> in the response. (default: false)
  --qp-fields: string # The fields to return in the response. Value is `all` or `none`. To return only the template name, ID, and default attributes, specify `none`. (default: all)
]: nothing -> record<total_pages: int, total_items: int, items: table<id: string, parent_id: string, status: string, detail: record, invoicer: record, primary_recipients: list, additional_recipients: list, items: list, configuration: record, amount: record, due_amount: record, gratuity: record, payments: record, refunds: record, links: list>, links: table<href: string, rel: string, method: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "total_required" $total_required "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/invoicing/invoices" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send invoice
#
# POST /v2/invoicing/invoices/{invoice_id}/send
# operationId: invoices.send
export def "invoicing-invoices-send invoicessend" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --subject: string # The subject of the email that is sent as a notification to the recipient.<blockquote><strong>Note:</strong> User-provided values for this field will not be honored and the subject will always be defaulted to a system-defined value.</blockquote>
  --note: string # A note to the payer.<blockquote><strong>Note:</strong> User-provided values for this field will not be honored and the note will always be defaulted to a system-defined value.</blockquote>
  --send-to-invoicer: oneof<nothing, bool> # Indicates whether to send a copy of the email to the merchant. (default: false)
  --send-to-recipient: oneof<nothing, bool> # Indicates whether to send a copy of the email to the recipient. (default: true)
  --additional-recipients: list # An array of one or more CC: emails to which notifications are sent. If you omit this parameter, a notification is sent to all CC: email addresses that are part of the invoice.<blockquote><strong>Note:</strong> Valid values are email addresses in the `additional_recipients` value associated with the invoice.</blockquote>
]: any -> record<href: string, rel: string, method: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/invoicing/invoices/($invoice_id)/send")
  let body = {subject: $subject, note: $note, send_to_invoicer: $send_to_invoicer, send_to_recipient: $send_to_recipient, additional_recipients: $additional_recipients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send invoice reminder
#
# POST /v2/invoicing/invoices/{invoice_id}/remind
# operationId: invoices.remind
export def "invoicing-invoices-remind invoicesremind" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject: string # The subject of the email that is sent as a notification to the recipient.<blockquote><strong>Note:</strong> User-provided values for this field will not be honored and the subject will always be defaulted to a system-defined value.</blockquote>
  --note: string # A note to the payer.<blockquote><strong>Note:</strong> User-provided values for this field will not be honored and the note will always be defaulted to a system-defined value.</blockquote>
  --send-to-invoicer: oneof<nothing, bool> # Indicates whether to send a copy of the email to the merchant. (default: false)
  --send-to-recipient: oneof<nothing, bool> # Indicates whether to send a copy of the email to the recipient. (default: true)
  --additional-recipients: list # An array of one or more CC: emails to which notifications are sent. If you omit this parameter, a notification is sent to all CC: email addresses that are part of the invoice.<blockquote><strong>Note:</strong> Valid values are email addresses in the `additional_recipients` value associated with the invoice.</blockquote>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/invoicing/invoices/($invoice_id)/remind")
  let body = {subject: $subject, note: $note, send_to_invoicer: $send_to_invoicer, send_to_recipient: $send_to_recipient, additional_recipients: $additional_recipients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel sent invoice
#
# POST /v2/invoicing/invoices/{invoice_id}/cancel
# operationId: invoices.cancel
export def "invoicing-invoices-cancel invoicescancel" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject: string # The subject of the email that is sent as a notification to the recipient.<blockquote><strong>Note:</strong> User-provided values for this field will not be honored and the subject will always be defaulted to a system-defined value.</blockquote>
  --note: string # A note to the payer.<blockquote><strong>Note:</strong> User-provided values for this field will not be honored and the note will always be defaulted to a system-defined value.</blockquote>
  --send-to-invoicer: oneof<nothing, bool> # Indicates whether to send a copy of the email to the merchant. (default: false)
  --send-to-recipient: oneof<nothing, bool> # Indicates whether to send a copy of the email to the recipient. (default: true)
  --additional-recipients: list # An array of one or more CC: emails to which notifications are sent. If you omit this parameter, a notification is sent to all CC: email addresses that are part of the invoice.<blockquote><strong>Note:</strong> Valid values are email addresses in the `additional_recipients` value associated with the invoice.</blockquote>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/invoicing/invoices/($invoice_id)/cancel")
  let body = {subject: $subject, note: $note, send_to_invoicer: $send_to_invoicer, send_to_recipient: $send_to_recipient, additional_recipients: $additional_recipients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Record payment for invoice
#
# POST /v2/invoicing/invoices/{invoice_id}/payments
# operationId: invoices.payments
# --amount shape: {currency_code: string, value: string}
# --shipping_info shape: {business_name?: string, name?: record, address?: record}
export def "invoicing-invoices-payments invoicespayments" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer # The payment type. Can be PayPal or an external payment. Includes cash or a check.
  --payment-id: string # The ID for a PayPal payment transaction. Required for the `PAYPAL` payment type.
  --payment-date: string # The stand-alone date, in [Internet date and time format](https://tools.ietf.org/html/rfc3339#section-5.6). To represent special legal values, such as a date of birth, you should use dates with no associated time or time-zone data. Whenever possible, use the standard `date_time` type. This regular expression does not validate all dates. For example, February 31 is valid and nothing is known about leap years. (format: ppaas_date_notime_v2)
  method: string@method-completer # The payment mode or method through which the invoicer can accept the payments.
  --note: string # A note associated with an external cash or check payment.
  --amount: record # The currency and amount for a financial transaction, such as a balance or payment due. — shape: {currency_code: string, value: string}
  --shipping-info: record # The contact information of the user. Includes name and address. — shape: {business_name?: string, name?: record, address?: record}
]: any -> record<payment_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/invoicing/invoices/($invoice_id)/payments")
  let body = {type: $type, payment_id: $payment_id, payment_date: $payment_date, method: $method, note: $note, amount: $amount, shipping_info: $shipping_info} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete external payment
#
# DELETE /v2/invoicing/invoices/{invoice_id}/payments/{transaction_id}
# operationId: invoices.payments-delete
export def "invoicing-invoices-payments invoicespayments-delete" [
  invoice_id: string
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/invoicing/invoices/($invoice_id)/payments/($transaction_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Record refund for invoice
#
# POST /v2/invoicing/invoices/{invoice_id}/refunds
# operationId: invoices.refunds
# --amount shape: {currency_code: string, value: string}
export def "invoicing-invoices-refunds invoicesrefunds" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer # The payment type. Can be PayPal or an external payment. Includes cash or a check.
  --refund-date: string # The stand-alone date, in [Internet date and time format](https://tools.ietf.org/html/rfc3339#section-5.6). To represent special legal values, such as a date of birth, you should use dates with no associated time or time-zone data. Whenever possible, use the standard `date_time` type. This regular expression does not validate all dates. For example, February 31 is valid and nothing is known about leap years. (format: ppaas_date_notime_v2)
  --amount: record # The currency and amount for a financial transaction, such as a balance or payment due. — shape: {currency_code: string, value: string}
  method: string@method-completer # The payment mode or method through which the invoicer can accept the payments.
]: any -> record<refund_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/invoicing/invoices/($invoice_id)/refunds")
  let body = {type: $type, refund_date: $refund_date, amount: $amount, method: $method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete external refund
#
# DELETE /v2/invoicing/invoices/{invoice_id}/refunds/{transaction_id}
# operationId: invoices.refunds-delete
export def "invoicing-invoices-refunds invoicesrefunds-delete" [
  invoice_id: string
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/invoicing/invoices/($invoice_id)/refunds/($transaction_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate QR code
#
# POST /v2/invoicing/invoices/{invoice_id}/generate-qr-code
# operationId: invoices.generate-qr-code
export def "invoicing-invoices-generate-qr-code invoicesgenerate-qr-code" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --width: int # The width, in pixels, of the QR code image. Value is from `150` to `500`. (default: 500)
  --height: int # The height, in pixels, of the QR code image. Value is from `150` to `500`. (default: 500)
  --action: string # The type of URL for which to generate a QR code. Valid values are `pay` and `details`. (default: pay)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/invoicing/invoices/($invoice_id)/generate-qr-code")
  let body = {width: $width, height: $height, action: $action} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate invoice number
#
# POST /v2/invoicing/generate-next-invoice-number
# operationId: invoicing.generate-next-invoice-number
export def "invoicing-generate-next-invoice-number invoicinggenerate-next-invoice-number" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fetch-id: oneof<nothing, bool> # Optional to decide the number or ID. (default: false)
]: any -> record<invoice_number: string, invoice_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/invoicing/generate-next-invoice-number")
  let body = {fetch_id: $fetch_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Show invoice details
#
# GET /v2/invoicing/invoices/{invoice_id}
# operationId: invoices.get
export def "invoicing-invoices invoicesget" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, parent_id: string, status: string, detail: record, invoicer: record, primary_recipients: table<billing_info: record, shipping_info: record>, additional_recipients: list<string>, items: table<id: string, name: string, description: string, quantity: string, unit_amount: record, tax: record, item_date: string, discount: record, unit_of_measure: string>, configuration: record, amount: record<currency_code: string, value: string, breakdown: record<item_total: record, discount: record, tax_total: record, shipping: record, custom: record>>, due_amount: record<currency_code: string, value: string>, gratuity: record<currency_code: string, value: string>, payments: record<paid_amount: record<currency_code: string, value: string>, transactions: list<record>>, refunds: record<refund_amount: record<currency_code: string, value: string>, transactions: list<record>>, links: table<href: string, rel: string, method: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/invoicing/invoices/($invoice_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fully update invoice
#
# PUT /v2/invoicing/invoices/{invoice_id}
# operationId: invoices.update
# --detail shape: {reference?: string, currency_code: string, note?: string, terms_and_conditions?: string, memo?: string, attachments?: list, invoice_number?: string, invoice_date?: string, payment_term?: record, metadata?: record}
# --invoicer shape: {email_address?: string, phones?: list, website?: string, tax_id?: string, additional_notes?: string, logo_url?: string}
# --primary_recipients item shape: {billing_info?: record, shipping_info?: record}
# --items item shape: {name: string, description?: string, quantity: string, unit_amount: record, tax?: record, item_date?: string, discount?: record, unit_of_measure?: "QUANTITY"|"HOURS"|"AMOUNT"}
# --configuration shape: {tax_calculated_after_discount?: bool, tax_inclusive?: bool, allow_tip?: bool, partial_payment?: record, has_conditional_rule?: bool, template_id?: string}
# --amount shape: {currency_code?: string, value?: string, breakdown?: record}
# --due_amount shape: {currency_code: string, value: string}
# --gratuity shape: {currency_code: string, value: string}
# --payments shape: {paid_amount?: record}
# --refunds shape: {refund_amount?: record}
# --links item shape: {href: string, rel: string, method?: "GET"|"POST"|"PUT"|"DELETE"|"HEAD"|"CONNECT"|"OPTIONS"|"PATCH"}
export def "invoicing-invoices invoicesupdate" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --send-to-recipient: oneof<nothing, bool> # Indicates whether to send the invoice update notification to the recipient. (default: true)
  --send-to-invoicer: oneof<nothing, bool> # Indicates whether to send the invoice update notification to the merchant. (default: true)
  --status: string@status-completer # The status of the invoice.
  detail: record # The details of the invoice. Includes invoice number, date, payment terms, and audit metadata. — shape: {reference?: string, currency_code: string, note?: string, terms_and_conditions?: string, memo?: string, attachments?: list, invoice_number?: string, invoice_date?: string, payment_term?: record, metadata?: record}
  --invoicer: record # The invoicer business information that appears on the invoice. — shape: {email_address?: string, phones?: list, website?: string, tax_id?: string, additional_notes?: string, logo_url?: string}
  --primary-recipients: list # The billing and shipping information. Includes name, email, address, phone and language. — item shape: {billing_info?: record, shipping_info?: record}
  --additional-recipients: list # An array of one or more CC: emails to which notifications are sent. If you omit this parameter, a notification is sent to all CC: email addresses that are part of the invoice.<blockquote><strong>Note:</strong> Valid values are email addresses in the `additional_recipients` value associated with the invoice.</blockquote>
  --items: list # An array of invoice line item information. — item shape: {name: string, description?: string, quantity: string, unit_amount: record, tax?: record, item_date?: string, discount?: record, unit_of_measure?: "QUANTITY"|"HOURS"|"AMOUNT"}
  --configuration: record # The invoice configuration details. Includes partial payment, tip, and tax calculated after discount. — shape: {tax_calculated_after_discount?: bool, tax_inclusive?: bool, allow_tip?: bool, partial_payment?: record, has_conditional_rule?: bool, template_id?: string}
  --amount: record # The invoice amount summary of item total, discount, tax total, and shipping. — shape: {currency_code?: string, value?: string, breakdown?: record}
  --due-amount: record # The currency and amount for a financial transaction, such as a balance or payment due. — shape: {currency_code: string, value: string}
  --gratuity: record # The currency and amount for a financial transaction, such as a balance or payment due. — shape: {currency_code: string, value: string}
  --payments: record # An array of payments registered against the invoice. — shape: {paid_amount?: record}
  --refunds: record # The invoicing refund details. Includes the refund type, date, amount, and method. — shape: {refund_amount?: record}
]: any -> record<id: string, parent_id: string, status: string, detail: record, invoicer: record, primary_recipients: table<billing_info: record, shipping_info: record>, additional_recipients: list<string>, items: table<id: string, name: string, description: string, quantity: string, unit_amount: record, tax: record, item_date: string, discount: record, unit_of_measure: string>, configuration: record, amount: record<currency_code: string, value: string, breakdown: record<item_total: record, discount: record, tax_total: record, shipping: record, custom: record>>, due_amount: record<currency_code: string, value: string>, gratuity: record<currency_code: string, value: string>, payments: record<paid_amount: record<currency_code: string, value: string>, transactions: list<record>>, refunds: record<refund_amount: record<currency_code: string, value: string>, transactions: list<record>>, links: table<href: string, rel: string, method: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "send_to_recipient" $send_to_recipient "scalar") (serialize-qp "send_to_invoicer" $send_to_invoicer "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/invoicing/invoices/($invoice_id)" $qp)
  let body = {status: $status, detail: $detail, invoicer: $invoicer, primary_recipients: $primary_recipients, additional_recipients: $additional_recipients, items: $items, configuration: $configuration, amount: $amount, due_amount: $due_amount, gratuity: $gratuity, payments: $payments, refunds: $refunds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete invoice
#
# DELETE /v2/invoicing/invoices/{invoice_id}
# operationId: invoices.delete
export def "invoicing-invoices invoicesdelete" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/invoicing/invoices/($invoice_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for invoices
#
# POST /v2/invoicing/search-invoices
# operationId: invoices.search-invoices
# --total_amount_range shape: {lower_amount: record, upper_amount: record}
# --invoice_date_range shape: {start: string, end: string}
# --due_date_range shape: {start: string, end: string}
# --payment_date_range shape: {start: string, end: string}
# --creation_date_range shape: {start: string, end: string}
export def "invoicing-search-invoices invoicessearch-invoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page: int # The page number to be retrieved, for the list of templates. So, a combination of `page=1` and `page_size=20` returns the first 20 templates. A combination of `page=2` and `page_size=20` returns the next 20 templates. (default: 1)
  --page-size: int # The maximum number of templates to return in the response. (default: 20)
  --total-required: oneof<nothing, bool> # Indicates whether the to show <code>total_pages</code> and <code>total_items</code> in the response. (default: false)
  --recipient-email: string # Filters the search by the email address.
  --recipient-first-name: string # Filters the search by the recipient first name.
  --recipient-last-name: string # Filters the search by the recipient last name.
  --recipient-business-name: string # Filters the search by the recipient business name.
  --invoice-number: string # Filters the search by the invoice number.
  --status: list # An array of status values.
  --reference: string # The reference data. Includes a Purchase Order (PO) number.
  --currency-code: string # The [three-character ISO-4217 currency code](/api/rest/reference/currency-codes/) that identifies the currency.
  --memo: string # A private bookkeeping memo for the user.
  --total-amount-range: record # The amount range. — shape: {lower_amount: record, upper_amount: record}
  --invoice-date-range: record # The date range. Filters invoices by creation date, invoice date, due date, and payment date. — shape: {start: string, end: string}
  --due-date-range: record # The date range. Filters invoices by creation date, invoice date, due date, and payment date. — shape: {start: string, end: string}
  --payment-date-range: record # The date and time range. Filters invoices by creation date, invoice date, due date, and payment date. — shape: {start: string, end: string}
  --creation-date-range: record # The date and time range. Filters invoices by creation date, invoice date, due date, and payment date. — shape: {start: string, end: string}
  --archived: oneof<nothing, bool> # Indicates whether to list merchant-archived invoices in the response. Value is:<ul><li><code>true</code>. Response lists only merchant-archived invoices.</li><li><code>false</code>. Response lists only unarchived invoices.</li><li><code>null</code>. Response lists all invoices.</li></ul>
  --body-fields: list # A CSV file of fields to return for the user, if available. Because the invoice object can be very large, field filtering is required. Valid collection fields are <code>items</code>, <code>payments</code>, <code>refunds</code>, <code>additional_recipients_info</code>, and <code>attachments</code>.
]: any -> record<total_pages: int, total_items: int, items: table<id: string, parent_id: string, status: string, detail: record, invoicer: record, primary_recipients: list, additional_recipients: list, items: list, configuration: record, amount: record, due_amount: record, gratuity: record, payments: record, refunds: record, links: list>, links: table<href: string, rel: string, method: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "total_required" $total_required "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/invoicing/search-invoices" $qp)
  let body = {recipient_email: $recipient_email, recipient_first_name: $recipient_first_name, recipient_last_name: $recipient_last_name, recipient_business_name: $recipient_business_name, invoice_number: $invoice_number, status: $status, reference: $reference, currency_code: $currency_code, memo: $memo, total_amount_range: $total_amount_range, invoice_date_range: $invoice_date_range, due_date_range: $due_date_range, payment_date_range: $payment_date_range, creation_date_range: $creation_date_range, archived: $archived, fields: $body_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List templates
#
# GET /v2/invoicing/templates
# operationId: templates.list
export def "invoicing-templates templateslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-fields: string # The fields to return in the response. Value is `all` or `none`. To return only the template name, ID, and default attributes, specify `none`. (default: all)
  --page: int # The page number to be retrieved, for the list of templates. So, a combination of `page=1` and `page_size=20` returns the first 20 templates. A combination of `page=2` and `page_size=20` returns the next 20 templates. (default: 1)
  --page-size: int # The maximum number of templates to return in the response. (default: 20)
]: nothing -> record<addresses: table<address_line_1: string, address_line_2: string, address_line_3: string, admin_area_4: string, admin_area_3: string, admin_area_2: string, admin_area_1: string, postal_code: string, country_code: string, address_details: record>, emails: string, phones: list<record>, templates: table<id: string, name: string, default_template: bool, template_info: record, settings: record, unit_of_measure: string, standard_template: bool, links: list>, links: table<href: string, rel: string, method: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/invoicing/templates" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create template
#
# POST /v2/invoicing/templates
# operationId: templates.create
# --template_info shape: {detail?: record, invoicer?: record, primary_recipients?: list, additional_recipients?: list, items?: list, configuration?: record, amount?: record, due_amount?: record}
# --settings shape: {template_item_settings?: list, template_subtotal_settings?: list}
# --links item shape: {href: string, rel: string, method?: "GET"|"POST"|"PUT"|"DELETE"|"HEAD"|"CONNECT"|"OPTIONS"|"PATCH"}
export def "invoicing-templates templatescreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # The template name.<blockquote><strong>Note:</strong> The template name must be unique.</blockquote>
  --default-template: oneof<nothing, bool> # Indicates whether this template is the default template. A invoicer can have one default template.
  --template-info: record # The template details. Includes invoicer business information, invoice recipients, items, and configuration. — shape: {detail?: record, invoicer?: record, primary_recipients?: list, additional_recipients?: list, items?: list, configuration?: record, amount?: record, due_amount?: record}
  --settings: record # The template settings. Sets a template as the default template or edit template. — shape: {template_item_settings?: list, template_subtotal_settings?: list}
  --unit-of-measure: string@unit-of-measure-completer # The unit of measure for the invoiced item.
]: any -> record<id: string, name: string, default_template: bool, template_info: record<detail: record, invoicer: record, primary_recipients: list<record>, additional_recipients: list<string>, items: list<record>, configuration: record<tax_calculated_after_discount: bool, tax_inclusive: bool, allow_tip: bool, partial_payment: record, has_conditional_rule: bool>, amount: record<currency_code: string, value: string, breakdown: record>, due_amount: record<currency_code: string, value: string>>, settings: record<template_item_settings: list<record>, template_subtotal_settings: list<record>>, unit_of_measure: string, standard_template: bool, links: table<href: string, rel: string, method: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/invoicing/templates")
  let body = {name: $name, default_template: $default_template, template_info: $template_info, settings: $settings, unit_of_measure: $unit_of_measure} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Show template details
#
# GET /v2/invoicing/templates/{template_id}
# operationId: templates.get
export def "invoicing-templates templatesget" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, name: string, default_template: bool, template_info: record<detail: record, invoicer: record, primary_recipients: list<record>, additional_recipients: list<string>, items: list<record>, configuration: record<tax_calculated_after_discount: bool, tax_inclusive: bool, allow_tip: bool, partial_payment: record, has_conditional_rule: bool>, amount: record<currency_code: string, value: string, breakdown: record>, due_amount: record<currency_code: string, value: string>>, settings: record<template_item_settings: list<record>, template_subtotal_settings: list<record>>, unit_of_measure: string, standard_template: bool, links: table<href: string, rel: string, method: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/invoicing/templates/($template_id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fully update template
#
# PUT /v2/invoicing/templates/{template_id}
# operationId: templates.update
# --template_info shape: {detail?: record, invoicer?: record, primary_recipients?: list, additional_recipients?: list, items?: list, configuration?: record, amount?: record, due_amount?: record}
# --settings shape: {template_item_settings?: list, template_subtotal_settings?: list}
# --links item shape: {href: string, rel: string, method?: "GET"|"POST"|"PUT"|"DELETE"|"HEAD"|"CONNECT"|"OPTIONS"|"PATCH"}
export def "invoicing-templates templatesupdate" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The template name.<blockquote><strong>Note:</strong> The template name must be unique.</blockquote>
  --default-template: oneof<nothing, bool> # Indicates whether this template is the default template. A invoicer can have one default template.
  --template-info: record # The template details. Includes invoicer business information, invoice recipients, items, and configuration. — shape: {detail?: record, invoicer?: record, primary_recipients?: list, additional_recipients?: list, items?: list, configuration?: record, amount?: record, due_amount?: record}
  --settings: record # The template settings. Sets a template as the default template or edit template. — shape: {template_item_settings?: list, template_subtotal_settings?: list}
  --unit-of-measure: string@unit-of-measure-completer # The unit of measure for the invoiced item.
]: any -> record<id: string, name: string, default_template: bool, template_info: record<detail: record, invoicer: record, primary_recipients: list<record>, additional_recipients: list<string>, items: list<record>, configuration: record<tax_calculated_after_discount: bool, tax_inclusive: bool, allow_tip: bool, partial_payment: record, has_conditional_rule: bool>, amount: record<currency_code: string, value: string, breakdown: record>, due_amount: record<currency_code: string, value: string>>, settings: record<template_item_settings: list<record>, template_subtotal_settings: list<record>>, unit_of_measure: string, standard_template: bool, links: table<href: string, rel: string, method: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/invoicing/templates/($template_id)")
  let body = {name: $name, default_template: $default_template, template_info: $template_info, settings: $settings, unit_of_measure: $unit_of_measure} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete template
#
# DELETE /v2/invoicing/templates/{template_id}
# operationId: templates.delete
export def "invoicing-templates templatesdelete" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/invoicing/templates/($template_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Connections.
#
# GET /v2/invoicing/accounting-sync/merchant/connections
# operationId: connections.get
export def "invoicing-accounting-sync-merchant-connections connectionsget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<connections: table<platform_name: string, last_sync_time: string, last_sync_status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/invoicing/accounting-sync/merchant/connections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Connection Status for an Invoice.
#
# GET /v2/invoicing/accounting-sync/invoices/{id}/connections
# operationId: invoice_connection_details.get
export def "invoicing-accounting-sync-invoices-connections detailsget" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, connection_status: table<connections: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/invoicing/accounting-sync/invoices/($id)/connections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
