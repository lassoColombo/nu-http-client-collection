# Auto-generated client for Open Banking - Payments initiation service v1.16.0
# Source: https://api.apis.guru/v2/specs/mastercard.com/open-banking-connect-pis/1.16.0/swagger.json
# Auth: --token flag or $env.OPEN_BANKING_PAYMENTS_INITIATION_SERVICE_TOKEN

const BASE_URL = "https://localhost/openbanking/sandbox/connect/api"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPEN_BANKING_PAYMENTS_INITIATION_SERVICE_TOKEN | default "" }
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

def base-url-completer [] { ["https://localhost/openbanking/sandbox/connect/api"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "payments-aspsps create" } } | get name | first)
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

# Get list of ASPSPs
#
# POST /payments/aspsps
# --requestInfo shape: {xRequestId: string}
export def "payments-aspsps create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Filter by country code (ISO 3166 Alpha 2), exact match pattern (e.g. GB)
  --id: string # Filter by internal id of ASPSP, exact match pattern (e.g. )
  --name: string # Filter by name of ASPSP, contains pattern (e.g. )
  request_info: record # shape: {xRequestId: string}
  --return-additional-data: list<string> # Specifies what additional fields for ASPSP object should be included in response
]: any -> record<aspsps: table<aspspServices: list, capabilities: record, country: string, id: string, logo: record, name: string, profile: string>, originalRequestInfo: record<xRequestId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payments/aspsps")
  let req_body = {"country": $country, "id": $id, "name": $name, "requestInfo": $request_info, "returnAdditionalData": $return_additional_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Extracts the original raw consent given by the aspsp
#
# POST /payments/consents/raw
# --requestInfo shape: {aspspId: string, consentId: string, merchant?: record, xRequestId: string}
export def "payments-consents-raw create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  request_info: any # shape: {aspspId: string, consentId: string, merchant?: record, xRequestId: string}
]: any -> record<originalRequestInfo: record<xRequestId: string>, rawConsent: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payments/consents/raw")
  let req_body = {"requestInfo": $request_info} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Redeem the payment
#
# POST /payments/cross-border-credit-transfers
# --requestInfo shape: {aspspId: string, authorization: string, merchant?: record, xRequestId: string}
export def "payments-cross-border-credit-transfers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  request_info: record # shape: {aspspId: string, authorization: string, merchant?: record, xRequestId: string}
]: any -> record<consent: record<consentId: string, consentRequestId: string, signatureStatus: string>, originalRequestInfo: record<xRequestId: string>, transfer: record<paymentId: string, statusReasonCode: string, transactionStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payments/cross-border-credit-transfers")
  let req_body = {"requestInfo": $request_info} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Request consent initiation via redirect
#
# POST /payments/cross-border-credit-transfers/consents
# --payments shape: {creditorAccount: record, creditorAddress?: record, creditorAgent: record, creditorName: string, debtorAccount: record, debtorAddress?: any, debtorName?: string, endToEndIdentification: string, instructedAmount: record, instructionIdentification?: string, instructionPriority: "Normal"|"Urgent", localInstrument: "Swift", remittanceInformationReference?: string, remittanceInformationUnstructured?: string, requestedExecutionDate?: string, transferCharges?: "SEN"|"SHA"|"BEN"}
# --requestInfo shape: {aspspId: string, flags?: list<string>, merchant?: record, tppRedirectURI: string, xRequestId: string}
export def "payments-cross-border-credit-transfers-consents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  payments: record # shape: {creditorAccount: record, creditorAddress?: record, creditorAgent: record, creditorName: string, debtorAccount: record, debtorAddress?: any, debtorName?: string, endToEndIdentification: string, instructedAmount: record, instructionIdentification?: string, instructionPriority: "Normal"|"Urgent", localInstrument: "Swift", remittanceInformationReference?: string, remittanceInformationUnstructured?: string, requestedExecutionDate?: string, transferCharges?: "SEN"|"SHA"|"BEN"}
  request_info: record # shape: {aspspId: string, flags?: list<string>, merchant?: record, tppRedirectURI: string, xRequestId: string}
]: any -> record<_links: record<scaRedirect: string>, additionalData: record<rawConsent: string>, aspspSCAApproach: string, consentRequestId: string, originalRequestInfo: record<xRequestId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payments/cross-border-credit-transfers/consents")
  let req_body = {"payments": $payments, "requestInfo": $request_info} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get payment status
#
# POST /payments/cross-border-credit-transfers/payment-status
# --requestInfo shape: {aspspId: string, consentId: string, merchant?: record, xRequestId: string}
export def "payments-cross-border-credit-transfers-payment-status create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  payment_id: string # Payment identification (e.g. 258aFR415:22Aa:6asdC)
  request_info: record # shape: {aspspId: string, consentId: string, merchant?: record, xRequestId: string}
]: any -> record<originalRequestInfo: record<xRequestId: string>, payments: record<statusReasonCode: string, transactionStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payments/cross-border-credit-transfers/payment-status")
  let req_body = {"paymentId": $payment_id, "requestInfo": $request_info} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Redeem the payment
#
# POST /payments/domestic-credit-transfers
# --requestInfo shape: {aspspId: string, authorization: string, merchant?: record, xRequestId: string}
export def "payments-domestic-credit-transfers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  request_info: record # shape: {aspspId: string, authorization: string, merchant?: record, xRequestId: string}
]: any -> record<consent: record<consentId: string, consentRequestId: string, signatureStatus: string>, originalRequestInfo: record<xRequestId: string>, transfer: record<paymentId: string, statusReasonCode: string, transactionStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payments/domestic-credit-transfers")
  let req_body = {"requestInfo": $request_info} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Request consent initiation via redirect
#
# POST /payments/domestic-credit-transfers/consents
# --payments shape: {creditorAccount: record, creditorAddress?: record, creditorAgent?: record, creditorName: string, debtorAccount?: any, debtorAgent?: any, endToEndIdentification: string, instructedAmount: record, instructionIdentification?: string, instructionPriority?: "Normal"|"Urgent", localInstrument: "UK.FasterPayments"|"PL.Elixir", remittanceInformationReference?: string, remittanceInformationUnstructured?: string, requestedExecutionDate?: string, schedule?: record}
# --requestInfo shape: {aspspId: string, flags?: list<string>, merchant?: record, tppRedirectURI: string, xRequestId: string}
export def "payments-domestic-credit-transfers-consents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  payments: record # shape: {creditorAccount: record, creditorAddress?: record, creditorAgent?: record, creditorName: string, debtorAccount?: any, debtorAgent?: any, endToEndIdentification: string, instructedAmount: record, instructionIdentification?: string, instructionPriority?: "Normal"|"Urgent", localInstrument: "UK.FasterPayments"|"PL.Elixir", remittanceInformationReference?: string, remittanceInformationUnstructured?: string, requestedExecutionDate?: string, schedule?: record}
  request_info: record # shape: {aspspId: string, flags?: list<string>, merchant?: record, tppRedirectURI: string, xRequestId: string}
]: any -> record<_links: record<scaRedirect: string>, additionalData: record<rawConsent: string>, aspspSCAApproach: string, consentRequestId: string, originalRequestInfo: record<xRequestId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payments/domestic-credit-transfers/consents")
  let req_body = {"payments": $payments, "requestInfo": $request_info} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get payment status
#
# POST /payments/domestic-credit-transfers/payment-status
# --requestInfo shape: {aspspId: string, consentId: string, merchant?: record, xRequestId: string}
export def "payments-domestic-credit-transfers-payment-status create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  payment_id: string # Payment identification (e.g. UK8aFR415:22Aa:6asdC)
  request_info: record # shape: {aspspId: string, consentId: string, merchant?: record, xRequestId: string}
]: any -> record<originalRequestInfo: record<xRequestId: string>, payments: record<statusReasonCode: string, transactionStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payments/domestic-credit-transfers/payment-status")
  let req_body = {"paymentId": $payment_id, "requestInfo": $request_info} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the status of each connectivity provider
#
# GET /payments/health
export def "payments-health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<connectors: table<name: string, status: string, statusMessage: string>, status: string, statusMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payments/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Redeem the payment
#
# POST /payments/sepa-credit-transfers
# --requestInfo shape: {aspspId: string, authorization: string, merchant?: record, xRequestId: string}
export def "payments-sepa-credit-transfers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  request_info: record # shape: {aspspId: string, authorization: string, merchant?: record, xRequestId: string}
]: any -> record<consent: record<consentId: string, consentRequestId: string>, originalRequestInfo: record<xRequestId: string>, transfer: record<paymentId: string, statusReasonCode: string, transactionStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payments/sepa-credit-transfers")
  let req_body = {"requestInfo": $request_info} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Request consent initiation via redirect
#
# POST /payments/sepa-credit-transfers/consents
# --payments shape: {categoryPurpose?: "CASH"|"CORT"|"DVPM"|"INTC"|"TREA", creditorAccount: record, creditorAddress: record, creditorAgent: any, creditorName: string, debtorAccount?: record, debtorAddress?: record, debtorAgent?: any, debtorName: string, endToEndIdentification: string, instructedAmount: record, instructionPriority: "Normal"|"Urgent", localInstrument: "SEPA", remittanceInformationReference?: string, remittanceInformationStructured?: string, remittanceInformationUnstructured?: string, ... (2 more fields)}
# --requestInfo shape: {aspspId: string, flags?: list<string>, merchant?: record, tppRedirectURI: string, xRequestId: string}
export def "payments-sepa-credit-transfers-consents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  payments: record # shape: {categoryPurpose?: "CASH"|"CORT"|"DVPM"|"INTC"|"TREA", creditorAccount: record, creditorAddress: record, creditorAgent: any, creditorName: string, debtorAccount?: record, debtorAddress?: record, debtorAgent?: any, debtorName: string, endToEndIdentification: string, instructedAmount: record, instructionPriority: "Normal"|"Urgent", localInstrument: "SEPA", remittanceInformationReference?: string, remittanceInformationStructured?: string, remittanceInformationUnstructured?: string, ... (2 more fields)}
  request_info: record # shape: {aspspId: string, flags?: list<string>, merchant?: record, tppRedirectURI: string, xRequestId: string}
]: any -> record<_links: record<scaRedirect: string>, additionalData: record<rawConsent: string>, aspspSCAApproach: string, consentRequestId: string, originalRequestInfo: record<xRequestId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payments/sepa-credit-transfers/consents")
  let req_body = {"payments": $payments, "requestInfo": $request_info} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get payment status
#
# POST /payments/sepa-credit-transfers/payment-status
# --requestInfo shape: {aspspId: string, consentId: string, merchant?: record, xRequestId: string}
export def "payments-sepa-credit-transfers-payment-status create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  payment_id: string # Payment identification (e.g. wAa:665hs5:r5544dhhKM)
  request_info: record # shape: {aspspId: string, consentId: string, merchant?: record, xRequestId: string}
]: any -> record<originalRequestInfo: record<xRequestId: string>, payments: record<statusReasonCode: string, transactionStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payments/sepa-credit-transfers/payment-status")
  let req_body = {"paymentId": $payment_id, "requestInfo": $request_info} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
