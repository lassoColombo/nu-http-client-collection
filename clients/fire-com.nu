# Auto-generated client for Fire Financial Services Business API v1.0
# Source: https://api.apis.guru/v2/specs/fire.com/1.0/openapi.json
# Auth: --token flag or $env.FIRE_FINANCIAL_SERVICES_BUSINESS_API_TOKEN

const BASE_URL = "https://api.fire.com/business"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FIRE_FINANCIAL_SERVICES_BUSINESS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.fire.com/business"] }
def auth-scheme-completer [] { ["bearer" "none"] }

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
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accounts: table<balance: int, cbic: string, ccan: string, ciban: string, cnsc: string, colour: string, currency: record, defaultAccount: bool, directDebitsAllowed: bool, fopOnly: bool, ican: int, name: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/accounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-fees-and-charges: oneof<nothing, bool> # a field to indicate you accept the fee for a new account
  --account-name: string # Name to give the new account (e.g. Operating Account)
  --currency: string@currency-completer # The currency of the new account
]: any -> record<balance: int, cbic: string, ccan: string, ciban: string, cnsc: string, colour: string, currency: record<code: string, description: string>, defaultAccount: bool, directDebitsAllowed: bool, fopOnly: bool, ican: int, name: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/accounts")
  let req_body = {"acceptFeesAndCharges": $accept_fees_and_charges, "accountName": $account_name, "currency": $currency} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<balance: int, cbic: string, ccan: string, ciban: string, cnsc: string, colour: string, currency: record<code: string, description: string>, defaultAccount: bool, directDebitsAllowed: bool, fopOnly: bool, ican: int, name: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ican | is-empty) { error make --unspanned { msg: "path parameter 'ican' must be non-empty" } }
  let full_url = (build-url $base ({ican: (encode-path-segment $ican)} | format pattern "/v1/accounts/{ican}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List transactions for an account (v1)
#
# GET /v1/accounts/{ican}/transactions
# DEPRECATED
# operationId: getTransactionsByIdv1
@deprecated
export def "accounts-transactions get-by-idv1" [
  ican: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int64
  --offset: int # format: int64
]: nothing -> record<dateRangeTo: int, total: int, transactions: table<amountAfterCharges: int, amountBeforeCharges: int, balance: int, batchItemDetails: record, card: record, currency: record, date: string, dateAcknowledged: string, directDebitDetails: record, eventUuid: string, feeAmount: int, fxTradeDetails: record, ican: int, myRef: string, paymentRequestPublicCode: string, proprietarySchemeDetails: list, refId: int, relatedParty: any, taxAmount: int, txnId: int, type: string, yourRef: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ican | is-empty) { error make --unspanned { msg: "path parameter 'ican' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ican: (encode-path-segment $ican)} | format pattern "/v1/accounts/{ican}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# Filtered list of transactions for an account (v1)
#
# GET /v1/accounts/{ican}/transactions/filter
# DEPRECATED
# operationId: getTransactionsFilteredById
@deprecated
export def "accounts-transactions-filter get-filtered" [
  ican: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-range-from: int # format: int64
  --date-range-to: int # format: int64
  --search-keyword: string
  --transaction-types: list<string>
  --offset: int # format: int64
]: nothing -> record<dateRangeTo: int, total: int, transactions: table<amountAfterCharges: int, amountBeforeCharges: int, balance: int, batchItemDetails: record, card: record, currency: record, date: string, dateAcknowledged: string, directDebitDetails: record, eventUuid: string, feeAmount: int, fxTradeDetails: record, ican: int, myRef: string, paymentRequestPublicCode: string, proprietarySchemeDetails: list, refId: int, relatedParty: any, taxAmount: int, txnId: int, type: string, yourRef: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ican | is-empty) { error make --unspanned { msg: "path parameter 'ican' must be non-empty" } }
  let qp = [(serialize-qp "dateRangeFrom" $date_range_from "scalar") (serialize-qp "dateRangeTo" $date_range_to "scalar") (serialize-qp "searchKeyword" $search_keyword "scalar") (serialize-qp "transactionTypes" $transaction_types "multi") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ican: (encode-path-segment $ican)} | format pattern "/v1/accounts/{ican}/transactions/filter") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"dateRangeFrom": $date_range_from, "dateRangeTo": $date_range_to, "searchKeyword": $search_keyword, "transactionTypes": $transaction_types, "offset": $offset} | compact), body: null}
}

# Create a new API Application
#
# POST /v1/apps
# operationId: createApiApplication
export def "apps create-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --application-name: string # A name for the API Application to help you identify it (e.g. Batch Processing API)
  --enabled: oneof<nothing, bool> # Whether or not this API Application can be used (e.g. true)
  --expiry: string # The date that this API Application can no longer be used. (format: date-time, e.g. 2019-08-22T07:48:56.460Z)
  --ican: int # The ICAN of one of your Fire accounts. Restrict this API Application to a certan account. (format: int64)
  --number-of-payee-approvals-required: int # Number of approvals required to create a payee in a batch (e.g. 1)
  --number-of-payment-approvals-required: int # Number of approvals required to process a payment in a batch (e.g. 1)
  --permissions: list<string> # The list of permissions required (e.g. [PERM_BUSINESS_POST_PAYMENT_REQUEST, PERM_BUSINESS_GET_ASPSPS])
]: any -> record<applicationId: int, clientId: string, clientKey: string, enabled: bool, expiry: string, ican: int, numberOfPayeeApprovalsRequired: int, numberOfPaymentApprovalsRequired: int, refreshToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/apps")
  let req_body = {"applicationName": $application_name, "enabled": $enabled, "expiry": $expiry, "ican": $ican, "numberOfPayeeApprovalsRequired": $number_of_payee_approvals_required, "numberOfPaymentApprovalsRequired": $number_of_payment_approvals_required, "permissions": $permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Authenticate with the API.
#
# POST /v1/apps/accesstokens
# operationId: authenticate
export def "apps-accesstokens create-authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # The Client ID for this API Application (e.g. 4ADFB67A-0F5B-4A9A-9D74-34437250045C)
  --client-secret: string # The SHA256 hash of the nonce above and the app’s Client Key. The Client Key will only be shown to you when you create the app, so don’t forget to save it somewhere safe. SECRET=( `/bin/echo -n $NONCE$CLIENT_KEY | sha256sum` ). (e.g. 4ADFB67A-0F5B-4A9A-9D74-34437250045C)
  --grant-type: string@grant-type-completer # Always `AccessToken`. (This will change to `refresh_token` in a future release.)
  --nonce: int # A random non-repeating number used as a salt for the `clientSecret` below. The simplest nonce is a unix time. (format: int64, e.g. 728345638475)
  --refresh-token: string # The Refresh Token for this API Application (e.g. 4ADFB67A-0F5B-4A9A-9D74-34437250045C)
]: any -> record<accessToken: string, apiApplicationId: int, businessId: int, expiry: string, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/apps/accesstokens")
  let req_body = {"clientId": $client_id, "clientSecret": $client_secret, "grantType": $grant_type, "nonce": $nonce, "refreshToken": $refresh_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get list of ASPSPs / Banks
#
# GET /v1/aspsps
# operationId: getListOfAspsps
export def "aspsps get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currency: string # The three letter code for the currency - either `EUR` or `GBP`. Use this to filter the list for banks that can be used to pay in a certain currency. (e.g. EUR)
]: nothing -> record<aspsps: table<alias: string, aspspUuid: string, country: record, currency: record, dateCreated: string, lastUpdated: string, logoUrl: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currency" $currency "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/aspsps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"currency": $currency} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"batchStatus": $batch_status, "batchTypes": $batch_types, "orderBy": $order_by, "order": $order} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"batchName": $batch_name, "callbackUrl": $callback_url, "currency": $currency, "jobNumber": $job_number, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_uuid | is-empty) { error make --unspanned { msg: "path parameter 'batchUuid' must be non-empty" } }
  let full_url = (build-url $base ({batch_uuid: (encode-path-segment $batch_uuid)} | format pattern "/v1/batches/{batch_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<batchName: string, batchUuid: string, callbackUrl: string, currency: string, dateCreated: string, jobNumber: string, lastUpdated: string, numberOfItemsFailed: int, numberOfItemsSubmitted: int, numberOfItemsSucceeded: int, sourceName: string, status: string, type: string, valueOfItemsFailed: int, valueOfItemsSubmitted: int, valueOfItemsSucceeded: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_uuid | is-empty) { error make --unspanned { msg: "path parameter 'batchUuid' must be non-empty" } }
  let full_url = (build-url $base ({batch_uuid: (encode-path-segment $batch_uuid)} | format pattern "/v1/batches/{batch_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_uuid | is-empty) { error make --unspanned { msg: "path parameter 'batchUuid' must be non-empty" } }
  let full_url = (build-url $base ({batch_uuid: (encode-path-segment $batch_uuid)} | format pattern "/v1/batches/{batch_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<approvals: table<emailAddress: string, firstName: string, lastName: string, lastUpdated: string, mobileNumber: string, status: string, userId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_uuid | is-empty) { error make --unspanned { msg: "path parameter 'batchUuid' must be non-empty" } }
  let full_url = (build-url $base ({batch_uuid: (encode-path-segment $batch_uuid)} | format pattern "/v1/batches/{batch_uuid}/approvals"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List items in a Batch
#
# GET /v1/batches/{batchUuid}/banktransfers
# operationId: getItemsBatchBankTransfer
export def "batches-banktransfers get-items-batch-bank-transfer" [
  batch_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # format: int64, e.g. 0
  --limit: int # format: int64, e.g. 10
]: nothing -> record<items: table<amount: int, amountAfterCharges: int, batchItemUuid: string, dateCreated: string, feeAmount: int, icanFrom: int, icanTo: int, lastUpdated: string, ref: string, refId: int, result: record, status: string, taxAmount: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_uuid | is-empty) { error make --unspanned { msg: "path parameter 'batchUuid' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({batch_uuid: (encode-path-segment $batch_uuid)} | format pattern "/v1/batches/{batch_uuid}/banktransfers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"offset": $offset, "limit": $limit} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($batch_uuid | is-empty) { error make --unspanned { msg: "path parameter 'batchUuid' must be non-empty" } }
  let full_url = (build-url $base ({batch_uuid: (encode-path-segment $batch_uuid)} | format pattern "/v1/batches/{batch_uuid}/banktransfers"))
  let req_body = {"amount": $amount, "destAccountHolderName": $dest_account_holder_name, "destAccountNumber": $dest_account_number, "destIban": $dest_iban, "destNsc": $dest_nsc, "icanFrom": $ican_from, "myRef": $my_ref, "payeeType": $payee_type, "yourRef": $your_ref, "payeeId": $payee_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_uuid | is-empty) { error make --unspanned { msg: "path parameter 'batchUuid' must be non-empty" } }
  if ($item_uuid | is-empty) { error make --unspanned { msg: "path parameter 'itemUuid' must be non-empty" } }
  let full_url = (build-url $base ({batch_uuid: (encode-path-segment $batch_uuid), item_uuid: (encode-path-segment $item_uuid)} | format pattern "/v1/batches/{batch_uuid}/banktransfers/{item_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # format: int64, e.g. 0
  --limit: int # format: int64, e.g. 10
]: nothing -> record<items: table<amount: int, amountAfterCharges: int, batchItemUuid: string, dateCreated: string, feeAmount: int, icanFrom: int, icanTo: int, lastUpdated: string, ref: string, refId: int, result: record, status: string, taxAmount: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_uuid | is-empty) { error make --unspanned { msg: "path parameter 'batchUuid' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({batch_uuid: (encode-path-segment $batch_uuid)} | format pattern "/v1/batches/{batch_uuid}/internaltransfers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"offset": $offset, "limit": $limit} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: int # amount of funds to be transfered (format: int64, e.g. 10000)
  --ican-from: int # The account ID for the fire.com account the funds are taken from (format: int64, e.g. 2001)
  --ican-to: int # The account ID for the fire.com account the funds are directed to (format: int64, e.g. 3221)
  --ref: string # The reference on the transaction (e.g. Moving funds to Operating Account)
]: any -> record<batchItemUuid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_uuid | is-empty) { error make --unspanned { msg: "path parameter 'batchUuid' must be non-empty" } }
  let full_url = (build-url $base ({batch_uuid: (encode-path-segment $batch_uuid)} | format pattern "/v1/batches/{batch_uuid}/internaltransfers"))
  let req_body = {"amount": $amount, "icanFrom": $ican_from, "icanTo": $ican_to, "ref": $ref} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_uuid | is-empty) { error make --unspanned { msg: "path parameter 'batchUuid' must be non-empty" } }
  if ($item_uuid | is-empty) { error make --unspanned { msg: "path parameter 'itemUuid' must be non-empty" } }
  let full_url = (build-url $base ({batch_uuid: (encode-path-segment $batch_uuid), item_uuid: (encode-path-segment $item_uuid)} | format pattern "/v1/batches/{batch_uuid}/internaltransfers/{item_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cards: table<blocked: bool, cardId: int, dateCreated: string, emailAddress: string, eurIcan: int, expiryDate: string, firstName: string, gbpIcan: int, lastName: string, maskedPan: string, provider: string, status: string, statusReason: string, userId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/cards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"acceptFeesAndCharges": $accept_fees_and_charges, "addressType": $address_type, "cardPin": $card_pin, "eurIcan": $eur_ican, "gbpIcan": $gbp_ican, "userId": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Block a card
#
# POST /v1/cards/{cardId}/block
# operationId: blockCard
export def "cards-block create" [
  card_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($card_id | is-empty) { error make --unspanned { msg: "path parameter 'cardId' must be non-empty" } }
  let full_url = (build-url $base ({card_id: (encode-path-segment $card_id)} | format pattern "/v1/cards/{card_id}/block"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int64
  --offset: int # format: int64
]: nothing -> table<dateRangeTo: int, total: int, transactions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($card_id | is-empty) { error make --unspanned { msg: "path parameter 'cardId' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({card_id: (encode-path-segment $card_id)} | format pattern "/v1/cards/{card_id}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "offset": $offset} | compact), body: null}
}

# Unblock a card
#
# POST /v1/cards/{cardId}/unblock
# operationId: unblockCard
export def "cards-unblock create" [
  card_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($card_id | is-empty) { error make --unspanned { msg: "path parameter 'cardId' must be non-empty" } }
  let full_url = (build-url $base ({card_id: (encode-path-segment $card_id)} | format pattern "/v1/cards/{card_id}/unblock"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mandate-uuid: string # The mandate UUID to retrieve (e.g. 1A07774B-1461-4595-BC4B-423B739712AF)
]: nothing -> record<directdebits: table<amount: int, currency: record, dateCreated: string, directDebitReference: string, directDebitUuid: string, isDDIC: bool, lastUpdated: string, mandateUUid: string, originatorAlias: string, originatorName: string, originatorReference: string, schemeRejectReason: string, schemeRejectReasonCode: string, status: string, targetIcan: int, targetPayeeId: int, type: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mandateUuid" $mandate_uuid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/directdebits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"mandateUuid": $mandate_uuid} | compact), body: null}
}

# Get the details of a direct debit
#
# GET /v1/directdebits/{directDebitUuid}
# operationId: getDirectDebitByUuid
export def "directdebits get-direct-debit-by-uuid" [
  direct_debit_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<amount: int, currency: record<code: string, description: string>, dateCreated: string, directDebitReference: string, directDebitUuid: string, isDDIC: bool, lastUpdated: string, mandateUUid: string, originatorAlias: string, originatorName: string, originatorReference: string, schemeRejectReason: string, schemeRejectReasonCode: string, status: string, targetIcan: int, targetPayeeId: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($direct_debit_uuid | is-empty) { error make --unspanned { msg: "path parameter 'directDebitUuid' must be non-empty" } }
  let full_url = (build-url $base ({direct_debit_uuid: (encode-path-segment $direct_debit_uuid)} | format pattern "/v1/directdebits/{direct_debit_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Reject a direct debit payment
#
# POST /v1/directdebits/{directDebitUuid}/reject
# operationId: rejectDirectDebit
export def "directdebits-reject reject-direct-debit" [
  direct_debit_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($direct_debit_uuid | is-empty) { error make --unspanned { msg: "path parameter 'directDebitUuid' must be non-empty" } }
  let full_url = (build-url $base ({direct_debit_uuid: (encode-path-segment $direct_debit_uuid)} | format pattern "/v1/directdebits/{direct_debit_uuid}/reject"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<mandates: table<alias: string, currency: record, dateCancelled: string, dateCompleted: string, dateCreated: string, fireRejectionReason: string, lastUpdated: string, latestDirectDebitAmount: int, latestDirectDebitDate: string, mandateReference: string, mandateUuid: string, numberOfDirectDebitCollected: int, originatorAlias: string, originatorLogoUrlLarge: string, originatorLogoUrlSmall: string, originatorName: string, originatorReference: string, schemeCancelReason: string, schemeCancelReasonCode: string, status: string, targetIcan: int, valueOfDirectDebitCollected: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/mandates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alias: string, currency: record<code: string, description: string>, dateCancelled: string, dateCompleted: string, dateCreated: string, fireRejectionReason: string, lastUpdated: string, latestDirectDebitAmount: int, latestDirectDebitDate: string, mandateReference: string, mandateUuid: string, numberOfDirectDebitCollected: int, originatorAlias: string, originatorLogoUrlLarge: string, originatorLogoUrlSmall: string, originatorName: string, originatorReference: string, schemeCancelReason: string, schemeCancelReasonCode: string, status: string, targetIcan: int, valueOfDirectDebitCollected: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mandate_uuid | is-empty) { error make --unspanned { msg: "path parameter 'mandateUuid' must be non-empty" } }
  let full_url = (build-url $base ({mandate_uuid: (encode-path-segment $mandate_uuid)} | format pattern "/v1/mandates/{mandate_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a direct debit mandate alias
#
# POST /v1/mandates/{mandateUuid}
# operationId: updateMandateAlias
export def "mandates update-alias" [
  mandate_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mandate_uuid | is-empty) { error make --unspanned { msg: "path parameter 'mandateUuid' must be non-empty" } }
  let full_url = (build-url $base ({mandate_uuid: (encode-path-segment $mandate_uuid)} | format pattern "/v1/mandates/{mandate_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Activate a direct debit mandate
#
# POST /v1/mandates/{mandateUuid}/activate
# operationId: activateMandate
export def "mandates-activate create" [
  mandate_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mandate_uuid | is-empty) { error make --unspanned { msg: "path parameter 'mandateUuid' must be non-empty" } }
  let full_url = (build-url $base ({mandate_uuid: (encode-path-segment $mandate_uuid)} | format pattern "/v1/mandates/{mandate_uuid}/activate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Cancel a direct debit mandate
#
# POST /v1/mandates/{mandateUuid}/cancel
# operationId: cancelMandateByUuid
export def "mandates-cancel cancel-by-uuid" [
  mandate_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($mandate_uuid | is-empty) { error make --unspanned { msg: "path parameter 'mandateUuid' must be non-empty" } }
  let full_url = (build-url $base ({mandate_uuid: (encode-path-segment $mandate_uuid)} | format pattern "/v1/mandates/{mandate_uuid}/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<fundingSources: table<accountHolderName: string, accountName: string, accountNumber: string, bic: string, createdBy: string, currency: record, dateCreated: string, iban: string, id: int, nsc: string, status: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/payees")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a Fire Open Payment request
#
# POST /v1/paymentrequests
# operationId: newPaymentRequest
# --orderDetails shape: {comment1?: string, comment2?: string, customerNumber?: string, deliveryAddressLine1?: string, deliveryAddressLine2?: string, deliveryCity?: string, deliveryCountry?: string, deliveryPostCode?: string, merchantCustomerIdentification?: string, merchantNumber?: string, orderId?: string, productId?: string, variableReference?: string}
export def "paymentrequests request-new-payment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"additionalFields": $additional_fields, "amount": $amount, "collectFields": $collect_fields, "currency": $currency, "description": $description, "expiry": $expiry, "icanTo": $ican_to, "mandatoryFields": $mandatory_fields, "maxNumberPayments": $max_number_payments, "myRef": $my_ref, "orderDetails": $order_details, "returnUrl": $return_url, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Payment Details
#
# GET /v1/payments/{paymentUuid}
# operationId: getPaymentDetails
export def "payments get-details" [
  payment_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<additionalFields: string, amount: int, collectFields: string, currency: record<code: string, description: string>, description: string, expiry: string, icanTo: int, mandatoryFields: string, maxNumberPayments: int, myRef: string, orderDetails: record<comment1: string, comment2: string, customerNumber: string, deliveryAddressLine1: string, deliveryAddressLine2: string, deliveryCity: string, deliveryCountry: string, deliveryPostCode: string, merchantCustomerIdentification: string, merchantNumber: string, orderId: string, productId: string, variableReference: string>, paymentRequestCode: string, paymentUuid: string, returnUrl: string, status: string, transactionType: string, type: string, webhookUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_uuid | is-empty) { error make --unspanned { msg: "path parameter 'paymentUuid' must be non-empty" } }
  let full_url = (build-url $base ({payment_uuid: (encode-path-segment $payment_uuid)} | format pattern "/v1/payments/{payment_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<emailAddress: string, firstName: string, id: int, lastName: string, lastlogin: string, mobileApplicationDetails: record<OS: string, businessUserId: int, clientID: string, deviceName: string, deviceOSVersion: string, mobileApplicationId: int, status: string>, mobileNumber: string, role: string, status: string, userCvl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/v1/user/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<emailAddress: string, firstName: string, id: int, lastName: string, lastlogin: string, mobileApplicationDetails: record<OS: string, businessUserId: int, clientID: string, deviceName: string, deviceOSVersion: string, mobileApplicationId: int, status: string>, mobileNumber: string, role: string, status: string, userCvl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List transactions for an account (v3)
#
# GET /v3/accounts/{ican}/transactions
# operationId: getTransactionsByIdv3
export def "accounts-transactions get-by-idv3" [
  ican: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # format: int64
  --date-range-from: int # format: int64
  --date-range-to: int # format: int64
  --start-after: string
]: nothing -> record<content: table<amountAfterCharges: int, amountBeforeCharges: int, balance: int, batchItemDetails: record, card: record, currency: record, date: string, dateAcknowledged: string, directDebitDetails: record, eventUuid: string, feeAmount: int, fxTradeDetails: record, ican: int, myRef: string, paymentRequestPublicCode: string, proprietarySchemeDetails: list, refId: int, relatedParty: any, taxAmount: int, txnId: int, type: string, yourRef: string>, links: table<href: string, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ican | is-empty) { error make --unspanned { msg: "path parameter 'ican' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "dateRangeFrom" $date_range_from "scalar") (serialize-qp "dateRangeTo" $date_range_to "scalar") (serialize-qp "startAfter" $start_after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ican: (encode-path-segment $ican)} | format pattern "/v3/accounts/{ican}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"limit": $limit, "dateRangeFrom": $date_range_from, "dateRangeTo": $date_range_to, "startAfter": $start_after} | compact), body: null}
}
