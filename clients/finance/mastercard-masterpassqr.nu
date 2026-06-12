# Auto-generated client for Send Person to Merchant vV1
# Source: https://api.apis.guru/v2/specs/mastercard.com/masterpassqr/V1/swagger.json
# Auth: --token flag or $env.SEND_PERSON_TO_MERCHANT_TOKEN

const BASE_URL = "https://api.mastercard.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SEND_PERSON_TO_MERCHANT_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.mastercard.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "send-env-partners-merchant-transfer createMerchantTransfer" } } | get name | first)
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

# Initiates a Mastercard Merchant Presented QR purchase transaction by securing funds from a consumer’s account with a Funding Transaction and pushing funds to a merchant account with a Payment Transaction.
#
# POST /send/#env/v1/partners/{partnerId}/merchant/transfer
# operationId: createMerchantTransfer
# --merchant_transfer shape: {additional_message?: string, convenience_amount?: string, convenience_indicator?: string, digital_account_reference_number?: string, interchange_rate_designator?: string, mastercard_assigned_id?: string, participant: record, participation_id?: string, payment_origination_country?: string, payment_type: string, processor_id?: string, qr_data?: string, recipient: record, recipient_account_uri: string, reconciliation_data?: record, routing_transit_number?: string, sender: record, sender_account_uri: string, transaction_local_date_time: string, transfer_amount: record, transfer_reference: string, unique_reference_number?: string}
export def "send-env-partners-merchant-transfer createMerchantTransfer" [
  partnerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --merchant-transfer: record # Contains the details of the request message. — shape: {additional_message?: string, convenience_amount?: string, convenience_indicator?: string, digital_account_reference_number?: string, interchange_rate_designator?: string, mastercard_assigned_id?: string, participant: record, participation_id?: string, payment_origination_country?: string, payment_type: string, processor_id?: string, qr_data?: string, recipient: record, recipient_account_uri: string, reconciliation_data?: record, routing_transit_number?: string, sender: record, sender_account_uri: string, transaction_local_date_time: string, transfer_amount: record, transfer_reference: string, unique_reference_number?: string}
]: any -> record<merchant_transfer: record<additional_message: string, created: string, digital_account_reference_number: string, funding_source: string, id: string, interchange_rate_designator: string, mastercard_assigned_id: string, original_status: string, participant: record<card_acceptor_id: string, card_acceptor_name: string>, participation_id: string, payment_origination_country: string, payment_type: string, processor_id: string, recipient: record<additional_merchant_data: record, address: record, email: string, first_name: string, last_name: string, merchant_category_code: string, middle_name: string, phone: string>, recipient_account_uri: string, reconciliation_data: record<custom_field: list>, resource_type: string, routing_transit_number: string, sender: record<additional_merchant_data: record, address: record, email: string, first_name: string, last_name: string, middle_name: string, phone: string>, sender_account_uri: string, status: string, status_timestamp: string, transaction_history: record<data: record, item_count: int, resource_type: string>, transaction_local_date_time: string, transfer_amount: record<currency: string, value: string>, transfer_reference: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/send/#env/v1/partners/($partnerId)/merchant/transfer")
  let body = {merchant_transfer: $merchant_transfer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Purpose of this service is to retrieve the Transfer resource associated with a specified transfer_reference value.
#
# GET /send/#env/v1/partners/{partnerId}/merchant/transfers
# operationId: getMerchantTransferByRef
export def "send-env-partners-merchant-transfers list" [
  partnerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ref: string # Query Param - Is the client specified transfer reference when initiating the transfer. Allowable characters are alphanumeric and * , - . _ ~. Details- 6-40 Example- DEF123456
]: nothing -> record<merchant_transfers: record<data: record<merchant_transfer: list>, item_count: int, resource_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ref" $ref "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/send/#env/v1/partners/($partnerId)/merchant/transfers" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initiates a Mastercard Merchant Presented QR purchase transaction by pushing funds to a merchant account.
#
# POST /send/#env/v1/partners/{partnerId}/merchant/transfers/payment
# operationId: createMerchantPayment
# --merchant_payment_transfer shape: {additional_message?: string, amount: string, authentication_value?: string, channel?: string, convenience_amount?: string, convenience_indicator?: string, currency: string, device_id?: string, digital_account_reference_number?: string, funding_source: string, funding_transaction_reference?: record, interchange_rate_designator?: string, location?: string, mastercard_assigned_id?: string, participant?: record, participation_id?: string, payment_origination_country?: string, payment_type: string, processor_id?: string, qr_data?: string, recipient: record, recipient_account_uri: string, reconciliation_data?: record, routing_transit_number?: string, sender?: record, sender_account_uri: string, token_cryptogram?: record, transaction_local_date_time: string, transfer_reference: string}
export def "send-env-partners-merchant-transfers-payment createMerchantPayment" [
  partnerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --merchant-payment-transfer: record # Contains the details of the request message. — shape: {additional_message?: string, amount: string, authentication_value?: string, channel?: string, convenience_amount?: string, convenience_indicator?: string, currency: string, device_id?: string, digital_account_reference_number?: string, funding_source: string, funding_transaction_reference?: record, interchange_rate_designator?: string, location?: string, mastercard_assigned_id?: string, participant?: record, participation_id?: string, payment_origination_country?: string, payment_type: string, processor_id?: string, qr_data?: string, recipient: record, recipient_account_uri: string, reconciliation_data?: record, routing_transit_number?: string, sender?: record, sender_account_uri: string, token_cryptogram?: record, transaction_local_date_time: string, transfer_reference: string}
]: any -> record<merchant_transfer: record<additional_message: string, channel: string, convenience_amount: string, convenience_indicator: string, created: string, device_id: string, digital_account_reference_number: string, funding_source: string, id: string, interchange_rate_designator: string, location: string, original_status: string, participant: record<card_acceptor_id: string, card_acceptor_name: string>, participation_id: string, payment_origination_country: string, payment_type: string, processor_id: string, qr_data: string, recipient: record<additional_merchant_data: record, address: record, email: string, first_name: string, last_name: string, merchant_category_code: string, middle_name: string, phone: string>, recipient_account_uri: string, reconciliation_data: record<custom_field: list>, resource_type: string, routing_transit_number: string, sender: record<address: record, date_of_birth: string, email: string, first_name: string, last_name: string, middle_name: string, phone: string>, sender_account_uri: string, status: string, status_timestamp: string, transaction_history: record<data: record, item_count: int, resource_type: string>, transaction_local_date_time: string, transfer_amount: record<currency: string, value: string>, transfer_reference: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/send/#env/v1/partners/($partnerId)/merchant/transfers/payment")
  let body = {merchant_payment_transfer: $merchant_payment_transfer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Initiates a Mastercard Merchant Presented QR Refund transaction by pushing funds from a merchant account back to the customer's account.
#
# POST /send/#env/v1/partners/{partnerId}/merchant/transfers/refund
# operationId: createMerchantRefund
# --merchant_refund_transfer shape: {additional_message?: string, amount: string, authentication_value?: string, channel?: string, currency: string, device_id?: string, digital_account_reference_number?: string, funding_source: string, interchange_rate_designator?: string, location?: string, mastercard_assigned_id?: string, participant?: record, participation_id?: string, payment_origination_country?: string, payment_transaction_reference?: record, payment_type: string, processor_id?: string, recipient?: record, reconciliation_data?: record, routing_transit_number?: string, sender?: record, sender_account_uri: string, token_cryptogram?: record, transaction_local_date_time: string, transfer_reference: string}
export def "send-env-partners-merchant-transfers-refund createMerchantRefund" [
  partnerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --merchant-refund-transfer: record # Contains the details of the request message. — shape: {additional_message?: string, amount: string, authentication_value?: string, channel?: string, currency: string, device_id?: string, digital_account_reference_number?: string, funding_source: string, interchange_rate_designator?: string, location?: string, mastercard_assigned_id?: string, participant?: record, participation_id?: string, payment_origination_country?: string, payment_transaction_reference?: record, payment_type: string, processor_id?: string, recipient?: record, reconciliation_data?: record, routing_transit_number?: string, sender?: record, sender_account_uri: string, token_cryptogram?: record, transaction_local_date_time: string, transfer_reference: string}
]: any -> record<merchant_transfer: record<channel: string, created: string, device_id: string, digital_account_reference_number: string, funding_source: string, id: string, interchange_rate_designator: string, location: string, original_status: string, participant: record<card_acceptor_id: string, card_acceptor_name: string>, payment_origination_country: string, payment_type: string, processor_id: string, recipient: record<additional_merchant_data: record, address: record, email: string, first_name: string, last_name: string, merchant_category_code: string, middle_name: string, phone: string>, recipient_account_uri: string, reconciliation_data: record<custom_field: list>, resource_type: string, routing_transit_number: string, sender: record<address: record, date_of_birth: string, email: string, first_name: string, last_name: string, middle_name: string, phone: string>, sender_account_uri: string, status: string, status_timestamp: string, transaction_history: record<data: record, item_count: int, resource_type: string>, transaction_local_date_time: string, transfer_amount: record<currency: string, value: string>, transfer_reference: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/send/#env/v1/partners/($partnerId)/merchant/transfers/refund")
  let body = {merchant_refund_transfer: $merchant_refund_transfer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Purpose of this service is to retrieve the Transfer resource associated with the specified transfer-id.
#
# GET /send/#env/v1/partners/{partnerId}/merchant/transfers/{transferId}
# operationId: getMerchantTransferById
export def "send-env-partners-merchant-transfers get" [
  partnerId: string
  transferId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<merchant_transfer: record<channel: string, created: string, device_id: string, digital_account_reference_number: string, funding_source: string, id: string, interchange_rate_designator: string, location: string, original_status: string, participant: record<card_acceptor_id: string, card_acceptor_name: string>, payment_origination_country: string, payment_type: string, processor_id: string, recipient: record<additional_merchant_data: record, address: record, email: string, first_name: string, last_name: string, merchant_category_code: string, middle_name: string, phone: string>, recipient_account_uri: string, reconciliation_data: record<custom_field: list>, resource_type: string, routing_transit_number: string, sender: record<additional_merchant_data: record, address: record, date_of_birth: string, email: string, first_name: string, last_name: string, middle_name: string, phone: string>, sender_account_uri: string, status: string, status_timestamp: string, transaction_history: record<data: record, item_count: int, resource_type: string>, transaction_local_date_time: string, transfer_amount: record<currency: string, value: string>, transfer_reference: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/send/#env/v1/partners/($partnerId)/merchant/transfers/($transferId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Funding Reversals must be submitted within 30 minutes of the funding transfer request, and should only be submitted for the following conditions:  Funding Transaction must be reversed if payment transaction cannot complete successfully, i.e. the payment transaction is rejected or declined.  Upon a successful reversal of a funding transaction, the refund must be credited to the sending consumer’s Funding Account.
#
# POST /send/v1/partners/{partner-id}/transfers/{transfer-id}/transactions/{transaction-id}/reversals
# operationId: createFundingReversal
# --funding_reversal shape: {reversal_reason: string}
export def "send-partners-transfers-transactions-reversals createFundingReversal" [
  partner_id: string
  transfer_id: string
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --funding-reversal: record # Contains the details of the request message. — shape: {reversal_reason: string}
]: any -> record<transfer: record<channel: string, created: string, device_id: string, id: string, location: string, original_status: string, payment_type: string, recipient: record<address: record, date_of_birth: string, email: string, first_name: string, government_ids: record, last_name: string, middle_name: string, nationality: string, phone: string, sanction_score: string>, recipient_account_uri: string, reconciliation_data: record<custom_field: list>, resource_type: string, sanction_screening_override: bool, sender: record<address: record, date_of_birth: string, email: string, first_name: string, government_ids: record, last_name: string, middle_name: string, nationality: string, phone: string, sanction_score: string>, sender_account_uri: string, statement_descriptor: string, status: string, status_timestamp: string, transaction_history: record<data: record, item_count: int, resource_type: string>, transfer_amount: record<currency: string, value: string>, transfer_reference: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/send/v1/partners/($partner_id)/transfers/($transfer_id)/transactions/($transaction_id)/reversals")
  let body = {funding_reversal: $funding_reversal} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Client can simulate a Mastercard Merchant Presented QR Payment notification to the registered URL endpoint. 
#
# POST /send/v1/partners/{partnerId}/events/generate/payment
# operationId: sendNotificationPaymentRetry
# --notification_request shape: {additional_message?: string, mastercard_assigned_id?: string, merchant_category_code?: string, payment_facilitator_id?: string, payment_type: string, recipient?: record, recipient_account_uri: string, transaction_amount?: record, transfer_status: string}
export def "send-partners-events-generate-payment sendNotificationPaymentRetry" [
  partnerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notification-request: record # Contains the details of the request message. — shape: {additional_message?: string, mastercard_assigned_id?: string, merchant_category_code?: string, payment_facilitator_id?: string, payment_type: string, recipient?: record, recipient_account_uri: string, transaction_amount?: record, transfer_status: string}
]: any -> record<notification_response: record<status: string, transfer_reference: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/send/v1/partners/($partnerId)/events/generate/payment")
  let body = {notification_request: $notification_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "N/A"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Client can simulate a Mastercard Merchant Presented QR Refund notification to the registered URL endpoint. 
#
# POST /send/v1/partners/{partnerId}/events/generate/refund
# operationId: sendNotificationRefundRetry
# --notification_request shape: {additional_message?: string, mastercard_assigned_id?: string, merchant_category_code?: string, payment_facilitator_id?: string, payment_type: string, recipient?: record, recipient_account_uri: string, transaction_amount?: record, transfer_status: string}
export def "send-partners-events-generate-refund sendNotificationRefundRetry" [
  partnerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notification-request: record # Contains the details of the request message. — shape: {additional_message?: string, mastercard_assigned_id?: string, merchant_category_code?: string, payment_facilitator_id?: string, payment_type: string, recipient?: record, recipient_account_uri: string, transaction_amount?: record, transfer_status: string}
]: any -> record<notification_response: record<status: string, transfer_reference: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/send/v1/partners/($partnerId)/events/generate/refund")
  let body = {notification_request: $notification_request} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "N/A"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This service allows Mastercard Merchant QR originating and receiving partners to register a PAN and service provider to receive notifications on an inbound Merchant Refund or Merchant Payment Transaction.
#
# POST /send/v1/partners/{partnerId}/notification-registries
# operationId: createTransferNotificationRegistration
# --accountregistration shape: {account_uri: string, notification_partner_id: string}
export def "send-partners-notification-registries createTransferNotificationRegistration" [
  partnerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --accountregistration: record # Contains the details of the request message. — shape: {account_uri: string, notification_partner_id: string}
]: any -> record<accountregistration: record<account_registration_reference: string, account_uri: string, notification_partner_id: string, notification_partner_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/send/v1/partners/($partnerId)/notification-registries")
  let body = {accountregistration: $accountregistration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This service allows Mastercard Merchant QR originating and receiving partners to delete a registered PAN for notifications. 
#
# DELETE /send/v1/partners/{partnerId}/notification-registries/{account-reg-ref}
# operationId: deleteTransferNotificationRegistration
export def "send-partners-notification-registries delete" [
  partnerId: string
  account_reg_ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<accountregistration: record<account_registration_reference: string, account_uri: string, notification_partner_id: string, notification_partner_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/send/v1/partners/($partnerId)/notification-registries/($account_reg_ref)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This service allows Mastercard Merchant QR originating and receiving partners to retrieve the service provider's information for a registered PAN for notifications. 
#
# GET /send/v1/partners/{partnerId}/notification-registries/{account-reg-ref}
# operationId: NotificationRegistrationAPIReadBy
export def "send-partners-notification-registries NotificationRegistrationAPIReadBy" [
  partnerId: string
  account_reg_ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<accountregistration: record<account_registration_reference: string, account_uri: string, notification_partner_id: string, notification_partner_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/send/v1/partners/($partnerId)/notification-registries/($account_reg_ref)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This service allows Mastercard Merchant QR originating and receiving partners to update the notitification service provider for a registered PAN.
#
# PUT /send/v1/partners/{partnerId}/notification-registries/{account-reg-ref}
# operationId: NotificationRegistrationAPIUpdate
# --accountregistration shape: {account_uri: string, notification_partner_id: string}
export def "send-partners-notification-registries NotificationRegistrationAPIUpdate" [
  partnerId: string
  account_reg_ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --accountregistration: record # Contains the details of the request message. — shape: {account_uri: string, notification_partner_id: string}
]: any -> record<accountregistration: record<account_registration_reference: string, account_uri: string, notification_partner_id: string, notification_partner_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/send/v1/partners/($partnerId)/notification-registries/($account_reg_ref)")
  let body = {accountregistration: $accountregistration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# The Funding Transaction enables the 'pull' of money from the sender's card to the Transaction Originator who is providing the Person to Merchant service. The amount that is debited from the Funding Account (sending consumer's account) will be the amount 'pushed' to the recipient via a payment transfer request.  Funds can be transferred from Mastercard® or Maestro® debit card accounts. To initiate the funding transaction, users can provide the sending consumer's Primary Account Number (PAN) or a unique identifier previously mapped to the sending consumer's account.
#
# POST /send/v1/partners/{partnerId}/transfers/funding
# operationId: createFunding
# --funding_transfer shape: {additional_message?: string, amount: string, authentication_value?: string, channel?: string, currency: string, device_id?: string, funding_hints?: string, interchange_rate_designator?: string, language_data?: string, language_identification?: string, location?: string, participation_id?: string, payment_type?: string, recipient?: record, recipient_account_uri: string, reconciliation_data?: record, sanction_screening_override?: bool, sender?: record, sender_account_uri?: string, statement_descriptor?: string, token_cryptogram?: record, transfer_reference: string}
export def "send-partners-transfers-funding createFunding" [
  partnerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --funding-transfer: record # Contains the details of the request message. — shape: {additional_message?: string, amount: string, authentication_value?: string, channel?: string, currency: string, device_id?: string, funding_hints?: string, interchange_rate_designator?: string, language_data?: string, language_identification?: string, location?: string, participation_id?: string, payment_type?: string, recipient?: record, recipient_account_uri: string, reconciliation_data?: record, sanction_screening_override?: bool, sender?: record, sender_account_uri?: string, statement_descriptor?: string, token_cryptogram?: record, transfer_reference: string}
]: any -> record<transfer: record<channel: string, created: string, device_id: string, id: string, interchange_rate_designator: string, location: string, original_status: string, payment_type: string, recipient: record<address: record, date_of_birth: string, email: string, first_name: string, government_ids: record, last_name: string, merchant_category_code: string, middle_name: string, nationality: string, phone: string, sanction_score: string>, recipient_account_uri: string, reconciliation_data: record<custom_field: list>, resource_type: string, sanction_screening_override: bool, sender: record<additional_merchant_data: record, address: record, date_of_birth: string, email: string, first_name: string, government_ids: record, last_name: string, middle_name: string, nationality: string, phone: string, sanction_score: string>, sender_account_uri: string, statement_descriptor: string, status: string, status_timestamp: string, transaction_history: record<data: record, item_count: int, resource_type: string>, transfer_amount: record<currency: string, value: string>, transfer_reference: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/send/v1/partners/($partnerId)/transfers/funding")
  let body = {funding_transfer: $funding_transfer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Used to create a digital account reference number from Incontrol 
#
# POST /send/v1/{partnerId}/digital-account
# operationId: createDigitalAccntRefNum
# --digital_account shape: {account_type: string, account_uri: string, reference: string}
export def "send-digital-account createDigitalAccntRefNum" [
  partnerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --digital-account: record # Contains the details of the request message. — shape: {account_type: string, account_uri: string, reference: string}
]: any -> record<digital_account: record<account_type: string, account_uri: string, digital_account_reference_number: record<issue_timestamp: string, pan: string>, reference: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/send/v1/($partnerId)/digital-account")
  let body = {digital_account: $digital_account} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Used to retreive a digital account reference list from Incontrol 
#
# POST /send/v1/{partnerId}/digital-account/search
# operationId: retrieveDigitalAccntRefNumList
# --digital_account shape: {account_type: string, account_uri: string, reference: string}
export def "send-digital-account-search retrieveDigitalAccntRefNumList" [
  partnerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --digital-account: record # Contains the details of the request message. — shape: {account_type: string, account_uri: string, reference: string}
]: any -> record<digital_account: record<account_type: string, account_uri: string, digital_account_reference_numbers: record<digital_account_reference_number: list>, reference: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/send/v1/($partnerId)/digital-account/search")
  let body = {digital_account: $digital_account} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
