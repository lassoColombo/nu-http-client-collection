# Auto-generated client for Open Banking - Payments initiation service v1.16.0
# Source: https://api.apis.guru/v2/specs/mastercard.com/open-banking-connect-pis/1.16.0/swagger.json
# Auth: --token flag or $env.OPEN_BANKING_PAYMENTS_INITIATION_SERVICE_TOKEN

const BASE_URL = "https://localhost/openbanking/sandbox/connect/api"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPEN_BANKING_PAYMENTS_INITIATION_SERVICE_TOKEN | default "" }
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

def base-url-completer [] { ["https://localhost/openbanking/sandbox/connect/api"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<connectors: table<name: string, status: string, statusMessage: string>, status: string, statusMessage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payments/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
