# Auto-generated client for Fire Financial Services Business API v1.0
# Source: https://api.apis.guru/v2/specs/fire.com/1.0/openapi.json
# Auth: --token flag or $env.FIRE_FINANCIAL_SERVICES_BUSINESS_API_TOKEN

const BASE_URL = "https://api.fire.com/business"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FIRE_FINANCIAL_SERVICES_BUSINESS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.fire.com/business"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def currency-completer [] { ["EUR" "GBP"] }
def grant-type-completer [] { ["AccessToken"] }
def batch-status-completer [] { ["FAILED" "REMOVED" "SUBMITTED" "SUCCEEDED"] }
def batch-types-completer [] { ["BANK_TRANSFER" "INTERNAL_TRANSFER" "NEW_PAYEE"] }
def order-by-completer [] { ["DATE"] }
def order-completer [] { ["ASC" "DESC"] }
def type-completer [] { ["BANK_TRANSFER" "INTERNAL_TRANSFER"] }
def payee-type-completer [] { ["ACCOUNT_DETAILS"] }
def address-type-completer [] { ["BUSINESS" "HOME"] }
def type-completer-1 [] { ["OTHER"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts list" } } | get name | first)
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

# List all fire.com Accounts
#
# GET /v1/accounts
# operationId: getAccounts
export def "accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accounts: table<balance: int, cbic: string, ccan: string, ciban: string, cnsc: string, colour: string, currency: record, defaultAccount: bool, directDebitsAllowed: bool, fopOnly: bool, ican: int, name: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/accounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new account
#
# POST /v1/accounts
# operationId: addAccount
export def "accounts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-fees-and-charges: oneof<nothing, bool> # a field to indicate you accept the fee for a new account
  --account-name: string # Name to give the new account (e.g. Operating Account)
  --currency: string@currency-completer # The currency of the new account
]: any -> record<balance: int, cbic: string, ccan: string, ciban: string, cnsc: string, colour: string, currency: record<code: string, description: string>, defaultAccount: bool, directDebitsAllowed: bool, fopOnly: bool, ican: int, name: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/accounts")
  let body = {"acceptFeesAndCharges": $accept_fees_and_charges, "accountName": $account_name, "currency": $currency} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve the details of a fire.com Account
#
# GET /v1/accounts/{ican}
# operationId: getAccountById
export def "accounts get" [
  ican: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<balance: int, cbic: string, ccan: string, ciban: string, cnsc: string, colour: string, currency: record<code: string, description: string>, defaultAccount: bool, directDebitsAllowed: bool, fopOnly: bool, ican: int, name: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ican: $ican} | format pattern "/v1/accounts/{ican}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List transactions for an account (v1)
#
# GET /v1/accounts/{ican}/transactions
# DEPRECATED
# operationId: getTransactionsByIdv1
@deprecated
export def "accounts-transactions get-by-ican" [
  ican: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int64
  --offset: int # format: int64
]: nothing -> record<dateRangeTo: int, total: int, transactions: table<amountAfterCharges: int, amountBeforeCharges: int, balance: int, batchItemDetails: record, card: record, currency: record, date: string, dateAcknowledged: string, directDebitDetails: record, eventUuid: string, feeAmount: int, fxTradeDetails: record, ican: int, myRef: string, paymentRequestPublicCode: string, proprietarySchemeDetails: list, refId: int, relatedParty: any, taxAmount: int, txnId: int, type: string, yourRef: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ican: $ican} | format pattern "/v1/accounts/{ican}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Filtered list of transactions for an account (v1)
#
# GET /v1/accounts/{ican}/transactions/filter
# DEPRECATED
# operationId: getTransactionsFilteredById
@deprecated
export def "accounts-transactions-filter get-transactions-filtered" [
  ican: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-range-from: int # format: int64
  --date-range-to: int # format: int64
  --search-keyword: string
  --transaction-types: list
  --offset: int # format: int64
]: nothing -> record<dateRangeTo: int, total: int, transactions: table<amountAfterCharges: int, amountBeforeCharges: int, balance: int, batchItemDetails: record, card: record, currency: record, date: string, dateAcknowledged: string, directDebitDetails: record, eventUuid: string, feeAmount: int, fxTradeDetails: record, ican: int, myRef: string, paymentRequestPublicCode: string, proprietarySchemeDetails: list, refId: int, relatedParty: any, taxAmount: int, txnId: int, type: string, yourRef: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dateRangeFrom" $date_range_from "scalar") (serialize-qp "dateRangeTo" $date_range_to "scalar") (serialize-qp "searchKeyword" $search_keyword "scalar") (serialize-qp "transactionTypes" $transaction_types "multi") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ican: $ican} | format pattern "/v1/accounts/{ican}/transactions/filter") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new API Application
#
# POST /v1/apps
# operationId: createApiApplication
export def "apps create-api-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --application-name: string # A name for the API Application to help you identify it (e.g. Batch Processing API)
  --enabled: oneof<nothing, bool> # Whether or not this API Application can be used (e.g. true)
  --expiry: string # The date that this API Application can no longer be used. (format: date-time, e.g. 2019-08-22T07:48:56.460Z)
  --ican: int # The ICAN of one of your Fire accounts. Restrict this API Application to a certan account. (format: int64)
  --number-of-payee-approvals-required: int # Number of approvals required to create a payee in a batch (e.g. 1)
  --number-of-payment-approvals-required: int # Number of approvals required to process a payment in a batch (e.g. 1)
  --permissions: list # The list of permissions required (e.g. [PERM_BUSINESS_POST_PAYMENT_REQUEST, PERM_BUSINESS_GET_ASPSPS])
]: any -> record<applicationId: int, clientId: string, clientKey: string, enabled: bool, expiry: string, ican: int, numberOfPayeeApprovalsRequired: int, numberOfPaymentApprovalsRequired: int, refreshToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/apps")
  let body = {"applicationName": $application_name, "enabled": $enabled, "expiry": $expiry, "ican": $ican, "numberOfPayeeApprovalsRequired": $number_of_payee_approvals_required, "numberOfPaymentApprovalsRequired": $number_of_payment_approvals_required, "permissions": $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Authenticate with the API.
#
# POST /v1/apps/accesstokens
# operationId: authenticate
export def "apps-accesstokens authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # The Client ID for this API Application (e.g. 4ADFB67A-0F5B-4A9A-9D74-34437250045C)
  --client-secret: string # The SHA256 hash of the nonce above and the app’s Client Key. The Client Key will only be shown to you when you create the app, so don’t forget to save it somewhere safe. SECRET=( `/bin/echo -n $NONCE$CLIENT_KEY | sha256sum` ). (e.g. 4ADFB67A-0F5B-4A9A-9D74-34437250045C)
  --grant-type: string@grant-type-completer # Always `AccessToken`. (This will change to `refresh_token` in a future release.)
  --nonce: int # A random non-repeating number used as a salt for the `clientSecret` below. The simplest nonce is a unix time. (format: int64, e.g. 728345638475)
  --refresh-token: string # The Refresh Token for this API Application (e.g. 4ADFB67A-0F5B-4A9A-9D74-34437250045C)
]: any -> record<accessToken: string, apiApplicationId: int, businessId: int, expiry: string, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/apps/accesstokens")
  let body = {"clientId": $client_id, "clientSecret": $client_secret, "grantType": $grant_type, "nonce": $nonce, "refreshToken": $refresh_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get list of ASPSPs / Banks
#
# GET /v1/aspsps
# operationId: getListOfAspsps
export def "aspsps get-list-of" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --currency: string # The three letter code for the currency - either `EUR` or `GBP`. Use this to filter the list for banks that can be used to pay in a certain currency. (e.g. EUR)
]: nothing -> record<aspsps: table<alias: string, aspspUuid: string, country: record, currency: record, dateCreated: string, lastUpdated: string, logoUrl: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currency" $currency "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/aspsps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List batches
#
# GET /v1/batches
# operationId: getBatches
export def "batches get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --batch-status: string@batch-status-completer # e.g. SUBMITTED
  --batch-types: string@batch-types-completer # e.g. INTERNAL_TRANSFER
  --order-by: string@order-by-completer # e.g. DATE
  --order: string@order-completer # e.g. DESC
]: nothing -> record<items: table<amount: int, amountAfterCharges: int, batchItemUuid: string, dateCreated: string, feeAmount: int, icanFrom: int, icanTo: int, lastUpdated: string, ref: string, refId: int, result: record, status: string, taxAmount: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "batchStatus" $batch_status "scalar") (serialize-qp "batchTypes" $batch_types "scalar") (serialize-qp "orderBy" $order_by "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/batches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new batch of payments
#
# POST /v1/batches
# operationId: createBatchPayment
export def "batches create-batch-payment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --batch-name: string # An optional name you give to the batch at creation time. (e.g. January 2018 Payroll)
  --callback-url: string # An optional POST URL that all events for this batch will be sent to. (e.g. https://my.webserver.com/cb/payroll)
  --currency: string # GBP or EUR (e.g. EUR)
  --job-number: string # An optional job number you can give to the batch to help link it to your own system. (e.g. 2022-01-PR)
  --type: string@type-completer # The type of the batch - can be one of the listed 3
]: any -> record<batchUuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/batches")
  let body = {"batchName": $batch_name, "callbackUrl": $callback_url, "currency": $currency, "jobNumber": $job_number, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel a batch
#
# DELETE /v1/batches/{batchUuid}
# operationId: cancelBatchPayment
export def "batches cancel-batch-payment" [
  batch_uuid: string
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
  let full_url = (build-url $base ({batch_uuid: $batch_uuid} | format pattern "/v1/batches/{batch_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details of a single Batch
#
# GET /v1/batches/{batchUuid}
# operationId: getDetailsSingleBatch
export def "batches get-details-single-batch" [
  batch_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<batchName: string, batchUuid: string, callbackUrl: string, currency: string, dateCreated: string, jobNumber: string, lastUpdated: string, numberOfItemsFailed: int, numberOfItemsSubmitted: int, numberOfItemsSucceeded: int, sourceName: string, status: string, type: string, valueOfItemsFailed: int, valueOfItemsSubmitted: int, valueOfItemsSucceeded: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({batch_uuid: $batch_uuid} | format pattern "/v1/batches/{batch_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit a batch for approval
#
# PUT /v1/batches/{batchUuid}
# operationId: submitBatch
export def "batches submit-batch" [
  batch_uuid: string
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
  let full_url = (build-url $base ({batch_uuid: $batch_uuid} | format pattern "/v1/batches/{batch_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Approvers for a Batch
#
# GET /v1/batches/{batchUuid}/approvals
# operationId: getListofApproversForBatch
export def "batches-approvals get-listof-approvers-for-batch" [
  batch_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<approvals: table<emailAddress: string, firstName: string, lastName: string, lastUpdated: string, mobileNumber: string, status: string, userId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({batch_uuid: $batch_uuid} | format pattern "/v1/batches/{batch_uuid}/approvals"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List items in a Batch
#
# GET /v1/batches/{batchUuid}/banktransfers
# operationId: getItemsBatchBankTransfer
export def "batches-banktransfers get-items-batch" [
  batch_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # format: int64, e.g. 0
  --limit: int # format: int64, e.g. 10
]: nothing -> record<items: table<amount: int, amountAfterCharges: int, batchItemUuid: string, dateCreated: string, feeAmount: int, icanFrom: int, icanTo: int, lastUpdated: string, ref: string, refId: int, result: record, status: string, taxAmount: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({batch_uuid: $batch_uuid} | format pattern "/v1/batches/{batch_uuid}/banktransfers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a bank transfer payment to the batch.
#
# POST /v1/batches/{batchUuid}/banktransfers
# operationId: addBankTransferBatchPayment
export def "batches-banktransfers create-bank-transfer-batch-payment" [
  batch_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: int # The value of the transaction (format: int64, e.g. 500)
  --dest-account-holder-name: string # The destination account holder name (e.g. John Smith)
  --dest-account-number: string # The destination Account Number if a GBP bank transfer (e.g. 12345678)
  --dest-iban: string # The destination IBAN if a Euro Bank transfer (e.g. IE00AIBK93123412341234)
  --dest-nsc: string # The destination Nsc if a GBP bank transfer (e.g. 123456)
  --ican-from: int # The Fire account ID for the fire.com account the funds are taken from. (format: int64, e.g. 2001)
  --my-ref: string # The reference on the transaction for your records - not shown to the beneficiary. (e.g. Payment to John Smith for Consultancy in device.)
  --payee-type: string@payee-type-completer # Use ACCOUNT_DETAILS if you are providing account numbers/sort codes/IBANs (Mode 2). Specify the account details in the destIban, destAccountHolderName, destNsc or destAccountNumber fields as appropriate. (e.g. ACCOUNT_DETAILS)
  --your-ref: string # The reference on the transaction - displayed on the beneficiary bank statement. (e.g. ACME LTD - INV 23434)
  --payee-id: int # The ID of the existing or automatically created payee (format: int64, e.g. 15002)
]: any -> record<batchItemUuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({batch_uuid: $batch_uuid} | format pattern "/v1/batches/{batch_uuid}/banktransfers"))
  let body = {"amount": $amount, "destAccountHolderName": $dest_account_holder_name, "destAccountNumber": $dest_account_number, "destIban": $dest_iban, "destNsc": $dest_nsc, "icanFrom": $ican_from, "myRef": $my_ref, "payeeType": $payee_type, "yourRef": $your_ref, "payeeId": $payee_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a Payment from the Batch (Bank Transfers)
#
# DELETE /v1/batches/{batchUuid}/banktransfers/{itemUuid}
# operationId: deleteBankTransferBatchPayment
export def "batches-banktransfers delete-bank-transfer-batch-payment" [
  batch_uuid: string
  item_uuid: string
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
  let full_url = (build-url $base ({batch_uuid: $batch_uuid, item_uuid: $item_uuid} | format pattern "/v1/batches/{batch_uuid}/banktransfers/{item_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List items in a Batch
#
# GET /v1/batches/{batchUuid}/internaltransfers
# operationId: getItemsBatchInternalTrasnfer
export def "batches-internaltransfers get-items-batch-internal-trasnfer" [
  batch_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # format: int64, e.g. 0
  --limit: int # format: int64, e.g. 10
]: nothing -> record<items: table<amount: int, amountAfterCharges: int, batchItemUuid: string, dateCreated: string, feeAmount: int, icanFrom: int, icanTo: int, lastUpdated: string, ref: string, refId: int, result: record, status: string, taxAmount: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({batch_uuid: $batch_uuid} | format pattern "/v1/batches/{batch_uuid}/internaltransfers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an internal transfer payment to the batch
#
# POST /v1/batches/{batchUuid}/internaltransfers
# operationId: addInternalTransferBatchPayment
export def "batches-internaltransfers create-internal-transfer-batch-payment" [
  batch_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: int # amount of funds to be transfered (format: int64, e.g. 10000)
  --ican-from: int # The account ID for the fire.com account the funds are taken from (format: int64, e.g. 2001)
  --ican-to: int # The account ID for the fire.com account the funds are directed to (format: int64, e.g. 3221)
  --ref: string # The reference on the transaction (e.g. Moving funds to Operating Account)
]: any -> record<batchItemUuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({batch_uuid: $batch_uuid} | format pattern "/v1/batches/{batch_uuid}/internaltransfers"))
  let body = {"amount": $amount, "icanFrom": $ican_from, "icanTo": $ican_to, "ref": $ref} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a Payment from the Batch (Internal Transfer)
#
# DELETE /v1/batches/{batchUuid}/internaltransfers/{itemUuid}
# operationId: deleteInternalTransferBatchPayment
export def "batches-internaltransfers delete-internal-transfer-batch-payment" [
  batch_uuid: string
  item_uuid: string
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
  let full_url = (build-url $base ({batch_uuid: $batch_uuid, item_uuid: $item_uuid} | format pattern "/v1/batches/{batch_uuid}/internaltransfers/{item_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View List of Cards.
#
# GET /v1/cards
# operationId: getListofCards
export def "cards get-listof" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cards: table<blocked: bool, cardId: int, dateCreated: string, emailAddress: string, eurIcan: int, expiryDate: string, firstName: string, gbpIcan: int, lastName: string, maskedPan: string, provider: string, status: string, statusReason: string, userId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/cards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new debit card.
#
# POST /v1/cards
# operationId: createNewCard
export def "cards create-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-fees-and-charges: oneof<nothing, bool> # e.g. true
  --address-type: string@address-type-completer # e.g. BUSINESS
  --card-pin: string # e.g. 5345
  --eur-ican: int # format: int64, e.g. 2150
  --gbp-ican: int # format: int64, e.g. 2152
  --user-id: int # format: int64, e.g. 3245
]: any -> record<cardId: int, expiryDate: string, maskedPan: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/cards")
  let body = {"acceptFeesAndCharges": $accept_fees_and_charges, "addressType": $address_type, "cardPin": $card_pin, "eurIcan": $eur_ican, "gbpIcan": $gbp_ican, "userId": $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Block a card
#
# POST /v1/cards/{cardId}/block
# operationId: blockCard
export def "cards-block blockCard" [
  card_id: int
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
  let full_url = (build-url $base ({card_id: $card_id} | format pattern "/v1/cards/{card_id}/block"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Card Transactions.
#
# GET /v1/cards/{cardId}/transactions
# operationId: getListofCardTransactions
export def "cards-transactions get-listof" [
  card_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int64
  --offset: int # format: int64
]: nothing -> table<dateRangeTo: int, total: int, transactions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({card_id: $card_id} | format pattern "/v1/cards/{card_id}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unblock a card
#
# POST /v1/cards/{cardId}/unblock
# operationId: unblockCard
export def "cards-unblock unblockCard" [
  card_id: int
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
  let full_url = (build-url $base ({card_id: $card_id} | format pattern "/v1/cards/{card_id}/unblock"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all DD payments associated with a direct debit mandate
#
# GET /v1/directdebits
# operationId: getDirectDebitsForMandateUuid
export def "directdebits get-direct-debits-for-mandate-uuid" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --mandate-uuid: string # The mandate UUID to retrieve (e.g. 1A07774B-1461-4595-BC4B-423B739712AF)
]: nothing -> record<directdebits: table<amount: int, currency: record, dateCreated: string, directDebitReference: string, directDebitUuid: string, isDDIC: bool, lastUpdated: string, mandateUUid: string, originatorAlias: string, originatorName: string, originatorReference: string, schemeRejectReason: string, schemeRejectReasonCode: string, status: string, targetIcan: int, targetPayeeId: int, type: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mandateUuid" $mandate_uuid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/directdebits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the details of a direct debit
#
# GET /v1/directdebits/{directDebitUuid}
# operationId: getDirectDebitByUuid
export def "directdebits get" [
  direct_debit_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<amount: int, currency: record<code: string, description: string>, dateCreated: string, directDebitReference: string, directDebitUuid: string, isDDIC: bool, lastUpdated: string, mandateUUid: string, originatorAlias: string, originatorName: string, originatorReference: string, schemeRejectReason: string, schemeRejectReasonCode: string, status: string, targetIcan: int, targetPayeeId: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({direct_debit_uuid: $direct_debit_uuid} | format pattern "/v1/directdebits/{direct_debit_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reject a direct debit payment
#
# POST /v1/directdebits/{directDebitUuid}/reject
# operationId: rejectDirectDebit
export def "directdebits-reject reject" [
  direct_debit_uuid: string
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
  let full_url = (build-url $base ({direct_debit_uuid: $direct_debit_uuid} | format pattern "/v1/directdebits/{direct_debit_uuid}/reject"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all direct debit mandates
#
# GET /v1/mandates
# operationId: getDirectDebitMandates
export def "mandates get-direct-debit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<mandates: table<alias: string, currency: record, dateCancelled: string, dateCompleted: string, dateCreated: string, fireRejectionReason: string, lastUpdated: string, latestDirectDebitAmount: int, latestDirectDebitDate: string, mandateReference: string, mandateUuid: string, numberOfDirectDebitCollected: int, originatorAlias: string, originatorLogoUrlLarge: string, originatorLogoUrlSmall: string, originatorName: string, originatorReference: string, schemeCancelReason: string, schemeCancelReasonCode: string, status: string, targetIcan: int, valueOfDirectDebitCollected: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/mandates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get direct debit mandate details
#
# GET /v1/mandates/{mandateUuid}
# operationId: getMandate
export def "mandates get" [
  mandate_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alias: string, currency: record<code: string, description: string>, dateCancelled: string, dateCompleted: string, dateCreated: string, fireRejectionReason: string, lastUpdated: string, latestDirectDebitAmount: int, latestDirectDebitDate: string, mandateReference: string, mandateUuid: string, numberOfDirectDebitCollected: int, originatorAlias: string, originatorLogoUrlLarge: string, originatorLogoUrlSmall: string, originatorName: string, originatorReference: string, schemeCancelReason: string, schemeCancelReasonCode: string, status: string, targetIcan: int, valueOfDirectDebitCollected: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({mandate_uuid: $mandate_uuid} | format pattern "/v1/mandates/{mandate_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a direct debit mandate alias
#
# POST /v1/mandates/{mandateUuid}
# operationId: updateMandateAlias
export def "mandates update-mandate-alias" [
  mandate_uuid: string
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
  let full_url = (build-url $base ({mandate_uuid: $mandate_uuid} | format pattern "/v1/mandates/{mandate_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Activate a direct debit mandate
#
# POST /v1/mandates/{mandateUuid}/activate
# operationId: activateMandate
export def "mandates-activate activateMandate" [
  mandate_uuid: string
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
  let full_url = (build-url $base ({mandate_uuid: $mandate_uuid} | format pattern "/v1/mandates/{mandate_uuid}/activate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel a direct debit mandate
#
# POST /v1/mandates/{mandateUuid}/cancel
# operationId: cancelMandateByUuid
export def "mandates-cancel cancel" [
  mandate_uuid: string
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
  let full_url = (build-url $base ({mandate_uuid: $mandate_uuid} | format pattern "/v1/mandates/{mandate_uuid}/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all Payee Bank Accounts
#
# GET /v1/payees
# operationId: getPayees
export def "payees get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<fundingSources: table<accountHolderName: string, accountName: string, accountNumber: string, bic: string, createdBy: string, currency: record, dateCreated: string, iban: string, id: int, nsc: string, status: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/payees")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Fire Open Payment request
#
# POST /v1/paymentrequests
# operationId: newPaymentRequest
# --orderDetails shape: {comment1?: string, comment2?: string, customerNumber?: string, deliveryAddressLine1?: string, deliveryAddressLine2?: string, deliveryCity?: string, deliveryCountry?: string, deliveryPostCode?: string, merchantCustomerIdentification?: string, merchantNumber?: string, orderId?: string, productId?: string, variableReference?: string}
export def "paymentrequests newPaymentRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fields: string # These fields will be dispalyed to the payer when using the hosted option. You can choose to display any of `ORDER_ID`, `PRODUCT_ID`, `CUSTOMER_ID`, `CUSTOMER_NUMBER` and `COMMENT2` to the payer. (e.g. ORDER_ID|PRODUCT_ID|CUSTOMER_ID|CUSTOMER_NUMBER|COMMENT2)
  --amount: int # The requested amount to pay. Note the last two digits represent pennies/cents, (e.g., £1.00 = 100). (format: int64, e.g. 1000)
  --collect-fields: string # For the hosted option, the payer will be asked to fill in these fields but they will not be mandatory. You can choose to collect any of the payer's `ADDRESS`, `REFERENCE` and/or `COMMENT1`. If you choose to collect these fields from the payer, you cannot set 'delivery’, 'variableReference’ or 'comment1’ fields respectively. (e.g. ADDRESS|REFERENCE|COMMENT1)
  currency: string@currency-completer # Either `EUR` or `GBP`, and must correspond to the currency of the account the funds are being lodged into in the `icanTo`.
  description: string # A public facing description of the request. This will be shown to the user when they tap or scan the request. (e.g. Gym Fees Oct 2020)
  --expiry: string # This is the expiry of the payment request. After this time, the payment cannot be paid. (format: date-time, e.g. 2020-10-22T07:48:56.460Z)
  ican_to: int # The ican of the account to collect the funds into. Must be one of your fire.com Accounts. (format: int64, e.g. 42)
  --mandatory-fields: string # For the hosted option, these fields will be madatory for the payer to fill in on the hosted payment page. You can choose to collect any the payer's `ADDRESS`, `REFERENCE` and/or `COMMENT1`. If you choose to collect these fields from the payer, you cannot set 'delivery’, 'variableReference’ or 'comment1’ fields respectively. (e.g. ADDRESS|REFERENCE|COMMENT1)
  --max-number-payments: int # The max number of people who can pay this request. Must be set to 1 for the ECOMMERCE_GOODS and ECOMMERCE_SERVICES types. (e.g. 1)
  my_ref: string # An internal description of the request. (e.g. Fees)
  --order-details: record # shape: {comment1?: string, comment2?: string, customerNumber?: string, deliveryAddressLine1?: string, deliveryAddressLine2?: string, deliveryCity?: string, deliveryCountry?: string, deliveryPostCode?: string, merchantCustomerIdentification?: string, merchantNumber?: string, orderId?: string, productId?: string, variableReference?: string}
  --return-url: string # The merchant return URL where the customer will be re-directed to with the result of the transaction. (e.g. https://example.com/callback)
  type: string@type-completer-1 # The type of Fire Open Payment that was created
]: any -> record<code: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/paymentrequests")
  let body = {"additionalFields": $additional_fields, "amount": $amount, "collectFields": $collect_fields, "currency": $currency, "description": $description, "expiry": $expiry, "icanTo": $ican_to, "mandatoryFields": $mandatory_fields, "maxNumberPayments": $max_number_payments, "myRef": $my_ref, "orderDetails": $order_details, "returnUrl": $return_url, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Payment Details
#
# GET /v1/payments/{paymentUuid}
# operationId: getPaymentDetails
export def "payments get-payment-details" [
  payment_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<additionalFields: string, amount: int, collectFields: string, currency: record<code: string, description: string>, description: string, expiry: string, icanTo: int, mandatoryFields: string, maxNumberPayments: int, myRef: string, orderDetails: record<comment1: string, comment2: string, customerNumber: string, deliveryAddressLine1: string, deliveryAddressLine2: string, deliveryCity: string, deliveryCountry: string, deliveryPostCode: string, merchantCustomerIdentification: string, merchantNumber: string, orderId: string, productId: string, variableReference: string>, paymentRequestCode: string, paymentUuid: string, returnUrl: string, status: string, transactionType: string, type: string, webhookUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({payment_uuid: $payment_uuid} | format pattern "/v1/payments/{payment_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns details of a specific fire.com user.
#
# GET /v1/user/{userId}
# operationId: getUser
export def "user get" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<emailAddress: string, firstName: string, id: int, lastName: string, lastlogin: string, mobileApplicationDetails: record<OS: string, businessUserId: int, clientID: string, deviceName: string, deviceOSVersion: string, mobileApplicationId: int, status: string>, mobileNumber: string, role: string, status: string, userCvl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/v1/user/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of all users on your fire.com account
#
# GET /v1/users
# operationId: getUsers
export def "users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<emailAddress: string, firstName: string, id: int, lastName: string, lastlogin: string, mobileApplicationDetails: record<OS: string, businessUserId: int, clientID: string, deviceName: string, deviceOSVersion: string, mobileApplicationId: int, status: string>, mobileNumber: string, role: string, status: string, userCvl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List transactions for an account (v3)
#
# GET /v3/accounts/{ican}/transactions
# operationId: getTransactionsByIdv3
export def "accounts-transactions get-by-ican-1" [
  ican: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int64
  --date-range-from: int # format: int64
  --date-range-to: int # format: int64
  --start-after: string
]: nothing -> record<content: table<amountAfterCharges: int, amountBeforeCharges: int, balance: int, batchItemDetails: record, card: record, currency: record, date: string, dateAcknowledged: string, directDebitDetails: record, eventUuid: string, feeAmount: int, fxTradeDetails: record, ican: int, myRef: string, paymentRequestPublicCode: string, proprietarySchemeDetails: list, refId: int, relatedParty: any, taxAmount: int, txnId: int, type: string, yourRef: string>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "dateRangeFrom" $date_range_from "scalar") (serialize-qp "dateRangeTo" $date_range_to "scalar") (serialize-qp "startAfter" $start_after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ican: $ican} | format pattern "/v3/accounts/{ican}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
