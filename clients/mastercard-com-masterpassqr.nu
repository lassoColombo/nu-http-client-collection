# Auto-generated client for Send Person to Merchant vV1
# Source: https://api.apis.guru/v2/specs/mastercard.com/masterpassqr/V1/swagger.json
# Auth: --token flag or $env.SEND_PERSON_TO_MERCHANT_TOKEN

const BASE_URL = "https://api.mastercard.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SEND_PERSON_TO_MERCHANT_TOKEN | default "" }
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

def base-url-completer [] { ["https://api.mastercard.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "send create-merchant-transfer" } } | get name | first)
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
# POST /send/
# operationId: createMerchantTransfer
# --merchant_transfer shape: {additional_message?: string, convenience_amount?: string, convenience_indicator?: string, digital_account_reference_number?: string, interchange_rate_designator?: string, mastercard_assigned_id?: string, participant: record, participation_id?: string, payment_origination_country?: string, payment_type: string, processor_id?: string, qr_data?: string, recipient: record, recipient_account_uri: string, reconciliation_data?: record, routing_transit_number?: string, sender: record, ... (5 more fields)}
export def "send create-merchant-transfer" [
  partner_id: string
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
  --merchant-transfer: record # Contains the details of the request message. — shape: {additional_message?: string, convenience_amount?: string, convenience_indicator?: string, digital_account_reference_number?: string, interchange_rate_designator?: string, mastercard_assigned_id?: string, participant: record, participation_id?: string, payment_origination_country?: string, payment_type: string, processor_id?: string, qr_data?: string, recipient: record, recipient_account_uri: string, reconciliation_data?: record, routing_transit_number?: string, sender: record, ... (5 more fields)}
]: any -> record<merchant_transfer: record<additional_message: string, created: string, digital_account_reference_number: string, funding_source: string, id: string, interchange_rate_designator: string, mastercard_assigned_id: string, original_status: string, participant: record<card_acceptor_id: string, card_acceptor_name: string>, participation_id: string, payment_origination_country: string, payment_type: string, processor_id: string, recipient: record<additional_merchant_data: record, address: record, email: string, first_name: string, last_name: string, merchant_category_code: string, middle_name: string, phone: string>, recipient_account_uri: string, reconciliation_data: record<custom_field: list>, resource_type: string, routing_transit_number: string, sender: record<additional_merchant_data: record, address: record, email: string, first_name: string, last_name: string, middle_name: string, phone: string>, sender_account_uri: string, status: string, status_timestamp: string, transaction_history: record<data: record, item_count: int, resource_type: string>, transaction_local_date_time: string, transfer_amount: record<currency: string, value: string>, transfer_reference: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partner_id | is-empty) { error make --unspanned { msg: "path parameter 'partnerId' must be non-empty" } }
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/send/"))
  let req_body = {"merchant_transfer": $merchant_transfer} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Purpose of this service is to retrieve the Transfer resource associated with a specified transfer_reference value.
#
# GET /send/
# operationId: getMerchantTransferByRef
export def "send get-merchant-transfer-by-ref" [
  partner_id: string
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
  --ref: string # Query Param - Is the client specified transfer reference when initiating the transfer. Allowable characters are alphanumeric and * , - . _ ~. Details- 6-40 Example- DEF123456
]: nothing -> record<merchant_transfers: record<data: record<merchant_transfer: list>, item_count: int, resource_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partner_id | is-empty) { error make --unspanned { msg: "path parameter 'partnerId' must be non-empty" } }
  let qp = [(serialize-qp "ref" $ref "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/send/") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ref": $ref} | compact), body: null}
}

# Initiates a Mastercard Merchant Presented QR purchase transaction by pushing funds to a merchant account.
#
# POST /send/
# operationId: createMerchantPayment
# --merchant_payment_transfer shape: {additional_message?: string, amount: string, authentication_value?: string, channel?: string, convenience_amount?: string, convenience_indicator?: string, currency: string, device_id?: string, digital_account_reference_number?: string, funding_source: string, funding_transaction_reference?: record, interchange_rate_designator?: string, location?: string, mastercard_assigned_id?: string, participant?: record, participation_id?: string, payment_origination_country?: string, payment_type: string, ... (11 more fields)}
export def "send create-merchant-payment" [
  partner_id: string
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
  --merchant-payment-transfer: record # Contains the details of the request message. — shape: {additional_message?: string, amount: string, authentication_value?: string, channel?: string, convenience_amount?: string, convenience_indicator?: string, currency: string, device_id?: string, digital_account_reference_number?: string, funding_source: string, funding_transaction_reference?: record, interchange_rate_designator?: string, location?: string, mastercard_assigned_id?: string, participant?: record, participation_id?: string, payment_origination_country?: string, payment_type: string, ... (11 more fields)}
]: any -> record<merchant_transfer: record<additional_message: string, channel: string, convenience_amount: string, convenience_indicator: string, created: string, device_id: string, digital_account_reference_number: string, funding_source: string, id: string, interchange_rate_designator: string, location: string, original_status: string, participant: record<card_acceptor_id: string, card_acceptor_name: string>, participation_id: string, payment_origination_country: string, payment_type: string, processor_id: string, qr_data: string, recipient: record<additional_merchant_data: record, address: record, email: string, first_name: string, last_name: string, merchant_category_code: string, middle_name: string, phone: string>, recipient_account_uri: string, reconciliation_data: record<custom_field: list>, resource_type: string, routing_transit_number: string, sender: record<address: record, date_of_birth: string, email: string, first_name: string, last_name: string, middle_name: string, phone: string>, sender_account_uri: string, status: string, status_timestamp: string, transaction_history: record<data: record, item_count: int, resource_type: string>, transaction_local_date_time: string, transfer_amount: record<currency: string, value: string>, transfer_reference: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partner_id | is-empty) { error make --unspanned { msg: "path parameter 'partnerId' must be non-empty" } }
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/send/"))
  let req_body = {"merchant_payment_transfer": $merchant_payment_transfer} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Initiates a Mastercard Merchant Presented QR Refund transaction by pushing funds from a merchant account back to the customer's account.
#
# POST /send/
# operationId: createMerchantRefund
# --merchant_refund_transfer shape: {additional_message?: string, amount: string, authentication_value?: string, channel?: string, currency: string, device_id?: string, digital_account_reference_number?: string, funding_source: string, interchange_rate_designator?: string, location?: string, mastercard_assigned_id?: string, participant?: record, participation_id?: string, payment_origination_country?: string, payment_transaction_reference?: record, payment_type: string, processor_id?: string, recipient?: record, ... (7 more fields)}
export def "send create-merchant-refund" [
  partner_id: string
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
  --merchant-refund-transfer: record # Contains the details of the request message. — shape: {additional_message?: string, amount: string, authentication_value?: string, channel?: string, currency: string, device_id?: string, digital_account_reference_number?: string, funding_source: string, interchange_rate_designator?: string, location?: string, mastercard_assigned_id?: string, participant?: record, participation_id?: string, payment_origination_country?: string, payment_transaction_reference?: record, payment_type: string, processor_id?: string, recipient?: record, ... (7 more fields)}
]: any -> record<merchant_transfer: record<channel: string, created: string, device_id: string, digital_account_reference_number: string, funding_source: string, id: string, interchange_rate_designator: string, location: string, original_status: string, participant: record<card_acceptor_id: string, card_acceptor_name: string>, payment_origination_country: string, payment_type: string, processor_id: string, recipient: record<additional_merchant_data: record, address: record, email: string, first_name: string, last_name: string, merchant_category_code: string, middle_name: string, phone: string>, recipient_account_uri: string, reconciliation_data: record<custom_field: list>, resource_type: string, routing_transit_number: string, sender: record<address: record, date_of_birth: string, email: string, first_name: string, last_name: string, middle_name: string, phone: string>, sender_account_uri: string, status: string, status_timestamp: string, transaction_history: record<data: record, item_count: int, resource_type: string>, transaction_local_date_time: string, transfer_amount: record<currency: string, value: string>, transfer_reference: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partner_id | is-empty) { error make --unspanned { msg: "path parameter 'partnerId' must be non-empty" } }
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/send/"))
  let req_body = {"merchant_refund_transfer": $merchant_refund_transfer} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Purpose of this service is to retrieve the Transfer resource associated with the specified transfer-id.
#
# GET /send/
# operationId: getMerchantTransferById
export def "send get-merchant-transfer" [
  partner_id: string
  transfer_id: string
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
]: nothing -> record<merchant_transfer: record<channel: string, created: string, device_id: string, digital_account_reference_number: string, funding_source: string, id: string, interchange_rate_designator: string, location: string, original_status: string, participant: record<card_acceptor_id: string, card_acceptor_name: string>, payment_origination_country: string, payment_type: string, processor_id: string, recipient: record<additional_merchant_data: record, address: record, email: string, first_name: string, last_name: string, merchant_category_code: string, middle_name: string, phone: string>, recipient_account_uri: string, reconciliation_data: record<custom_field: list>, resource_type: string, routing_transit_number: string, sender: record<additional_merchant_data: record, address: record, date_of_birth: string, email: string, first_name: string, last_name: string, middle_name: string, phone: string>, sender_account_uri: string, status: string, status_timestamp: string, transaction_history: record<data: record, item_count: int, resource_type: string>, transaction_local_date_time: string, transfer_amount: record<currency: string, value: string>, transfer_reference: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partner_id | is-empty) { error make --unspanned { msg: "path parameter 'partnerId' must be non-empty" } }
  if ($transfer_id | is-empty) { error make --unspanned { msg: "path parameter 'transferId' must be non-empty" } }
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id), transfer_id: (encode-path-segment $transfer_id)} | format pattern "/send/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Funding Reversals must be submitted within 30 minutes of the funding transfer request, and should only be submitted for the following conditions: Funding Transaction must be reversed if payment transaction cannot complete successfully, i.e. the payment transaction is rejected or declined. Upon a successful reversal of a funding transaction, the refund must be credited to the sending consumer’s Funding Account.
#
# POST /send/v1/partners/{partner-id}/transfers/{transfer-id}/transactions/{transaction-id}/reversals
# operationId: createFundingReversal
export def "send-partners-transfers-transactions-reversals create-funding" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<transfer: record<channel: string, created: string, device_id: string, id: string, location: string, original_status: string, payment_type: string, recipient: record<address: record, date_of_birth: string, email: string, first_name: string, government_ids: record, last_name: string, middle_name: string, nationality: string, phone: string, sanction_score: string>, recipient_account_uri: string, reconciliation_data: record<custom_field: list>, resource_type: string, sanction_screening_override: bool, sender: record<address: record, date_of_birth: string, email: string, first_name: string, government_ids: record, last_name: string, middle_name: string, nationality: string, phone: string, sanction_score: string>, sender_account_uri: string, statement_descriptor: string, status: string, status_timestamp: string, transaction_history: record<data: record, item_count: int, resource_type: string>, transfer_amount: record<currency: string, value: string>, transfer_reference: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partner_id | is-empty) { error make --unspanned { msg: "path parameter 'partner-id' must be non-empty" } }
  if ($transfer_id | is-empty) { error make --unspanned { msg: "path parameter 'transfer-id' must be non-empty" } }
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transaction-id' must be non-empty" } }
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id), transfer_id: (encode-path-segment $transfer_id), transaction_id: (encode-path-segment $transaction_id)} | format pattern "/send/v1/partners/{partner_id}/transfers/{transfer_id}/transactions/{transaction_id}/reversals"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml" $req_body {query: {}, body: $req_body}
}

# Client can simulate a Mastercard Merchant Presented QR Payment notification to the registered URL endpoint.
#
# POST /send/v1/partners/{partnerId}/events/generate/payment
# operationId: sendNotificationPaymentRetry
export def "send-partners-events-generate-payment send-notification-retry" [
  partner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<notification_response: record<status: string, transfer_reference: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partner_id | is-empty) { error make --unspanned { msg: "path parameter 'partnerId' must be non-empty" } }
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/send/v1/partners/{partner_id}/events/generate/payment"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "N/A"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml" $req_body {query: {}, body: $req_body}
}

# Client can simulate a Mastercard Merchant Presented QR Refund notification to the registered URL endpoint.
#
# POST /send/v1/partners/{partnerId}/events/generate/refund
# operationId: sendNotificationRefundRetry
export def "send-partners-events-generate-refund send-notification-retry" [
  partner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<notification_response: record<status: string, transfer_reference: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partner_id | is-empty) { error make --unspanned { msg: "path parameter 'partnerId' must be non-empty" } }
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/send/v1/partners/{partner_id}/events/generate/refund"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "N/A"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml" $req_body {query: {}, body: $req_body}
}

# This service allows Mastercard Merchant QR originating and receiving partners to register a PAN and service provider to receive notifications on an inbound Merchant Refund or Merchant Payment Transaction.
#
# POST /send/v1/partners/{partnerId}/notification-registries
# operationId: createTransferNotificationRegistration
# --accountregistration shape: {account_uri: string, notification_partner_id: string}
export def "send-partners-notification-registries create-transfer-registration" [
  partner_id: string
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
  --accountregistration: record # Contains the details of the request message. — shape: {account_uri: string, notification_partner_id: string}
]: any -> record<accountregistration: record<account_registration_reference: string, account_uri: string, notification_partner_id: string, notification_partner_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partner_id | is-empty) { error make --unspanned { msg: "path parameter 'partnerId' must be non-empty" } }
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/send/v1/partners/{partner_id}/notification-registries"))
  let req_body = {"accountregistration": $accountregistration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# This service allows Mastercard Merchant QR originating and receiving partners to delete a registered PAN for notifications.
#
# DELETE /send/v1/partners/{partnerId}/notification-registries/{account-reg-ref}
# operationId: deleteTransferNotificationRegistration
export def "send-partners-notification-registries delete-transfer-registration" [
  partner_id: string
  account_reg_ref: string
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
]: nothing -> record<accountregistration: record<account_registration_reference: string, account_uri: string, notification_partner_id: string, notification_partner_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partner_id | is-empty) { error make --unspanned { msg: "path parameter 'partnerId' must be non-empty" } }
  if ($account_reg_ref | is-empty) { error make --unspanned { msg: "path parameter 'account-reg-ref' must be non-empty" } }
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id), account_reg_ref: (encode-path-segment $account_reg_ref)} | format pattern "/send/v1/partners/{partner_id}/notification-registries/{account_reg_ref}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This service allows Mastercard Merchant QR originating and receiving partners to retrieve the service provider's information for a registered PAN for notifications.
#
# GET /send/v1/partners/{partnerId}/notification-registries/{account-reg-ref}
# operationId: NotificationRegistrationAPIReadBy
export def "send-partners-notification-registries get-registration" [
  partner_id: string
  account_reg_ref: string
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
]: nothing -> record<accountregistration: record<account_registration_reference: string, account_uri: string, notification_partner_id: string, notification_partner_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partner_id | is-empty) { error make --unspanned { msg: "path parameter 'partnerId' must be non-empty" } }
  if ($account_reg_ref | is-empty) { error make --unspanned { msg: "path parameter 'account-reg-ref' must be non-empty" } }
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id), account_reg_ref: (encode-path-segment $account_reg_ref)} | format pattern "/send/v1/partners/{partner_id}/notification-registries/{account_reg_ref}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# This service allows Mastercard Merchant QR originating and receiving partners to update the notitification service provider for a registered PAN.
#
# PUT /send/v1/partners/{partnerId}/notification-registries/{account-reg-ref}
# operationId: NotificationRegistrationAPIUpdate
# --accountregistration shape: {account_uri: string, notification_partner_id: string}
export def "send-partners-notification-registries update-registration" [
  partner_id: string
  account_reg_ref: string
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
  --accountregistration: record # Contains the details of the request message. — shape: {account_uri: string, notification_partner_id: string}
]: any -> record<accountregistration: record<account_registration_reference: string, account_uri: string, notification_partner_id: string, notification_partner_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partner_id | is-empty) { error make --unspanned { msg: "path parameter 'partnerId' must be non-empty" } }
  if ($account_reg_ref | is-empty) { error make --unspanned { msg: "path parameter 'account-reg-ref' must be non-empty" } }
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id), account_reg_ref: (encode-path-segment $account_reg_ref)} | format pattern "/send/v1/partners/{partner_id}/notification-registries/{account_reg_ref}"))
  let req_body = {"accountregistration": $accountregistration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The Funding Transaction enables the 'pull' of money from the sender's card to the Transaction Originator who is providing the Person to Merchant service. The amount that is debited from the Funding Account (sending consumer's account) will be the amount 'pushed' to the recipient via a payment transfer request. Funds can be transferred from Mastercard® or Maestro® debit card accounts. To initiate the funding transaction, users can provide the sending consumer's Primary Account Number (PAN) or a unique identifier previously mapped to the sending consumer's account.
#
# POST /send/v1/partners/{partnerId}/transfers/funding
# operationId: createFunding
export def "send-partners-transfers-funding create" [
  partner_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<transfer: record<channel: string, created: string, device_id: string, id: string, interchange_rate_designator: string, location: string, original_status: string, payment_type: string, recipient: record<address: record, date_of_birth: string, email: string, first_name: string, government_ids: record, last_name: string, merchant_category_code: string, middle_name: string, nationality: string, phone: string, sanction_score: string>, recipient_account_uri: string, reconciliation_data: record<custom_field: list>, resource_type: string, sanction_screening_override: bool, sender: record<additional_merchant_data: record, address: record, date_of_birth: string, email: string, first_name: string, government_ids: record, last_name: string, middle_name: string, nationality: string, phone: string, sanction_score: string>, sender_account_uri: string, statement_descriptor: string, status: string, status_timestamp: string, transaction_history: record<data: record, item_count: int, resource_type: string>, transfer_amount: record<currency: string, value: string>, transfer_reference: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partner_id | is-empty) { error make --unspanned { msg: "path parameter 'partnerId' must be non-empty" } }
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/send/v1/partners/{partner_id}/transfers/funding"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/xml" $req_body {query: {}, body: $req_body}
}

# Used to create a digital account reference number from Incontrol
#
# POST /send/v1/{partnerId}/digital-account
# operationId: createDigitalAccntRefNum
# --digital_account shape: {account_type: string, account_uri: string, reference: string}
export def "send-digital-account create-accnt-ref-num" [
  partner_id: string
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
  --digital-account: record # Contains the details of the request message. — shape: {account_type: string, account_uri: string, reference: string}
]: any -> record<digital_account: record<account_type: string, account_uri: string, digital_account_reference_number: record<issue_timestamp: string, pan: string>, reference: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partner_id | is-empty) { error make --unspanned { msg: "path parameter 'partnerId' must be non-empty" } }
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/send/v1/{partner_id}/digital-account"))
  let req_body = {"digital_account": $digital_account} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Used to retreive a digital account reference list from Incontrol
#
# POST /send/v1/{partnerId}/digital-account/search
# operationId: retrieveDigitalAccntRefNumList
# --digital_account shape: {account_type: string, account_uri: string, reference: string}
export def "send-digital-account-search get-accnt-ref-num-list" [
  partner_id: string
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
  --digital-account: record # Contains the details of the request message. — shape: {account_type: string, account_uri: string, reference: string}
]: any -> record<digital_account: record<account_type: string, account_uri: string, digital_account_reference_numbers: record<digital_account_reference_number: list>, reference: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partner_id | is-empty) { error make --unspanned { msg: "path parameter 'partnerId' must be non-empty" } }
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/send/v1/{partner_id}/digital-account/search"))
  let req_body = {"digital_account": $digital_account} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
