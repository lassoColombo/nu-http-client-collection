# Auto-generated client for Send Person to Merchant vV1
# Source: https://api.apis.guru/v2/specs/mastercard.com/masterpassqr/V1/swagger.json
# Auth: --token flag or $env.SEND_PERSON_TO_MERCHANT_TOKEN

const BASE_URL = "https://api.mastercard.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o SEND_PERSON_TO_MERCHANT_TOKEN | default "" }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
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
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/send/") $auth.query)
  let req_body = {"merchant_transfer": $merchant_transfer} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/send/") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ref": $ref} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/send/") $auth.query)
  let req_body = {"merchant_payment_transfer": $merchant_payment_transfer} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/send/") $auth.query)
  let req_body = {"merchant_refund_transfer": $merchant_refund_transfer} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id), transfer_id: (encode-path-segment $transfer_id)} | format pattern "/send/") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id), transfer_id: (encode-path-segment $transfer_id), transaction_id: (encode-path-segment $transaction_id)} | format pattern "/send/v1/partners/{partner_id}/transfers/{transfer_id}/transactions/{transaction_id}/reversals") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/send/v1/partners/{partner_id}/events/generate/payment") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "N/A"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/send/v1/partners/{partner_id}/events/generate/refund") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "N/A"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/send/v1/partners/{partner_id}/notification-registries") $auth.query)
  let req_body = {"accountregistration": $accountregistration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id), account_reg_ref: (encode-path-segment $account_reg_ref)} | format pattern "/send/v1/partners/{partner_id}/notification-registries/{account_reg_ref}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id), account_reg_ref: (encode-path-segment $account_reg_ref)} | format pattern "/send/v1/partners/{partner_id}/notification-registries/{account_reg_ref}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id), account_reg_ref: (encode-path-segment $account_reg_ref)} | format pattern "/send/v1/partners/{partner_id}/notification-registries/{account_reg_ref}") $auth.query)
  let req_body = {"accountregistration": $accountregistration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/send/v1/partners/{partner_id}/transfers/funding") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/send/v1/{partner_id}/digital-account") $auth.query)
  let req_body = {"digital_account": $digital_account} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  let full_url = (build-url $base ({partner_id: (encode-path-segment $partner_id)} | format pattern "/send/v1/{partner_id}/digital-account/search") $auth.query)
  let req_body = {"digital_account": $digital_account} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
