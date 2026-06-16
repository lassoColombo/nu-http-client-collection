# Auto-generated client for Velo Payments APIs v2.34.63
# Source: https://api.apis.guru/v2/specs/velopayments.com/2.34.63/openapi.json
# Auth: --token flag or $env.VELO_PAYMENTS_APIS_TOKEN

const BASE_URL = "https://api.sandbox.velopayments.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VELO_PAYMENTS_APIS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://api.sandbox.velopayments.com" "https://api.payouts.velopayments.com"] }
def auth-scheme-completer [] { ["bearer" "basic"] }

# Completers for enum parameters
def linkType-completer [] { ["PARENT_OF"] }
def type-completer [] { ["FBO" "PRIVATE" "WUBS_DECOUPLED"] }
def type-completer-1 [] { ["BACKOFFICE" "PAYEE" "PAYOR"] }
def status-completer [] { ["DISABLED" "ENABLED" "PENDING"] }
def payeeType-completer [] { ["COMPANY" "INDIVIDUAL"] }
def mfaType-completer [] { ["SMS" "TOTP" "YUBIKEY"] }
def userType-completer [] { ["BACKOFFICE" "PAYEE" "PAYOR"] }
def mfaType-completer-1 [] { ["TOTP" "YUBIKEY"] }
def tokenType-completer [] { ["INVITE_MFA_USER" "MFA_REGISTRATION"] }
def payeeType-completer-1 [] { ["Company" "Individual"] }
def status-completer-1 [] { ["ACCEPTED" "ACCEPTED_BY_RAILS" "AWAITING_FUNDS" "BANK_PAYMENT_REQUESTED" "CONFIRMED" "FAILED" "FUNDED" "REJECTED" "RETURNED" "UNFUNDED" "WITHDRAWN"] }
def status-completer-2 [] { ["ACCEPTED" "COMPLETED" "CONFIRMED" "INCOMPLETE" "INSTRUCTED" "QUOTED" "REJECTED" "SUBMITTED" "WITHDRAWN"] }
def status-completer-3 [] { ["ACCEPTED" "REJECTED" "WITHDRAWABLE" "WITHDRAWN"] }
def transmissionType-completer [] { ["ACH" "SAME_DAY_ACH" "WIRE"] }
def transmissionType-completer-1 [] { ["ACH" "GACHO" "LOCAL" "SAME_DAY_ACH" "WIRE"] }
def scheduleStatus-completer [] { ["ANY" "EXECUTED" "FAILED" "SCHEDULED"] }
def postInstructFxStatus-completer [] { ["ANY" "CANCELLED" "COMPLETED" "EXECUTED" "INITIATED" "REFUNDED" "RESUBMITTED" "RETURNED"] }
def include-completer [] { ["payorAndDescendants" "payorOnly"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "authenticate veloAuth" } } | get name | first)
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

# Authentication endpoint
#
# POST /v1/authenticate
# operationId: veloAuth
export def "authenticate veloAuth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --grant-type: string # OAuth grant type. Should use 'client_credentials' (default: client_credentials)
]: nothing -> record<access_token: string, entityIds: list<string>, expires_in: float, refresh_token: string, scope: string, token_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "grant_type" $grant_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/authenticate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Funding Audit Delta
#
# GET /v1/deltas/fundings
# operationId: listFundingAuditDeltas
export def "deltas-fundings listFundingAuditDeltas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payorId: string # format: uuid
  --updatedSince: string # format: date-time
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --pageSize: int # The number of results to return in a page (format: int32, default: 25)
]: nothing -> record<content: table<amount: int, currency: string, fundingId: string, status: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payorId "scalar") (serialize-qp "updatedSince" $updatedSince "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/deltas/fundings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# V1 List Payment Changes
#
# GET /v1/deltas/payments
# DEPRECATED
# operationId: listPaymentChanges
@deprecated
export def "deltas-payments listPaymentChanges" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payorId: string # The Payor ID to find associated Payments (format: uuid)
  --updatedSince: string # The updatedSince filter in the format YYYY-MM-DDThh:mm:ss+hh:mm (format: date-time)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --pageSize: int # The number of results to return in a page (format: int32, default: 100)
]: nothing -> record<content: table<paymentAmount: int, paymentCurrency: string, paymentId: string, payorPaymentId: string, payoutId: string, sourceAmount: int, sourceCurrency: string, status: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payorId "scalar") (serialize-qp "updatedSince" $updatedSince "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/deltas/payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Funding
#
# GET /v1/fundings/{fundingId}
# operationId: getFundingByIdV1
export def "fundings get" [
  fundingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allocationDate: string, allocationType: string, amount: int, currency: string, detectedFundingRef: string, fundingAccountType: string, fundingId: string, hiddenDate: string, payorId: string, physicalAccountName: string, reason: string, sourceAccountId: string, status: string, text: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/fundings/($fundingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Logout
#
# POST /v1/logout
# operationId: logout
export def "logout logout" [
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
  let full_url = (build-url $base "/v1/logout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset password
#
# POST /v1/password/reset
# operationId: resetPassword
export def "password-reset resetPassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # the email address of the user requesting the reset password (format: email, e.g. foo@example.com)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/password/reset")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Payment Channel Country Rules
#
# GET /v1/paymentChannelRules
# operationId: listPaymentChannelRulesV1
export def "payment-channel-rules listPaymentChannelRulesV1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bank: table<isoCountryCode: string, rules: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/paymentChannelRules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# V1 Get Fundings for Payor
#
# GET /v1/paymentaudit/fundings
# DEPRECATED
# operationId: getFundingsV1
@deprecated
export def "paymentaudit-fundings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payorId: string # The account owner Payor ID (format: uuid)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --pageSize: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields. Example: ```?sort=destinationCurrency:asc,destinationAmount:asc``` Default is no sort. The supported sort fields are: dateTime and amount.
]: nothing -> record<content: table<amount: float, currency: string, dateTime: string, events: list, fundingAccountName: string, fundingType: string, sourceAccountName: string, status: string, topupType: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payorId "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/paymentaudit/fundings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# V1 Get Payout Statistics
#
# GET /v1/paymentaudit/payoutStatistics
# DEPRECATED
# operationId: getPayoutStatsV1
@deprecated
export def "paymentaudit-payout-statistics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payorId: string # The account owner Payor ID. Required for external users. (format: uuid)
]: nothing -> record<thisMonthFailedPaymentsCount: int, thisMonthPayoutsCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payorId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/paymentaudit/payoutStatistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Withdraw a Payment
#
# POST /v1/payments/{paymentId}/withdraw
# operationId: withdrawPayment
export def "payments-withdraw withdrawPayment" [
  paymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  reason: string # Reason for withdrawal (e.g. Payment submitted in error)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/payments/($paymentId)/withdraw")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Payor Links
#
# GET /v1/payorLinks
# operationId: payorLinksV1
export def "payor-links payorLinksV1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --descendantsOfPayor: string # The Payor ID from which to start the query to show all descendants (format: uuid)
  --parentOfPayor: string # Query for the parent payor details for this payor id (format: uuid)
  --fields: string # <p>List of additional Payor fields to include in the response for each Payor</p> <p>The values of payorId and payorName are always included for each Payor by default</p> <p>You can add fields to the response for each payor by including them in the fields parameter separated by commas</p> <p>The supported fields are any combination of: primaryContactEmail,kycState</p>
]: nothing -> record<links: table<fromPayorId: string, linkId: string, linkType: string, toPayorId: string>, payors: table<kycState: string, payorId: string, payorName: string, primaryContactEmail: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "descendantsOfPayor" $descendantsOfPayor "scalar") (serialize-qp "parentOfPayor" $parentOfPayor "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/payorLinks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Payor Link
#
# POST /v1/payorLinks
# operationId: createPayorLinks
export def "payor-links createPayorLinks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  fromPayorId: string # format: uuid
  linkType: string@linkType-completer
  toPayorId: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/payorLinks")
  let body = {fromPayorId: $fromPayorId, linkType: $linkType, toPayorId: $toPayorId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Payor
#
# GET /v1/payors/{payorId}
# DEPRECATED
# operationId: getPayorByIdV1
@deprecated
export def "payors get-by-payorId" [
  payorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: record<city: string, country: string, countyOrProvince: string, line1: string, line2: string, line3: string, line4: string, zipOrPostcode: string>, allowsLanguageChoice: bool, collectiveAlias: string, dbaName: string, fundingAccountAccountName: string, fundingAccountAccountNumber: string, fundingAccountRoutingNumber: string, includesReports: bool, kycState: string, language: string, manualLockout: bool, maxMasterPayorAdmins: int, payeeGracePeriodDays: int, payeeGracePeriodProcessingEnabled: bool, payorId: string, payorName: string, primaryContactEmail: string, primaryContactName: string, primaryContactPhone: string, reminderEmailsOptOut: bool, supportContact: string, transmissionTypes: record<ACH: bool, SAME_DAY_ACH: bool, WIRE: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/payors/($payorId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Application
#
# POST /v1/payors/{payorId}/applications
# operationId: payorCreateApplicationV1
export def "payors-applications payorCreateApplicationV1" [
  payorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the application. (nullable, e.g. SAP Application integration)
  name: string # The name of the application. (e.g. SAP)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/payors/($payorId)/applications")
  let body = {description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create API Key
#
# POST /v1/payors/{payorId}/applications/{applicationId}/keys
# operationId: payorCreateApiKeyV1
export def "payors-applications-keys payorCreateApiKeyV1" [
  payorId: string
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the key. (nullable, e.g. Key for iOS mobile application)
  name: string # A name for the key. (e.g. iOS Key)
  roles: list # <p>A role to assign to the key.</p> <p>If you want your API key to have write access then assign the role velo.payor.admin</p> <p>A later version will change this property from a list to string</p>  (e.g. [velo.payor.admin])
]: any -> record<apiKey: string, apiSecret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/payors/($payorId)/applications/($applicationId)/keys")
  let body = {description: $description, name: $name, roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Branding
#
# GET /v1/payors/{payorId}/branding
# operationId: payorGetBranding
export def "payors-branding payorGetBranding" [
  payorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<collectiveAlias: string, dbaName: string, logoUrl: string, payorName: string, supportContact: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/payors/($payorId)/branding")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Logo
#
# POST /v1/payors/{payorId}/branding/logos
# operationId: payorAddPayorLogoV1
export def "payors-branding-logos payorAddPayorLogoV1" [
  payorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --logo: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/payors/($payorId)/branding/logos")
  let body = {logo: $logo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Reminder Email Opt-Out
#
# POST /v1/payors/{payorId}/reminderEmailsUpdate
# operationId: payorEmailOptOut
export def "payors-reminder-emails-update payorEmailOptOut" [
  payorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reminderEmailsOptOut: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/payors/($payorId)/reminderEmailsUpdate")
  let body = {reminderEmailsOptOut: $reminderEmailsOptOut} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set notifications
#
# POST /v1/sourceAccounts/{sourceAccountId}/notifications
# DEPRECATED
# operationId: setNotificationsRequest
@deprecated
export def "source-accounts-notifications setNotificationsRequest" [
  sourceAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  minimumBalance: int # Amount to set as minimum balance in minor units (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sourceAccounts/($sourceAccountId)/notifications")
  let body = {minimumBalance: $minimumBalance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Supported Countries
#
# GET /v1/supportedCountries
# DEPRECATED
# operationId: listSupportedCountriesV1
@deprecated
export def "supported-countries listSupportedCountriesV1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countries: table<currencies: list, isoCountryCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/supportedCountries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# validate
#
# POST /v1/validate
# operationId: validateAccessToken
export def "validate validateAccessToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Bearer token authorization leg of validate
  otp: string # an OTP either sent via sms or generated by a registered MFA device (e.g. 123456)
]: any -> record<access_token: string, entityIds: list<string>, expires_in: int, refresh_token: string, scope: string, token_type: string, user_info: record<mfa_details: record<mfa_type: string, verified: bool>, userType: string, user_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/validate")
  let body = {otp: $otp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the details about the webhooks for the given payor.
#
# GET /v1/webhooks
# operationId: listWebhooksV1
export def "webhooks listWebhooksV1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --pageSize: int # The number of results to return in a page (format: int32, default: 25)
  --payorId: string # The Payor ID (format: uuid)
]: nothing -> record<content: table<authorizationHeader: string, categories: list, enabled: bool, id: string, payorId: string, webhookUrl: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "payorId" $payorId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Webhook
#
# POST /v1/webhooks
# operationId: createWebhookV1
export def "webhooks createWebhookV1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorizationHeader: string # the authorization header to include with the notification.
  --categories: list # the categories to enable.
  --enabled: oneof<nothing, bool> # whether the webhook is enabled.
  payorId: string # format: uuid
  webhookUrl: string # the webhook URL to use.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/webhooks")
  let body = {authorizationHeader: $authorizationHeader, categories: $categories, enabled: $enabled, payorId: $payorId, webhookUrl: $webhookUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get details about the given webhook.
#
# GET /v1/webhooks/{webhookId}
# operationId: getWebhookV1
export def "webhooks get" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<authorizationHeader: string, categories: list<string>, enabled: bool, id: string, payorId: string, webhookUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Webhook
#
# POST /v1/webhooks/{webhookId}
# operationId: updateWebhookV1
export def "webhooks updateWebhookV1" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorizationHeader: string # the authorization header to include with the notification. (nullable)
  --categories: list # The notification categories to enable. (nullable)
  --enabled: oneof<nothing, bool> # whether the webhook is enabled.
  --webhookUrl: string # the webhook URL to use.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/webhooks/($webhookId)")
  let body = {authorizationHeader: $authorizationHeader, categories: $categories, enabled: $enabled, webhookUrl: $webhookUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/webhooks/{webhookId}/ping
#
# operationId: pingWebhookV1
export def "webhooks-ping pingWebhookV1" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, webhookId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/webhooks/($webhookId)/ping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Supported Currencies
#
# GET /v2/currencies
# operationId: listSupportedCurrenciesV2
export def "currencies listSupportedCurrenciesV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<currencies: table<currency: string, maxPaymentAmount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/currencies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Funding Accounts
#
# GET /v2/fundingAccounts
# operationId: getFundingAccountsV2
export def "funding-accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payorId: string # format: uuid
  --name: string # The descriptive funding account name
  --country: string # The 2 letter ISO 3166-1 country code (upper case) (e.g. US)
  --currency: string # The ISO 4217 currency code (e.g. USD)
  --type: string # The type of funding account. (e.g. FBO)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --pageSize: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields (e.g. ?sort=accountName:asc,name:asc) Default is accountName:asc The supported sort fields are - accountName, name. (default: accountName:asc)
  --sensitive: oneof<nothing, bool> # default: false
]: nothing -> record<content: table<accountName: string, accountNumber: string, archived: bool, country: string, currency: string, id: string, name: string, payorId: string, routingNumber: string, type: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payorId "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sensitive" $sensitive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/fundingAccounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Funding Account
#
# POST /v2/fundingAccounts
# operationId: createFundingAccountV2
export def "funding-accounts createFundingAccountV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountName: string # Required if type is either FBO or PRIVATE
  --accountNumber: string # Required if type is either FBO or PRIVATE
  --currency: string # ISO 4217 currency code, Required if type is either WUBS_DECOUPLED or PRIVATE (e.g. USD)
  name: string
  payorId: string # format: uuid
  --routingNumber: string # Required if type is either FBO or PRIVATE
  type: string@type-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/fundingAccounts")
  let body = {accountName: $accountName, accountNumber: $accountNumber, currency: $currency, name: $name, payorId: $payorId, routingNumber: $routingNumber, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Funding Account
#
# GET /v2/fundingAccounts/{fundingAccountId}
# operationId: getFundingAccountV2
export def "funding-accounts get" [
  fundingAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sensitive: oneof<nothing, bool> # default: false
]: nothing -> record<accountName: string, accountNumber: string, archived: bool, country: string, currency: string, id: string, name: string, payorId: string, routingNumber: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sensitive" $sensitive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/fundingAccounts/($fundingAccountId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payor
#
# GET /v2/payors/{payorId}
# operationId: getPayorByIdV2
export def "payors get-by-payorId-1" [
  payorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: record<city: string, country: string, countyOrProvince: string, line1: string, line2: string, line3: string, line4: string, zipOrPostcode: string>, allowsLanguageChoice: bool, collectiveAlias: string, dbaName: string, includesReports: bool, kycState: string, language: string, managingPayees: bool, manualLockout: bool, maxMasterPayorAdmins: int, openBankingEnabled: bool, payeeGracePeriodDays: int, payeeGracePeriodProcessingEnabled: bool, paymentRails: string, payorId: string, payorName: string, payorXid: string, primaryContactEmail: string, primaryContactName: string, primaryContactPhone: string, provider: string, reminderEmailsOptOut: bool, remoteSystemIds: list<string>, supportContact: string, transmissionTypes: record<ACH: bool, SAME_DAY_ACH: bool, WIRE: bool>, usdTxnValueReportingThreshold: int, wuCustomerId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/payors/($payorId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of source accounts
#
# GET /v2/sourceAccounts
# DEPRECATED
# operationId: getSourceAccountsV2
@deprecated
export def "source-accounts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --physicalAccountName: string # Physical Account Name
  --physicalAccountId: string # The physical account ID (format: uuid)
  --payorId: string # The account owner Payor ID (format: uuid)
  --fundingAccountId: string # The funding account ID (format: uuid)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --pageSize: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields e.g. ?sort=name:asc Default is name:asc The supported sort fields are - fundingRef, name, balance  (default: fundingRef:asc)
]: nothing -> record<content: table<accountType: string, autoTopUpConfig: record, balance: int, balanceVisible: bool, currency: string, customerId: string, fundingAccountId: string, fundingRef: string, id: string, name: string, notifications: record, payorId: string, physicalAccountId: string, physicalAccountName: string, pooled: bool, railsId: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "physicalAccountName" $physicalAccountName "scalar") (serialize-qp "physicalAccountId" $physicalAccountId "scalar") (serialize-qp "payorId" $payorId "scalar") (serialize-qp "fundingAccountId" $fundingAccountId "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/sourceAccounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Source Account
#
# GET /v2/sourceAccounts/{sourceAccountId}
# DEPRECATED
# operationId: getSourceAccountV2
@deprecated
export def "source-accounts get-by-sourceAccountId" [
  sourceAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accountType: string, autoTopUpConfig: record<enabled: bool, minBalance: int, targetBalance: int>, balance: int, balanceVisible: bool, currency: string, customerId: string, fundingAccountId: string, fundingRef: string, id: string, name: string, notifications: record<minimumBalance: int>, payorId: string, physicalAccountId: string, physicalAccountName: string, pooled: bool, railsId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/sourceAccounts/($sourceAccountId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Funding Request
#
# POST /v2/sourceAccounts/{sourceAccountId}/fundingRequest
# DEPRECATED
# operationId: createFundingRequestV2
@deprecated
export def "source-accounts-funding-request createFundingRequestV2" [
  sourceAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: int # Amount to fund, decimal implied (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/sourceAccounts/($sourceAccountId)/fundingRequest")
  let body = {amount: $amount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Transfer Funds between source accounts
#
# POST /v2/sourceAccounts/{sourceAccountId}/transfers
# DEPRECATED
# operationId: transferFundsV2
@deprecated
export def "source-accounts-transfers transferFundsV2" [
  sourceAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: int # Amount to transfer, in minor units (format: int64)
  currency: string # e.g. USD
  toSourceAccountId: string # The 'to' source account id, which will be credited (format: uuid)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/sourceAccounts/($sourceAccountId)/transfers")
  let body = {amount: $amount, currency: $currency, toSourceAccountId: $toSourceAccountId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Supported Countries
#
# GET /v2/supportedCountries
# operationId: listSupportedCountriesV2
export def "supported-countries listSupportedCountriesV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countries: table<currencies: list, isoCountryCode: string, regions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/supportedCountries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Users
#
# GET /v2/users
# operationId: listUsers
export def "users listUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-1 # The Type of the User. (e.g. PAYOR)
  --status: string@status-completer # The status of the User. (e.g. ENABLED)
  --entityId: string # The entityId of the User. (format: uuid)
  --payeeType: string@payeeType-completer # The Type of the Payee entity. Either COMPANY or INDIVIDUAL. (e.g. COMPANY)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --pageSize: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields (e.g. ?sort=email:asc,lastName:asc) Default is email:asc 'name' The supported sort fields are - email, lastNmae.  (default: email:asc)
]: nothing -> record<content: table<companyName: string, email: string, entityId: string, firstName: string, id: string, lastName: string, lockedOut: bool, lockedOutTimestamp: string, mfaStatus: string, mfaType: string, primaryContactNumber: string, roles: list, secondaryContactNumber: string, smsNumber: string, status: string, userType: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "entityId" $entityId "scalar") (serialize-qp "payeeType" $payeeType "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invite a User
#
# POST /v2/users/invite
# operationId: inviteUser
export def "users-invite inviteUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # the email address of the invited user (format: email, e.g. foo@example.com)
  --entityId: string # The payorId or payeeId or null if the user is a backoffice admin  (nullable, format: uuid, e.g. 7fffa261-ac68-49e6-b605-d24a444d9206)
  --firstName: string # e.g. John
  --lastName: string # e.g. Doe
  mfaType: string@mfaType-completer # <p>The MFA type that the user will use</p> <p>The type may be conditional on the role(s) the user has</p>  (e.g. TOTP)
  primaryContactNumber: string # The main contact number for the user  (e.g. 11235555555)
  roles: list # The role(s) for the user The role must exist The role can be a custom role or a system role but the invoker must have the permissions to assign the role System roles are: velo.backoffice.admin, velo.payor.master_admin, velo.payor.admin, velo.payor.support, velo.payee.admin, velo.payee.support  (e.g. [velo.payor.admin])
  --secondaryContactNumber: string # The secondary contact number for the user  (nullable, e.g. 11235555550)
  smsNumber: string # The phone number of a device that the user can receive sms messages on  (e.g. 11235555555)
  --userType: string@userType-completer # Will default to PAYOR if not provided but entityId is provided (e.g. PAYEE)
  --verificationCode: string # Optional property that MUST be suppied when manually verifying a user The user's smsNumber is registered via a separate endpoint and an OTP sent to them  (nullable, e.g. 123456)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/users/invite")
  let body = {email: $email, entityId: $entityId, firstName: $firstName, lastName: $lastName, mfaType: $mfaType, primaryContactNumber: $primaryContactNumber, roles: $roles, secondaryContactNumber: $secondaryContactNumber, smsNumber: $smsNumber, userType: $userType, verificationCode: $verificationCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Register SMS Number
#
# POST /v2/users/registration/sms
# operationId: registerSms
export def "users-registration-sms registerSms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  smsNumber: string # The phone number of a device that the user can receive sms messages on  (e.g. 11235555555)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/users/registration/sms")
  let body = {smsNumber: $smsNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Self
#
# GET /v2/users/self
# operationId: getSelf
export def "users-self get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<companyName: string, email: string, entityId: string, firstName: string, id: string, lastName: string, lockedOut: bool, lockedOutTimestamp: string, mfaStatus: string, mfaType: string, primaryContactNumber: string, roles: table<name: string>, secondaryContactNumber: string, smsNumber: string, status: string, userType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/users/self")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unregister MFA for Self
#
# POST /v2/users/self/mfa/unregister
# operationId: unregisterMFAForSelf
export def "users-self-mfa-unregister unregisterMFAForSelf" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Bearer token authorization leg of validate
  mfaType: string@mfaType-completer # The type of the MFA device (e.g. TOTP)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/users/self/mfa/unregister")
  let body = {mfaType: $mfaType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Password for self
#
# POST /v2/users/self/password
# operationId: updatePasswordSelf
export def "users-self-password updatePasswordSelf" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  newPassword: string # The new password (e.g. My_new_password)
  oldPassword: string # The user's current password (e.g. My_current_password)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/users/self/password")
  let body = {newPassword: $newPassword, oldPassword: $oldPassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Validate the proposed password
#
# POST /v2/users/self/password/validate
# operationId: validatePasswordSelf
export def "users-self-password-validate validatePasswordSelf" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # a password that passes validation (e.g. My_strong_password)
]: any -> record<score: int, suggestions: list<string>, valid: bool, warning: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/users/self/password/validate")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update User Details for self
#
# POST /v2/users/self/userDetailsUpdate
# operationId: userDetailsUpdateForSelf
export def "users-self-user-details-update userDetailsUpdateForSelf" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # the email address of the user (nullable, format: email, e.g. foo@example.com)
  --firstName: string # nullable, e.g. John
  --lastName: string # nullable, e.g. Doe
  --primaryContactNumber: string # The main contact number for the user  (nullable, e.g. 11235555555)
  --secondaryContactNumber: string # The secondary contact number for the user  (nullable, e.g. 11235555550)
  --smsNumber: string # The phone number of a device that the user can receive sms messages on  (nullable, e.g. 11235555555)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/users/self/userDetailsUpdate")
  let body = {email: $email, firstName: $firstName, lastName: $lastName, primaryContactNumber: $primaryContactNumber, secondaryContactNumber: $secondaryContactNumber, smsNumber: $smsNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a User
#
# DELETE /v2/users/{userId}
# operationId: deleteUserByIdV2
export def "users delete" [
  userId: string
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
  let full_url = (build-url $base $"/v2/users/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get User
#
# GET /v2/users/{userId}
# operationId: getUserByIdV2
export def "users get" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<companyName: string, email: string, entityId: string, firstName: string, id: string, lastName: string, lockedOut: bool, lockedOutTimestamp: string, mfaStatus: string, mfaType: string, primaryContactNumber: string, roles: table<name: string>, secondaryContactNumber: string, smsNumber: string, status: string, userType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable a User
#
# POST /v2/users/{userId}/disable
# operationId: disableUserV2
export def "users-disable disableUserV2" [
  userId: string
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
  let full_url = (build-url $base $"/v2/users/($userId)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable a User
#
# POST /v2/users/{userId}/enable
# operationId: enableUserV2
export def "users-enable enableUserV2" [
  userId: string
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
  let full_url = (build-url $base $"/v2/users/($userId)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unregister MFA for the user
#
# POST /v2/users/{userId}/mfa/unregister
# operationId: unregisterMFA
export def "users-mfa-unregister unregisterMFA" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  mfaType: string@mfaType-completer-1 # The type of the MFA device (e.g. TOTP)
  --verificationCode: string # <p>Optional property that MUST be suppied when manually verifying a user</p> <p>The user's smsNumber is registered via a separate endpoint and an OTP sent to them</p>  (nullable, e.g. 123456)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($userId)/mfa/unregister")
  let body = {mfaType: $mfaType, verificationCode: $verificationCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update User Role
#
# POST /v2/users/{userId}/roleUpdate
# operationId: roleUpdate
export def "users-role-update roleUpdate" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  roles: list # <p>The role(s) for the user</p> <p>The role must exist</p> <p>The role can be a custom role or a system role but the invoker must have the permissions to assign the role</p> <p>System roles are: backoffice.admin, payor.master_admin, payor.admin, payor.support</p>  (e.g. [payor.admin])
  --verificationCode: string # <p>Optional property that MUST be suppied when manually verifying a user</p> <p>The user's smsNumber is registered via a separate endpoint and an OTP sent to them</p>  (nullable, e.g. 123456)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($userId)/roleUpdate")
  let body = {roles: $roles, verificationCode: $verificationCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resend a token
#
# POST /v2/users/{userId}/tokens
# operationId: resendToken
export def "users-tokens resendToken" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  tokenType: string@tokenType-completer # The type of the token to resend (e.g. INVITE_MFA_USER)
  --verificationCode: string # <p>Optional property that MUST be suppied when manually verifying a user</p> <p>The user's smsNumber is registered via a separate endpoint and an OTP sent to them</p>  (nullable, e.g. 123456)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($userId)/tokens")
  let body = {tokenType: $tokenType, verificationCode: $verificationCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unlock a User
#
# POST /v2/users/{userId}/unlock
# operationId: unlockUserV2
export def "users-unlock unlockUserV2" [
  userId: string
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
  let full_url = (build-url $base $"/v2/users/($userId)/unlock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update User Details
#
# POST /v2/users/{userId}/userDetailsUpdate
# operationId: userDetailsUpdate
export def "users-user-details-update userDetailsUpdate" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # the email address of the user (nullable, format: email, e.g. foo@example.com)
  --firstName: string # nullable, e.g. John
  --lastName: string # nullable, e.g. Doe
  --mfaType: string@mfaType-completer # The type of the MFA device (nullable, e.g. TOTP)
  --primaryContactNumber: string # The main contact number for the user  (nullable, e.g. 11235555555)
  --secondaryContactNumber: string # The secondary contact number for the user  (nullable, e.g. 11235555550)
  --smsNumber: string # The phone number of a device that the user can receive sms messages on  (nullable, e.g. 11235555555)
  --verificationCode: string # <p>Optional property that MUST be suppied when manually verifying a user</p> <p>The user's smsNumber is registered via a separate endpoint and an OTP sent to them</p>  (nullable, e.g. 123456)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/users/($userId)/userDetailsUpdate")
  let body = {email: $email, firstName: $firstName, lastName: $lastName, mfaType: $mfaType, primaryContactNumber: $primaryContactNumber, secondaryContactNumber: $secondaryContactNumber, smsNumber: $smsNumber, verificationCode: $verificationCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Payees
#
# GET /v3/payees
# DEPRECATED
# operationId: listPayeesV3
@deprecated
export def "payees listPayeesV3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payorId: string # The account owner Payor ID (format: uuid)
  --watchlistStatus: string # The watchlistStatus of the payees.
  --disabled: oneof<nothing, bool> # Payee disabled
  --onboardedStatus: string # The onboarded status of the payees.
  --email: string # Email address (format: email, e.g. bob@example.com)
  --displayName: string # The display name of the payees. (e.g. Bob Smith)
  --remoteId: string # The remote id of the payees. (e.g. remoteId123)
  --payeeType: string # The onboarded status of the payees.
  --payeeCountry: string # The country of the payee - 2 letter ISO 3166-1 country code (upper case) (e.g. US)
  --page: int # Page number. Default is 1. (format: int32, default: 1, e.g. 1)
  --pageSize: int # Page size. Default is 25. Max allowable is 100. (format: int32, default: 25, e.g. 25)
  --qp-sort: string # List of sort fields (e.g. ?sort=onboardedStatus:asc,name:asc) Default is name:asc 'name' is treated as company name for companies - last name + ',' + firstName for individuals The supported sort fields are - payeeId, displayName, payoutStatus, onboardedStatus.  (default: displayName:asc, e.g. displayName:asc)
]: nothing -> record<content: table<company: record, country: string, created: string, disabled: bool, disabledComment: string, disabledUpdatedTimestamp: string, displayName: string, email: string, individual: record, language: string, onboardedStatus: string, payeeId: string, payeeType: string, payorRefs: list, watchlistOverrideComment: string, watchlistStatus: string, watchlistStatusUpdatedTimestamp: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>, summary: record<totalInvitedCount: int, totalOnboardedCount: int, totalPayeesCount: int, totalRegisteredCount: int, totalWatchlistFailedCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payorId "scalar") (serialize-qp "watchlistStatus" $watchlistStatus "scalar") (serialize-qp "disabled" $disabled "scalar") (serialize-qp "onboardedStatus" $onboardedStatus "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "displayName" $displayName "scalar") (serialize-qp "remoteId" $remoteId "scalar") (serialize-qp "payeeType" $payeeType "scalar") (serialize-qp "payeeCountry" $payeeCountry "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/payees" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initiate Payee Creation
#
# POST /v3/payees
# DEPRECATED
# operationId: createPayeeV3
# --payees item shape: {address: record, challenge?: record, company?: record, email: string, individual?: record, language?: string, paymentChannel?: record, remoteId: string, type: string}
@deprecated
export def "payees createPayeeV3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  payees: list # item shape: {address: record, challenge?: record, company?: record, email: string, individual?: record, language?: string, paymentChannel?: record, remoteId: string, type: string}
  payorId: string # e.g. 9ac75325-5dcd-42d5-b992-175d7e0a035e
]: any -> record<batchId: string, rejectedCsvRows: table<lineNumber: int, message: string, rejectedContent: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/payees")
  let body = {payees: $payees, payorId: $payorId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Query Batch Status
#
# GET /v3/payees/batch/{batchId}
# DEPRECATED
# operationId: queryBatchStatusV3
@deprecated
export def "payees-batch queryBatchStatusV3" [
  batchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<failureCount: int, failures: table<failedSubmission: record, failureMessage: string>, pendingCount: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/payees/batch/($batchId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Payee Changes
#
# GET /v3/payees/deltas
# DEPRECATED
# operationId: listPayeeChangesV3
@deprecated
export def "payees-deltas listPayeeChangesV3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payorId: string # The Payor ID to find associated Payees (format: uuid)
  --updatedSince: string # The updatedSince filter in the format YYYY-MM-DDThh:mm:ss+hh:mm (format: date-time)
  --page: int # Page number. Default is 1. (format: int32, default: 1, e.g. 1)
  --pageSize: int # Page size. Default is 100. Max allowable is 1000. (format: int32, default: 100, e.g. 100)
]: nothing -> record<content: table<dbaName: string, displayName: string, email: string, onboardedStatus: string, payeeCountry: string, payeeId: string, remoteId: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payorId "scalar") (serialize-qp "updatedSince" $updatedSince "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/payees/deltas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payee Invitation Status
#
# GET /v3/payees/payors/{payorId}/invitationStatus
# DEPRECATED
# operationId: getPayeesInvitationStatusV3
@deprecated
export def "payees-payors-invitation-status get-by-payorId" [
  payorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payeeId: string # The UUID of the payee. (format: uuid, e.g. 2aa5d7e0-2ecb-403f-8494-1865ed0454e9)
  --invitationStatus: string # The invitation status of the payees.
  --page: int # Page number. Default is 1. (format: int32, default: 1, e.g. 1)
  --pageSize: int # Page size. Default is 25. Max allowable is 100. (format: int32, default: 25, e.g. 25)
]: nothing -> record<content: table<gracePeriodEndDate: string, invitationStatus: string, payeeId: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payeeId" $payeeId "scalar") (serialize-qp "invitationStatus" $invitationStatus "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/payees/payors/($payorId)/invitationStatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Payee by Id
#
# DELETE /v3/payees/{payeeId}
# DEPRECATED
# operationId: deletePayeeByIdV3
@deprecated
export def "payees delete-by-payeeId" [
  payeeId: string
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
  let full_url = (build-url $base $"/v3/payees/($payeeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payee by Id
#
# GET /v3/payees/{payeeId}
# DEPRECATED
# operationId: getPayeeByIdV3
@deprecated
export def "payees get-by-payeeId" [
  payeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> record<acceptTermsAndConditionsTimestamp: string, address: record<city: string, country: string, countyOrProvince: string, line1: string, line2: string, line3: string, line4: string, zipOrPostcode: string>, cellphoneNumber: string, challenge: record<description: string, value: string>, company: record<name: string, operatingName: string, taxId: string>, country: string, created: string, disabled: bool, disabledComment: string, disabledUpdatedTimestamp: string, displayName: string, email: string, enhancedKycCompleted: bool, gracePeriodEndDate: string, individual: record<dateOfBirth: string, name: record<firstName: string, lastName: string, otherNames: string, title: string>, nationalIdentification: string>, kycCompletedTimestamp: string, language: string, marketingOptInDecision: bool, marketingOptInTimestamp: string, onboardedStatus: string, pausePayment: bool, pausePaymentTimestamp: string, payeeId: string, payeeType: string, payorRefs: table<invitationStatus: string, invitationStatusTimestamp: string, payableIssues: list, payableStatus: bool, paymentChannelId: string, payorId: string, remoteId: string>, watchlistOverrideComment: string, watchlistOverrideExpiresAtTimestamp: string, watchlistStatus: string, watchlistStatusUpdatedTimestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sensitive" $sensitive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/payees/($payeeId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resend Payee Invite
#
# POST /v3/payees/{payeeId}/invite
# DEPRECATED
# operationId: resendPayeeInviteV3
@deprecated
export def "payees-invite resendPayeeInviteV3" [
  payeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  payorId: string # format: uuid, e.g. 9ac75325-5dcd-42d5-b992-175d7e0a035e
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/payees/($payeeId)/invite")
  let body = {payorId: $payorId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Payee Details
#
# POST /v3/payees/{payeeId}/payeeDetailsUpdate
# DEPRECATED
# operationId: payeeDetailsUpdateV3
# --address shape: {city: string, country: string, countyOrProvince?: string, line1: string, line2?: string, line3?: string, line4?: string, zipOrPostcode?: string}
# --challenge shape: {description: string, value: string}
# --company shape: {name: string, operatingName?: string, taxId?: string}
# --individual shape: {name: any}
@deprecated
export def "payees-payee-details-update payeeDetailsUpdateV3" [
  payeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # e.g. {city: Key West, country: US, countyOrProvince: FL, line1: 500 Duval St, line2: line2, line3: line3, line4: line4, zipOrPostcode: 33945} — shape: {city: string, country: string, countyOrProvince?: string, line1: string, line2?: string, line3?: string, line4?: string, zipOrPostcode?: string}
  --challenge: record # e.g. {description: challenge description, value: challenge test} — shape: {description: string, value: string}
  --company: record # nullable, e.g. {name: ABC Group Plc, operatingName: ABC Co, taxId: 123123123} — shape: {name: string, operatingName?: string, taxId?: string}
  --email: string # nullable, format: email, e.g. bob@example.com
  --individual: record # e.g. {dateOfBirth: 1985-01-01, name: {firstName: Bob, lastName: Smith, otherNames: A, title: Mr}, nationalIdentification: AB123456C} — shape: {name: any}
  --language: string # An IETF BCP 47 language code which has been configured for use within this Velo environment.<BR> See the /v1/supportedLanguages endpoint to list the available codes for an environment.  (e.g. en-US)
  --payeeType: string@payeeType-completer-1 # The type of the payee
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/payees/($payeeId)/payeeDetailsUpdate")
  let body = {address: $address, challenge: $challenge, company: $company, email: $email, individual: $individual, language: $language, payeeType: $payeeType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Payee Remote Id
#
# POST /v3/payees/{payeeId}/remoteIdUpdate
# DEPRECATED
@deprecated
export def "payees-remote-id-update post-by-payeeId" [
  payeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  payorId: string # format: uuid, e.g. 9ac75325-5dcd-42d5-b992-175d7e0a035e
  remoteId: string # e.g. remoteId123
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/payees/($payeeId)/remoteIdUpdate")
  let body = {payorId: $payorId, remoteId: $remoteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# V3 Get List of Payments
#
# GET /v3/paymentaudit/payments
# DEPRECATED
# operationId: listPaymentsAuditV3
@deprecated
export def "paymentaudit-payments listPaymentsAuditV3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payeeId: string # The UUID of the payee. (format: uuid)
  --payorId: string # The account owner Payor Id. Required for external users. (format: uuid)
  --payorName: string # The payor’s name. This filters via a case insensitive substring match.
  --remoteId: string # The remote id of the payees.
  --status: string@status-completer-1 # Payment Status
  --sourceAccountName: string # The source account name filter. This filters via a case insensitive substring match.
  --sourceAmountFrom: int # The source amount from range filter. Filters for sourceAmount >= sourceAmountFrom (format: int32)
  --sourceAmountTo: int # The source amount to range filter. Filters for sourceAmount ⇐ sourceAmountTo (format: int32)
  --sourceCurrency: string # The source currency filter. Filters based on an exact match on the currency.
  --paymentAmountFrom: int # The payment amount from range filter. Filters for paymentAmount >= paymentAmountFrom (format: int32)
  --paymentAmountTo: int # The payment amount to range filter. Filters for paymentAmount ⇐ paymentAmountTo (format: int32)
  --paymentCurrency: string # The payment currency filter. Filters based on an exact match on the currency.
  --submittedDateFrom: string # The submitted date from range filter. Format is yyyy-MM-dd. (format: date)
  --submittedDateTo: string # The submitted date to range filter. Format is yyyy-MM-dd. (format: date)
  --paymentMemo: string # The payment memo filter. This filters via a case insensitive substring match.
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --pageSize: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields (e.g. ?sort=submittedDateTime:asc,status:asc). Default is sort by remoteId The supported sort fields are: sourceAmount, sourceCurrency, paymentAmount, paymentCurrency, routingNumber, accountNumber, remoteId, submittedDateTime and status
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> record<content: table<accountName: string, accountNumber: string, countryCode: string, events: list, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentScheme: string, payorId: string, payorName: string, payorPaymentId: string, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, returnCost: int, returnReason: string, routingNumber: string, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payeeId" $payeeId "scalar") (serialize-qp "payorId" $payorId "scalar") (serialize-qp "payorName" $payorName "scalar") (serialize-qp "remoteId" $remoteId "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sourceAccountName" $sourceAccountName "scalar") (serialize-qp "sourceAmountFrom" $sourceAmountFrom "scalar") (serialize-qp "sourceAmountTo" $sourceAmountTo "scalar") (serialize-qp "sourceCurrency" $sourceCurrency "scalar") (serialize-qp "paymentAmountFrom" $paymentAmountFrom "scalar") (serialize-qp "paymentAmountTo" $paymentAmountTo "scalar") (serialize-qp "paymentCurrency" $paymentCurrency "scalar") (serialize-qp "submittedDateFrom" $submittedDateFrom "scalar") (serialize-qp "submittedDateTo" $submittedDateTo "scalar") (serialize-qp "paymentMemo" $paymentMemo "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sensitive" $sensitive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/paymentaudit/payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# V3 Get Payment
#
# GET /v3/paymentaudit/payments/{paymentId}
# DEPRECATED
# operationId: getPaymentDetailsV3
@deprecated
export def "paymentaudit-payments get-by-paymentId" [
  paymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> record<accountName: string, accountNumber: string, countryCode: string, events: table<accountName: string, accountNumber: string, eventDateTime: string, eventId: string, eventType: string, iban: string, paymentAmount: int, paymentCurrency: string, principal: string, routingNumber: string, sourceAmount: int, sourceCurrency: string>, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentScheme: string, payorId: string, payorName: string, payorPaymentId: string, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, returnCost: int, returnReason: string, routingNumber: string, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sensitive" $sensitive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/paymentaudit/payments/($paymentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# V3 Get Payouts for Payor
#
# GET /v3/paymentaudit/payouts
# DEPRECATED
# operationId: getPayoutsForPayorV3
@deprecated
export def "paymentaudit-payouts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payorId: string # The account owner Payor ID (format: uuid)
  --payoutMemo: string # Payout Memo filter - case insensitive sub-string match
  --status: string@status-completer-2 # Payout Status
  --submittedDateFrom: string # The submitted date from range filter. Format is yyyy-MM-dd. (format: date)
  --submittedDateTo: string # The submitted date to range filter. Format is yyyy-MM-dd. (format: date)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --pageSize: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields (e.g. ?sort=submittedDateTime:asc,instructedDateTime:asc,status:asc) Default is submittedDateTime:asc The supported sort fields are: submittedDateTime, instructedDateTime, status.
]: nothing -> record<content: table<fxSummaries: list, instructedDateTime: string, payorId: string, payoutId: string, payoutMemo: string, sourceAccountSummary: list, status: string, submittedDateTime: string, totalFailedPayments: int, totalIncompletePayments: int, totalPayments: int, withdrawnDateTime: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payorId "scalar") (serialize-qp "payoutMemo" $payoutMemo "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "submittedDateFrom" $submittedDateFrom "scalar") (serialize-qp "submittedDateTo" $submittedDateTo "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/paymentaudit/payouts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# V3 Get Payments for Payout
#
# GET /v3/paymentaudit/payouts/{payoutId}
# DEPRECATED
# operationId: getPaymentsForPayout_PA_V3
@deprecated
export def "paymentaudit-payouts V3" [
  payoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --remoteId: string # The remote id of the payees.
  --status: string@status-completer-1 # Payment Status
  --sourceAmountFrom: int # The source amount from range filter. Filters for sourceAmount >= sourceAmountFrom (format: int32)
  --sourceAmountTo: int # The source amount to range filter. Filters for sourceAmount ⇐ sourceAmountTo (format: int32)
  --paymentAmountFrom: int # The payment amount from range filter. Filters for paymentAmount >= paymentAmountFrom (format: int32)
  --paymentAmountTo: int # The payment amount to range filter. Filters for paymentAmount ⇐ paymentAmountTo (format: int32)
  --submittedDateFrom: string # The submitted date from range filter. Format is yyyy-MM-dd. (format: date)
  --submittedDateTo: string # The submitted date to range filter. Format is yyyy-MM-dd. (format: date)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --pageSize: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # <p>List of sort fields (e.g. ?sort=submittedDateTime:asc,status:asc). Default is sort by remoteId</p> <p>The supported sort fields are: sourceAmount, sourceCurrency, paymentAmount, paymentCurrency, routingNumber, accountNumber, remoteId, submittedDateTime and status</p>
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> record<content: table<accountName: string, accountNumber: string, countryCode: string, events: list, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentScheme: string, payorId: string, payorName: string, payorPaymentId: string, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, returnCost: int, returnReason: string, routingNumber: string, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>, summary: record<confirmedPayments: int, failedPayments: int, incompletePayments: int, instructedDateTime: string, payoutMemo: string, payoutStatus: string, releasedPayments: int, submittedDateTime: string, totalPayments: int, withdrawnDateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "remoteId" $remoteId "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sourceAmountFrom" $sourceAmountFrom "scalar") (serialize-qp "sourceAmountTo" $sourceAmountTo "scalar") (serialize-qp "paymentAmountFrom" $paymentAmountFrom "scalar") (serialize-qp "paymentAmountTo" $paymentAmountTo "scalar") (serialize-qp "submittedDateFrom" $submittedDateFrom "scalar") (serialize-qp "submittedDateTo" $submittedDateTo "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sensitive" $sensitive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/paymentaudit/payouts/($payoutId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# V3 Export Transactions
#
# GET /v3/paymentaudit/transactions
# DEPRECATED
# operationId: exportTransactionsCSVV3
@deprecated
export def "paymentaudit-transactions exportTransactionsCSVV3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payorId: string # The Payor ID for whom you wish to run the report. For a Payor requesting the report, this could be their exact Payor, or it could be a child/descendant Payor.  (format: uuid)
  --startDate: string # Start date, inclusive. Format is YYYY-MM-DD (format: date)
  --endDate: string # End date, inclusive. Format is YYYY-MM-DD (format: date)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payorId "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/paymentaudit/transactions" $qp)
  let accept_val = "application/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit Payout
#
# POST /v3/payouts
# operationId: submitPayoutV3
# --payments item shape: {amount: int, currency: string, paymentMemo?: string, paymentMetadata?: string, payorPaymentId?: string, remoteId: string, remoteSystemId?: string, sourceAccountName: string, transmissionType?: "SAME_DAY_ACH"|"WIRE"|"ACH"|"LOCAL"|"SWIFT"}
export def "payouts submitPayoutV3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  payments: list # item shape: {amount: int, currency: string, paymentMemo?: string, paymentMetadata?: string, payorPaymentId?: string, remoteId: string, remoteSystemId?: string, sourceAccountName: string, transmissionType?: "SAME_DAY_ACH"|"WIRE"|"ACH"|"LOCAL"|"SWIFT"}
  --payoutFromPayorId: string # <p>The id of the payor whose source account(s) will be debited</p> <p>payoutFromPayorId and payoutToPayorId must be both supplied or both omitted</p>  (format: uuid, e.g. c4261044-13df-4a6c-b1d4-fa8be2b46f5a)
  --payoutMemo: string # <p>Text applied to all payment memos unless specified explicitly on a payment</p> <p>This should be the reference field on the statement seen by the payee (but not via ACH)</p>  (e.g. Monthly Payment)
  --payoutToPayorId: string # <p>The id of the payor whose payees will be paid</p> <p>payoutFromPayorId and payoutToPayorId must be both supplied or both omitted</p>  (format: uuid, e.g. 9afc6b39-de12-466a-a9ca-07c7a23b312d)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/payouts")
  let body = {payments: $payments, payoutFromPayorId: $payoutFromPayorId, payoutMemo: $payoutMemo, payoutToPayorId: $payoutToPayorId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Withdraw Payout
#
# DELETE /v3/payouts/{payoutId}
# operationId: withdrawPayoutV3
export def "payouts withdrawPayoutV3" [
  payoutId: string
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
  let full_url = (build-url $base $"/v3/payouts/($payoutId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payout Summary
#
# GET /v3/payouts/{payoutId}
# operationId: getPayoutSummaryV3
export def "payouts get" [
  payoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acceptedPayments: table<amount: int, currencyType: string, paymentMemo: string, paymentMetadata: string, payorPaymentId: string, railsId: string, remoteId: string, remoteSystemId: string, sourceAccountName: string>, accounts: table<currency: string, sourceAccountId: string, sourceAccountName: string, totalPayoutCost: int>, fxSummaries: table<creationTime: string, expiryTime: string, fundingStatus: string, invertedRate: float, paymentCurrency: string, quoteId: string, rate: float, sourceCurrency: string, status: string, totalPaymentAmount: int, totalSourceAmount: int>, paymentsAccepted: int, paymentsRejected: int, paymentsSubmitted: int, paymentsWithdrawn: int, payoutId: string, rejectedPayments: table<amount: int, currencyType: string, lineNumber: int, message: string, paymentMetadata: string, payorPaymentId: string, reason: string, reasonCode: string, remoteId: string, remoteSystemId: string, sourceAccountName: string>, schedule: record<notificationsEnabled: bool, scheduleStatus: string, scheduledAt: string, scheduledByPrincipalId: string, scheduledFor: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/payouts/($payoutId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Instruct Payout
#
# POST /v3/payouts/{payoutId}
# operationId: instructPayoutV3
export def "payouts instructPayoutV3" [
  payoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fxRateDegredationThresholdPercentage: float # Halt instruction if the FX rates have become worse since the last quote (format: float)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/payouts/($payoutId)")
  let body = {fxRateDegredationThresholdPercentage: $fxRateDegredationThresholdPercentage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve payments for a payout
#
# GET /v3/payouts/{payoutId}/payments
# operationId: getPaymentsForPayoutV3
export def "payouts-payments get" [
  payoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-3 # Payment Status * ACCEPTED: any payment which was accepted at submission time (status may have changed since) * REJECTED: any payment rejected by initial submission processing * WITHDRAWN: any payment which has been withdrawn * WITHDRAWABLE: any payment eligible for withdrawal
  --remoteId: string # The remote id of the payees.
  --payorPaymentId: string # Payor's Id of the Payment
  --sourceAccountName: string # Physical Account Name
  --transmissionType: string@transmissionType-completer # Transmission Type * ACH * SAME_DAY_ACH * WIRE
  --paymentMemo: string # Payment Memo of the Payment
  --pageSize: int # The number of results to return in a page (format: int32, default: 25)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
]: nothing -> record<content: table<amount: int, autoWithdrawnReasonCode: string, currency: string, payee: record, paymentId: string, paymentMemo: string, paymentMetadata: string, payorPaymentId: string, railsId: string, remoteId: string, remoteSystemId: string, sourceAccountName: string, status: string, transmissionType: string, withdrawable: bool>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "remoteId" $remoteId "scalar") (serialize-qp "payorPaymentId" $payorPaymentId "scalar") (serialize-qp "sourceAccountName" $sourceAccountName "scalar") (serialize-qp "transmissionType" $transmissionType "scalar") (serialize-qp "paymentMemo" $paymentMemo "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/payouts/($payoutId)/payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a quote for the payout
#
# POST /v3/payouts/{payoutId}/quote
# operationId: createQuoteForPayoutV3
export def "payouts-quote createQuoteForPayoutV3" [
  payoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<fxSummaries: table<creationTime: string, expiryTime: string, fundingStatus: string, invertedRate: float, paymentCurrency: string, quoteId: string, rate: float, sourceCurrency: string, status: string, totalPaymentAmount: int, totalSourceAmount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/payouts/($payoutId)/quote")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deschedule a payout
#
# DELETE /v3/payouts/{payoutId}/schedule
# operationId: deschedulePayout
export def "payouts-schedule deschedulePayout" [
  payoutId: string
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
  let full_url = (build-url $base $"/v3/payouts/($payoutId)/schedule")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Schedule a payout
#
# POST /v3/payouts/{payoutId}/schedule
# operationId: scheduleForPayout
export def "payouts-schedule scheduleForPayout" [
  payoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notificationsEnabled: oneof<nothing, bool> # Flag to indicate whether to receive notifications when scheduled payout is processed
  scheduledFor: string # UTC timestamp for instructing the payout. Format is ISO-8601. (format: date-time, e.g. 2025-01-01T10:00:00Z)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/payouts/($payoutId)/schedule")
  let body = {notificationsEnabled: $notificationsEnabled, scheduledFor: $scheduledFor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get list of source accounts
#
# GET /v3/sourceAccounts
# operationId: getSourceAccountsV3
export def "source-accounts get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --physicalAccountName: string # Physical Account Name
  --physicalAccountId: string # The physical account ID (format: uuid)
  --payorId: string # The account owner Payor ID (format: uuid)
  --fundingAccountId: string # The funding account ID (format: uuid)
  --includeUserDeleted: string # A filter for retrieving both active accounts and user deleted ones (format: boolean)
  --type: string # The type of source account.
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --pageSize: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields e.g. ?sort=name:asc Default is name:asc The supported sort fields are - fundingRef, name, balance  (default: fundingRef:asc)
]: nothing -> record<content: table<autoTopUpConfig: record, balance: int, country: string, currency: string, customerId: string, deleted: bool, deletedAt: string, fundingRef: string, id: string, name: string, notifications: record, payorId: string, physicalAccountId: string, physicalAccountName: string, pooled: bool, railsId: string, type: string, userDeleted: bool>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "physicalAccountName" $physicalAccountName "scalar") (serialize-qp "physicalAccountId" $physicalAccountId "scalar") (serialize-qp "payorId" $payorId "scalar") (serialize-qp "fundingAccountId" $fundingAccountId "scalar") (serialize-qp "includeUserDeleted" $includeUserDeleted "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/sourceAccounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a source account by ID
#
# DELETE /v3/sourceAccounts/{sourceAccountId}
# operationId: deleteSourceAccountV3
export def "source-accounts delete" [
  sourceAccountId: string
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
  let full_url = (build-url $base $"/v3/sourceAccounts/($sourceAccountId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details about given source account.
#
# GET /v3/sourceAccounts/{sourceAccountId}
# operationId: getSourceAccountV3
export def "source-accounts get-by-sourceAccountId-1" [
  sourceAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<autoTopUpConfig: record<enabled: bool, fundingAccountId: string, minBalance: int, targetBalance: int>, balance: int, country: string, currency: string, customerId: string, deleted: bool, deletedAt: string, fundingRef: string, id: string, name: string, notifications: record<minimumBalance: int>, payorId: string, physicalAccountId: string, physicalAccountName: string, pooled: bool, railsId: string, type: string, userDeleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/sourceAccounts/($sourceAccountId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Funding Request
#
# POST /v3/sourceAccounts/{sourceAccountId}/fundingRequest
# operationId: createFundingRequestV3
export def "source-accounts-funding-request createFundingRequestV3" [
  sourceAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: int # Amount to fund in minor units (format: int64)
  fundingAccountId: string # The funding account id (format: uuid)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/sourceAccounts/($sourceAccountId)/fundingRequest")
  let body = {amount: $amount, fundingAccountId: $fundingAccountId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set notifications
#
# POST /v3/sourceAccounts/{sourceAccountId}/notifications
# operationId: setNotificationsRequestV3
export def "source-accounts-notifications setNotificationsRequestV3" [
  sourceAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  minimumBalance: int # Amount to set as minimum balance for notifications in minor units (format: int64, e.g. 10000000)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/sourceAccounts/($sourceAccountId)/notifications")
  let body = {minimumBalance: $minimumBalance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Transfer Funds between source accounts
#
# POST /v3/sourceAccounts/{sourceAccountId}/transfers
# operationId: transferFundsV3
export def "source-accounts-transfers transferFundsV3" [
  sourceAccountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: int # Amount to transfer, in minor units (format: int64)
  currency: string # Valid ISO 4217 3 letter currency code. See the <a href="https://www.iso.org/iso-4217-currency-codes.html" target="_blank" a>ISO specification</a> for details. (e.g. USD)
  toSourceAccountId: string # The 'to' source account id, which will be credited (format: uuid)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/sourceAccounts/($sourceAccountId)/transfers")
  let body = {amount: $amount, currency: $currency, toSourceAccountId: $toSourceAccountId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Payees
#
# GET /v4/payees
# operationId: listPayeesV4
export def "payees listPayeesV4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payorId: string # The account owner Payor ID (format: uuid)
  --watchlistStatus: string # The watchlistStatus of the payees.
  --disabled: oneof<nothing, bool> # Payee disabled
  --onboardedStatus: string # The onboarded status of the payees.
  --email: string # Email address (format: email, e.g. bob@example.com)
  --displayName: string # The display name of the payees. (e.g. Bob Smith)
  --remoteId: string # The remote id of the payees. (e.g. remoteId123)
  --payeeType: string # The onboarded status of the payees.
  --payeeCountry: string # The country of the payee - 2 letter ISO 3166-1 country code (upper case) (e.g. US)
  --ofacStatus: string # The ofacStatus of the payees.
  --page: int # Page number. Default is 1. (format: int32, default: 1, e.g. 1)
  --pageSize: int # Page size. Default is 25. Max allowable is 100. (format: int32, default: 25, e.g. 25)
  --qp-sort: string # List of sort fields (e.g. ?sort=onboardedStatus:asc,name:asc) Default is name:asc 'name' is treated as company name for companies - last name + ',' + firstName for individuals The supported sort fields are - payeeId, displayName, payoutStatus, onboardedStatus.  (default: displayName:asc, e.g. displayName:asc)
]: nothing -> record<content: table<company: record, country: string, created: string, disabled: bool, disabledComment: string, disabledUpdatedTimestamp: string, displayName: string, email: string, individual: record, language: string, onboardedStatus: string, payeeId: string, payeeType: string, payorRefs: list, watchlistOverrideComment: string, watchlistStatus: string, watchlistStatusUpdatedTimestamp: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>, summary: record<totalInvitedCount: int, totalOnboardedCount: int, totalPayeesCount: int, totalRegisteredCount: int, totalWatchlistFailedCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payorId "scalar") (serialize-qp "watchlistStatus" $watchlistStatus "scalar") (serialize-qp "disabled" $disabled "scalar") (serialize-qp "onboardedStatus" $onboardedStatus "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "displayName" $displayName "scalar") (serialize-qp "remoteId" $remoteId "scalar") (serialize-qp "payeeType" $payeeType "scalar") (serialize-qp "payeeCountry" $payeeCountry "scalar") (serialize-qp "ofacStatus" $ofacStatus "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/payees" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initiate Payee Creation
#
# POST /v4/payees
# operationId: v4CreatePayee
# --payees item shape: {address: record, challenge?: record, company?: record, email: string, individual?: record, language?: string, paymentChannel?: record, remoteId: string, type: "Individual"|"Company"}
export def "payees v4CreatePayee" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  payees: list # item shape: {address: record, challenge?: record, company?: record, email: string, individual?: record, language?: string, paymentChannel?: record, remoteId: string, type: "Individual"|"Company"}
  payorId: string # e.g. 9ac75325-5dcd-42d5-b992-175d7e0a035e
]: any -> record<batchId: string, rejectedCsvRows: table<lineNumber: int, message: string, rejectedContent: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/payees")
  let body = {payees: $payees, payorId: $payorId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Query Batch Status
#
# GET /v4/payees/batch/{batchId}
# operationId: queryBatchStatusV4
export def "payees-batch queryBatchStatusV4" [
  batchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<failureCount: int, failures: table<failedSubmission: record, failureMessage: string>, pendingCount: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/payees/batch/($batchId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Payee Changes
#
# GET /v4/payees/deltas
# operationId: listPayeeChangesV4
export def "payees-deltas listPayeeChangesV4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payorId: string # The Payor ID to find associated Payees (format: uuid)
  --updatedSince: string # The updatedSince filter in the format YYYY-MM-DDThh:mm:ss+hh:mm (format: date-time)
  --page: int # Page number. Default is 1. (format: int32, default: 1, e.g. 1)
  --pageSize: int # Page size. Default is 100. Max allowable is 1000. (format: int32, default: 100, e.g. 100)
]: nothing -> record<content: table<dbaName: string, displayName: string, email: string, onboardedStatus: string, payeeCountry: string, payeeId: string, remoteId: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payorId "scalar") (serialize-qp "updatedSince" $updatedSince "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/payees/deltas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payee Invitation Status
#
# GET /v4/payees/payors/{payorId}/invitationStatus
# operationId: getPayeesInvitationStatusV4
export def "payees-payors-invitation-status get-by-payorId-1" [
  payorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payeeId: string # The UUID of the payee. (format: uuid, e.g. 2aa5d7e0-2ecb-403f-8494-1865ed0454e9)
  --invitationStatus: string # The invitation status of the payees.
  --page: int # Page number. Default is 1. (format: int32, default: 1, e.g. 1)
  --pageSize: int # Page size. Default is 25. Max allowable is 100. (format: int32, default: 25, e.g. 25)
]: nothing -> record<content: table<gracePeriodEndDate: string, invitationStatus: string, payeeId: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payeeId" $payeeId "scalar") (serialize-qp "invitationStatus" $invitationStatus "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/payees/payors/($payorId)/invitationStatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Payee by Id
#
# DELETE /v4/payees/{payeeId}
# operationId: deletePayeeByIdV4
export def "payees delete-by-payeeId-1" [
  payeeId: string
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
  let full_url = (build-url $base $"/v4/payees/($payeeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payee by Id
#
# GET /v4/payees/{payeeId}
# operationId: getPayeeByIdV4
export def "payees get-by-payeeId-1" [
  payeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> record<acceptTermsAndConditionsTimestamp: string, address: record<city: string, country: string, countyOrProvince: string, line1: string, line2: string, line3: string, line4: string, zipOrPostcode: string>, cellphoneNumber: string, challenge: record<description: string, value: string>, company: record<name: string, operatingName: string, taxId: string>, country: string, created: string, disabled: bool, disabledComment: string, disabledUpdatedTimestamp: string, displayName: string, email: string, enhancedKycCompleted: bool, gracePeriodEndDate: string, individual: record<dateOfBirth: string, name: record<firstName: string, lastName: string, otherNames: string, title: string>, nationalIdentification: string>, kycCompletedTimestamp: string, language: string, marketingOptInDecision: bool, marketingOptInTimestamp: string, onboardedStatus: string, pausePayment: bool, pausePaymentTimestamp: string, payeeId: string, payeeType: string, payorRefs: table<invitationStatus: string, invitationStatusTimestamp: string, payableIssues: list, payableStatus: bool, paymentChannelId: string, payorId: string, remoteId: string>, watchlistOverrideComment: string, watchlistOverrideExpiresAtTimestamp: string, watchlistStatus: string, watchlistStatusUpdatedTimestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sensitive" $sensitive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/payees/($payeeId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resend Payee Invite
#
# POST /v4/payees/{payeeId}/invite
# operationId: resendPayeeInviteV4
export def "payees-invite resendPayeeInviteV4" [
  payeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  payorId: string # format: uuid, e.g. 9ac75325-5dcd-42d5-b992-175d7e0a035e
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/payees/($payeeId)/invite")
  let body = {payorId: $payorId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Payee Details
#
# POST /v4/payees/{payeeId}/payeeDetailsUpdate
# operationId: payeeDetailsUpdateV4
# --address shape: {city: string, country: string, countyOrProvince?: string, line1: string, line2?: string, line3?: string, line4?: string, zipOrPostcode?: string}
# --challenge shape: {description: string, value: string}
# --company shape: {name: string, operatingName?: string, taxId?: string}
# --individual shape: {name: any}
export def "payees-payee-details-update payeeDetailsUpdateV4" [
  payeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # e.g. {city: Key West, country: US, countyOrProvince: FL, line1: 500 Duval St, line2: line2, line3: line3, line4: line4, zipOrPostcode: 33945} — shape: {city: string, country: string, countyOrProvince?: string, line1: string, line2?: string, line3?: string, line4?: string, zipOrPostcode?: string}
  --challenge: record # <p>Used to override the default challenge presented to the payee when they onboard</p> <p>Not used after the payee has onboarded</p>  (e.g. {description: challenge description, value: 11984567}) — shape: {description: string, value: string}
  --company: record # nullable, e.g. {name: ABC Group Plc, operatingName: ABC Co, taxId: 123123123} — shape: {name: string, operatingName?: string, taxId?: string}
  --contactSmsNumber: string # The phone number of a device that the payee wishes to receive sms messages on  (e.g. 11235555555)
  --email: string # nullable, format: email, e.g. bob@example.com
  --individual: record # e.g. {dateOfBirth: 1985-01-01, name: {firstName: Bob, lastName: Smith, otherNames: A, title: Mr}, nationalIdentification: AB123456C} — shape: {name: any}
  --language: string # An IETF BCP 47 language code which has been configured for use within this Velo environment.<BR> See the /v1/supportedLanguages endpoint to list the available codes for an environment.  (e.g. en-US)
  --payeeType: string@payeeType-completer-1 # The type of the payee
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/payees/($payeeId)/payeeDetailsUpdate")
  let body = {address: $address, challenge: $challenge, company: $company, contactSmsNumber: $contactSmsNumber, email: $email, individual: $individual, language: $language, payeeType: $payeeType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Payee Remote Id
#
# POST /v4/payees/{payeeId}/remoteIdUpdate
export def "payees-remote-id-update post-by-payeeId-1" [
  payeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  payorId: string # format: uuid, e.g. 9ac75325-5dcd-42d5-b992-175d7e0a035e
  remoteId: string # e.g. remoteId123
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v4/payees/($payeeId)/remoteIdUpdate")
  let body = {payorId: $payorId, remoteId: $remoteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Fundings for Payor
#
# GET /v4/paymentaudit/fundings
# operationId: getFundingsV4
export def "paymentaudit-fundings get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payorId: string # The account owner Payor ID (format: uuid)
  --sourceAccountName: string # The source account name
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --pageSize: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields. Example: ```?sort=destinationCurrency:asc,destinationAmount:asc``` Default is no sort. The supported sort fields are: dateTime and amount.
]: nothing -> record<content: table<amount: float, currency: string, dateTime: string, events: list, fundingAccountName: string, fundingType: string, sourceAccountName: string, status: string, topupType: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payorId "scalar") (serialize-qp "sourceAccountName" $sourceAccountName "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/paymentaudit/fundings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get List of Payments
#
# GET /v4/paymentaudit/payments
# operationId: listPaymentsAuditV4
export def "paymentaudit-payments listPaymentsAuditV4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payeeId: string # The UUID of the payee. (format: uuid)
  --payorId: string # The account owner Payor Id. Required for external users. (format: uuid)
  --payorName: string # The payor’s name. This filters via a case insensitive substring match.
  --remoteId: string # The remote id of the payees.
  --remoteSystemId: string # The id of the remote system that is orchestrating payments
  --status: string@status-completer-1 # Payment Status
  --transmissionType: string@transmissionType-completer-1 # Transmission Type * ACH * SAME_DAY_ACH * WIRE * GACHO
  --sourceAccountName: string # The source account name filter. This filters via a case insensitive substring match.
  --sourceAmountFrom: int # The source amount from range filter. Filters for sourceAmount >= sourceAmountFrom (format: int32)
  --sourceAmountTo: int # The source amount to range filter. Filters for sourceAmount ⇐ sourceAmountTo (format: int32)
  --sourceCurrency: string # The source currency filter. Filters based on an exact match on the currency.
  --paymentAmountFrom: int # The payment amount from range filter. Filters for paymentAmount >= paymentAmountFrom (format: int32)
  --paymentAmountTo: int # The payment amount to range filter. Filters for paymentAmount ⇐ paymentAmountTo (format: int32)
  --paymentCurrency: string # The payment currency filter. Filters based on an exact match on the currency.
  --submittedDateFrom: string # The submitted date from range filter. Format is yyyy-MM-dd. (format: date)
  --submittedDateTo: string # The submitted date to range filter. Format is yyyy-MM-dd. (format: date)
  --paymentMemo: string # The payment memo filter. This filters via a case insensitive substring match.
  --railsId: string # Payout Rails ID filter - case insensitive match. Any value is allowed, but you should use one of the supported railsId values. To get this list of values, you should call the 'Get Supported Rails' endpoint.
  --scheduledForDateFrom: string # Filter payouts scheduled to run on or after the given date. Format is yyyy-MM-dd. (format: date)
  --scheduledForDateTo: string # Filter payouts scheduled to run on or before the given date. Format is yyyy-MM-dd. (format: date)
  --scheduleStatus: string@scheduleStatus-completer # Payout Schedule Status
  --postInstructFxStatus: string@postInstructFxStatus-completer # The status of the post instruct FX step if one was required for the payment
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --pageSize: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields (e.g. ?sort=submittedDateTime:asc,status:asc). Default is sort by submittedDateTime:desc,paymentId:asc The supported sort fields are: sourceAmount, sourceCurrency, paymentAmount, paymentCurrency, routingNumber, accountNumber, remoteId, submittedDateTime, status and paymentId
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> record<content: table<accountName: string, accountNumber: string, autoWithdrawnReasonCode: string, countryCode: string, events: list, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, isPaymentCcyBaseCcy: bool, payeeAddressCountryCode: string, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentMetadata: string, paymentScheme: string, paymentTrackingReference: string, payorId: string, payorName: string, payorPaymentId: string, payout: record, postInstructFxInfo: record, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, remoteSystemId: string, remoteSystemPaymentId: string, returnCost: int, returnReason: string, routingNumber: string, schedule: record, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string, transmissionType: string, withdrawable: bool, withdrawnReason: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payeeId" $payeeId "scalar") (serialize-qp "payorId" $payorId "scalar") (serialize-qp "payorName" $payorName "scalar") (serialize-qp "remoteId" $remoteId "scalar") (serialize-qp "remoteSystemId" $remoteSystemId "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "transmissionType" $transmissionType "scalar") (serialize-qp "sourceAccountName" $sourceAccountName "scalar") (serialize-qp "sourceAmountFrom" $sourceAmountFrom "scalar") (serialize-qp "sourceAmountTo" $sourceAmountTo "scalar") (serialize-qp "sourceCurrency" $sourceCurrency "scalar") (serialize-qp "paymentAmountFrom" $paymentAmountFrom "scalar") (serialize-qp "paymentAmountTo" $paymentAmountTo "scalar") (serialize-qp "paymentCurrency" $paymentCurrency "scalar") (serialize-qp "submittedDateFrom" $submittedDateFrom "scalar") (serialize-qp "submittedDateTo" $submittedDateTo "scalar") (serialize-qp "paymentMemo" $paymentMemo "scalar") (serialize-qp "railsId" $railsId "scalar") (serialize-qp "scheduledForDateFrom" $scheduledForDateFrom "scalar") (serialize-qp "scheduledForDateTo" $scheduledForDateTo "scalar") (serialize-qp "scheduleStatus" $scheduleStatus "scalar") (serialize-qp "postInstructFxStatus" $postInstructFxStatus "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sensitive" $sensitive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/paymentaudit/payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payment
#
# GET /v4/paymentaudit/payments/{paymentId}
# operationId: getPaymentDetailsV4
export def "paymentaudit-payments get-by-paymentId-1" [
  paymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> record<accountName: string, accountNumber: string, autoWithdrawnReasonCode: string, countryCode: string, events: table<accountName: string, accountNumber: string, eventDateTime: string, eventId: string, eventType: string, iban: string, paymentAmount: int, paymentCurrency: string, principal: string, routingNumber: string, scheduledAt: string, scheduledBy: string, scheduledFor: string, sourceAmount: int, sourceCurrency: string>, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, isPaymentCcyBaseCcy: bool, payeeAddressCountryCode: string, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentMetadata: string, paymentScheme: string, paymentTrackingReference: string, payorId: string, payorName: string, payorPaymentId: string, payout: record<payoutFrom: record<dbaName: string, payorId: string, payorName: string, principal: string, principalId: string>, payoutId: string, payoutTo: record<dbaName: string, payorId: string, payorName: string, principal: string, principalId: string>>, postInstructFxInfo: record<fxMode: string, fxStatus: string, fxStatusUpdatedAt: string, fxTransactionReference: string>, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, remoteSystemId: string, remoteSystemPaymentId: string, returnCost: int, returnReason: string, routingNumber: string, schedule: record<notificationsEnabled: bool, scheduleStatus: string, scheduledAt: string, scheduledBy: string, scheduledByPrincipalId: string, scheduledFor: string>, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string, transmissionType: string, withdrawable: bool, withdrawnReason: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sensitive" $sensitive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/paymentaudit/payments/($paymentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payout Statistics
#
# GET /v4/paymentaudit/payoutStatistics
# operationId: getPayoutStatsV4
export def "paymentaudit-payout-statistics get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payorId: string # The account owner Payor ID. Required for external users. (format: uuid)
]: nothing -> record<thisMonthFailedPaymentsCount: int, thisMonthPayoutsCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payorId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/paymentaudit/payoutStatistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payouts for Payor
#
# GET /v4/paymentaudit/payouts
# operationId: getPayoutsForPayorV4
export def "paymentaudit-payouts get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payorId: string # The id (UUID) of the payor funding the payout or the payor whose payees are being paid. (format: uuid)
  --payoutMemo: string # Payout Memo filter - case insensitive sub-string match
  --status: string@status-completer-2 # Payout Status
  --submittedDateFrom: string # The submitted date from range filter. Format is yyyy-MM-dd. (format: date)
  --submittedDateTo: string # The submitted date to range filter. Format is yyyy-MM-dd. (format: date)
  --fromPayorName: string # The name of the payor whose payees are being paid. This filters via a case insensitive substring match.
  --scheduledForDateFrom: string # Filter payouts scheduled to run on or after the given date. Format is yyyy-MM-dd. (format: date)
  --scheduledForDateTo: string # Filter payouts scheduled to run on or before the given date. Format is yyyy-MM-dd. (format: date)
  --scheduleStatus: string@scheduleStatus-completer # Payout Schedule Status
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --pageSize: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields (e.g. ?sort=submittedDateTime:asc,instructedDateTime:asc,status:asc) Default is submittedDateTime:asc The supported sort fields are: submittedDateTime, instructedDateTime, status, totalPayments, payoutId, scheduledFor
]: nothing -> record<content: table<dateTime: string, fxSummaries: list, instructedDateTime: string, payorId: string, payorName: string, payoutId: string, payoutMemo: string, payoutType: string, schedule: record, sourceAccountSummary: list, status: string, submittedDateTime: string, totalIncompletePayments: int, totalPayments: int, totalReturnedPayments: int, totalWithdrawnPayments: int, withdrawnDateTime: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payorId "scalar") (serialize-qp "payoutMemo" $payoutMemo "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "submittedDateFrom" $submittedDateFrom "scalar") (serialize-qp "submittedDateTo" $submittedDateTo "scalar") (serialize-qp "fromPayorName" $fromPayorName "scalar") (serialize-qp "scheduledForDateFrom" $scheduledForDateFrom "scalar") (serialize-qp "scheduledForDateTo" $scheduledForDateTo "scalar") (serialize-qp "scheduleStatus" $scheduleStatus "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/paymentaudit/payouts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Payments for Payout
#
# GET /v4/paymentaudit/payouts/{payoutId}
# operationId: getPaymentsForPayoutV4
export def "paymentaudit-payouts get-by-payoutId" [
  payoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --remoteId: string # The remote id of the payees.
  --remoteSystemId: string # The id of the remote system that is orchestrating payments
  --status: string@status-completer-1 # Payment Status
  --sourceAmountFrom: int # The source amount from range filter. Filters for sourceAmount >= sourceAmountFrom (format: int32)
  --sourceAmountTo: int # The source amount to range filter. Filters for sourceAmount ⇐ sourceAmountTo (format: int32)
  --paymentAmountFrom: int # The payment amount from range filter. Filters for paymentAmount >= paymentAmountFrom (format: int32)
  --paymentAmountTo: int # The payment amount to range filter. Filters for paymentAmount ⇐ paymentAmountTo (format: int32)
  --submittedDateFrom: string # The submitted date from range filter. Format is yyyy-MM-dd. (format: date)
  --submittedDateTo: string # The submitted date to range filter. Format is yyyy-MM-dd. (format: date)
  --transmissionType: string@transmissionType-completer-1 # Transmission Type * ACH * SAME_DAY_ACH * WIRE * GACHO
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --pageSize: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields (e.g. ?sort=submittedDateTime:asc,status:asc). Default is sort by remoteId The supported sort fields are: sourceAmount, sourceCurrency, paymentAmount, paymentCurrency, routingNumber, accountNumber, remoteId, submittedDateTime and status
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> record<content: table<accountName: string, accountNumber: string, autoWithdrawnReasonCode: string, countryCode: string, events: list, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, isPaymentCcyBaseCcy: bool, payeeAddressCountryCode: string, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentMetadata: string, paymentScheme: string, paymentTrackingReference: string, payorId: string, payorName: string, payorPaymentId: string, payout: record, postInstructFxInfo: record, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, remoteSystemId: string, remoteSystemPaymentId: string, returnCost: int, returnReason: string, routingNumber: string, schedule: record, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string, transmissionType: string, withdrawable: bool, withdrawnReason: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>, summary: record<confirmedPayments: int, incompletePayments: int, instructed: record<principal: string, principalId: string>, instructedDateTime: string, payoutFrom: record<dbaName: string, payorId: string, payorName: string, principal: string, principalId: string>, payoutMemo: string, payoutStatus: string, payoutTo: record<dbaName: string, payorId: string, payorName: string, principal: string, principalId: string>, payoutType: string, quoted: record<principal: string, principalId: string>, quotedDateTime: string, releasedPayments: int, returnedPayments: int, schedule: record<notificationsEnabled: bool, scheduleStatus: string, scheduledAt: string, scheduledBy: string, scheduledByPrincipalId: string, scheduledFor: string>, submittedDateTime: string, submitting: record<dbaName: string, payorId: string, payorName: string, principal: string, principalId: string>, totalPayments: int, withdrawn: record<principal: string, principalId: string>, withdrawnDateTime: string, withdrawnPayments: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "remoteId" $remoteId "scalar") (serialize-qp "remoteSystemId" $remoteSystemId "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sourceAmountFrom" $sourceAmountFrom "scalar") (serialize-qp "sourceAmountTo" $sourceAmountTo "scalar") (serialize-qp "paymentAmountFrom" $paymentAmountFrom "scalar") (serialize-qp "paymentAmountTo" $paymentAmountTo "scalar") (serialize-qp "submittedDateFrom" $submittedDateFrom "scalar") (serialize-qp "submittedDateTo" $submittedDateTo "scalar") (serialize-qp "transmissionType" $transmissionType "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sensitive" $sensitive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v4/paymentaudit/payouts/($payoutId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export Transactions
#
# GET /v4/paymentaudit/transactions
# operationId: exportTransactionsCSVV4
export def "paymentaudit-transactions exportTransactionsCSVV4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payorId: string # <p>The Payor ID for whom you wish to run the report.</p> <p>For a Payor requesting the report, this could be their exact Payor, or it could be a child/descendant Payor.</p>  (format: uuid)
  --startDate: string # Start date, inclusive. Format is YYYY-MM-DD (format: date)
  --endDate: string # End date, inclusive. Format is YYYY-MM-DD (format: date)
  --include: string@include-completer # <p>Mode to determine whether to include other Payor's data in the results.</p> <p>May only be used if payorId is specified.</p> <p>Can be omitted or set to 'payorOnly' or 'payorAndDescendants'.</p> <p>payorOnly: Only include results for the specified Payor. This is the default if 'include' is omitted.</p> <p>payorAndDescendants: Aggregate results for all descendant Payors of the specified Payor. Should only be used if the Payor with the specified payorId has at least one child Payor.</p> <p>Note when a Payor requests the report and include=payorAndDescendants is used, the following additional columns are included in the CSV: Payor Name, Payor Id</p>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payorId "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/paymentaudit/transactions" $qp)
  let accept_val = "application/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Payment Changes
#
# GET /v4/payments/deltas
# operationId: listPaymentChangesV4
export def "payments-deltas listPaymentChangesV4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payorId: string # The Payor ID to find associated Payments (format: uuid)
  --updatedSince: string # The updatedSince filter in the format YYYY-MM-DDThh:mm:ss+hh:mm (format: date-time)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --pageSize: int # The number of results to return in a page (format: int32, default: 100)
]: nothing -> record<content: table<paymentAmount: int, paymentCurrency: string, paymentId: string, payorPaymentId: string, payoutId: string, sourceAmount: int, sourceCurrency: string, status: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payorId "scalar") (serialize-qp "updatedSince" $updatedSince "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/payments/deltas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
