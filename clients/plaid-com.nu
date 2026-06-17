# Auto-generated client for The Plaid API v2020-09-14_1.334.0
# Source: https://api.apis.guru/v2/specs/plaid.com/2020-09-14_1.334.0/openapi.json
# Auth: --token flag or $env.THE_PLAID_API_TOKEN

const BASE_URL = "https://production.plaid.com"
const DEFAULT_AUTH = "plaid-client-id"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o THE_PLAID_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "plaid-client-id" => { {headers: {PLAID-CLIENT-ID: $token_val}, query: ""} }
    "plaid-version" => { {headers: {Plaid-Version: $token_val}, query: ""} }
    "plaid-secret" => { {headers: {PLAID-SECRET: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://production.plaid.com" "https://development.plaid.com" "https://sandbox.plaid.com"] }
def auth-scheme-completer [] { ["plaid-client-id" "plaid-version" "plaid-secret"] }

# Completers for enum parameters
def report-type-completer [] { ["VERIFICATION_OF_EMPLOYMENT"] }
def ach-class-completer [] { ["ccd" "ppd" "tel" "web"] }
def network-completer [] { ["ach" "same-day-ach" "wire"] }
def type-completer [] { ["credit" "debit"] }
def bank-transfer-type-completer [] { ["" "credit" "debit"] }
def direction-completer [] { ["" "inbound" "outbound"] }
def report-type-completer-1 [] { ["assets" "income"] }
def country-code-completer [] { ["CA" "US"] }
def category-completer [] { ["CONSENT" "FRAUD" "MAINTENANCE" "NEW_DATA" "SECURITY"] }
def priority-completer [] { ["HIGH" "LOW" "MEDIUM"] }
def severity-completer [] { ["ALERT" "EMERGENCY" "INFO" "NOTICE" "WARNING"] }
def type-completer-1 [] { ["BALANCE" "CONSENT_REVOKED" "CONSENT_UPDATED" "CUSTOM" "PLANNED_OUTAGE" "SERVICE"] }
def strategy-completer [] { ["custom" "incomplete" "infer" "reset"] }
def context-completer [] { ["ENROLLMENT" "PORTAL"] }
def decision-outcome-completer [] { ["APPROVE" "NOT_EVALUATED" "REJECT" "REVIEW" "TAKE_OTHER_RISK_MEASURES"] }
def payment-method-completer [] { ["DEBIT_CARD" "MULTIPLE_PAYMENT_METHODS" "NEXT_DAY_ACH" "REAL_TIME_PAYMENTS" "SAME_DAY_ACH" "STANDARD_ACH"] }
def processor-completer [] { ["achq" "adyen" "alpaca" "apex_clearing" "astra" "atomic" "check" "checkbook" "checkout" "circle" "drivewealth" "dwolla" "galileo" "gusto" "highnote" "i2c" "lithic" "marqeta" "modern_treasury" "moov" "ocrolus" "prime_trust" "riskified" "rize" "sila_money" "solid" "svb_api" "treasury_prime" "unit" "vesta" "vopay" "wepay" "wyre"] }
def verification-status-completer [] { ["VERIFICATION_STATUS_PENDING_APPROVAL" "VERIFICATION_STATUS_PROCESSING_COMPLETE" "VERIFICATION_STATUS_PROCESSING_FAILED"] }
def webhook-code-completer [] { ["AUTH_DATA_UPDATE" "DEFAULT_UPDATE" "NEW_ACCOUNTS_AVAILABLE" "RECURRING_TRANSACTIONS_UPDATE" "SYNC_UPDATES_AVAILABLE"] }
def webhook-type-completer [] { ["AUTH" "HOLDINGS" "INVESTMENTS_TRANSACTIONS" "ITEM" "LIABILITIES" "TRANSACTIONS"] }
def verification-status-completer-1 [] { ["automatically_verified" "verification_expired"] }
def network-completer-1 [] { ["ach" "rtp" "same-day-ach"] }
def transfer-type-completer [] { ["" "credit" "debit"] }
def mode-completer [] { ["DISBURSEMENT" "PAYMENT"] }
def network-completer-2 [] { ["ach" "same-day-ach"] }
def iso-currency-code-completer [] { ["EUR" "GBP"] }
def status-completer [] { ["cleared" "pending_review" "rejected"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts-balance-get accountsBalanceGet" } } | get name | first)
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

# Retrieve real-time balance data
#
# POST /accounts/balance/get
# Docs: /api/products/balance/#accountsbalanceget
# operationId: accountsBalanceGet
# --options shape: {account_ids?: list, min_last_updated_datetime?: string}
export def "accounts-balance-get accountsBalanceGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --options: record # An optional object to filter `/accounts/balance/get` results. — shape: {account_ids?: list, min_last_updated_datetime?: string}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, persistent_account_id: string, subtype: string, type: string, verification_status: string>, item: record<available_products: list<string>, billed_products: list<string>, consent_expiration_time: string, consented_products: list<string>, error: record<causes: list, display_message: string, documentation_url: string, error_code: string, error_message: string, error_type: string, request_id: string, status: float, suggested_action: string>, institution_id: string, item_id: string, products: list<string>, update_type: string, webhook: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts/balance/get")
  let body = {"access_token": $access_token, "client_id": $client_id, "options": $options, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve accounts
#
# POST /accounts/get
# Docs: /api/accounts/#accountsget
# operationId: accountsGet
# --options shape: {account_ids?: list}
export def "accounts-get accountsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --options: record # An optional object to filter `/accounts/get` results. — shape: {account_ids?: list}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, persistent_account_id: string, subtype: string, type: string, verification_status: string>, item: record<available_products: list<string>, billed_products: list<string>, consent_expiration_time: string, consented_products: list<string>, error: record<causes: list, display_message: string, documentation_url: string, error_code: string, error_message: string, error_type: string, request_id: string, status: float, suggested_action: string>, institution_id: string, item_id: string, products: list<string>, update_type: string, webhook: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts/get")
  let body = {"access_token": $access_token, "client_id": $client_id, "options": $options, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve information about a Plaid application
#
# POST /application/get
# operationId: applicationGet
export def "application-get applicationGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  application_id: string # This field will map to the application ID that is returned from /item/applications/list, or provided to the institution in an oauth redirect.
  client_id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<application: record<application_id: string, application_url: string, city: string, company_legal_name: string, country_code: string, display_name: string, join_date: string, logo_url: string, name: string, postal_code: string, reason_for_access: string, region: string, use_case: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/get")
  let body = {"application_id": $application_id, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Asset Report Audit Copy
#
# POST /asset_report/audit_copy/create
# Docs: /api/products/assets/#asset_reportaudit_copycreate
# operationId: assetReportAuditCopyCreate
export def "asset-report-audit-copy-create assetReportAuditCopyCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  asset_report_token: string # A token that can be provided to endpoints such as `/asset_report/get` or `/asset_report/pdf/get` to fetch or update an Asset Report.
  --auditor-id: string # The `auditor_id` of the third party with whom you would like to share the Asset Report.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<audit_copy_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset_report/audit_copy/create")
  let body = {"asset_report_token": $asset_report_token, "auditor_id": $auditor_id, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an Asset Report Audit Copy
#
# POST /asset_report/audit_copy/get
# Docs: /none/
# operationId: assetReportAuditCopyGet
export def "asset-report-audit-copy-get assetReportAuditCopyGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  audit_copy_token: string # The `audit_copy_token` granting access to the Audit Copy you would like to get.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<report: record<asset_report_id: string, client_report_id: string, date_generated: string, days_requested: float, items: list<record>, user: record<client_user_id: string, email: string, first_name: string, last_name: string, middle_name: string, phone_number: string, ssn: string>>, request_id: string, warnings: table<cause: record, warning_code: string, warning_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset_report/audit_copy/get")
  let body = {"audit_copy_token": $audit_copy_token, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove Asset Report Audit Copy
#
# POST /asset_report/audit_copy/remove
# Docs: /api/products/assets/#asset_reportaudit_copyremove
# operationId: assetReportAuditCopyRemove
export def "asset-report-audit-copy-remove assetReportAuditCopyRemove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  audit_copy_token: string # The `audit_copy_token` granting access to the Audit Copy you would like to revoke.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<removed: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset_report/audit_copy/remove")
  let body = {"audit_copy_token": $audit_copy_token, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create an Asset Report
#
# POST /asset_report/create
# Docs: /api/products/assets/#asset_reportcreate
# operationId: assetReportCreate
# --options shape: {add_ons?: list, client_report_id?: string, include_fast_report?: bool, products?: list, user?: record, webhook?: string}
export def "asset-report-create assetReportCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_tokens: list # An array of access tokens corresponding to the Items that will be included in the report. The `assets` product must have been initialized for the Items during link; the Assets product cannot be added after initialization.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  days_requested: int # The maximum integer number of days of history to include in the Asset Report. If using Fannie Mae Day 1 Certainty, `days_requested` must be at least 61 for new originations or at least 31 for refinancings.  An Asset Report requested with "Additional History" (that is, with more than 61 days of transaction history) will incur an Additional History fee.
  --options: record # An optional object to filter `/asset_report/create` results. If provided, must be non-`null`. The optional `user` object is required for the report to be eligible for Fannie Mae's Day 1 Certainty program. — shape: {add_ons?: list, client_report_id?: string, include_fast_report?: bool, products?: list, user?: record, webhook?: string}
  --report-type: string@report-type-completer # When set to `VERIFICATION_OF_EMPLOYMENT` and the Asset Report is added to an Audit Copy Token, the Asset Report will be retrieved by Freddie Mac in the Verification Of Employment (VOE) version instead of the default Verification Of Assets (VOA) version.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<asset_report_id: string, asset_report_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset_report/create")
  let body = {"access_tokens": $access_tokens, "client_id": $client_id, "days_requested": $days_requested, "options": $options, "report_type": $report_type, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Filter Asset Report
#
# POST /asset_report/filter
# Docs: /api/products/assets/#asset_reportfilter
# operationId: assetReportFilter
export def "asset-report-filter assetReportFilter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_ids_to_exclude: list # The accounts to exclude from the Asset Report, identified by `account_id`.
  asset_report_token: string # A token that can be provided to endpoints such as `/asset_report/get` or `/asset_report/pdf/get` to fetch or update an Asset Report.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<asset_report_id: string, asset_report_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset_report/filter")
  let body = {"account_ids_to_exclude": $account_ids_to_exclude, "asset_report_token": $asset_report_token, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an Asset Report
#
# POST /asset_report/get
# Docs: /api/products/assets/#asset_reportget
# operationId: assetReportGet
# --options shape: {days_to_include?: int}
export def "asset-report-get assetReportGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  asset_report_token: string # A token that can be provided to endpoints such as `/asset_report/get` or `/asset_report/pdf/get` to fetch or update an Asset Report.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --fast-report: oneof<nothing, bool> # `true` to fetch "fast" version of asset report. Defaults to false if omitted. (default: false)
  --include-insights: oneof<nothing, bool> # `true` if you would like to retrieve the Asset Report with Insights, `false` otherwise. This field defaults to `false` if omitted. (default: false)
  --options: record # An optional object to filter or add data to `/asset_report/get` results. If provided, must be non-`null`. — shape: {days_to_include?: int}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<report: record<asset_report_id: string, client_report_id: string, date_generated: string, days_requested: float, items: list<record>, user: record<client_user_id: string, email: string, first_name: string, last_name: string, middle_name: string, phone_number: string, ssn: string>>, request_id: string, warnings: table<cause: record, warning_code: string, warning_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset_report/get")
  let body = {"asset_report_token": $asset_report_token, "client_id": $client_id, "fast_report": $fast_report, "include_insights": $include_insights, "options": $options, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a PDF Asset Report
#
# POST /asset_report/pdf/get
# Docs: /api/products/assets/#asset_reportpdfget
# operationId: assetReportPdfGet
# --options shape: {days_to_include?: int}
export def "asset-report-pdf-get assetReportPdfGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  asset_report_token: string # A token that can be provided to endpoints such as `/asset_report/get` or `/asset_report/pdf/get` to fetch or update an Asset Report.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --options: record # An optional object to filter or add data to `/asset_report/get` results. If provided, must be non-`null`. — shape: {days_to_include?: int}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset_report/pdf/get")
  let body = {"asset_report_token": $asset_report_token, "client_id": $client_id, "options": $options, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Refresh an Asset Report
#
# POST /asset_report/refresh
# Docs: /api/products/assets/#asset_reportrefresh
# operationId: assetReportRefresh
# --options shape: {client_report_id?: string, user?: record, webhook?: string}
export def "asset-report-refresh assetReportRefresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  asset_report_token: string # The `asset_report_token` returned by the original call to `/asset_report/create`
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --days-requested: int # The maximum number of days of history to include in the Asset Report. Must be an integer. If not specified, the value from the original call to `/asset_report/create` will be used. (nullable)
  --options: record # An optional object to filter `/asset_report/refresh` results. If provided, cannot be `null`. If not specified, the `options` from the original call to `/asset_report/create` will be used. — shape: {client_report_id?: string, user?: record, webhook?: string}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<asset_report_id: string, asset_report_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset_report/refresh")
  let body = {"asset_report_token": $asset_report_token, "client_id": $client_id, "days_requested": $days_requested, "options": $options, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an Asset Report
#
# POST /asset_report/remove
# Docs: /api/products/assets/#asset_reportremove
# operationId: assetReportRemove
export def "asset-report-remove assetReportRemove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  asset_report_token: string # A token that can be provided to endpoints such as `/asset_report/get` or `/asset_report/pdf/get` to fetch or update an Asset Report.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<removed: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset_report/remove")
  let body = {"asset_report_token": $asset_report_token, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve auth data
#
# POST /auth/get
# Docs: /api/products/auth/#authget
# operationId: authGet
# --options shape: {account_ids?: list}
export def "auth-get authGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --options: record # An optional object to filter `/auth/get` results. — shape: {account_ids?: list}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, persistent_account_id: string, subtype: string, type: string, verification_status: string>, item: record<available_products: list<string>, billed_products: list<string>, consent_expiration_time: string, consented_products: list<string>, error: record<causes: list, display_message: string, documentation_url: string, error_code: string, error_message: string, error_type: string, request_id: string, status: float, suggested_action: string>, institution_id: string, item_id: string, products: list<string>, update_type: string, webhook: string>, numbers: record<ach: list<record>, bacs: list<record>, eft: list<record>, international: list<record>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/get")
  let body = {"access_token": $access_token, "client_id": $client_id, "options": $options, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get balance of your Bank Transfer account
#
# POST /bank_transfer/balance/get
# Docs: /bank-transfers/reference#bank_transferbalanceget
# operationId: bankTransferBalanceGet
export def "bank-transfer-balance-get bankTransferBalanceGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --origination-account-id: string # If multiple origination accounts are available, `origination_account_id` must be used to specify the account for which balance will be returned. (nullable)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<balance: record<available: string, transactable: string>, origination_account_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank_transfer/balance/get")
  let body = {"client_id": $client_id, "origination_account_id": $origination_account_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel a bank transfer
#
# POST /bank_transfer/cancel
# Docs: /bank-transfers/reference#bank_transfercancel
# operationId: bankTransferCancel
export def "bank-transfer-cancel bankTransferCancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  bank_transfer_id: string # Plaid’s unique identifier for a bank transfer.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank_transfer/cancel")
  let body = {"bank_transfer_id": $bank_transfer_id, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a bank transfer
#
# POST /bank_transfer/create
# Docs: /bank-transfers/reference#bank_transfercreate
# operationId: bankTransferCreate
# --user shape: {email_address?: string, legal_name: string}
export def "bank-transfer-create bankTransferCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The Plaid `access_token` for the account that will be debited or credited.
  account_id: string # The Plaid `account_id` for the account that will be debited or credited.
  --ach-class: string@ach-class-completer # Specifies the use case of the transfer. Required for transfers on an ACH network.  `"ccd"` - Corporate Credit or Debit - fund transfer between two corporate bank accounts  `"ppd"` - Prearranged Payment or Deposit - the transfer is part of a pre-existing relationship with a consumer, eg. bill payment  `"tel"` - Telephone-Initiated Entry  `"web"` - Internet-Initiated Entry - debits from a consumer’s account where their authorization is obtained over the Internet
  amount: string # The amount of the bank transfer (decimal string with two digits of precision e.g. "10.00").
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --custom-tag: string # An arbitrary string provided by the client for storage with the bank transfer. May be up to 100 characters. (nullable)
  description: string # The transfer description. Maximum of 10 characters.
  idempotency_key: string # A random key provided by the client, per unique bank transfer. Maximum of 50 characters.  The API supports idempotency for safely retrying requests without accidentally performing the same operation twice. For example, if a request to create a bank transfer fails due to a network connection error, you can retry the request with the same idempotency key to guarantee that only a single bank transfer is created.
  iso_currency_code: string # The currency of the transfer amount – should be set to "USD".
  --metadata: record # The Metadata object is a mapping of client-provided string fields to any string value. The following limitations apply: The JSON values must be Strings (no nested JSON objects allowed) Only ASCII characters may be used Maximum of 50 key/value pairs Maximum key length of 40 characters Maximum value length of 500 characters  (nullable)
  network: string@network-completer # The network or rails used for the transfer. Valid options are `ach`, `same-day-ach`, or `wire`.
  --origination-account-id: string # Plaid’s unique identifier for the origination account for this transfer. If you have more than one origination account, this value must be specified. Otherwise, this field should be left blank. (nullable)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  type: string@type-completer # The type of bank transfer. This will be either `debit` or `credit`.  A `debit` indicates a transfer of money into the origination account; a `credit` indicates a transfer of money out of the origination account.
  user: record # The legal name and other information for the account holder. — shape: {email_address?: string, legal_name: string}
]: any -> record<bank_transfer: record<account_id: string, ach_class: string, amount: string, cancellable: bool, created: string, custom_tag: string, description: string, direction: string, failure_reason: record<ach_return_code: string, description: string>, id: string, iso_currency_code: string, metadata: record, network: string, origination_account_id: string, status: string, type: string, user: record<email_address: string, legal_name: string, routing_number: string>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank_transfer/create")
  let body = {"access_token": $access_token, "account_id": $account_id, "ach_class": $ach_class, "amount": $amount, "client_id": $client_id, "custom_tag": $custom_tag, "description": $description, "idempotency_key": $idempotency_key, "iso_currency_code": $iso_currency_code, "metadata": $metadata, "network": $network, "origination_account_id": $origination_account_id, "secret": $secret, "type": $type, "user": $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List bank transfer events
#
# POST /bank_transfer/event/list
# Docs: /api/products/auth#bank_transfereventlist
# operationId: bankTransferEventList
export def "bank-transfer-event-list bankTransferEventList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # The account ID to get events for all transactions to/from an account. (nullable)
  --bank-transfer-id: string # Plaid’s unique identifier for a bank transfer. (nullable)
  --bank-transfer-type: string@bank-transfer-type-completer # The type of bank transfer. This will be either `debit` or `credit`.  A `debit` indicates a transfer of money into your origination account; a `credit` indicates a transfer of money out of your origination account. (nullable)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --count: int # The maximum number of bank transfer events to return. If the number of events matching the above parameters is greater than `count`, the most recent events will be returned. (nullable, default: 25)
  --direction: string@direction-completer # Indicates the direction of the transfer: `outbound`: for API-initiated transfers `inbound`: for payments received by the FBO account. (nullable)
  --end-date: string # The end datetime of bank transfers to list. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
  --event-types: list # Filter events by event type.
  --offset: int # The offset into the list of bank transfer events. When `count`=25 and `offset`=0, the first 25 events will be returned. When `count`=25 and `offset`=25, the next 25 bank transfer events will be returned. (nullable, default: 0)
  --origination-account-id: string # The origination account ID to get events for transfers from a specific origination account. (nullable)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --start-date: string # The start datetime of bank transfers to list. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
]: any -> record<bank_transfer_events: table<account_id: string, bank_transfer_amount: string, bank_transfer_id: string, bank_transfer_iso_currency_code: string, bank_transfer_type: string, direction: string, event_id: int, event_type: string, failure_reason: record, origination_account_id: string, timestamp: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank_transfer/event/list")
  let body = {"account_id": $account_id, "bank_transfer_id": $bank_transfer_id, "bank_transfer_type": $bank_transfer_type, "client_id": $client_id, "count": $count, "direction": $direction, "end_date": $end_date, "event_types": $event_types, "offset": $offset, "origination_account_id": $origination_account_id, "secret": $secret, "start_date": $start_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sync bank transfer events
#
# POST /bank_transfer/event/sync
# Docs: /api/products/auth/#bank_transfereventsync
# operationId: bankTransferEventSync
export def "bank-transfer-event-sync bankTransferEventSync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  after_id: int # The latest (largest) `event_id` fetched via the sync endpoint, or 0 initially.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --count: int # The maximum number of bank transfer events to return. (nullable, default: 25)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<bank_transfer_events: table<account_id: string, bank_transfer_amount: string, bank_transfer_id: string, bank_transfer_iso_currency_code: string, bank_transfer_type: string, direction: string, event_id: int, event_type: string, failure_reason: record, origination_account_id: string, timestamp: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank_transfer/event/sync")
  let body = {"after_id": $after_id, "client_id": $client_id, "count": $count, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a bank transfer
#
# POST /bank_transfer/get
# Docs: /bank-transfers/reference#bank_transferget
# operationId: bankTransferGet
export def "bank-transfer-get bankTransferGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  bank_transfer_id: string # Plaid’s unique identifier for a bank transfer.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<bank_transfer: record<account_id: string, ach_class: string, amount: string, cancellable: bool, created: string, custom_tag: string, description: string, direction: string, failure_reason: record<ach_return_code: string, description: string>, id: string, iso_currency_code: string, metadata: record, network: string, origination_account_id: string, status: string, type: string, user: record<email_address: string, legal_name: string, routing_number: string>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank_transfer/get")
  let body = {"bank_transfer_id": $bank_transfer_id, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List bank transfers
#
# POST /bank_transfer/list
# Docs: /bank-transfers/reference#bank_transferlist
# operationId: bankTransferList
export def "bank-transfer-list bankTransferList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --count: int # The maximum number of bank transfers to return. (default: 25)
  --direction: string@direction-completer # Indicates the direction of the transfer: `outbound` for API-initiated transfers, or `inbound` for payments received by the FBO account. (nullable)
  --end-date: string # The end datetime of bank transfers to list. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
  --offset: int # The number of bank transfers to skip before returning results. (default: 0)
  --origination-account-id: string # Filter bank transfers to only those originated through the specified origination account. (nullable)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --start-date: string # The start datetime of bank transfers to list. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
]: any -> record<bank_transfers: table<account_id: string, ach_class: string, amount: string, cancellable: bool, created: string, custom_tag: string, description: string, direction: string, failure_reason: record, id: string, iso_currency_code: string, metadata: record, network: string, origination_account_id: string, status: string, type: string, user: record>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank_transfer/list")
  let body = {"client_id": $client_id, "count": $count, "direction": $direction, "end_date": $end_date, "offset": $offset, "origination_account_id": $origination_account_id, "secret": $secret, "start_date": $start_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Migrate account into Bank Transfers
#
# POST /bank_transfer/migrate_account
# Docs: /bank-transfers/reference#bank_transfermigrate_account
# operationId: bankTransferMigrateAccount
export def "bank-transfer-migrate-account bankTransferMigrateAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_number: string # The user's account number.
  account_type: string # The type of the bank account (`checking` or `savings`).
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  routing_number: string # The user's routing number.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --wire-routing-number: string # The user's wire transfer routing number. This is the ABA number; for some institutions, this may differ from the ACH number used in `routing_number`.
]: any -> record<access_token: string, account_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank_transfer/migrate_account")
  let body = {"account_number": $account_number, "account_type": $account_type, "client_id": $client_id, "routing_number": $routing_number, "secret": $secret, "wire_routing_number": $wire_routing_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a sweep
#
# POST /bank_transfer/sweep/get
# Docs: /api/products/transfer/#bank_transfersweepget
# operationId: bankTransferSweepGet
export def "bank-transfer-sweep-get bankTransferSweepGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  sweep_id: string # Identifier of the sweep.
]: any -> record<request_id: string, sweep: record<amount: string, created_at: string, id: string, iso_currency_code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank_transfer/sweep/get")
  let body = {"client_id": $client_id, "secret": $secret, "sweep_id": $sweep_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List sweeps
#
# POST /bank_transfer/sweep/list
# Docs: /api/products/transfer/#bank_transfersweeplist
# operationId: bankTransferSweepList
export def "bank-transfer-sweep-list bankTransferSweepList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --count: int # The maximum number of sweeps to return. (nullable, default: 25)
  --end-time: string # The end datetime of sweeps to return (RFC 3339 format). (nullable, format: date-time)
  --origination-account-id: string # If multiple origination accounts are available, `origination_account_id` must be used to specify the account that the sweeps belong to. (nullable)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --start-time: string # The start datetime of sweeps to return (RFC 3339 format). (nullable, format: date-time)
]: any -> record<request_id: string, sweeps: table<amount: string, created_at: string, id: string, iso_currency_code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank_transfer/sweep/list")
  let body = {"client_id": $client_id, "count": $count, "end_time": $end_time, "origination_account_id": $origination_account_id, "secret": $secret, "start_time": $start_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve information from the bank accounts used for employment verification
#
# POST /beta/credit/v1/bank_employment/get
# Docs: /api/products/income/#creditbank_employmentget
# operationId: creditBankEmploymentGet
export def "beta-credit-bank-employment-get creditBankEmploymentGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_token: string # The user token associated with the User data is being requested for.
]: any -> record<bank_employment_reports: table<bank_employment_report_id: string, days_requested: int, generated_time: string, items: list, warnings: list>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beta/credit/v1/bank_employment/get")
  let body = {"client_id": $client_id, "secret": $secret, "user_token": $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create transaction category rule
#
# POST /beta/transactions/rules/v1/create
# operationId: transactionsRulesCreate
# --rule_details shape: {field: "TRANSACTION_ID"|"NAME", query: string, type: "EXACT_MATCH"|"SUBSTRING_MATCH"}
export def "beta-transactions-rules-create transactionsRulesCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  personal_finance_category: string # Personal finance detailed category.  See the [`taxonomy csv file`](https://plaid.com/documents/transactions-personal-finance-category-taxonomy.csv) for a full list of personal finance categories.
  rule_details: record # A representation of transactions rule details. — shape: {field: "TRANSACTION_ID"|"NAME", query: string, type: "EXACT_MATCH"|"SUBSTRING_MATCH"}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string, rule: record<created_at: string, id: string, item_id: string, personal_finance_category: string, rule_details: record<field: string, query: string, type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beta/transactions/rules/v1/create")
  let body = {"access_token": $access_token, "client_id": $client_id, "personal_finance_category": $personal_finance_category, "rule_details": $rule_details, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return a list of rules created for the Item associated with the access token.
#
# POST /beta/transactions/rules/v1/list
# operationId: transactionsRulesList
export def "beta-transactions-rules-list transactionsRulesList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string, rules: table<created_at: string, id: string, item_id: string, personal_finance_category: string, rule_details: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beta/transactions/rules/v1/list")
  let body = {"access_token": $access_token, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove transaction rule
#
# POST /beta/transactions/rules/v1/remove
# operationId: transactionsRulesRemove
export def "beta-transactions-rules-remove transactionsRulesRemove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  rule_id: string # A rule's unique identifier
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beta/transactions/rules/v1/remove")
  let body = {"access_token": $access_token, "client_id": $client_id, "rule_id": $rule_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# enhance locally-held transaction data
#
# POST /beta/transactions/v1/enhance
# operationId: transactionsEnhance
# --transactions item shape: {amount: float, description: string, id: string, iso_currency_code: string}
export def "beta-transactions-enhance transactionsEnhance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_type: string # The type of account for the requested transactions (`depository` or `credit`).
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  transactions: list # An array of raw transactions to be enhanced. — item shape: {amount: float, description: string, id: string, iso_currency_code: string}
]: any -> record<enhanced_transactions: table<amount: float, description: string, enhancements: record, id: string, iso_currency_code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beta/transactions/v1/enhance")
  let body = {"account_type": $account_type, "client_id": $client_id, "secret": $secret, "transactions": $transactions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Categories
#
# POST /categories/get
# Docs: /api/products/transactions/#categoriesget
# operationId: categoriesGet
export def "categories-get categoriesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<categories: table<category_id: string, group: string, hierarchy: list>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/categories/get")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an Asset Report with Freddie Mac format. Only Freddie Mac can use this endpoint.
#
# POST /credit/asset_report/freddie_mac/get
# Docs: /none/
# operationId: creditAssetReportFreddieMacGet
export def "credit-asset-report-freddie-mac-get creditAssetReportFreddieMacGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  audit_copy_token: string # A token that can be shared with a third party auditor to allow them to obtain access to the Asset Report. This token should be stored securely.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<DEAL: record<LOANS: record<LOAN: record>, PARTIES: record<PARTY: list>, SERVICES: record<SERVICE: record>>, SchemaVersion: float, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/asset_report/freddie_mac/get")
  let body = {"audit_copy_token": $audit_copy_token, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Asset or Income Report Audit Copy Token
#
# POST /credit/audit_copy_token/create
# Docs: /api/products/income/#creditaudit_copy_tokencreate
# operationId: creditAuditCopyTokenCreate
export def "credit-audit-copy-token-create creditAuditCopyTokenCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  report_tokens: list # List of report tokens; can include both Asset Report tokens and Income Report tokens.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<audit_copy_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/audit_copy_token/create")
  let body = {"client_id": $client_id, "report_tokens": $report_tokens, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove an Audit Copy token
#
# POST /credit/audit_copy_token/remove
# Docs: /api/products/income/#creditaudit_copy_tokenremove
# operationId: creditReportAuditCopyRemove
export def "credit-audit-copy-token-remove creditReportAuditCopyRemove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  audit_copy_token: string # The `audit_copy_token` granting access to the Audit Copy you would like to revoke.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<removed: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/audit_copy_token/remove")
  let body = {"audit_copy_token": $audit_copy_token, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an Audit Copy Token
#
# POST /credit/audit_copy_token/update
# Docs: /none/
# operationId: creditAuditCopyTokenUpdate
export def "credit-audit-copy-token-update creditAuditCopyTokenUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  audit_copy_token: string # The `audit_copy_token` you would like to update.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  report_tokens: list # Array of tokens which the specified Audit Copy Token will be updated with. The types of token supported are asset report token and employment report token. There can be at most 1 of each type can be in the array.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string, updated: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/audit_copy_token/update")
  let body = {"audit_copy_token": $audit_copy_token, "client_id": $client_id, "report_tokens": $report_tokens, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve information from the bank accounts used for income verification
#
# POST /credit/bank_income/get
# Docs: /api/products/income/#creditbank_incomeget
# operationId: creditBankIncomeGet
# --options shape: {count?: int}
export def "credit-bank-income-get creditBankIncomeGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --options: record # An optional object for `/credit/bank_income/get` request options. — shape: {count?: int}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-token: string # The user token associated with the User data is being requested for.
]: any -> record<bank_income: table<bank_income_id: string, bank_income_summary: record, days_requested: int, generated_time: string, items: list, warnings: list>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/bank_income/get")
  let body = {"client_id": $client_id, "options": $options, "secret": $secret, "user_token": $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve information from the bank accounts used for income verification in PDF format
#
# POST /credit/bank_income/pdf/get
# Docs: /api/products/income/#creditbank_incomepdfget
# operationId: creditBankIncomePdfGet
export def "credit-bank-income-pdf-get creditBankIncomePdfGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_token: string # The user token associated with the User data is being requested for.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/bank_income/pdf/get")
  let body = {"client_id": $client_id, "secret": $secret, "user_token": $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Refresh a user's bank income information
#
# POST /credit/bank_income/refresh
# Docs: /api/products/income/#creditbank_incomerefresh
# operationId: creditBankIncomeRefresh
# --options shape: {days_requested?: int, webhook?: string}
export def "credit-bank-income-refresh creditBankIncomeRefresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --options: record # An optional object for `/credit/bank_income/refresh` request options. — shape: {days_requested?: int, webhook?: string}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_token: string # The user token associated with the User data is being requested for.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/bank_income/refresh")
  let body = {"client_id": $client_id, "options": $options, "secret": $secret, "user_token": $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a summary of an individual's employment information
#
# POST /credit/employment/get
# Docs: /api/products/income/#creditemploymentget
# operationId: creditEmploymentGet
export def "credit-employment-get creditEmploymentGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_token: string # The user token associated with the User data is being requested for.
]: any -> record<items: table<employment_report_token: string, employments: list, item_id: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/employment/get")
  let body = {"client_id": $client_id, "secret": $secret, "user_token": $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an Asset Report with Freddie Mac format (aka VOA - Verification Of Assets), and a Verification Of Employment (VOE) report if this one is available. Only Freddie Mac can use this endpoint.
#
# POST /credit/freddie_mac/reports/get
# Docs: /none/
# operationId: creditFreddieMacReportsGet
export def "credit-freddie-mac-reports-get creditFreddieMacReportsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  audit_copy_token: string # A token that can be shared with a third party auditor to allow them to obtain access to the Asset Report. This token should be stored securely.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<VOA: record<DEAL: record<LOANS: record, PARTIES: record, SERVICES: record>, SchemaVersion: float>, VOE: record<DEAL: record<LOANS: record, PARTIES: record, SERVICES: record>, SchemaVersion: float>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/freddie_mac/reports/get")
  let body = {"audit_copy_token": $audit_copy_token, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a user's payroll information
#
# POST /credit/payroll_income/get
# Docs: /api/products/income/#creditpayroll_incomeget
# operationId: creditPayrollIncomeGet
export def "credit-payroll-income-get creditPayrollIncomeGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-token: string # The user token associated with the User data is being requested for.
]: any -> record<error: record<causes: list<any>, display_message: string, documentation_url: string, error_code: string, error_message: string, error_type: string, request_id: string, status: float, suggested_action: string>, items: table<accounts: list, institution_id: string, institution_name: string, item_id: string, payroll_income: list, status: record, updated_at: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/payroll_income/get")
  let body = {"client_id": $client_id, "secret": $secret, "user_token": $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Check income verification eligibility and optimize conversion
#
# POST /credit/payroll_income/precheck
# Docs: /api/products/income/#creditpayroll_incomeprecheck
# operationId: creditPayrollIncomePrecheck
# --employer shape: {address?: record, name?: string, tax_id?: string, url?: string}
# --payroll_institution shape: {name?: string}
# --us_military_info shape: {branch?: string, is_active_duty?: bool}
export def "credit-payroll-income-precheck creditPayrollIncomePrecheck" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-tokens: list # An array of access tokens corresponding to Items belonging to the user whose eligibility is being checked. Note that if the Items specified here are not already initialized with `transactions`, providing them in this field will cause these Items to be initialized with (and billed for) the Transactions product.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --employer: record # Information about the end user's employer (nullable) — shape: {address?: record, name?: string, tax_id?: string, url?: string}
  --payroll-institution: record # Information about the end user's payroll institution (nullable) — shape: {name?: string}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --us-military-info: record # Data about military info in the income verification precheck. (nullable) — shape: {branch?: string, is_active_duty?: bool}
  --user-token: string # The user token associated with the User data is being requested for.
]: any -> record<confidence: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/payroll_income/precheck")
  let body = {"access_tokens": $access_tokens, "client_id": $client_id, "employer": $employer, "payroll_institution": $payroll_institution, "secret": $secret, "us_military_info": $us_military_info, "user_token": $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Refresh a digital payroll income verification
#
# POST /credit/payroll_income/refresh
# Docs: /api/products/income/#creditpayroll_incomerefresh
# operationId: creditPayrollIncomeRefresh
export def "credit-payroll-income-refresh creditPayrollIncomeRefresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-token: string # The user token associated with the User data is being requested for.
]: any -> record<request_id: string, verification_refresh_status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/payroll_income/refresh")
  let body = {"client_id": $client_id, "secret": $secret, "user_token": $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a relay token to share an Asset Report with a partner client (beta)
#
# POST /credit/relay/create
# Docs: /api/products/assets/#creditrelaycreate
# operationId: creditRelayCreate
export def "credit-relay-create creditRelayCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  report_tokens: list # List of report token strings, with at most one token of each report type. Currently only Asset Report token is supported.
  secondary_client_id: string # The `secondary_client_id` is the client id of the third party with whom you would like to share the relay token.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --webhook: string # URL to which Plaid will send webhooks when the Secondary Client successfully retrieves an Asset Report by calling `/credit/relay/get`. (nullable)
]: any -> record<relay_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/relay/create")
  let body = {"client_id": $client_id, "report_tokens": $report_tokens, "secondary_client_id": $secondary_client_id, "secret": $secret, "webhook": $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve the reports associated with a relay token that was shared with you (beta)
#
# POST /credit/relay/get
# Docs: /api/products/assets/#creditrelayget
# operationId: creditRelayGet
export def "credit-relay-get creditRelayGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  relay_token: string # The `relay_token` granting access to the report you would like to get.
  report_type: string@report-type-completer-1 # The report type. It can be `assets` or `income`.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<report: record<asset_report_id: string, client_report_id: string, date_generated: string, days_requested: float, items: list<record>, user: record<client_user_id: string, email: string, first_name: string, last_name: string, middle_name: string, phone_number: string, ssn: string>>, request_id: string, warnings: table<cause: record, warning_code: string, warning_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/relay/get")
  let body = {"client_id": $client_id, "relay_token": $relay_token, "report_type": $report_type, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Refresh a report of a relay token (beta)
#
# POST /credit/relay/refresh
# Docs: /api/products/assets/#creditrelayrefresh
# operationId: creditRelayRefresh
export def "credit-relay-refresh creditRelayRefresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  relay_token: string # The `relay_token` granting access to the report you would like to refresh.
  report_type: string@report-type-completer-1 # The report type. It can be `assets` or `income`.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --webhook: string # The URL registered to receive webhooks when the report of a relay token has been refreshed. (nullable)
]: any -> record<asset_report_id: string, relay_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/relay/refresh")
  let body = {"client_id": $client_id, "relay_token": $relay_token, "report_type": $report_type, "secret": $secret, "webhook": $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove relay token (beta)
#
# POST /credit/relay/remove
# Docs: /api/products/assets/#creditrelayremove
# operationId: creditRelayRemove
export def "credit-relay-remove creditRelayRemove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  relay_token: string # The `relay_token` you would like to revoke.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<removed: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/relay/remove")
  let body = {"client_id": $client_id, "relay_token": $relay_token, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve Link sessions for your user
#
# POST /credit/sessions/get
# Docs: /api/products/income/#creditsessionsget
# operationId: creditSessionsGet
export def "credit-sessions-get creditSessionsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_token: string # The user token associated with the User data is being requested for.
]: any -> record<request_id: string, sessions: table<errors: list, link_session_id: string, results: record, session_start_time: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/sessions/get")
  let body = {"client_id": $client_id, "secret": $secret, "user_token": $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a dashboard user
#
# POST /dashboard_user/get
# Docs: /api/products/monitor/#dashboard_userget
# operationId: dashboardUserGet
export def "dashboard-user-get dashboardUserGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  dashboard_user_id: string # ID of the associated user. (e.g. 54350110fedcbaf01234ffee)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<created_at: string, email_address: string, id: string, request_id: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dashboard_user/get")
  let body = {"client_id": $client_id, "dashboard_user_id": $dashboard_user_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List dashboard users
#
# POST /dashboard_user/list
# Docs: /api/products/monitor/#dashboard_userlist
# operationId: dashboardUserList
export def "dashboard-user-list dashboardUserList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<dashboard_users: table<created_at: string, email_address: string, id: string, status: string>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dashboard_user/list")
  let body = {"client_id": $client_id, "cursor": $cursor, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a deposit switch without using Plaid Exchange
#
# POST /deposit_switch/alt/create
# Docs: /deposit-switch/reference#deposit_switchaltcreate
# operationId: depositSwitchAltCreate
# --options shape: {transaction_item_access_tokens?: list, webhook?: string}
# --target_account shape: {account_name: string, account_number: string, account_subtype: "checking"|"savings", routing_number: string}
# --target_user shape: {address?: record, email: string, family_name: string, given_name: string, phone: string, tax_payer_id?: string}
export def "deposit-switch-alt-create depositSwitchAltCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --country-code: string@country-code-completer # ISO-3166-1 alpha-2 country code standard. (nullable)
  --options: record # Options to configure the `/deposit_switch/create` request. If provided, cannot be `null`. — shape: {transaction_item_access_tokens?: list, webhook?: string}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  target_account: record # The deposit switch destination account — shape: {account_name: string, account_number: string, account_subtype: "checking"|"savings", routing_number: string}
  target_user: record # The deposit switch target user — shape: {address?: record, email: string, family_name: string, given_name: string, phone: string, tax_payer_id?: string}
]: any -> record<deposit_switch_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deposit_switch/alt/create")
  let body = {"client_id": $client_id, "country_code": $country_code, "options": $options, "secret": $secret, "target_account": $target_account, "target_user": $target_user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a deposit switch
#
# POST /deposit_switch/create
# Docs: /deposit-switch/reference#deposit_switchcreate
# operationId: depositSwitchCreate
# --options shape: {transaction_item_access_tokens?: list, webhook?: string}
export def "deposit-switch-create depositSwitchCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --country-code: string@country-code-completer # ISO-3166-1 alpha-2 country code standard. (nullable)
  --options: record # Options to configure the `/deposit_switch/create` request. If provided, cannot be `null`. — shape: {transaction_item_access_tokens?: list, webhook?: string}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  target_access_token: string # Access token for the target Item, typically provided in the Import Item response. 
  target_account_id: string # Plaid Account ID that specifies the target bank account. This account will become the recipient for a user's direct deposit.
]: any -> record<deposit_switch_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deposit_switch/create")
  let body = {"client_id": $client_id, "country_code": $country_code, "options": $options, "secret": $secret, "target_access_token": $target_access_token, "target_account_id": $target_account_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a deposit switch
#
# POST /deposit_switch/get
# Docs: /deposit-switch/reference#deposit_switchget
# operationId: depositSwitchGet
export def "deposit-switch-get depositSwitchGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  deposit_switch_id: string # The ID of the deposit switch
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<account_has_multiple_allocations: bool, amount_allocated: float, date_completed: string, date_created: string, deposit_switch_id: string, employer_id: string, employer_name: string, institution_id: string, institution_name: string, is_allocated_remainder: bool, percent_allocated: float, request_id: string, state: string, switch_method: string, target_account_id: string, target_item_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deposit_switch/get")
  let body = {"client_id": $client_id, "deposit_switch_id": $deposit_switch_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a deposit switch token
#
# POST /deposit_switch/token/create
# Docs: /deposit-switch/reference#deposit_switchtokencreate
# operationId: depositSwitchTokenCreate
export def "deposit-switch-token-create depositSwitchTokenCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  deposit_switch_id: string # The ID of the deposit switch
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<deposit_switch_token: string, deposit_switch_token_expiration_time: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deposit_switch/token/create")
  let body = {"client_id": $client_id, "deposit_switch_id": $deposit_switch_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search employer database
#
# POST /employers/search
# Docs: /api/employers/#employerssearch
# operationId: employersSearch
export def "employers-search employersSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  products: list # The Plaid products the returned employers should support. Currently, this field must be set to `"deposit_switch"`.
  query: string # The employer name to be searched for.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<employers: table<address: record, confidence_score: float, employer_id: string, name: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/employers/search")
  let body = {"client_id": $client_id, "products": $products, "query": $query, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# (Deprecated) Retrieve a summary of an individual's employment information
#
# POST /employment/verification/get
# DEPRECATED
# Docs: /api/products/income/#employmentverificationget
# operationId: employmentVerificationGet
@deprecated
export def "employment-verification-get employmentVerificationGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<employments: table<employer: record, end_date: string, platform_ids: record, start_date: string, status: string, title: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/employment/verification/get")
  let body = {"access_token": $access_token, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Webhook receiver for fdx notifications
#
# POST /fdx/notifications
# Docs: /api/fdx/notifications/#post
# operationId: fdxNotifications
# --notificationPayload shape: {customFields?: record, id?: string, idType?: "ACCOUNT"|"CUSTOMER"|"PARTY"|"MAINTENANCE"|"CONSENT"}
# --publisher shape: {homeUri?: string, logoUri?: string, name: string, registeredEntityId?: string, registeredEntityName?: string, registry?: "FDX"|"GLEIF"|"ICANN"|"PRIVATE", type: "DATA_ACCESS_PLATFORM"|"DATA_PROVIDER"|"DATA_RECIPIENT"|"INDIVIDUAL"|"MERCHANT"|"VENDOR"}
# --subscriber shape: {homeUri?: string, logoUri?: string, name: string, registeredEntityId?: string, registeredEntityName?: string, registry?: "FDX"|"GLEIF"|"ICANN"|"PRIVATE", type: "DATA_ACCESS_PLATFORM"|"DATA_PROVIDER"|"DATA_RECIPIENT"|"INDIVIDUAL"|"MERCHANT"|"VENDOR"}
# --url shape: {action?: "GET"|"POST"|"PATCH"|"DELETE"|"PUT", href: string, rel?: string, types?: list}
export def "fdx-notifications fdxNotifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  category: string@category-completer # Category of Notification
  notification_id: string # Id of notification
  notification_payload: record # Custom key-value pairs payload for a notification — shape: {customFields?: record, id?: string, idType?: "ACCOUNT"|"CUSTOMER"|"PARTY"|"MAINTENANCE"|"CONSENT"}
  --priority: string@priority-completer # Priority of notification
  publisher: record # FDX Participant - an entity or person that is a part of a FDX API transaction — shape: {homeUri?: string, logoUri?: string, name: string, registeredEntityId?: string, registeredEntityName?: string, registry?: "FDX"|"GLEIF"|"ICANN"|"PRIVATE", type: "DATA_ACCESS_PLATFORM"|"DATA_PROVIDER"|"DATA_RECIPIENT"|"INDIVIDUAL"|"MERCHANT"|"VENDOR"}
  sent_on: string # ISO 8601 date-time in format 'YYYY-MM-DDThh:mm:ss.nnn[Z|[+|-]hh:mm]' according to [IETF RFC3339](https://xml2rfc.tools.ietf.org/public/rfc/html/rfc3339.html#anchor14) (format: date-time, e.g. 2021-07-15T14:46:41.375Z)
  --severity: string@severity-completer # Severity level of notification
  --subscriber: record # FDX Participant - an entity or person that is a part of a FDX API transaction — shape: {homeUri?: string, logoUri?: string, name: string, registeredEntityId?: string, registeredEntityName?: string, registry?: "FDX"|"GLEIF"|"ICANN"|"PRIVATE", type: "DATA_ACCESS_PLATFORM"|"DATA_PROVIDER"|"DATA_RECIPIENT"|"INDIVIDUAL"|"MERCHANT"|"VENDOR"}
  type: string@type-completer-1 # Type of Notification
  --body-url: record # REST application constraint (Hypermedia As The Engine Of Application State) — shape: {action?: "GET"|"POST"|"PATCH"|"DELETE"|"PUT", href: string, rel?: string, types?: list}
]: any -> record<causes: list<any>, display_message: string, documentation_url: string, error_code: string, error_message: string, error_type: string, request_id: string, status: float, suggested_action: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fdx/notifications")
  let body = {"category": $category, "notificationId": $notification_id, "notificationPayload": $notification_payload, "priority": $priority, "publisher": $publisher, "sentOn": $sent_on, "severity": $severity, "subscriber": $subscriber, "type": $type, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve identity data
#
# POST /identity/get
# Docs: /api/products/identity/#identityget
# operationId: identityGet
# --options shape: {account_ids?: list}
export def "identity-get identityGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --options: record # An optional object to filter `/identity/get` results. — shape: {account_ids?: list}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, persistent_account_id: string, subtype: string, type: string, verification_status: string, owners: list>, item: record<available_products: list<string>, billed_products: list<string>, consent_expiration_time: string, consented_products: list<string>, error: record<causes: list, display_message: string, documentation_url: string, error_code: string, error_message: string, error_type: string, request_id: string, status: float, suggested_action: string>, institution_id: string, item_id: string, products: list<string>, update_type: string, webhook: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/identity/get")
  let body = {"access_token": $access_token, "client_id": $client_id, "options": $options, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve identity match score
#
# POST /identity/match
# Docs: /api/products/identity/#identitymatch
# operationId: identityMatch
# --options shape: {account_ids?: list}
# --user shape: {address?: any, email_address?: string, legal_name?: string, phone_number?: string}
export def "identity-match identityMatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --options: record # An optional object to filter /identity/match results — shape: {account_ids?: list}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user: record # The user's legal name, phone number, email address and address used to perform fuzzy match. — shape: {address?: any, email_address?: string, legal_name?: string, phone_number?: string}
]: any -> record<accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, persistent_account_id: string, subtype: string, type: string, verification_status: string, address: record, email_address: record, legal_name: record, phone_number: record>, item: record<available_products: list<string>, billed_products: list<string>, consent_expiration_time: string, consented_products: list<string>, error: record<causes: list, display_message: string, documentation_url: string, error_code: string, error_message: string, error_type: string, request_id: string, status: float, suggested_action: string>, institution_id: string, item_id: string, products: list<string>, update_type: string, webhook: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/identity/match")
  let body = {"access_token": $access_token, "client_id": $client_id, "options": $options, "secret": $secret, "user": $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new identity verification
#
# POST /identity_verification/create
# Docs: /api/products/identity-verification/#identity_verificationcreate
# operationId: identityVerificationCreate
# --user shape: {address?: record, client_user_id: string, date_of_birth?: string, email_address?: string, id_number?: record, name?: record, phone_number?: string}
export def "identity-verification-create identityVerificationCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --gave-consent: oneof<nothing, bool> # A flag specifying whether the end user has already agreed to a privacy policy specifying that their data will be shared with Plaid for verification purposes.  If `gave_consent` is set to `true`, the `accept_tos` step will be marked as `skipped` and the end user's session will start at the next step requirement. (default: false, e.g. true)
  --is-idempotent: oneof<nothing, bool> # An optional flag specifying how you would like Plaid to handle attempts to create an Identity Verification when an Identity Verification already exists for the provided `client_user_id` and `template_id`. If idempotency is enabled, Plaid will return the existing Identity Verification. If idempotency is disabled, Plaid will reject the request with a `400 Bad Request` status code if an Identity Verification already exists for the supplied `client_user_id` and `template_id`. (nullable, e.g. true)
  --is-shareable: oneof<nothing, bool> # A flag specifying whether you would like Plaid to expose a shareable URL for the verification being created. (e.g. true)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  template_id: string # ID of the associated Identity Verification template. (e.g. idvtmp_4FrXJvfQU3zGUR)
  user: record # User information collected outside of Link, most likely via your own onboarding process.  Each of the following identity fields are optional:  `email_address`  `phone_number`  `date_of_birth`  `name`  `address`  `id_number`  Specifically, these fields are optional in that they can either be fully provided (satisfying every required field in their subschema) or omitted from the request entirely by not providing the key or value. Providing these fields via the API will result in Link skipping the data collection process for the associated user. All verification steps enabled in the associated Identity Verification Template will still be run. Verification steps will either be run immediately, or once the user completes the `accept_tos` step, depending on the value provided to the `gave_consent` field. — shape: {address?: record, client_user_id: string, date_of_birth?: string, email_address?: string, id_number?: record, name?: record, phone_number?: string}
]: any -> record<client_user_id: string, completed_at: string, created_at: string, documentary_verification: record<documents: list<record>, status: string>, id: string, kyc_check: record<address: record<po_box: string, summary: string, type: string>, date_of_birth: record<summary: string>, id_number: record<summary: string>, name: record<summary: string>, phone_number: record<summary: string>, status: string>, previous_attempt_id: string, redacted_at: string, request_id: string, shareable_url: string, status: string, steps: record<accept_tos: string, documentary_verification: string, kyc_check: string, risk_check: string, selfie_check: string, verify_sms: string, watchlist_screening: string>, template: record<id: string, version: float>, user: record<address: record<city: string, country: string, postal_code: string, region: string, street: string, street2: string>, date_of_birth: string, email_address: string, id_number: record<type: string, value: string>, ip_address: string, name: record<family_name: string, given_name: string>, phone_number: string>, watchlist_screening_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/identity_verification/create")
  let body = {"client_id": $client_id, "gave_consent": $gave_consent, "is_idempotent": $is_idempotent, "is_shareable": $is_shareable, "secret": $secret, "template_id": $template_id, "user": $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve Identity Verification
#
# POST /identity_verification/get
# Docs: /api/products/identity-verification/#identity_verificationget
# operationId: identityVerificationGet
export def "identity-verification-get identityVerificationGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  identity_verification_id: string # ID of the associated Identity Verification attempt. (e.g. idv_52xR9LKo77r1Np)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<client_user_id: string, completed_at: string, created_at: string, documentary_verification: record<documents: list<record>, status: string>, id: string, kyc_check: record<address: record<po_box: string, summary: string, type: string>, date_of_birth: record<summary: string>, id_number: record<summary: string>, name: record<summary: string>, phone_number: record<summary: string>, status: string>, previous_attempt_id: string, redacted_at: string, request_id: string, shareable_url: string, status: string, steps: record<accept_tos: string, documentary_verification: string, kyc_check: string, risk_check: string, selfie_check: string, verify_sms: string, watchlist_screening: string>, template: record<id: string, version: float>, user: record<address: record<city: string, country: string, postal_code: string, region: string, street: string, street2: string>, date_of_birth: string, email_address: string, id_number: record<type: string, value: string>, ip_address: string, name: record<family_name: string, given_name: string>, phone_number: string>, watchlist_screening_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/identity_verification/get")
  let body = {"client_id": $client_id, "identity_verification_id": $identity_verification_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Identity Verifications
#
# POST /identity_verification/list
# Docs: /api/products/identity-verification/#identity_verificationlist
# operationId: identityVerificationList
export def "identity-verification-list identityVerificationList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  client_user_id: string # An identifier to help you connect this object to your internal systems. For example, your database ID corresponding to this object. (e.g. your-db-id-3b24110)
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  template_id: string # ID of the associated Identity Verification template. (e.g. idvtmp_4FrXJvfQU3zGUR)
]: any -> record<identity_verifications: table<client_user_id: string, completed_at: string, created_at: string, documentary_verification: record, id: string, kyc_check: record, previous_attempt_id: string, redacted_at: string, shareable_url: string, status: string, steps: record, template: record, user: record, watchlist_screening_id: string>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/identity_verification/list")
  let body = {"client_id": $client_id, "client_user_id": $client_user_id, "cursor": $cursor, "secret": $secret, "template_id": $template_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retry an Identity Verification
#
# POST /identity_verification/retry
# Docs: /api/products/identity-verification/#identity_verificationretry
# operationId: identityVerificationRetry
# --steps shape: {documentary_verification: bool, kyc_check: bool, selfie_check: bool, verify_sms: bool}
export def "identity-verification-retry identityVerificationRetry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  client_user_id: string # An identifier to help you connect this object to your internal systems. For example, your database ID corresponding to this object. (e.g. your-db-id-3b24110)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --steps: record # Instructions for the `custom` retry strategy specifying which steps should be required or skipped.   Note:   This field must be provided when the retry strategy is `custom` and must be omitted otherwise.  Custom retries override settings in your Plaid Template. For example, if your Plaid Template has `verify_sms` disabled, a custom retry with `verify_sms` enabled will still require the step.  The `selfie_check` step is currently not supported on the sandbox server. Sandbox requests will silently disable the `selfie_check` step when provided. (nullable) — shape: {documentary_verification: bool, kyc_check: bool, selfie_check: bool, verify_sms: bool}
  strategy: string@strategy-completer # An instruction specifying what steps the new Identity Verification attempt should require the user to complete:   `reset` - Restart the user at the beginning of the session, regardless of whether they successfully completed part of their previous session.  `incomplete` - Start the new session at the step that the user failed in the previous session, skipping steps that have already been successfully completed.  `infer` - If the most recent Identity Verification attempt associated with the given `client_user_id` has a status of `failed` or `expired`, retry using the `incomplete` strategy. Otherwise, use the `reset` strategy.  `custom` - Start the new session with a custom configuration, specified by the value of the `steps` field  Note:  The `incomplete` strategy cannot be applied if the session's failing step is `screening` or `risk_check`.  The `infer` strategy cannot be applied if the session's status is still `active`
  template_id: string # ID of the associated Identity Verification template. (e.g. idvtmp_4FrXJvfQU3zGUR)
]: any -> record<client_user_id: string, completed_at: string, created_at: string, documentary_verification: record<documents: list<record>, status: string>, id: string, kyc_check: record<address: record<po_box: string, summary: string, type: string>, date_of_birth: record<summary: string>, id_number: record<summary: string>, name: record<summary: string>, phone_number: record<summary: string>, status: string>, previous_attempt_id: string, redacted_at: string, request_id: string, shareable_url: string, status: string, steps: record<accept_tos: string, documentary_verification: string, kyc_check: string, risk_check: string, selfie_check: string, verify_sms: string, watchlist_screening: string>, template: record<id: string, version: float>, user: record<address: record<city: string, country: string, postal_code: string, region: string, street: string, street2: string>, date_of_birth: string, email_address: string, id_number: record<type: string, value: string>, ip_address: string, name: record<family_name: string, given_name: string>, phone_number: string>, watchlist_screening_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/identity_verification/retry")
  let body = {"client_id": $client_id, "client_user_id": $client_user_id, "secret": $secret, "steps": $steps, "strategy": $strategy, "template_id": $template_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# (Deprecated) Create an income verification instance
#
# POST /income/verification/create
# DEPRECATED
# Docs: /api/products/income/#incomeverificationcreate
# operationId: incomeVerificationCreate
# --options shape: {access_tokens?: list}
@deprecated
export def "income-verification-create incomeVerificationCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --options: record # Optional arguments for `/income/verification/create` — shape: {access_tokens?: list}
  --precheck-id: string # The ID of a precheck created with `/income/verification/precheck`. Will be used to improve conversion of the income verification flow.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  webhook: string # The URL endpoint to which Plaid should send webhooks related to the progress of the income verification process.
]: any -> record<income_verification_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/income/verification/create")
  let body = {"client_id": $client_id, "options": $options, "precheck_id": $precheck_id, "secret": $secret, "webhook": $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# (Deprecated) Download the original documents used for income verification
#
# POST /income/verification/documents/download
# DEPRECATED
# Docs: /api/products/income/#incomeverificationdocumentsdownload
# operationId: incomeVerificationDocumentsDownload
@deprecated
@deprecated --flag income-verification-id
export def "income-verification-documents-download incomeVerificationDocumentsDownload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-token: string # The access token associated with the Item data is being requested for. (nullable)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --document-id: string # The document ID to download. If passed, a single document will be returned in the resulting zip file, rather than all document (nullable)
  --income-verification-id: string # The ID of the verification. (DEPRECATED, nullable)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/income/verification/documents/download")
  let body = {"access_token": $access_token, "client_id": $client_id, "document_id": $document_id, "income_verification_id": $income_verification_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# (Deprecated) Retrieve information from the paystubs used for income verification
#
# POST /income/verification/paystubs/get
# DEPRECATED
# Docs: /api/products/income/#incomeverificationpaystubsget
# operationId: incomeVerificationPaystubsGet
@deprecated
@deprecated --flag income-verification-id
export def "income-verification-paystubs-get incomeVerificationPaystubsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-token: string # The access token associated with the Item data is being requested for. (nullable)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --income-verification-id: string # The ID of the verification for which to get paystub information. (DEPRECATED, nullable)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<document_metadata: table<doc_id: string, doc_type: string, name: string, status: string>, error: record<causes: list<any>, display_message: string, documentation_url: string, error_code: string, error_message: string, error_type: string, request_id: string, status: float, suggested_action: string>, paystubs: table<deductions: record, doc_id: string, earnings: record, employee: record, employer: record, employment_details: record, income_breakdown: list, net_pay: record, pay_period_details: record, paystub_details: record, ytd_earnings: record>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/income/verification/paystubs/get")
  let body = {"access_token": $access_token, "client_id": $client_id, "income_verification_id": $income_verification_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# (Deprecated) Check digital income verification eligibility and optimize conversion
#
# POST /income/verification/precheck
# DEPRECATED
# Docs: /api/products/income/#incomeverificationprecheck
# operationId: incomeVerificationPrecheck
# --employer shape: {address?: record, name?: string, tax_id?: string, url?: string}
# --payroll_institution shape: {name?: string}
# --us_military_info shape: {branch?: string, is_active_duty?: bool}
# --user shape: {email_address?: string, first_name?: string, home_address?: record, last_name?: string}
@deprecated
@deprecated --flag transactions-access-token
export def "income-verification-precheck incomeVerificationPrecheck" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --employer: record # Information about the end user's employer (nullable) — shape: {address?: record, name?: string, tax_id?: string, url?: string}
  --payroll-institution: record # Information about the end user's payroll institution (nullable) — shape: {name?: string}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --transactions-access-token: any # DEPRECATED
  --transactions-access-tokens: list # An array of access tokens corresponding to Items belonging to the user whose eligibility is being checked. Note that if the Items specified here are not already initialized with `transactions`, providing them in this field will cause these Items to be initialized with (and billed for) the Transactions product.
  --us-military-info: record # Data about military info in the income verification precheck. (nullable) — shape: {branch?: string, is_active_duty?: bool}
  --user: record # Information about the user whose eligibility is being evaluated. (nullable) — shape: {email_address?: string, first_name?: string, home_address?: record, last_name?: string}
]: any -> record<confidence: string, precheck_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/income/verification/precheck")
  let body = {"client_id": $client_id, "employer": $employer, "payroll_institution": $payroll_institution, "secret": $secret, "transactions_access_token": $transactions_access_token, "transactions_access_tokens": $transactions_access_tokens, "us_military_info": $us_military_info, "user": $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# (Deprecated) Retrieve information from the tax documents used for income verification
#
# POST /income/verification/taxforms/get
# DEPRECATED
# Docs: /api/products/income/#incomeverificationtaxformsget
# operationId: incomeVerificationTaxformsGet
@deprecated
@deprecated --flag income-verification-id
export def "income-verification-taxforms-get incomeVerificationTaxformsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-token: string # The access token associated with the Item data is being requested for. (nullable)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --income-verification-id: string # The ID of the verification. (DEPRECATED, nullable)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<document_metadata: table<doc_id: string, doc_type: string, name: string, status: string>, error: record<causes: list<any>, display_message: string, documentation_url: string, error_code: string, error_message: string, error_type: string, request_id: string, status: float, suggested_action: string>, request_id: string, taxforms: table<doc_id: string, document_type: string, w2: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/income/verification/taxforms/get")
  let body = {"access_token": $access_token, "client_id": $client_id, "income_verification_id": $income_verification_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get details of all supported institutions
#
# POST /institutions/get
# Docs: /api/institutions/#institutionsget
# operationId: institutionsGet
# --options shape: {include_auth_metadata?: bool, include_optional_metadata?: bool, include_payment_initiation_metadata?: bool, oauth?: bool, products?: list, routing_numbers?: list}
export def "institutions-get institutionsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  count: int # The total number of Institutions to return.
  country_codes: list # Specify an array of Plaid-supported country codes this institution supports, using the ISO-3166-1 alpha-2 country code standard.  In API versions 2019-05-29 and earlier, the `country_codes` parameter is an optional parameter within the `options` object and will default to `[US]` if it is not supplied.
  offset: int # The number of Institutions to skip.
  --options: record # An optional object to filter `/institutions/get` results. — shape: {include_auth_metadata?: bool, include_optional_metadata?: bool, include_payment_initiation_metadata?: bool, oauth?: bool, products?: list, routing_numbers?: list}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<institutions: table<auth_metadata: record, country_codes: list, institution_id: string, logo: string, name: string, oauth: bool, payment_initiation_metadata: record, primary_color: string, products: list, routing_numbers: list, status: record, url: string>, request_id: string, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/institutions/get")
  let body = {"client_id": $client_id, "count": $count, "country_codes": $country_codes, "offset": $offset, "options": $options, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get details of an institution
#
# POST /institutions/get_by_id
# Docs: /api/institutions/#institutionsget_by_id
# operationId: institutionsGetById
# --options shape: {include_auth_metadata?: bool, include_optional_metadata?: bool, include_payment_initiation_metadata?: bool, include_status?: bool}
export def "institutions-get-by-id institutionsGetById" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  country_codes: list # Specify an array of Plaid-supported country codes this institution supports, using the ISO-3166-1 alpha-2 country code standard. In API versions 2019-05-29 and earlier, the `country_codes` parameter is an optional parameter within the `options` object and will default to `[US]` if it is not supplied.
  institution_id: string # The ID of the institution to get details about
  --options: record # Specifies optional parameters for `/institutions/get_by_id`. If provided, must not be `null`. — shape: {include_auth_metadata?: bool, include_optional_metadata?: bool, include_payment_initiation_metadata?: bool, include_status?: bool}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<institution: record<auth_metadata: record<supported_methods: record>, country_codes: list<string>, institution_id: string, logo: string, name: string, oauth: bool, payment_initiation_metadata: record<maximum_payment_amount: record, standing_order_metadata: record, supports_international_payments: bool, supports_refund_details: bool, supports_sepa_instant: bool>, primary_color: string, products: list<string>, routing_numbers: list<string>, status: record<auth: record, health_incidents: list, identity: record, investments: record, investments_updates: record, item_logins: record, liabilities: record, liabilities_updates: record, transactions_updates: record>, url: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/institutions/get_by_id")
  let body = {"client_id": $client_id, "country_codes": $country_codes, "institution_id": $institution_id, "options": $options, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search institutions
#
# POST /institutions/search
# Docs: /api/institutions/#institutionssearch
# operationId: institutionsSearch
# --options shape: {include_auth_metadata?: bool, include_optional_metadata?: bool, include_payment_initiation_metadata?: bool, oauth?: bool, payment_initiation?: record}
export def "institutions-search institutionsSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  country_codes: list # Specify an array of Plaid-supported country codes this institution supports, using the ISO-3166-1 alpha-2 country code standard. In API versions 2019-05-29 and earlier, the `country_codes` parameter is an optional parameter within the `options` object and will default to `[US]` if it is not supplied.
  --options: record # An optional object to filter `/institutions/search` results. — shape: {include_auth_metadata?: bool, include_optional_metadata?: bool, include_payment_initiation_metadata?: bool, oauth?: bool, payment_initiation?: record}
  --products: list # Filter the Institutions based on whether they support all products listed in `products`. Provide `null` to get institutions regardless of supported products. Note that when `auth` is specified as a product, if you are enabled for Instant Match or Automated Micro-deposits, institutions that support those products will be returned even if `auth` is not present in their product array. (nullable)
  query: string # The search query. Institutions with names matching the query are returned
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<institutions: table<auth_metadata: record, country_codes: list, institution_id: string, logo: string, name: string, oauth: bool, payment_initiation_metadata: record, primary_color: string, products: list, routing_numbers: list, status: record, url: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/institutions/search")
  let body = {"client_id": $client_id, "country_codes": $country_codes, "options": $options, "products": $products, "query": $query, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Investment holdings
#
# POST /investments/holdings/get
# Docs: /api/products/investments/#investmentsholdingsget
# operationId: investmentsHoldingsGet
# --options shape: {account_ids?: list}
export def "investments-holdings-get investmentsHoldingsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --options: record # An optional object to filter `/investments/holdings/get` results. If provided, must not be `null`. — shape: {account_ids?: list}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, persistent_account_id: string, subtype: string, type: string, verification_status: string>, holdings: table<account_id: string, cost_basis: float, institution_price: float, institution_price_as_of: string, institution_price_datetime: string, institution_value: float, iso_currency_code: string, quantity: float, security_id: string, unofficial_currency_code: string>, item: record<available_products: list<string>, billed_products: list<string>, consent_expiration_time: string, consented_products: list<string>, error: record<causes: list, display_message: string, documentation_url: string, error_code: string, error_message: string, error_type: string, request_id: string, status: float, suggested_action: string>, institution_id: string, item_id: string, products: list<string>, update_type: string, webhook: string>, request_id: string, securities: table<close_price: float, close_price_as_of: string, cusip: string, institution_id: string, institution_security_id: string, is_cash_equivalent: bool, isin: string, iso_currency_code: string, name: string, proxy_security_id: string, security_id: string, sedol: string, ticker_symbol: string, type: string, unofficial_currency_code: string, update_datetime: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/investments/holdings/get")
  let body = {"access_token": $access_token, "client_id": $client_id, "options": $options, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get investment transactions
#
# POST /investments/transactions/get
# Docs: /api/products/investments/#investmentstransactionsget
# operationId: investmentsTransactionsGet
# --options shape: {account_ids?: list, count?: int, offset?: int}
export def "investments-transactions-get investmentsTransactionsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  end_date: string # The most recent date for which to fetch transaction history. Dates should be formatted as YYYY-MM-DD. (format: date)
  --options: record # An optional object to filter `/investments/transactions/get` results. If provided, must be non-`null`. — shape: {account_ids?: list, count?: int, offset?: int}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  start_date: string # The earliest date for which to fetch transaction history. Dates should be formatted as YYYY-MM-DD. (format: date)
]: any -> record<accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, persistent_account_id: string, subtype: string, type: string, verification_status: string>, investment_transactions: table<account_id: string, amount: float, cancel_transaction_id: string, date: string, fees: float, investment_transaction_id: string, iso_currency_code: string, name: string, price: float, quantity: float, security_id: string, subtype: string, type: string, unofficial_currency_code: string>, item: record<available_products: list<string>, billed_products: list<string>, consent_expiration_time: string, consented_products: list<string>, error: record<causes: list, display_message: string, documentation_url: string, error_code: string, error_message: string, error_type: string, request_id: string, status: float, suggested_action: string>, institution_id: string, item_id: string, products: list<string>, update_type: string, webhook: string>, request_id: string, securities: table<close_price: float, close_price_as_of: string, cusip: string, institution_id: string, institution_security_id: string, is_cash_equivalent: bool, isin: string, iso_currency_code: string, name: string, proxy_security_id: string, security_id: string, sedol: string, ticker_symbol: string, type: string, unofficial_currency_code: string, update_datetime: string>, total_investment_transactions: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/investments/transactions/get")
  let body = {"access_token": $access_token, "client_id": $client_id, "end_date": $end_date, "options": $options, "secret": $secret, "start_date": $start_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invalidate access_token
#
# POST /item/access_token/invalidate
# Docs: /api/tokens/#itemaccess_tokeninvalidate
# operationId: itemAccessTokenInvalidate
export def "item-access-token-invalidate itemAccessTokenInvalidate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<new_access_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/access_token/invalidate")
  let body = {"access_token": $access_token, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List a historical log of user consent events
#
# POST /item/activity/list
# operationId: itemActivityList
export def "item-activity-list itemActivityList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --count: int # default: 50
  --cursor: string # Cursor used for pagination.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<activities: table<activity: string, id: string, initiated_date: string, initiator: string, scopes: record, state: string, target_application_id: string>, cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/activity/list")
  let body = {"access_token": $access_token, "client_id": $client_id, "count": $count, "cursor": $cursor, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List a user’s connected applications
#
# POST /item/application/list
# operationId: itemApplicationList
export def "item-application-list itemApplicationList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-token: string # The access token associated with the Item data is being requested for. (nullable)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<applications: table<application_id: string, application_url: string, created_at: string, display_name: string, logo_url: string, name: string, reason_for_access: string, scopes: record>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/application/list")
  let body = {"access_token": $access_token, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update the scopes of access for a particular application
#
# POST /item/application/scopes/update
# operationId: itemApplicationScopesUpdate
# --scopes shape: {accounts?: list, new_accounts?: bool, product_access?: record}
export def "item-application-scopes-update itemApplicationScopesUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  application_id: string # This field will map to the application ID that is returned from /item/applications/list, or provided to the institution in an oauth redirect.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  context: string@context-completer # An indicator for when scopes are being updated. When scopes are updated via enrollment (i.e. OAuth), the partner must send `ENROLLMENT`. When scopes are updated in a post-enrollment view, the partner must send `PORTAL`.
  scopes: record # The scopes object — shape: {accounts?: list, new_accounts?: bool, product_access?: record}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --state: string # When scopes are updated during enrollment, this field must be populated with the state sent to the partner in the OAuth Login URI. This field is required when the context is `ENROLLMENT`.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/application/scopes/update")
  let body = {"access_token": $access_token, "application_id": $application_id, "client_id": $client_id, "context": $context, "scopes": $scopes, "secret": $secret, "state": $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an Item
#
# POST /item/get
# Docs: /api/items/#itemget
# operationId: itemGet
export def "item-get itemGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<item: record<available_products: list<string>, billed_products: list<string>, consent_expiration_time: string, consented_products: list<string>, error: record<causes: list, display_message: string, documentation_url: string, error_code: string, error_message: string, error_type: string, request_id: string, status: float, suggested_action: string>, institution_id: string, item_id: string, products: list<string>, update_type: string, webhook: string>, request_id: string, status: record<investments: record<last_failed_update: string, last_successful_update: string>, last_webhook: record<code_sent: string, sent_at: string>, transactions: record<last_failed_update: string, last_successful_update: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/get")
  let body = {"access_token": $access_token, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Import Item
#
# POST /item/import
# operationId: itemImport
# --options shape: {webhook?: string}
# --user_auth shape: {auth_token: string, user_id: string}
export def "item-import itemImport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --options: record # An optional object to configure `/item/import` request. — shape: {webhook?: string}
  products: list # Array of product strings
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_auth: record # Object of user ID and auth token pair, permitting Plaid to aggregate a user’s accounts — shape: {auth_token: string, user_id: string}
]: any -> record<access_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/import")
  let body = {"client_id": $client_id, "options": $options, "products": $products, "secret": $secret, "user_auth": $user_auth} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create public token
#
# POST /item/public_token/create
# Docs: /api/tokens/#itempublic_tokencreate
# operationId: itemCreatePublicToken
export def "item-public-token-create itemCreatePublicToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<expiration: string, public_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/public_token/create")
  let body = {"access_token": $access_token, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Exchange public token for an access token
#
# POST /item/public_token/exchange
# Docs: /api/tokens/#itempublic_tokenexchange
# operationId: itemPublicTokenExchange
export def "item-public-token-exchange itemPublicTokenExchange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  public_token: string # Your `public_token`, obtained from the Link `onSuccess` callback or `/sandbox/item/public_token/create`.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<access_token: string, item_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/public_token/exchange")
  let body = {"client_id": $client_id, "public_token": $public_token, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove an Item
#
# POST /item/remove
# Docs: /api/items/#itemremove
# operationId: itemRemove
export def "item-remove itemRemove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/remove")
  let body = {"access_token": $access_token, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Webhook URL
#
# POST /item/webhook/update
# Docs: /api/items/#itemwebhookupdate
# operationId: itemWebhookUpdate
export def "item-webhook-update itemWebhookUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --webhook: string # The new webhook URL to associate with the Item. To remove a webhook from an Item, set to `null`. (nullable)
]: any -> record<item: record<available_products: list<string>, billed_products: list<string>, consent_expiration_time: string, consented_products: list<string>, error: record<causes: list, display_message: string, documentation_url: string, error_code: string, error_message: string, error_type: string, request_id: string, status: float, suggested_action: string>, institution_id: string, item_id: string, products: list<string>, update_type: string, webhook: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/webhook/update")
  let body = {"access_token": $access_token, "client_id": $client_id, "secret": $secret, "webhook": $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve Liabilities data
#
# POST /liabilities/get
# Docs: /api/products/liabilities/#liabilitiesget
# operationId: liabilitiesGet
# --options shape: {account_ids?: list}
export def "liabilities-get liabilitiesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --options: record # An optional object to filter `/liabilities/get` results. If provided, `options` cannot be null. — shape: {account_ids?: list}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, persistent_account_id: string, subtype: string, type: string, verification_status: string>, item: record<available_products: list<string>, billed_products: list<string>, consent_expiration_time: string, consented_products: list<string>, error: record<causes: list, display_message: string, documentation_url: string, error_code: string, error_message: string, error_type: string, request_id: string, status: float, suggested_action: string>, institution_id: string, item_id: string, products: list<string>, update_type: string, webhook: string>, liabilities: record<credit: list<record>, mortgage: list<record>, student: list<record>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/liabilities/get")
  let body = {"access_token": $access_token, "client_id": $client_id, "options": $options, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Exchange the Link Correlation Id for a Link Token
#
# POST /link/oauth/correlation_id/exchange
# Docs: /api/oauth/#linkcorrelationid
# operationId: linkOauthCorrelationIdExchange
export def "link-oauth-correlation-id-exchange linkOauthCorrelationIdExchange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  link_correlation_id: string # A `link_correlation_id` from a received OAuth redirect URI callback
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<link_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/link/oauth/correlation_id/exchange")
  let body = {"client_id": $client_id, "link_correlation_id": $link_correlation_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Link Token
#
# POST /link/token/create
# Docs: /api/tokens/#linktokencreate
# operationId: linkTokenCreate
# --account_filters shape: {credit?: record, depository?: record, investment?: record, loan?: record}
# --auth shape: {auth_type_select_enabled?: bool, automated_microdeposits_enabled?: bool, flow_type?: "FLEXIBLE_AUTH", instant_match_enabled?: bool, same_day_microdeposits_enabled?: bool}
# --deposit_switch shape: {deposit_switch_id: string}
# --employment shape: {bank_employment?: record, employment_source_types?: list}
# --eu_config shape: {headless?: bool}
# --identity_verification shape: {consent?: any, gave_consent?: bool, template_id: string}
# --income_verification shape: {access_tokens?: list, asset_report_id?: string, bank_income?: record, income_source_types?: list, income_verification_id?: string, payroll_income?: record, precheck_id?: string, stated_income_sources?: list}
# --institution_data shape: {routing_number?: string}
# --investments shape: {allow_unverified_crypto_wallets?: bool}
# --payment_initiation shape: {consent_id?: string, payment_id?: string}
# --transfer shape: {intent_id?: string, payment_profile_token?: string}
# --update shape: {account_selection_enabled?: bool}
# --user shape: {address?: record, client_user_id: string, date_of_birth?: string, email_address?: string, email_address_verified_time?: string, id_number?: record, legal_name?: string, name?: any, phone_number?: string, phone_number_verified_time?: string, ssn?: string}
export def "link-token-create linkTokenCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-token: string # The `access_token` associated with the Item to update or reference, used when updating, modifying, or accessing an existing `access_token`. Used when launching Link in update mode, when completing the Same-day (manual) Micro-deposit flow, or (optionally) when initializing Link for a returning user as part of the Transfer UI flow.
  --account-filters: record # By default, Link will provide limited account filtering: it will only display Institutions that are compatible with all products supplied in the `products` parameter of `/link/token/create`, and, if `auth` is specified in the `products` array, will also filter out accounts other than `checking` and `savings` accounts on the Account Select pane. You can further limit the accounts shown in Link by using `account_filters` to specify the account subtypes to be shown in Link. Only the specified subtypes will be shown. This filtering applies to both the Account Select view (if enabled) and the Institution Select view. Institutions that do not support the selected subtypes will be omitted from Link. To indicate that all subtypes should be shown, use the value `"all"`. If the `account_filters` filter is used, any account type for which a filter is not specified will be entirely omitted from Link. For a full list of valid types and subtypes, see the [Account schema](https://plaid.com/docs/api/accounts#account-type-schema).  For institutions using OAuth, the filter will not affect the list of accounts shown by the bank in the OAuth window. — shape: {credit?: record, depository?: record, investment?: record, loan?: record}
  --additional-consented-products: list # (Beta) This field has no effect unless you are participating in the Product Scope Transparency beta program. List of additional Plaid product(s) you wish to collect consent for. These products will not be billed until you start using them by calling the relevant endpoints.  `balance` is *not* a valid value, the Balance product does not require explicit initialization and will automatically have consent collected.  Institutions that do not support these products will still be shown in Link
  --android-package-name: string # The name of your app's Android package. Required if using the `link_token` to initialize Link on Android. When creating a `link_token` for initializing Link on other platforms, this field must be left blank. Any package name specified here must also be added to the Allowed Android package names setting on the [developer dashboard](https://dashboard.plaid.com/team/api). 
  --body-auth: record # Specifies options for initializing Link for use with the Auth product. This field can be used to enable or disable extended Auth flows for the resulting Link session. Omitting any field will result in a default that can be configured by your account manager. — shape: {auth_type_select_enabled?: bool, automated_microdeposits_enabled?: bool, flow_type?: "FLEXIBLE_AUTH", instant_match_enabled?: bool, same_day_microdeposits_enabled?: bool}
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  client_name: string # The name of your application, as it should be displayed in Link. Maximum length of 30 characters. If a value longer than 30 characters is provided, Link will display "This Application" instead.
  country_codes: list # Specify an array of Plaid-supported country codes using the ISO-3166-1 alpha-2 country code standard. Institutions from all listed countries will be shown. For a complete mapping of supported products by country, see https://plaid.com/global/.  If Link is launched with multiple country codes, only products that you are enabled for in all countries will be used by Link. Note that while all countries are enabled by default in Sandbox and Development, in Production only US and Canada are enabled by default. To gain access to European institutions in the Production environment, [file a product access Support ticket](https://dashboard.plaid.com/support/new/product-and-development/product-troubleshooting/request-product-access) via the Plaid dashboard. If you initialize with a European country code, your users will see the European consent panel during the Link flow.  If using a Link customization, make sure the country codes in the customization match those specified in `country_codes`. If both `country_codes` and a Link customization are used, the value in `country_codes` may override the value in the customization.  If using the Auth features Instant Match, Same-day Micro-deposits, or Automated Micro-deposits, `country_codes` must be set to `['US']`.
  --deposit-switch: record # Specifies options for initializing Link for use with the Deposit Switch (beta) product. This field is required if `deposit_switch` is included in the `products` array. — shape: {deposit_switch_id: string}
  --employment: record # Specifies options for initializing Link for use with the Employment product. This field is required if `employment` is included in the `products` array. — shape: {bank_employment?: record, employment_source_types?: list}
  --eu-config: record # Configuration parameters for EU flows — shape: {headless?: bool}
  --identity-verification: record # Specifies option for initializing Link for use with the Identity Verification product. — shape: {consent?: any, gave_consent?: bool, template_id: string}
  --income-verification: record # Specifies options for initializing Link for use with the Income product. This field is required if `income_verification` is included in the `products` array. — shape: {access_tokens?: list, asset_report_id?: string, bank_income?: record, income_source_types?: list, income_verification_id?: string, payroll_income?: record, precheck_id?: string, stated_income_sources?: list}
  --institution-data: record # A map containing data used to highlight institutions in Link. — shape: {routing_number?: string}
  --institution-id: string # Used for certain Europe-only configurations, as well as certain legacy use cases in other regions.
  --investments: record # Configuration parameters for the Investments product — shape: {allow_unverified_crypto_wallets?: bool}
  language: string # The language that Link should be displayed in.  Supported languages are: - Danish (`'da'`) - Dutch (`'nl'`) - English (`'en'`) - Estonian (`'et'`) - French (`'fr'`) - German (`'de'`) - Italian (`'it'`) - Latvian (`'lv'`) - Lithuanian (`'lt'`) - Norwegian (`'no'`) - Polish (`'po'`) - Romanian (`'ro'`) - Spanish (`'es'`) - Swedish (`'se'`)  When using a Link customization, the language configured here must match the setting in the customization, or the customization will not be applied.
  --link-customization-name: string # The name of the Link customization from the Plaid Dashboard to be applied to Link. If not specified, the `default` customization will be used. When using a Link customization, the language in the customization must match the language selected via the `language` parameter, and the countries in the customization should match the country codes selected via `country_codes`.
  --payment-initiation: record # Specifies options for initializing Link for use with the Payment Initiation (Europe) product. This field is required if `payment_initiation` is included in the `products` array. Either `payment_id` or `consent_id` must be provided. — shape: {consent_id?: string, payment_id?: string}
  --products: list # List of Plaid product(s) you wish to use. If launching Link in update mode, should be omitted; required otherwise.  `balance` is *not* a valid value, the Balance product does not require explicit initialization and will automatically be initialized when any other product is initialized.  The products specified here will determine which institutions will be available to your users in Link. Only institutions that support *all* requested products can be selected; a if a user attempts to select an institution that does not support a listed product, a "Connectivity not supported" error message will appear in Link. To maximize the number of institutions available, initialize Link with the minimal product set required for your use case. Additional products can be added after Link initialization by calling the relevant endpoints. For details and exceptions, see [Choosing when to initialize products](https://plaid.com/docs/link/initializing-products/).  Note that, unless you have opted to disable Instant Match support, institutions that support Instant Match will also be shown in Link if `auth` is specified as a product, even though these institutions do not contain `auth` in their product array.  In Production, you will be billed for each product that you specify when initializing Link. Note that a product cannot be removed from an Item once the Item has been initialized with that product. To stop billing on an Item for subscription-based products, such as Liabilities, Investments, and Transactions, remove the Item via `/item/remove`.
  --redirect-uri: string # A URI indicating the destination where a user should be forwarded after completing the Link flow; used to support OAuth authentication flows when launching Link in the browser or via a webview. The `redirect_uri` should not contain any query parameters. When used in Production or Development, must be an https URI. To specify any subdomain, use `*` as a wildcard character, e.g. `https://*.example.com/oauth.html`. If `android_package_name` is specified, this field should be left blank.  Note that any redirect URI must also be added to the Allowed redirect URIs list in the [developer dashboard](https://dashboard.plaid.com/team/api).
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --transfer: record # Specifies options for initializing Link for use with the Transfer product. — shape: {intent_id?: string, payment_profile_token?: string}
  --update: record # Specifies options for initializing Link for [update mode](https://plaid.com/docs/link/update-mode). — shape: {account_selection_enabled?: bool}
  user: record # An object specifying information about the end user who will be linking their account. — shape: {address?: record, client_user_id: string, date_of_birth?: string, email_address?: string, email_address_verified_time?: string, id_number?: record, legal_name?: string, name?: any, phone_number?: string, phone_number_verified_time?: string, ssn?: string}
  --user-token: string # A user token generated using `/user/create`. Any Item created during the Link session will be associated with the user.
  --webhook: string # The destination URL to which any webhooks should be sent.
]: any -> record<expiration: string, link_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/link/token/create")
  let body = {"access_token": $access_token, "account_filters": $account_filters, "additional_consented_products": $additional_consented_products, "android_package_name": $android_package_name, "auth": $body_auth, "client_id": $client_id, "client_name": $client_name, "country_codes": $country_codes, "deposit_switch": $deposit_switch, "employment": $employment, "eu_config": $eu_config, "identity_verification": $identity_verification, "income_verification": $income_verification, "institution_data": $institution_data, "institution_id": $institution_id, "investments": $investments, "language": $language, "link_customization_name": $link_customization_name, "payment_initiation": $payment_initiation, "products": $products, "redirect_uri": $redirect_uri, "secret": $secret, "transfer": $transfer, "update": $update, "user": $user, "user_token": $user_token, "webhook": $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Link Token
#
# POST /link/token/get
# Docs: /api/tokens/#linktokenget
# operationId: linkTokenGet
export def "link-token-get linkTokenGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  link_token: string # A `link_token` from a previous invocation of `/link/token/create`
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<created_at: string, expiration: string, link_token: string, metadata: record<account_filters: record<credit: record, depository: record, investment: record, loan: record>, client_name: string, country_codes: list<string>, initial_products: list<string>, institution_data: record<routing_number: string>, language: string, redirect_uri: string, webhook: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/link/token/get")
  let body = {"client_id": $client_id, "link_token": $link_token, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Link Delivery session
#
# POST /link_delivery/create
# Docs: /docs/assets/waitlist/link-delivery/
# operationId: linkDeliveryCreate
# --communication_methods item shape: {address?: string, method?: "SMS"|"EMAIL"}
export def "link-delivery-create linkDeliveryCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  communication_methods: list # The list of communication methods to send the Link Delivery URL to. — item shape: {address?: string, method?: "SMS"|"EMAIL"}
  link_token: string # A `link_token` from a previous invocation of `/link/token/create` with Link Delivery enabled.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<link_delivery_session_id: string, link_delivery_url: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/link_delivery/create")
  let body = {"client_id": $client_id, "communication_methods": $communication_methods, "link_token": $link_token, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Link Delivery session
#
# POST /link_delivery/get
# Docs: /docs/assets/waitlist/link-delivery/
# operationId: linkDeliveryGet
export def "link-delivery-get linkDeliveryGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  link_delivery_session_id: string # The ID for the Link Delivery session from a previous invocation of `/link_delivery/create`.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<access_tokens: list<string>, completed_at: string, created_at: string, item_ids: list<string>, request_id: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/link_delivery/get")
  let body = {"client_id": $client_id, "link_delivery_session_id": $link_delivery_session_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new end customer for a Plaid reseller.
#
# POST /partner/customer/create
# Docs: /api/partner/#partnercustomercreate
# operationId: partnerCustomerCreate
# --address shape: {city?: string, country_code?: string, postal_code?: string, region?: string, street?: string}
# --assets_under_management shape: {amount: float, iso_currency_code: string}
# --billing_contact shape: {email?: string, family_name?: string, given_name?: string}
# --customer_support_info shape: {contact_url?: string, email?: string, link_update_url?: string, phone_number?: string}
# --technical_contact shape: {email?: string, family_name?: string, given_name?: string}
export def "partner-customer-create partnerCustomerCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  address: record # The end customer's address. — shape: {city?: string, country_code?: string, postal_code?: string, region?: string, street?: string}
  application_name: string # The name of the end customer's application. This will be shown to end users when they go through the Plaid Link flow.
  --assets-under-management: record # Assets under management for the given end customer. Required for end customers with monthly service commitments. — shape: {amount: float, iso_currency_code: string}
  --billing-contact: record # The billing contact for the end customer. Defaults to partner's technical contact if omitted. — shape: {email?: string, family_name?: string, given_name?: string}
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  company_name: string # The company name of the end customer being created. This will be used to display the end customer in the Plaid Dashboard. It will not be shown to end users.
  --create-link-customization: oneof<nothing, bool> # If `true`, the end customer's default Link customization will be set to match the partner's. You can always change the end customer's Link customization in the Plaid Dashboard. See the [Link Customization docs](https://plaid.com/docs/link/customization/) for more information.
  --customer-support-info: record # This information is public. Users of your app will see this information when managing connections between your app and their bank accounts in Plaid Portal. Defaults to partner's customer support info if omitted. — shape: {contact_url?: string, email?: string, link_update_url?: string, phone_number?: string}
  --is-bank-addendum-completed: oneof<nothing, bool> # Denotes whether the partner has forwarded the Plaid bank addendum to the end customer.
  --is-diligence-attested: oneof<nothing, bool> # Denotes whether or not the partner has completed attestation of diligence for the end customer to be created.
  legal_entity_name: string # The end customer's legal name. This will be shared with financial institutions as part of the OAuth registration process. It will not be shown to end users.
  --logo: string # Base64-encoded representation of the end customer's logo. Must be a PNG of size 1024x1024 under 4MB. The logo will be shared with financial institutions and shown to the end user during Link flows. A logo is required if `create_link_customization` is `true`. If `create_link_customization` is `false` and the logo is omitted, a stock logo will be used.
  products: list # The products to be enabled for the end customer.
  --redirect-uris: list # A list of URIs indicating the destination(s) where a user can be forwarded after completing the Link flow; used to support OAuth authentication flows when launching Link in the browser or via a webview. URIs should not contain any query parameters. When used in Production or Development, URIs must use https. To specify any subdomain, use `*` as a wildcard character, e.g. `https://*.example.com/oauth.html`. To modify redirect URIs for an end customer after creating them, go to the end customer's [API page](https://dashboard.plaid.com/team/api) in the Dashboard.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --technical-contact: record # The technical contact for the end customer. Defaults to partner's technical contact if omitted. — shape: {email?: string, family_name?: string, given_name?: string}
  website: string # The end customer's website.
]: any -> record<end_customer: record, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/partner/customer/create")
  let body = {"address": $address, "application_name": $application_name, "assets_under_management": $assets_under_management, "billing_contact": $billing_contact, "client_id": $client_id, "company_name": $company_name, "create_link_customization": $create_link_customization, "customer_support_info": $customer_support_info, "is_bank_addendum_completed": $is_bank_addendum_completed, "is_diligence_attested": $is_diligence_attested, "legal_entity_name": $legal_entity_name, "logo": $logo, "products": $products, "redirect_uris": $redirect_uris, "secret": $secret, "technical_contact": $technical_contact, "website": $website} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Enables a Plaid reseller's end customer in the Production environment.
#
# POST /partner/customer/enable
# Docs: /api/partner/#partnercustomerenable
# operationId: partnerCustomerEnable
export def "partner-customer-enable partnerCustomerEnable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  end_customer_client_id: string
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<production_secret: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/partner/customer/enable")
  let body = {"client_id": $client_id, "end_customer_client_id": $end_customer_client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a Plaid reseller's end customer.
#
# POST /partner/customer/get
# Docs: /api/partner/#partnercustomerget
# operationId: partnerCustomerGet
export def "partner-customer-get partnerCustomerGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  end_customer_client_id: string
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<end_customer: record<client_id: string, company_name: string, status: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/partner/customer/get")
  let body = {"client_id": $client_id, "end_customer_client_id": $end_customer_client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns OAuth-institution registration information for a given end customer.
#
# POST /partner/customer/oauth_institutions/get
# Docs: /api/partner/#partnercustomeroauth_institutionsget
# operationId: partnerCustomerOauthInstitutionsGet
export def "partner-customer-oauth-institutions-get partnerCustomerOauthInstitutionsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  end_customer_client_id: string
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<flowdown_status: string, institutions: table<classic_disablement_date: string, environments: record, institution_id: string, name: string, production_enablement_date: string>, questionnaire_status: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/partner/customer/oauth_institutions/get")
  let body = {"client_id": $client_id, "end_customer_client_id": $end_customer_client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes a Plaid reseller's end customer.
#
# POST /partner/customer/remove
# Docs: /api/partner/#partnercustomerremove
# operationId: partnerCustomerRemove
export def "partner-customer-remove partnerCustomerRemove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  end_customer_client_id: string
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/partner/customer/remove")
  let body = {"client_id": $client_id, "end_customer_client_id": $end_customer_client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create payment consent
#
# POST /payment_initiation/consent/create
# Docs: /api/products/payment-initiation/#payment_initiationconsentcreate
# operationId: paymentInitiationConsentCreate
# --constraints shape: {max_payment_amount: any, periodic_amounts: list, valid_date_time?: record}
# --options shape: {bacs?: any, iban?: string, request_refund_details?: bool}
export def "payment-initiation-consent-create paymentInitiationConsentCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  constraints: record # Limitations that will be applied to payments initiated using the payment consent. — shape: {max_payment_amount: any, periodic_amounts: list, valid_date_time?: record}
  --options: record # Additional payment consent options (nullable) — shape: {bacs?: any, iban?: string, request_refund_details?: bool}
  recipient_id: string # The ID of the recipient the payment consent is for. The created consent can be used to transfer funds to this recipient only.
  reference: string # A reference for the payment consent. This must be an alphanumeric string with at most 18 characters and must not contain any special characters.
  scopes: list # An array of payment consent scopes.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<consent_id: string, request_id: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/consent/create")
  let body = {"client_id": $client_id, "constraints": $constraints, "options": $options, "recipient_id": $recipient_id, "reference": $reference, "scopes": $scopes, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get payment consent
#
# POST /payment_initiation/consent/get
# Docs: /api/products/payment-initiation/#payment_initiationconsentget
# operationId: paymentInitiationConsentGet
export def "payment-initiation-consent-get paymentInitiationConsentGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  consent_id: string # The `consent_id` returned from `/payment_initiation/consent/create`.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/consent/get")
  let body = {"client_id": $client_id, "consent_id": $consent_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Execute a single payment using consent
#
# POST /payment_initiation/consent/payment/execute
# Docs: /api/products/payment-initiation/#payment_initiationconsentpaymentexecute
# operationId: paymentInitiationConsentPaymentExecute
# --amount shape: {currency: "GBP"|"EUR"|"PLN"|"SEK"|"DKK"|"NOK", value: float}
export def "payment-initiation-consent-payment-execute paymentInitiationConsentPaymentExecute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: record # The amount and currency of a payment — shape: {currency: "GBP"|"EUR"|"PLN"|"SEK"|"DKK"|"NOK", value: float}
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  consent_id: string # The consent ID.
  idempotency_key: string # A random key provided by the client, per unique consent payment. Maximum of 128 characters.  The API supports idempotency for safely retrying requests without accidentally performing the same operation twice. If a request to execute a consent payment fails due to a network connection error, you can retry the request with the same idempotency key to guarantee that only a single payment is created. If the request was successfully processed, it will prevent any payment that uses the same idempotency key, and was received within 24 hours of the first request, from being processed.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<payment_id: string, request_id: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/consent/payment/execute")
  let body = {"amount": $amount, "client_id": $client_id, "consent_id": $consent_id, "idempotency_key": $idempotency_key, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke payment consent
#
# POST /payment_initiation/consent/revoke
# Docs: /api/products/payment-initiation/#payment_initiationconsentrevoke
# operationId: paymentInitiationConsentRevoke
export def "payment-initiation-consent-revoke paymentInitiationConsentRevoke" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  consent_id: string # The consent ID.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/consent/revoke")
  let body = {"client_id": $client_id, "consent_id": $consent_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a payment
#
# POST /payment_initiation/payment/create
# Docs: /api/products/payment-initiation/#payment_initiationpaymentcreate
# operationId: paymentInitiationPaymentCreate
# --amount shape: {currency: "GBP"|"EUR"|"PLN"|"SEK"|"DKK"|"NOK", value: float}
# --options shape: {bacs?: any, iban?: string, request_refund_details?: bool, scheme?: ""|"LOCAL_DEFAULT"|"LOCAL_INSTANT"|"SEPA_CREDIT_TRANSFER"|"SEPA_CREDIT_TRANSFER_INSTANT"}
export def "payment-initiation-payment-create paymentInitiationPaymentCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: record # The amount and currency of a payment — shape: {currency: "GBP"|"EUR"|"PLN"|"SEK"|"DKK"|"NOK", value: float}
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --options: record # Additional payment options (nullable) — shape: {bacs?: any, iban?: string, request_refund_details?: bool, scheme?: ""|"LOCAL_DEFAULT"|"LOCAL_INSTANT"|"SEPA_CREDIT_TRANSFER"|"SEPA_CREDIT_TRANSFER_INSTANT"}
  recipient_id: string # The ID of the recipient the payment is for.
  reference: string # A reference for the payment. This must be an alphanumeric string with at most 18 characters and must not contain any special characters (since not all institutions support them). In order to track settlement via Payment Confirmation, each payment must have a unique reference. If the reference provided through the API is not unique, Plaid will adjust it. Both the originally provided and automatically adjusted references (if any) can be found in the `reference` and `adjusted_reference` fields, respectively.
  --schedule: any # The schedule that the payment will be executed on. If a schedule is provided, the payment is automatically set up as a standing order. If no schedule is specified, the payment will be executed only once.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<payment_id: string, request_id: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/payment/create")
  let body = {"amount": $amount, "client_id": $client_id, "options": $options, "recipient_id": $recipient_id, "reference": $reference, "schedule": $schedule, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get payment details
#
# POST /payment_initiation/payment/get
# Docs: /api/products/payment-initiation/#payment_initiationpaymentget
# operationId: paymentInitiationPaymentGet
export def "payment-initiation-payment-get paymentInitiationPaymentGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  payment_id: string # The `payment_id` returned from `/payment_initiation/payment/create`.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<adjusted_reference: string, adjusted_scheme: string, amount: record<currency: string, value: float>, amount_refunded: record<currency: string, value: float>, bacs: record<account: string, sort_code: string>, consent_id: string, iban: string, last_status_update: string, payment_id: string, recipient_id: string, reference: string, refund_details: record<bacs: record<account: string, sort_code: string>, iban: string, name: string>, refund_ids: list<string>, schedule: record<adjusted_start_date: string, end_date: string, interval: string, interval_execution_day: int, start_date: string>, scheme: string, status: string, transaction_id: string, wallet_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/payment/get")
  let body = {"client_id": $client_id, "payment_id": $payment_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List payments
#
# POST /payment_initiation/payment/list
# Docs: /api/products/payment-initiation/#payment_initiationpaymentlist
# operationId: paymentInitiationPaymentList
export def "payment-initiation-payment-list paymentInitiationPaymentList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --consent-id: string # The consent ID. If specified, only payments, executed using this consent, will be returned. (nullable)
  --count: int # The maximum number of payments to return. If `count` is not specified, a maximum of 10 payments will be returned, beginning with the most recent payment before the cursor (if specified). (nullable, default: 10)
  --cursor: string # A string in RFC 3339 format (i.e. "2019-12-06T22:35:49Z"). Only payments created before the cursor will be returned. (nullable, format: date-time)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<next_cursor: string, payments: table<adjusted_reference: string, adjusted_scheme: string, amount: record, amount_refunded: record, bacs: record, consent_id: string, iban: string, last_status_update: string, payment_id: string, recipient_id: string, reference: string, refund_details: record, refund_ids: list, schedule: record, scheme: string, status: string, transaction_id: string, wallet_id: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/payment/list")
  let body = {"client_id": $client_id, "consent_id": $consent_id, "count": $count, "cursor": $cursor, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reverse an existing payment
#
# POST /payment_initiation/payment/reverse
# Docs: /api/products/payment-initiation/#payment_initiationpaymentreverse
# operationId: paymentInitiationPaymentReverse
export def "payment-initiation-payment-reverse paymentInitiationPaymentReverse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: any # The amount and currency of a payment
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  idempotency_key: string # A random key provided by the client, per unique wallet transaction. Maximum of 128 characters.  The API supports idempotency for safely retrying requests without accidentally performing the same operation twice. If a request to execute a wallet transaction fails due to a network connection error, then after a minimum delay of one minute, you can retry the request with the same idempotency key to guarantee that only a single wallet transaction is created. If the request was successfully processed, it will prevent any transaction that uses the same idempotency key, and was received within 24 hours of the first request, from being processed.
  payment_id: string # The ID of the payment to reverse
  reference: string # A reference for the refund. This must be an alphanumeric string with 6 to 18 characters and must not contain any special characters or spaces.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<refund_id: string, request_id: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/payment/reverse")
  let body = {"amount": $amount, "client_id": $client_id, "idempotency_key": $idempotency_key, "payment_id": $payment_id, "reference": $reference, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create payment token
#
# POST /payment_initiation/payment/token/create
# DEPRECATED
# Docs: /link/maintain-legacy-integration/#creating-a-payment-token
# operationId: createPaymentToken
@deprecated
export def "payment-initiation-payment-token-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  payment_id: string # The `payment_id` returned from `/payment_initiation/payment/create`.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<payment_token: string, payment_token_expiration_time: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/payment/token/create")
  let body = {"client_id": $client_id, "payment_id": $payment_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create payment recipient
#
# POST /payment_initiation/recipient/create
# Docs: /api/products/payment-initiation/#payment_initiationrecipientcreate
# operationId: paymentInitiationRecipientCreate
# --address shape: {city: string, country: string, postal_code: string, street: list}
export def "payment-initiation-recipient-create paymentInitiationRecipientCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # The optional address of the payment recipient. (nullable) — shape: {city: string, country: string, postal_code: string, street: list}
  --bacs: any # An object containing a BACS account number and sort code. If an IBAN is not provided or if this recipient needs to accept domestic GBP-denominated payments, BACS data is required. (nullable)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --iban: string # The International Bank Account Number (IBAN) for the recipient. If BACS data is not provided, an IBAN is required. (nullable)
  name: string # The name of the recipient. We recommend using strings of length 18 or less and avoid special characters to ensure compatibility with all institutions.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<recipient_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/recipient/create")
  let body = {"address": $address, "bacs": $bacs, "client_id": $client_id, "iban": $iban, "name": $name, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get payment recipient
#
# POST /payment_initiation/recipient/get
# Docs: /api/products/payment-initiation/#payment_initiationrecipientget
# operationId: paymentInitiationRecipientGet
export def "payment-initiation-recipient-get paymentInitiationRecipientGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  recipient_id: string # The ID of the recipient
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<address: record<city: string, country: string, postal_code: string, street: list<string>>, bacs: record<account: string, sort_code: string>, iban: string, name: string, recipient_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/recipient/get")
  let body = {"client_id": $client_id, "recipient_id": $recipient_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List payment recipients
#
# POST /payment_initiation/recipient/list
# Docs: /api/products/payment-initiation/#payment_initiationrecipientlist
# operationId: paymentInitiationRecipientList
export def "payment-initiation-recipient-list paymentInitiationRecipientList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<recipients: table<address: record, bacs: record, iban: string, name: string, recipient_id: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/recipient/list")
  let body = {"client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create payment profile
#
# POST /payment_profile/create
# Docs: /api/products/transfer/#payment_profilecreate
# operationId: paymentProfileCreate
export def "payment-profile-create paymentProfileCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<payment_profile_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_profile/create")
  let body = {"client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get payment profile
#
# POST /payment_profile/get
# Docs: /api/products/transfer/#payment_profileget
# operationId: paymentProfileGet
export def "payment-profile-get paymentProfileGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  payment_profile_token: string # A payment profile token associated with the Payment Profile data that is being requested.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<created_at: string, deleted_at: string, request_id: string, status: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_profile/get")
  let body = {"client_id": $client_id, "payment_profile_token": $payment_profile_token, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove payment profile
#
# POST /payment_profile/remove
# Docs: /api/products/transfer/#payment_profileremove
# operationId: paymentProfileRemove
export def "payment-profile-remove paymentProfileRemove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  payment_profile_token: string # A payment profile token associated with the Payment Profile data that is being requested.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_profile/remove")
  let body = {"client_id": $client_id, "payment_profile_token": $payment_profile_token, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Apex bank account token
#
# POST /processor/apex/processor_token/create
# Docs: /none/
# operationId: processorApexProcessorTokenCreate
export def "processor-apex-processor-token-create processorApexProcessorTokenCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  account_id: string # The `account_id` value obtained from the `onSuccess` callback in Link
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<processor_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/apex/processor_token/create")
  let body = {"access_token": $access_token, "account_id": $account_id, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve Auth data
#
# POST /processor/auth/get
# Docs: /api/processors/#processorauthget
# operationId: processorAuthGet
export def "processor-auth-get processorAuthGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<account: record<account_id: string, balances: record<available: float, current: float, iso_currency_code: string, last_updated_datetime: string, limit: float, unofficial_currency_code: string>, mask: string, name: string, official_name: string, persistent_account_id: string, subtype: string, type: string, verification_status: string>, numbers: record<ach: record<account: string, account_id: string, can_transfer_in: bool, can_transfer_out: bool, routing: string, wire_routing: string>, bacs: record<account: string, account_id: string, sort_code: string>, eft: record<account: string, account_id: string, branch: string, institution: string>, international: record<account_id: string, bic: string, iban: string>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/auth/get")
  let body = {"client_id": $client_id, "processor_token": $processor_token, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve Balance data
#
# POST /processor/balance/get
# Docs: /api/processors/#processorbalanceget
# operationId: processorBalanceGet
# --options shape: {min_last_updated_datetime?: string}
export def "processor-balance-get processorBalanceGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --options: record # An optional object to filter `/processor/balance/get` results. — shape: {min_last_updated_datetime?: string}
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<account: record<account_id: string, balances: record<available: float, current: float, iso_currency_code: string, last_updated_datetime: string, limit: float, unofficial_currency_code: string>, mask: string, name: string, official_name: string, persistent_account_id: string, subtype: string, type: string, verification_status: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/balance/get")
  let body = {"client_id": $client_id, "options": $options, "processor_token": $processor_token, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a bank transfer as a processor
#
# POST /processor/bank_transfer/create
# Docs: /api/processors/#bank_transfercreate
# operationId: processorBankTransferCreate
# --user shape: {email_address?: string, legal_name: string}
export def "processor-bank-transfer-create processorBankTransferCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ach-class: string@ach-class-completer # Specifies the use case of the transfer. Required for transfers on an ACH network.  `"ccd"` - Corporate Credit or Debit - fund transfer between two corporate bank accounts  `"ppd"` - Prearranged Payment or Deposit - the transfer is part of a pre-existing relationship with a consumer, eg. bill payment  `"tel"` - Telephone-Initiated Entry  `"web"` - Internet-Initiated Entry - debits from a consumer’s account where their authorization is obtained over the Internet
  amount: string # The amount of the bank transfer (decimal string with two digits of precision e.g. "10.00").
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --custom-tag: string # An arbitrary string provided by the client for storage with the bank transfer. May be up to 100 characters. (nullable)
  description: string # The transfer description. Maximum of 10 characters.
  idempotency_key: string # A random key provided by the client, per unique bank transfer. Maximum of 50 characters.  The API supports idempotency for safely retrying requests without accidentally performing the same operation twice. For example, if a request to create a bank transfer fails due to a network connection error, you can retry the request with the same idempotency key to guarantee that only a single bank transfer is created.
  iso_currency_code: string # The currency of the transfer amount – should be set to "USD".
  --metadata: record # The Metadata object is a mapping of client-provided string fields to any string value. The following limitations apply: The JSON values must be Strings (no nested JSON objects allowed) Only ASCII characters may be used Maximum of 50 key/value pairs Maximum key length of 40 characters Maximum value length of 500 characters  (nullable)
  network: string@network-completer # The network or rails used for the transfer. Valid options are `ach`, `same-day-ach`, or `wire`.
  --origination-account-id: string # Plaid’s unique identifier for the origination account for this transfer. If you have more than one origination account, this value must be specified. (nullable)
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  type: string@type-completer # The type of bank transfer. This will be either `debit` or `credit`.  A `debit` indicates a transfer of money into the origination account; a `credit` indicates a transfer of money out of the origination account.
  user: record # The legal name and other information for the account holder. — shape: {email_address?: string, legal_name: string}
]: any -> record<bank_transfer: record<account_id: string, ach_class: string, amount: string, cancellable: bool, created: string, custom_tag: string, description: string, direction: string, failure_reason: record<ach_return_code: string, description: string>, id: string, iso_currency_code: string, metadata: record, network: string, origination_account_id: string, status: string, type: string, user: record<email_address: string, legal_name: string, routing_number: string>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/bank_transfer/create")
  let body = {"ach_class": $ach_class, "amount": $amount, "client_id": $client_id, "custom_tag": $custom_tag, "description": $description, "idempotency_key": $idempotency_key, "iso_currency_code": $iso_currency_code, "metadata": $metadata, "network": $network, "origination_account_id": $origination_account_id, "processor_token": $processor_token, "secret": $secret, "type": $type, "user": $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve Identity data
#
# POST /processor/identity/get
# Docs: /api/processors/#processoridentityget
# operationId: processorIdentityGet
export def "processor-identity-get processorIdentityGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<account: record<account_id: string, balances: record<available: float, current: float, iso_currency_code: string, last_updated_datetime: string, limit: float, unofficial_currency_code: string>, mask: string, name: string, official_name: string, persistent_account_id: string, subtype: string, type: string, verification_status: string, owners: list<record>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/identity/get")
  let body = {"client_id": $client_id, "processor_token": $processor_token, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Report whether you initiated an ACH transaction
#
# POST /processor/signal/decision/report
# Docs: /api/processors/#processorsignaldecisionreport
# operationId: processorSignalDecisionReport
export def "processor-signal-decision-report processorSignalDecisionReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount-instantly-available: float # The amount (in USD) made available to your customers instantly following the debit transaction. It could be a partial amount of the requested transaction (example: 102.05). (nullable, format: double)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  client_transaction_id: string # Must be the same as the `client_transaction_id` supplied when calling `/signal/evaluate`
  --days-funds-on-hold: int # The actual number of days (hold time) since the ACH debit transaction that you wait before making funds available to your customers. The holding time could affect the ACH return rate.  For example, use 0 if you make funds available to your customers instantly or the same day following the debit transaction, or 1 if you make funds available the next day following the debit initialization. (nullable)
  --decision-outcome: string@decision-outcome-completer # The payment decision from the risk assessment.  `APPROVE`: approve the transaction without requiring further actions from your customers. For example, use this field if you are placing a standard hold for all the approved transactions before making funds available to your customers. You should also use this field if you decide to accelerate the fund availability for your customers.  `REVIEW`: the transaction requires manual review  `REJECT`: reject the transaction  `TAKE_OTHER_RISK_MEASURES`: for example, placing a longer hold on funds than those approved transactions or introducing customer frictions such as step-up verification/authentication  `NOT_EVALUATED`: if only logging the Signal results without using them  Possible values:  `APPROVE`, `REVIEW`, `REJECT`, `TAKE_OTHER_RISK_MEASURES`, `NOT_EVALUATED`  (nullable)
  --initiated: oneof<nothing, bool> # `true` if the ACH transaction was initiated, `false` otherwise.  This field must be returned as a boolean. If formatted incorrectly, this will result in an [`INVALID_FIELD`](/docs/errors/invalid-request/#invalid_field) error.
  --payment-method: string@payment-method-completer # The payment method to complete the transaction after the risk assessment. It may be different from the default payment method.  `SAME_DAY_ACH`: Same Day ACH by NACHA. The debit transaction is processed and settled on the same day  `NEXT_DAY_ACH`: Next Day ACH settlement for debit transactions, offered by some payment processors  `STANDARD_ACH`: standard ACH by NACHA  `REAL_TIME_PAYMENTS`: real-time payments such as RTP and FedNow  `DEBIT_CARD`: if the default payment is over debit card networks  `MULTIPLE_PAYMENT_METHODS`: if there is no default debit rail or there are multiple payment methods  Possible values: `SAME_DAY_ACH`, `NEXT_DAY_ACH`, `STANDARD_ACH`, `REAL_TIME_PAYMENTS`, `DEBIT_CARD`, `MULTIPLE_PAYMENT_METHODS`  (nullable)
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/signal/decision/report")
  let body = {"amount_instantly_available": $amount_instantly_available, "client_id": $client_id, "client_transaction_id": $client_transaction_id, "days_funds_on_hold": $days_funds_on_hold, "decision_outcome": $decision_outcome, "initiated": $initiated, "payment_method": $payment_method, "processor_token": $processor_token, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Evaluate a planned ACH transaction
#
# POST /processor/signal/evaluate
# Docs: /api/processors/#processorsignalevaluate
# operationId: processorSignalEvaluate
# --device shape: {ip_address?: string, user_agent?: string}
# --user shape: {address?: record, email_address?: string, name?: record, phone_number?: string}
export def "processor-signal-evaluate processorSignalEvaluate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # The transaction amount, in USD (e.g. `102.05`) (format: double)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  client_transaction_id: string # The unique ID that you would like to use to refer to this transaction. For your convenience mapping your internal data, you could use your internal ID/identifier for this transaction. The max length for this field is 36 characters.
  --client-user-id: string # A unique ID that identifies the end user in your system. This ID is used to correlate requests by a user with multiple Items. The max length for this field is 36 characters. Personally identifiable information, such as an email address or phone number, should not be used in the `client_user_id`.
  --default-payment-method: string # The default ACH or non-ACH payment method to complete the transaction. `SAME_DAY_ACH`: Same Day ACH by NACHA. The debit transaction is processed and settled on the same day `NEXT_DAY_ACH`: Next Day ACH settlement for debit transactions, offered by some payment processors `STANDARD_ACH`: standard ACH by NACHA `REAL_TIME_PAYMENTS`: real-time payments such as RTP and FedNow `DEBIT_CARD`: if the default payment is over debit card networks `MULTIPLE_PAYMENT_METHODS`: if there is no default debit rail or there are multiple payment methods Possible values:  `SAME_DAY_ACH`, `NEXT_DAY_ACH`, `STANDARD_ACH`, `REAL_TIME_PAYMENTS`, `DEBIT_CARD`, `MULTIPLE_PAYMENT_METHODS` (nullable)
  --device: record # Details about the end user's device — shape: {ip_address?: string, user_agent?: string}
  --is-recurring: oneof<nothing, bool> # **true** if the ACH transaction is a recurring transaction; **false** otherwise  (nullable)
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user: record # Details about the end user initiating the transaction (i.e., the account holder). — shape: {address?: record, email_address?: string, name?: record, phone_number?: string}
  --user-present: oneof<nothing, bool> # `true` if the end user is present while initiating the ACH transfer and the endpoint is being called; `false` otherwise (for example, when the ACH transfer is scheduled and the end user is not present, or you call this endpoint after the ACH transfer but before submitting the Nacha file for ACH processing). (nullable)
]: any -> record<core_attributes: record<address_change_count_28d: int, address_change_count_90d: int, available_balance: float, balance_last_updated: string, credit_transactions_count_10d: int, credit_transactions_count_30d: int, credit_transactions_count_60d: int, credit_transactions_count_90d: int, current_balance: float, days_since_first_plaid_connection: int, days_with_negative_balance_count_90d: int, debit_transactions_count_10d: int, debit_transactions_count_30d: int, debit_transactions_count_60d: int, debit_transactions_count_90d: int, email_change_count_28d: int, email_change_count_90d: int, failed_plaid_non_oauth_authentication_attempts_count_30d: int, failed_plaid_non_oauth_authentication_attempts_count_3d: int, failed_plaid_non_oauth_authentication_attempts_count_7d: int, is_savings_or_money_market_account: bool, nsf_overdraft_transactions_count_30d: int, nsf_overdraft_transactions_count_60d: int, nsf_overdraft_transactions_count_7d: int, nsf_overdraft_transactions_count_90d: int, p10_eod_balance_30d: float, p10_eod_balance_31d_to_60d: float, p10_eod_balance_60d: float, p10_eod_balance_61d_to_90d: float, p10_eod_balance_90d: float, p50_credit_transactions_amount_28d: float, p50_debit_transactions_amount_28d: float, p50_eod_balance_30d: float, p50_eod_balance_31d_to_60d: float, p50_eod_balance_60d: float, p50_eod_balance_61d_to_90d: float, p50_eod_balance_90d: float, p90_eod_balance_30d: float, p90_eod_balance_31d_to_60d: float, p90_eod_balance_60d: float, p90_eod_balance_61d_to_90d: float, p90_eod_balance_90d: float, p95_credit_transactions_amount_28d: float, p95_debit_transactions_amount_28d: float, phone_change_count_28d: int, phone_change_count_90d: int, plaid_connections_count_30d: int, plaid_connections_count_7d: int, plaid_non_oauth_authentication_attempts_count_30d: int, plaid_non_oauth_authentication_attempts_count_3d: int, plaid_non_oauth_authentication_attempts_count_7d: int, total_credit_transactions_amount_10d: float, total_credit_transactions_amount_30d: float, total_credit_transactions_amount_60d: float, total_credit_transactions_amount_90d: float, total_debit_transactions_amount_10d: float, total_debit_transactions_amount_30d: float, total_debit_transactions_amount_60d: float, total_debit_transactions_amount_90d: float, total_plaid_connections_count: int, transactions_last_updated: string, unauthorized_transactions_count_30d: int, unauthorized_transactions_count_60d: int, unauthorized_transactions_count_7d: int, unauthorized_transactions_count_90d: int>, request_id: string, scores: record<bank_initiated_return_risk: record<risk_tier: int, score: int>, customer_initiated_return_risk: record<risk_tier: int, score: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/signal/evaluate")
  let body = {"amount": $amount, "client_id": $client_id, "client_transaction_id": $client_transaction_id, "client_user_id": $client_user_id, "default_payment_method": $default_payment_method, "device": $device, "is_recurring": $is_recurring, "processor_token": $processor_token, "secret": $secret, "user": $user, "user_present": $user_present} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Report a return for an ACH transaction
#
# POST /processor/signal/return/report
# Docs: /api/processors/#processorsignalreturnreport
# operationId: processorSignalReturnReport
export def "processor-signal-return-report processorSignalReturnReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  client_transaction_id: string # Must be the same as the `client_transaction_id` supplied when calling `/processor/signal/evaluate`
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  return_code: string # Must be a valid ACH return code (e.g. "R01")  If formatted incorrectly, this will result in an [`INVALID_FIELD`](/docs/errors/invalid-request/#invalid_field) error.
  --returned-at: string # Date and time when you receive the returns from your payment processors, in ISO 8601 format (`YYYY-MM-DDTHH:mm:ssZ`). (nullable, format: date-time)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/signal/return/report")
  let body = {"client_id": $client_id, "client_transaction_id": $client_transaction_id, "processor_token": $processor_token, "return_code": $return_code, "returned_at": $returned_at, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Stripe bank account token
#
# POST /processor/stripe/bank_account_token/create
# Docs: /api/processors/#processorstripebank_account_tokencreate
# operationId: processorStripeBankAccountTokenCreate
export def "processor-stripe-bank-account-token-create processorStripeBankAccountTokenCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  account_id: string # The `account_id` value obtained from the `onSuccess` callback in Link
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string, stripe_bank_account_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/stripe/bank_account_token/create")
  let body = {"access_token": $access_token, "account_id": $account_id, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create processor token
#
# POST /processor/token/create
# Docs: /api/processors/#processortokencreate
# operationId: processorTokenCreate
export def "processor-token-create processorTokenCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  account_id: string # The `account_id` value obtained from the `onSuccess` callback in Link
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  processor: string@processor-completer # The processor you are integrating with.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<processor_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/token/create")
  let body = {"access_token": $access_token, "account_id": $account_id, "client_id": $client_id, "processor": $processor, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Manually fire a Bank Transfer webhook
#
# POST /sandbox/bank_transfer/fire_webhook
# Docs: /bank-transfers/reference/#sandboxbank_transferfire_webhook
# operationId: sandboxBankTransferFireWebhook
export def "sandbox-bank-transfer-fire-webhook sandboxBankTransferFireWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  webhook: string # The URL to which the webhook should be sent.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/bank_transfer/fire_webhook")
  let body = {"client_id": $client_id, "secret": $secret, "webhook": $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Simulate a bank transfer event in Sandbox
#
# POST /sandbox/bank_transfer/simulate
# Docs: /bank-transfers/reference/#sandboxbank_transfersimulate
# operationId: sandboxBankTransferSimulate
# --failure_reason shape: {ach_return_code?: string, description?: string}
export def "sandbox-bank-transfer-simulate sandboxBankTransferSimulate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  bank_transfer_id: string # Plaid’s unique identifier for a bank transfer.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  event_type: string # The asynchronous event to be simulated. May be: `posted`, `failed`, or `reversed`.  An error will be returned if the event type is incompatible with the current transfer status. Compatible status --> event type transitions include:  `pending` --> `failed`  `pending` --> `posted`  `posted` --> `reversed`
  --failure-reason: record # The failure reason if the type of this transfer is `"failed"` or `"reversed"`. Null value otherwise. (nullable) — shape: {ach_return_code?: string, description?: string}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/bank_transfer/simulate")
  let body = {"bank_transfer_id": $bank_transfer_id, "client_id": $client_id, "event_type": $event_type, "failure_reason": $failure_reason, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Manually fire an Income webhook
#
# POST /sandbox/income/fire_webhook
# Docs: /api/sandbox/#sandboxincomefire_webhook
# operationId: sandboxIncomeFireWebhook
export def "sandbox-income-fire-webhook sandboxIncomeFireWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  item_id: string # The Item ID associated with the verification.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-id: string # The Plaid `user_id` of the User associated with this webhook, warning, or error.
  verification_status: string@verification-status-completer # `VERIFICATION_STATUS_PROCESSING_COMPLETE`: The income verification status processing has completed. If the user uploaded multiple documents, this webhook will fire when all documents have finished processing. Call the `/income/verification/paystubs/get` endpoint and check the document metadata to see which documents were successfully parsed.  `VERIFICATION_STATUS_PROCESSING_FAILED`: A failure occurred when attempting to process the verification documentation.  `VERIFICATION_STATUS_PENDING_APPROVAL`: (deprecated) The income verification has been sent to the user for review.
  webhook: string # The URL to which the webhook should be sent.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/income/fire_webhook")
  let body = {"client_id": $client_id, "item_id": $item_id, "secret": $secret, "user_id": $user_id, "verification_status": $verification_status, "webhook": $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fire a test webhook
#
# POST /sandbox/item/fire_webhook
# Docs: /api/sandbox/#sandboxitemfire_webhook
# operationId: sandboxItemFireWebhook
export def "sandbox-item-fire-webhook sandboxItemFireWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  webhook_code: string@webhook-code-completer # The webhook codes that can be fired by this test endpoint.
  --webhook-type: string@webhook-type-completer # The webhook types that can be fired by this test endpoint.
]: any -> record<request_id: string, webhook_fired: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/item/fire_webhook")
  let body = {"access_token": $access_token, "client_id": $client_id, "secret": $secret, "webhook_code": $webhook_code, "webhook_type": $webhook_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Force a Sandbox Item into an error state
#
# POST /sandbox/item/reset_login
# Docs: /api/sandbox/#sandboxitemreset_login
# operationId: sandboxItemResetLogin
export def "sandbox-item-reset-login sandboxItemResetLogin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string, reset_login: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/item/reset_login")
  let body = {"access_token": $access_token, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set verification status for Sandbox account
#
# POST /sandbox/item/set_verification_status
# Docs: /api/sandbox/#sandboxitemset_verification_status
# operationId: sandboxItemSetVerificationStatus
export def "sandbox-item-set-verification-status sandboxItemSetVerificationStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  account_id: string # The `account_id` of the account whose verification status is to be modified
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  verification_status: string@verification-status-completer-1 # The verification status to set the account to.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/item/set_verification_status")
  let body = {"access_token": $access_token, "account_id": $account_id, "client_id": $client_id, "secret": $secret, "verification_status": $verification_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Save the selected accounts when connecting to the Platypus Oauth institution
#
# POST /sandbox/oauth/select_accounts
# operationId: sandboxOauthSelectAccounts
export def "sandbox-oauth-select-accounts sandboxOauthSelectAccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accounts: list
  oauth_state_id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/oauth/select_accounts")
  let body = {"accounts": $accounts, "oauth_state_id": $oauth_state_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset the login of a Payment Profile
#
# POST /sandbox/payment_profile/reset_login
# Docs: /api/sandbox/#sandboxpayment_profilereset_login
# operationId: sandboxPaymentProfileResetLogin
export def "sandbox-payment-profile-reset-login sandboxPaymentProfileResetLogin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  payment_profile_token: string # A payment profile token associated with the Payment Profile data that is being requested.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string, reset_login: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/payment_profile/reset_login")
  let body = {"client_id": $client_id, "payment_profile_token": $payment_profile_token, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a test Item and processor token
#
# POST /sandbox/processor_token/create
# Docs: /api/sandbox/#sandboxprocessor_tokencreate
# operationId: sandboxProcessorTokenCreate
# --options shape: {override_password?: string, override_username?: string}
export def "sandbox-processor-token-create sandboxProcessorTokenCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  institution_id: string # The ID of the institution the Item will be associated with
  --options: record # An optional set of options to be used when configuring the Item. If specified, must not be `null`. — shape: {override_password?: string, override_username?: string}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<processor_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/processor_token/create")
  let body = {"client_id": $client_id, "institution_id": $institution_id, "options": $options, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a test Item
#
# POST /sandbox/public_token/create
# Docs: /api/sandbox/#sandboxpublic_tokencreate
# operationId: sandboxPublicTokenCreate
# --options shape: {income_verification?: record, override_password?: string, override_username?: string, transactions?: record, webhook?: string}
export def "sandbox-public-token-create sandboxPublicTokenCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  initial_products: list # The products to initially pull for the Item. May be any products that the specified `institution_id`  supports. This array may not be empty.
  institution_id: string # The ID of the institution the Item will be associated with
  --options: record # An optional set of options to be used when configuring the Item. If specified, must not be `null`. — shape: {income_verification?: record, override_password?: string, override_username?: string, transactions?: record, webhook?: string}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-token: string # The user token associated with the User data is being requested for.
]: any -> record<public_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/public_token/create")
  let body = {"client_id": $client_id, "initial_products": $initial_products, "institution_id": $institution_id, "options": $options, "secret": $secret, "user_token": $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Manually fire a Transfer webhook
#
# POST /sandbox/transfer/fire_webhook
# Docs: /api/sandbox/#sandboxtransferfire_webhook
# operationId: sandboxTransferFireWebhook
export def "sandbox-transfer-fire-webhook sandboxTransferFireWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  webhook: string # The URL to which the webhook should be sent.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/transfer/fire_webhook")
  let body = {"client_id": $client_id, "secret": $secret, "webhook": $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Trigger the creation of a repayment
#
# POST /sandbox/transfer/repayment/simulate
# Docs: /api/sandbox/#sandboxtransferrepaymentsimulate
# operationId: sandboxTransferRepaymentSimulate
export def "sandbox-transfer-repayment-simulate sandboxTransferRepaymentSimulate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/transfer/repayment/simulate")
  let body = {"client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Simulate a transfer event in Sandbox
#
# POST /sandbox/transfer/simulate
# Docs: /api/sandbox/#sandboxtransfersimulate
# operationId: sandboxTransferSimulate
# --failure_reason shape: {ach_return_code?: string, description?: string}
export def "sandbox-transfer-simulate sandboxTransferSimulate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  event_type: string # The asynchronous event to be simulated. May be: `posted`, `settled`, `failed`, or `returned`.  An error will be returned if the event type is incompatible with the current transfer status. Compatible status --> event type transitions include:  `pending` --> `failed`  `pending` --> `posted`  `posted` --> `returned`  `posted` --> `settled`
  --failure-reason: record # The failure reason if the event type for a transfer is `"failed"` or `"returned"`. Null value otherwise. (nullable) — shape: {ach_return_code?: string, description?: string}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  transfer_id: string # Plaid’s unique identifier for a transfer.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/transfer/simulate")
  let body = {"client_id": $client_id, "event_type": $event_type, "failure_reason": $failure_reason, "secret": $secret, "transfer_id": $transfer_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Simulate creating a sweep
#
# POST /sandbox/transfer/sweep/simulate
# Docs: /api/sandbox/#sandboxtransfersweepsimulate
# operationId: sandboxTransferSweepSimulate
export def "sandbox-transfer-sweep-simulate sandboxTransferSweepSimulate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string, sweep: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/transfer/sweep/simulate")
  let body = {"client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Advance a test clock
#
# POST /sandbox/transfer/test_clock/advance
# Docs: /api/sandbox/#sandboxtransfertest_clockadvance
# operationId: sandboxTransferTestClockAdvance
export def "sandbox-transfer-test-clock-advance sandboxTransferTestClockAdvance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  new_virtual_time: string # The virtual timestamp on the test clock. This will be of the form `2006-01-02T15:04:05Z`. (format: date-time)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  test_clock_id: string # Plaid’s unique identifier for a test clock.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/transfer/test_clock/advance")
  let body = {"client_id": $client_id, "new_virtual_time": $new_virtual_time, "secret": $secret, "test_clock_id": $test_clock_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a test clock
#
# POST /sandbox/transfer/test_clock/create
# Docs: /api/sandbox/#sandboxtransfertest_clockcreate
# operationId: sandboxTransferTestClockCreate
export def "sandbox-transfer-test-clock-create sandboxTransferTestClockCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  virtual_time: string # The virtual timestamp on the test clock. This will be of the form `2006-01-02T15:04:05Z`. (format: date-time)
]: any -> record<request_id: string, test_clock: record<test_clock_id: string, virtual_time: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/transfer/test_clock/create")
  let body = {"client_id": $client_id, "secret": $secret, "virtual_time": $virtual_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a test clock
#
# POST /sandbox/transfer/test_clock/get
# Docs: /api/sandbox/#sandboxtransfertest_clockget
# operationId: sandboxTransferTestClockGet
export def "sandbox-transfer-test-clock-get sandboxTransferTestClockGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  test_clock_id: string # Plaid’s unique identifier for a test clock.
]: any -> record<request_id: string, test_clock: record<test_clock_id: string, virtual_time: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/transfer/test_clock/get")
  let body = {"client_id": $client_id, "secret": $secret, "test_clock_id": $test_clock_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List test clocks
#
# POST /sandbox/transfer/test_clock/list
# Docs: /api/sandbox/#sandboxtransfertest_clocklist
# operationId: sandboxTransferTestClockList
export def "sandbox-transfer-test-clock-list sandboxTransferTestClockList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --count: int # The maximum number of test clocks to return. (nullable, default: 25)
  --end-virtual-time: string # The end virtual timestamp of test clocks to return. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
  --offset: int # The number of test clocks to skip before returning results. (default: 0)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --start-virtual-time: string # The start virtual timestamp of test clocks to return. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
]: any -> record<request_id: string, test_clocks: table<test_clock_id: string, virtual_time: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/transfer/test_clock/list")
  let body = {"client_id": $client_id, "count": $count, "end_virtual_time": $end_virtual_time, "offset": $offset, "secret": $secret, "start_virtual_time": $start_virtual_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Report whether you initiated an ACH transaction
#
# POST /signal/decision/report
# Docs: /api/products/signal#signaldecisionreport
# operationId: signalDecisionReport
export def "signal-decision-report signalDecisionReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount-instantly-available: float # The amount (in USD) made available to your customers instantly following the debit transaction. It could be a partial amount of the requested transaction (example: 102.05). (nullable, format: double)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  client_transaction_id: string # Must be the same as the `client_transaction_id` supplied when calling `/signal/evaluate`
  --days-funds-on-hold: int # The actual number of days (hold time) since the ACH debit transaction that you wait before making funds available to your customers. The holding time could affect the ACH return rate.  For example, use 0 if you make funds available to your customers instantly or the same day following the debit transaction, or 1 if you make funds available the next day following the debit initialization. (nullable)
  --decision-outcome: string@decision-outcome-completer # The payment decision from the risk assessment.  `APPROVE`: approve the transaction without requiring further actions from your customers. For example, use this field if you are placing a standard hold for all the approved transactions before making funds available to your customers. You should also use this field if you decide to accelerate the fund availability for your customers.  `REVIEW`: the transaction requires manual review  `REJECT`: reject the transaction  `TAKE_OTHER_RISK_MEASURES`: for example, placing a longer hold on funds than those approved transactions or introducing customer frictions such as step-up verification/authentication  `NOT_EVALUATED`: if only logging the Signal results without using them  Possible values:  `APPROVE`, `REVIEW`, `REJECT`, `TAKE_OTHER_RISK_MEASURES`, `NOT_EVALUATED`  (nullable)
  --initiated: oneof<nothing, bool> # `true` if the ACH transaction was initiated, `false` otherwise.  This field must be returned as a boolean. If formatted incorrectly, this will result in an [`INVALID_FIELD`](/docs/errors/invalid-request/#invalid_field) error.
  --payment-method: string@payment-method-completer # The payment method to complete the transaction after the risk assessment. It may be different from the default payment method.  `SAME_DAY_ACH`: Same Day ACH by NACHA. The debit transaction is processed and settled on the same day  `NEXT_DAY_ACH`: Next Day ACH settlement for debit transactions, offered by some payment processors  `STANDARD_ACH`: standard ACH by NACHA  `REAL_TIME_PAYMENTS`: real-time payments such as RTP and FedNow  `DEBIT_CARD`: if the default payment is over debit card networks  `MULTIPLE_PAYMENT_METHODS`: if there is no default debit rail or there are multiple payment methods  Possible values: `SAME_DAY_ACH`, `NEXT_DAY_ACH`, `STANDARD_ACH`, `REAL_TIME_PAYMENTS`, `DEBIT_CARD`, `MULTIPLE_PAYMENT_METHODS`  (nullable)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signal/decision/report")
  let body = {"amount_instantly_available": $amount_instantly_available, "client_id": $client_id, "client_transaction_id": $client_transaction_id, "days_funds_on_hold": $days_funds_on_hold, "decision_outcome": $decision_outcome, "initiated": $initiated, "payment_method": $payment_method, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Evaluate a planned ACH transaction
#
# POST /signal/evaluate
# Docs: /api/products/signal#signalevaluate
# operationId: signalEvaluate
# --device shape: {ip_address?: string, user_agent?: string}
# --user shape: {address?: record, email_address?: string, name?: record, phone_number?: string}
export def "signal-evaluate signalEvaluate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  account_id: string # The Plaid `account_id` of the account that is the funding source for the proposed transaction. The `account_id` is returned in the `/accounts/get` endpoint as well as the [`onSuccess`](/docs/link/ios/#link-ios-onsuccess-linkSuccess-metadata-accounts-id) callback metadata.  This will return an [`INVALID_ACCOUNT_ID`](/docs/errors/invalid-input/#invalid_account_id) error if the account has been removed at the bank or if the `account_id` is no longer valid.
  amount: float # The transaction amount, in USD (e.g. `102.05`) (format: double)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  client_transaction_id: string # The unique ID that you would like to use to refer to this transaction. For your convenience mapping your internal data, you could use your internal ID/identifier for this transaction. The max length for this field is 36 characters.
  --client-user-id: string # A unique ID that identifies the end user in your system. This ID is used to correlate requests by a user with multiple Items. The max length for this field is 36 characters. Personally identifiable information, such as an email address or phone number, should not be used in the `client_user_id`.
  --default-payment-method: string # The default ACH or non-ACH payment method to complete the transaction. `SAME_DAY_ACH`: Same Day ACH by NACHA. The debit transaction is processed and settled on the same day `NEXT_DAY_ACH`: Next Day ACH settlement for debit transactions, offered by some payment processors `STANDARD_ACH`: standard ACH by NACHA `REAL_TIME_PAYMENTS`: real-time payments such as RTP and FedNow `DEBIT_CARD`: if the default payment is over debit card networks `MULTIPLE_PAYMENT_METHODS`: if there is no default debit rail or there are multiple payment methods Possible values:  `SAME_DAY_ACH`, `NEXT_DAY_ACH`, `STANDARD_ACH`, `REAL_TIME_PAYMENTS`, `DEBIT_CARD`, `MULTIPLE_PAYMENT_METHODS` (nullable)
  --device: record # Details about the end user's device — shape: {ip_address?: string, user_agent?: string}
  --is-recurring: oneof<nothing, bool> # `true` if the ACH transaction is a recurring transaction; `false` otherwise  (nullable)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user: record # Details about the end user initiating the transaction (i.e., the account holder). — shape: {address?: record, email_address?: string, name?: record, phone_number?: string}
  --user-present: oneof<nothing, bool> # `true` if the end user is present while initiating the ACH transfer and the endpoint is being called; `false` otherwise (for example, when the ACH transfer is scheduled and the end user is not present, or you call this endpoint after the ACH transfer but before submitting the Nacha file for ACH processing). (nullable)
]: any -> record<core_attributes: record<address_change_count_28d: int, address_change_count_90d: int, available_balance: float, balance_last_updated: string, credit_transactions_count_10d: int, credit_transactions_count_30d: int, credit_transactions_count_60d: int, credit_transactions_count_90d: int, current_balance: float, days_since_first_plaid_connection: int, days_with_negative_balance_count_90d: int, debit_transactions_count_10d: int, debit_transactions_count_30d: int, debit_transactions_count_60d: int, debit_transactions_count_90d: int, email_change_count_28d: int, email_change_count_90d: int, failed_plaid_non_oauth_authentication_attempts_count_30d: int, failed_plaid_non_oauth_authentication_attempts_count_3d: int, failed_plaid_non_oauth_authentication_attempts_count_7d: int, is_savings_or_money_market_account: bool, nsf_overdraft_transactions_count_30d: int, nsf_overdraft_transactions_count_60d: int, nsf_overdraft_transactions_count_7d: int, nsf_overdraft_transactions_count_90d: int, p10_eod_balance_30d: float, p10_eod_balance_31d_to_60d: float, p10_eod_balance_60d: float, p10_eod_balance_61d_to_90d: float, p10_eod_balance_90d: float, p50_credit_transactions_amount_28d: float, p50_debit_transactions_amount_28d: float, p50_eod_balance_30d: float, p50_eod_balance_31d_to_60d: float, p50_eod_balance_60d: float, p50_eod_balance_61d_to_90d: float, p50_eod_balance_90d: float, p90_eod_balance_30d: float, p90_eod_balance_31d_to_60d: float, p90_eod_balance_60d: float, p90_eod_balance_61d_to_90d: float, p90_eod_balance_90d: float, p95_credit_transactions_amount_28d: float, p95_debit_transactions_amount_28d: float, phone_change_count_28d: int, phone_change_count_90d: int, plaid_connections_count_30d: int, plaid_connections_count_7d: int, plaid_non_oauth_authentication_attempts_count_30d: int, plaid_non_oauth_authentication_attempts_count_3d: int, plaid_non_oauth_authentication_attempts_count_7d: int, total_credit_transactions_amount_10d: float, total_credit_transactions_amount_30d: float, total_credit_transactions_amount_60d: float, total_credit_transactions_amount_90d: float, total_debit_transactions_amount_10d: float, total_debit_transactions_amount_30d: float, total_debit_transactions_amount_60d: float, total_debit_transactions_amount_90d: float, total_plaid_connections_count: int, transactions_last_updated: string, unauthorized_transactions_count_30d: int, unauthorized_transactions_count_60d: int, unauthorized_transactions_count_7d: int, unauthorized_transactions_count_90d: int>, request_id: string, scores: record<bank_initiated_return_risk: record<risk_tier: int, score: int>, customer_initiated_return_risk: record<risk_tier: int, score: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signal/evaluate")
  let body = {"access_token": $access_token, "account_id": $account_id, "amount": $amount, "client_id": $client_id, "client_transaction_id": $client_transaction_id, "client_user_id": $client_user_id, "default_payment_method": $default_payment_method, "device": $device, "is_recurring": $is_recurring, "secret": $secret, "user": $user, "user_present": $user_present} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Opt-in an Item to Signal
#
# POST /signal/prepare
# Docs: /api/products/signal#signalprepare
# operationId: signalPrepare
export def "signal-prepare signalPrepare" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signal/prepare")
  let body = {"access_token": $access_token, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Report a return for an ACH transaction
#
# POST /signal/return/report
# Docs: /api/products/signal#signalreturnreport
# operationId: signalReturnReport
export def "signal-return-report signalReturnReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  client_transaction_id: string # Must be the same as the `client_transaction_id` supplied when calling `/signal/evaluate`
  return_code: string # Must be a valid ACH return code (e.g. "R01")  If formatted incorrectly, this will result in an [`INVALID_FIELD`](/docs/errors/invalid-request/#invalid_field) error.
  --returned-at: string # Date and time when you receive the returns from your payment processors, in ISO 8601 format (`YYYY-MM-DDTHH:mm:ssZ`). (nullable, format: date-time)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signal/return/report")
  let body = {"client_id": $client_id, "client_transaction_id": $client_transaction_id, "return_code": $return_code, "returned_at": $returned_at, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Enrich locally-held transaction data
#
# POST /transactions/enrich
# Docs: /api/products/enrich/#transactionsenrich
# operationId: transactionsEnrich
# --options shape: {include_legacy_category?: bool}
# --transactions item shape: {amount: float, date_posted?: string, description: string, direction: "INFLOW"|"OUTFLOW", id: string, iso_currency_code: string, location?: record, mcc?: string}
export def "transactions-enrich transactionsEnrich" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_type: string # The account type for the requested transactions (either `depository` or `credit`).
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --options: record # An optional object to be used with the request. — shape: {include_legacy_category?: bool}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  transactions: list # An array of transaction objects to be enriched by Plaid. Maximum of 100 transactions per request. — item shape: {amount: float, date_posted?: string, description: string, direction: "INFLOW"|"OUTFLOW", id: string, iso_currency_code: string, location?: record, mcc?: string}
]: any -> record<enriched_transactions: table<amount: float, description: string, direction: string, enrichments: record, id: string, iso_currency_code: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactions/enrich")
  let body = {"account_type": $account_type, "client_id": $client_id, "options": $options, "secret": $secret, "transactions": $transactions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get transaction data
#
# POST /transactions/get
# Docs: /api/products/transactions/#transactionsget
# operationId: transactionsGet
# --options shape: {account_ids?: list, count?: int, include_logo_and_counterparty_beta?: bool, include_original_description?: bool, include_personal_finance_category?: bool, include_personal_finance_category_beta?: bool, offset?: int}
export def "transactions-get transactionsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  end_date: string # The latest date for which data should be returned. Dates should be formatted as YYYY-MM-DD. (format: date)
  --options: record # An optional object to be used with the request. If specified, `options` must not be `null`. — shape: {account_ids?: list, count?: int, include_logo_and_counterparty_beta?: bool, include_original_description?: bool, include_personal_finance_category?: bool, include_personal_finance_category_beta?: bool, offset?: int}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  start_date: string # The earliest date for which data should be returned. Dates should be formatted as YYYY-MM-DD. (format: date)
]: any -> record<accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, persistent_account_id: string, subtype: string, type: string, verification_status: string>, item: record<available_products: list<string>, billed_products: list<string>, consent_expiration_time: string, consented_products: list<string>, error: record<causes: list, display_message: string, documentation_url: string, error_code: string, error_message: string, error_type: string, request_id: string, status: float, suggested_action: string>, institution_id: string, item_id: string, products: list<string>, update_type: string, webhook: string>, request_id: string, total_transactions: int, transactions: table<account_id: string, account_owner: string, amount: float, category: list, category_id: string, check_number: string, date: string, iso_currency_code: string, location: record, logo_url: string, merchant_name: string, name: string, original_description: string, payment_meta: record, pending: bool, pending_transaction_id: string, transaction_id: string, transaction_type: string, unofficial_currency_code: string, website: string, authorized_date: string, authorized_datetime: string, counterparties: list, datetime: string, payment_channel: string, personal_finance_category: record, personal_finance_category_icon_url: string, transaction_code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactions/get")
  let body = {"access_token": $access_token, "client_id": $client_id, "end_date": $end_date, "options": $options, "secret": $secret, "start_date": $start_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch recurring transaction streams
#
# POST /transactions/recurring/get
# Docs: /api/products/transactions/#transactionsrecurringget
# operationId: transactionsRecurringGet
# --options shape: {include_personal_finance_category?: bool}
export def "transactions-recurring-get transactionsRecurringGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  account_ids: list # A list of `account_ids` to retrieve for the Item  Note: An error will be returned if a provided `account_id` is not associated with the Item.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --options: record # An optional object to be used with the request. If specified, `options` must not be `null`. — shape: {include_personal_finance_category?: bool}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<inflow_streams: table<account_id: string, average_amount: record, category: list, category_id: string, description: string, first_date: string, frequency: string, is_active: bool, last_amount: record, last_date: string, merchant_name: string, personal_finance_category: record, status: string, stream_id: string, transaction_ids: list>, outflow_streams: table<account_id: string, average_amount: record, category: list, category_id: string, description: string, first_date: string, frequency: string, is_active: bool, last_amount: record, last_date: string, merchant_name: string, personal_finance_category: record, status: string, stream_id: string, transaction_ids: list>, request_id: string, updated_datetime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactions/recurring/get")
  let body = {"access_token": $access_token, "account_ids": $account_ids, "client_id": $client_id, "options": $options, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Refresh transaction data
#
# POST /transactions/refresh
# Docs: /api/products/transactions/#transactionsrefresh
# operationId: transactionsRefresh
export def "transactions-refresh transactionsRefresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactions/refresh")
  let body = {"access_token": $access_token, "client_id": $client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get incremental transaction updates on an Item
#
# POST /transactions/sync
# Docs: /api/products/transactions/#transactionssync
# operationId: transactionsSync
# --options shape: {include_logo_and_counterparty_beta?: bool, include_original_description?: bool, include_personal_finance_category?: bool}
export def "transactions-sync transactionsSync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The access token associated with the Item data is being requested for.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --count: int # The number of transaction updates to fetch. (default: 100)
  --cursor: string # The cursor value represents the last update requested. Providing it will cause the response to only return changes after this update. If omitted, the entire history of updates will be returned, starting with the first-added transactions on the item. Note: The upper-bound length of this cursor is 256 characters of base64.
  --options: record # An optional object to be used with the request. If specified, `options` must not be `null`. — shape: {include_logo_and_counterparty_beta?: bool, include_original_description?: bool, include_personal_finance_category?: bool}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<added: table<account_id: string, account_owner: string, amount: float, category: list, category_id: string, check_number: string, date: string, iso_currency_code: string, location: record, logo_url: string, merchant_name: string, name: string, original_description: string, payment_meta: record, pending: bool, pending_transaction_id: string, transaction_id: string, transaction_type: string, unofficial_currency_code: string, website: string, authorized_date: string, authorized_datetime: string, counterparties: list, datetime: string, payment_channel: string, personal_finance_category: record, personal_finance_category_icon_url: string, transaction_code: string>, has_more: bool, modified: table<account_id: string, account_owner: string, amount: float, category: list, category_id: string, check_number: string, date: string, iso_currency_code: string, location: record, logo_url: string, merchant_name: string, name: string, original_description: string, payment_meta: record, pending: bool, pending_transaction_id: string, transaction_id: string, transaction_type: string, unofficial_currency_code: string, website: string, authorized_date: string, authorized_datetime: string, counterparties: list, datetime: string, payment_channel: string, personal_finance_category: record, personal_finance_category_icon_url: string, transaction_code: string>, next_cursor: string, removed: table<transaction_id: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactions/sync")
  let body = {"access_token": $access_token, "client_id": $client_id, "count": $count, "cursor": $cursor, "options": $options, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a transfer authorization
#
# POST /transfer/authorization/create
# Docs: /api/products/transfer/#transferauthorizationcreate
# operationId: transferAuthorizationCreate
# --device shape: {ip_address?: string, user_agent?: string}
# --user shape: {address?: record, email_address?: string, legal_name: string, phone_number?: string}
@deprecated --flag origination-account-id
export def "transfer-authorization-create transferAuthorizationCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-token: string # The Plaid `access_token` for the account that will be debited or credited. Required if not using `payment_profile_token`.
  --account-id: string # The Plaid `account_id` corresponding to the end-user account that will be debited or credited. Returned only if `account_id` was set on intent creation.
  --ach-class: string@ach-class-completer # Specifies the use case of the transfer. Required for transfers on an ACH network.  `"ccd"` - Corporate Credit or Debit - fund transfer between two corporate bank accounts  `"ppd"` - Prearranged Payment or Deposit - the transfer is part of a pre-existing relationship with a consumer, eg. bill payment  `"tel"` - Telephone-Initiated Entry  `"web"` - Internet-Initiated Entry - debits from a consumer’s account where their authorization is obtained over the Internet
  amount: string # The amount of the transfer (decimal string with two digits of precision e.g. "10.00").
  --beacon-session-id: string # The unique identifier returned by Plaid's [beacon](https://plaid.com/docs/transfer/guarantee/#using-a-beacon) when it is run on your webpage. Required for Guarantee customers who are not using [Transfer UI](https://plaid.com/docs/transfer/using-transfer-ui/) and have a web checkout experience. (nullable)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --device: record # Information about the device being used to initiate the authorization. — shape: {ip_address?: string, user_agent?: string}
  --funding-account-id: string # The id of the funding account to use, available in the Plaid Dashboard. This determines which of your business checking accounts will be credited or debited. Defaults to the account configured during onboarding. (nullable)
  --idempotency-key: string # A random key provided by the client, per unique authorization. Maximum of 50 characters.  The API supports idempotency for safely retrying requests without accidentally performing the same operation twice. For example, if a request to create an authorization fails due to a network connection error, you can retry the request with the same idempotency key to guarantee that only a single authorization is created.  Failure to provide this key may result in duplicate charges.  Required for guaranteed ACH customers. (nullable)
  --iso-currency-code: string # The currency of the transfer amount. The default value is "USD".
  network: string@network-completer-1 # The network or rails used for the transfer.  For transfers submitted as either `ach` or `same-day-ach` the cutoff for same-day is 9:30 AM Pacific Time and the cutoff for next-day transfers is 5:30 PM Pacific Time. It is recommended to submit a transfer at least 15 minutes before the cutoff time in order to ensure that it will be processed before the cutoff. Any transfer that is indicated as `same-day-ach` and that misses the same-day cutoff, but is submitted in time for the next-day cutoff, will be sent over next-day rails and will not incur same-day charges. Note that both legs of the transfer will be downgraded if applicable.
  --origination-account-id: string # Plaid's unique identifier for the origination account for this authorization. If not specified, the default account will be used. (DEPRECATED)
  --originator-client-id: string # The Plaid client ID that is the originator of this transfer. Only needed if creating transfers on behalf of another client as a third-party sender (TPS). (nullable)
  --payment-profile-token: string # The payment profile token associated with the Payment Profile that will be debited or credited. Required if not using `access_token`.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  type: string@type-completer # The type of transfer. This will be either `debit` or `credit`.  A `debit` indicates a transfer of money into the origination account; a `credit` indicates a transfer of money out of the origination account.
  user: record # The legal name and other information for the account holder. — shape: {address?: record, email_address?: string, legal_name: string, phone_number?: string}
  --user-present: oneof<nothing, bool> # Required for Guarantee. If the end user is initiating the specific transfer themselves via an interactive UI, this should be `true`; for automatic recurring payments where the end user is not actually initiating each individual transfer, it should be `false`. (nullable)
  --with-guarantee: oneof<nothing, bool> # If set to `false`, Plaid will not offer a `guarantee_decision` for this request(Guarantee customers only). (nullable, default: true)
]: any -> record<authorization: record<created: string, decision: string, decision_rationale: record<code: string, description: string>, guarantee_decision: string, guarantee_decision_rationale: record<code: string, description: string>, id: string, proposed_transfer: record<account_id: string, ach_class: string, amount: string, funding_account_id: string, iso_currency_code: string, network: string, origination_account_id: string, originator_client_id: string, type: string, user: record>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/authorization/create")
  let body = {"access_token": $access_token, "account_id": $account_id, "ach_class": $ach_class, "amount": $amount, "beacon_session_id": $beacon_session_id, "client_id": $client_id, "device": $device, "funding_account_id": $funding_account_id, "idempotency_key": $idempotency_key, "iso_currency_code": $iso_currency_code, "network": $network, "origination_account_id": $origination_account_id, "originator_client_id": $originator_client_id, "payment_profile_token": $payment_profile_token, "secret": $secret, "type": $type, "user": $user, "user_present": $user_present, "with_guarantee": $with_guarantee} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel a transfer
#
# POST /transfer/cancel
# Docs: /api/products/transfer/#transfercancel
# operationId: transferCancel
export def "transfer-cancel transferCancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  transfer_id: string # Plaid’s unique identifier for a transfer.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/cancel")
  let body = {"client_id": $client_id, "secret": $secret, "transfer_id": $transfer_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get RTP eligibility information of a transfer
#
# POST /transfer/capabilities/get
# Docs: /api/products/transfer/#transfercapabilitiesget
# operationId: transferCapabilitiesGet
export def "transfer-capabilities-get transferCapabilitiesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-token: string # The Plaid `access_token` for the account that will be debited or credited. Required if not using `payment_profile_token`.
  --account-id: string # The Plaid `account_id` corresponding to the end-user account that will be debited or credited. Returned only if `account_id` was set on intent creation.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --payment-profile-token: string # A payment profile token associated with the Payment Profile data that is being requested.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<institution_supported_networks: record<rtp: record<credit: bool>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/capabilities/get")
  let body = {"access_token": $access_token, "account_id": $account_id, "client_id": $client_id, "payment_profile_token": $payment_profile_token, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a transfer
#
# POST /transfer/create
# Docs: /api/products/transfer/#transfercreate
# operationId: transferCreate
# --user shape: {address?: record, email_address?: string, legal_name?: string, phone_number?: string}
@deprecated --flag ach-class
@deprecated --flag idempotency-key
@deprecated --flag iso-currency-code
@deprecated --flag network
@deprecated --flag origination-account-id
@deprecated --flag type
@deprecated --flag user
export def "transfer-create transferCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-token: string # The Plaid `access_token` for the account that will be debited or credited. Required if not using `payment_profile_token`.
  --account-id: string # The Plaid `account_id` corresponding to the end-user account that will be debited or credited. Returned only if `account_id` was set on intent creation.
  --ach-class: any # DEPRECATED
  --amount: string # The amount of the transfer (decimal string with two digits of precision e.g. "10.00").
  authorization_id: string # Plaid’s unique identifier for a transfer authorization. This parameter also serves the purpose of acting as an idempotency identifier.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  description: string # The transfer description. Maximum of 10 characters.
  --idempotency-key: string # Deprecated. `authorization_id` is now used as idempotency instead.  A random key provided by the client, per unique transfer. Maximum of 50 characters.  The API supports idempotency for safely retrying requests without accidentally performing the same operation twice. For example, if a request to create a transfer fails due to a network connection error, you can retry the request with the same idempotency key to guarantee that only a single transfer is created. (DEPRECATED)
  --iso-currency-code: string # The currency of the transfer amount. The default value is "USD". (DEPRECATED)
  --metadata: record # The Metadata object is a mapping of client-provided string fields to any string value. The following limitations apply: The JSON values must be Strings (no nested JSON objects allowed) Only ASCII characters may be used Maximum of 50 key/value pairs Maximum key length of 40 characters Maximum value length of 500 characters  (nullable)
  --network: any # DEPRECATED
  --origination-account-id: string # Plaid’s unique identifier for the origination account for this transfer. If you have more than one origination account, this value must be specified. Otherwise, this field should be left blank. (DEPRECATED, nullable)
  --payment-profile-token: string # The payment profile token associated with the Payment Profile that will be debited or credited. Required if not using `access_token`.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --type: any # DEPRECATED
  --user: record # The legal name and other information for the account holder. (DEPRECATED, nullable) — shape: {address?: record, email_address?: string, legal_name?: string, phone_number?: string}
]: any -> record<request_id: string, transfer: record<account_id: string, ach_class: string, amount: string, cancellable: bool, created: string, description: string, expected_settlement_date: string, failure_reason: record<ach_return_code: string, description: string>, funding_account_id: string, guarantee_decision: string, guarantee_decision_rationale: record<code: string, description: string>, id: string, iso_currency_code: string, metadata: record, network: string, origination_account_id: string, originator_client_id: string, recurring_transfer_id: string, refunds: list<record>, standard_return_window: string, status: string, sweep_status: string, type: string, unauthorized_return_window: string, user: record<address: record, email_address: string, legal_name: string, phone_number: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/create")
  let body = {"access_token": $access_token, "account_id": $account_id, "ach_class": $ach_class, "amount": $amount, "authorization_id": $authorization_id, "client_id": $client_id, "description": $description, "idempotency_key": $idempotency_key, "iso_currency_code": $iso_currency_code, "metadata": $metadata, "network": $network, "origination_account_id": $origination_account_id, "payment_profile_token": $payment_profile_token, "secret": $secret, "type": $type, "user": $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List transfer events
#
# POST /transfer/event/list
# Docs: /api/products/transfer/#transfereventlist
# operationId: transferEventList
@deprecated --flag origination-account-id
export def "transfer-event-list transferEventList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # The account ID to get events for all transactions to/from an account. (nullable)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --count: int # The maximum number of transfer events to return. If the number of events matching the above parameters is greater than `count`, the most recent events will be returned. (nullable, default: 25)
  --end-date: string # The end datetime of transfers to list. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
  --event-types: list # Filter events by event type.
  --funding-account-id: string # Filter transfer events to only those with the specified `funding_account_id`. (nullable)
  --offset: int # The offset into the list of transfer events. When `count`=25 and `offset`=0, the first 25 events will be returned. When `count`=25 and `offset`=25, the next 25 events will be returned. (nullable, default: 0)
  --origination-account-id: string # The origination account ID to get events for transfers from a specific origination account. (DEPRECATED, nullable)
  --originator-client-id: string # Filter transfer events to only those with the specified originator client. (nullable)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --start-date: string # The start datetime of transfers to list. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
  --sweep-id: string # Plaid’s unique identifier for a sweep.
  --transfer-id: string # Plaid’s unique identifier for a transfer. (nullable)
  --transfer-type: string@transfer-type-completer # The type of transfer. This will be either `debit` or `credit`.  A `debit` indicates a transfer of money into your origination account; a `credit` indicates a transfer of money out of your origination account. (nullable)
]: any -> record<request_id: string, transfer_events: table<account_id: string, event_id: int, event_type: string, failure_reason: record, funding_account_id: string, origination_account_id: string, originator_client_id: string, refund_id: string, sweep_amount: string, sweep_id: string, timestamp: string, transfer_amount: string, transfer_id: string, transfer_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/event/list")
  let body = {"account_id": $account_id, "client_id": $client_id, "count": $count, "end_date": $end_date, "event_types": $event_types, "funding_account_id": $funding_account_id, "offset": $offset, "origination_account_id": $origination_account_id, "originator_client_id": $originator_client_id, "secret": $secret, "start_date": $start_date, "sweep_id": $sweep_id, "transfer_id": $transfer_id, "transfer_type": $transfer_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sync transfer events
#
# POST /transfer/event/sync
# Docs: /api/products/transfer/#transfereventsync
# operationId: transferEventSync
export def "transfer-event-sync transferEventSync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  after_id: int # The latest (largest) `event_id` fetched via the sync endpoint, or 0 initially.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --count: int # The maximum number of transfer events to return. (nullable, default: 25)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string, transfer_events: table<account_id: string, event_id: int, event_type: string, failure_reason: record, funding_account_id: string, origination_account_id: string, originator_client_id: string, refund_id: string, sweep_amount: string, sweep_id: string, timestamp: string, transfer_amount: string, transfer_id: string, transfer_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/event/sync")
  let body = {"after_id": $after_id, "client_id": $client_id, "count": $count, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a transfer
#
# POST /transfer/get
# Docs: /api/products/transfer/#transferget
# operationId: transferGet
export def "transfer-get transferGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  transfer_id: string # Plaid’s unique identifier for a transfer.
]: any -> record<request_id: string, transfer: record<account_id: string, ach_class: string, amount: string, cancellable: bool, created: string, description: string, expected_settlement_date: string, failure_reason: record<ach_return_code: string, description: string>, funding_account_id: string, guarantee_decision: string, guarantee_decision_rationale: record<code: string, description: string>, id: string, iso_currency_code: string, metadata: record, network: string, origination_account_id: string, originator_client_id: string, recurring_transfer_id: string, refunds: list<record>, standard_return_window: string, status: string, sweep_status: string, type: string, unauthorized_return_window: string, user: record<address: record, email_address: string, legal_name: string, phone_number: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/get")
  let body = {"client_id": $client_id, "secret": $secret, "transfer_id": $transfer_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a transfer intent object to invoke the Transfer UI
#
# POST /transfer/intent/create
# Docs: /api/products/transfer/#transferintentcreate
# operationId: transferIntentCreate
# --user shape: {address?: record, email_address?: string, legal_name: string, phone_number?: string}
@deprecated --flag origination-account-id
export def "transfer-intent-create transferIntentCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # The Plaid `account_id` corresponding to the end-user account that will be debited or credited. (nullable)
  --ach-class: string@ach-class-completer # Specifies the use case of the transfer. Required for transfers on an ACH network.  `"ccd"` - Corporate Credit or Debit - fund transfer between two corporate bank accounts  `"ppd"` - Prearranged Payment or Deposit - the transfer is part of a pre-existing relationship with a consumer, eg. bill payment  `"tel"` - Telephone-Initiated Entry  `"web"` - Internet-Initiated Entry - debits from a consumer’s account where their authorization is obtained over the Internet
  amount: string # The amount of the transfer (decimal string with two digits of precision e.g. "10.00").
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  description: string # A description for the underlying transfer. Maximum of 8 characters.
  --funding-account-id: string # The id of the funding account to use, available in the Plaid Dashboard. This determines which of your business checking accounts will be credited or debited. Defaults to the account configured during onboarding. (nullable)
  --iso-currency-code: string # The currency of the transfer amount, e.g. "USD"
  --metadata: record # The Metadata object is a mapping of client-provided string fields to any string value. The following limitations apply: The JSON values must be Strings (no nested JSON objects allowed) Only ASCII characters may be used Maximum of 50 key/value pairs Maximum key length of 40 characters Maximum value length of 500 characters  (nullable)
  mode: string@mode-completer # The direction of the flow of transfer funds.  `PAYMENT`: Transfers funds from an end user's account to your business account.  `DISBURSEMENT`: Transfers funds from your business account to an end user's account.
  --network: string@network-completer-2 # The network or rails used for the transfer. Defaults to `same-day-ach`.  For transfers submitted as either `ach` or `same-day-ach` the cutoff for same-day is 9:30 AM Pacific Time and the cutoff for next-day transfers is 5:30 PM Pacific Time. It is recommended to submit a transfer at least 15 minutes before the cutoff time in order to ensure that it will be processed before the cutoff. Any transfer that is indicated as `same-day-ach` and that misses the same-day cutoff, but is submitted in time for the next-day cutoff, will be sent over next-day rails and will not incur same-day charges. Note that both legs of the transfer will be downgraded if applicable. (default: same-day-ach)
  --origination-account-id: string # Plaid’s unique identifier for the origination account for the intent. If not provided, the default account will be used. (DEPRECATED, nullable)
  --require-guarantee: oneof<nothing, bool> # When `true`, the transfer requires a `GUARANTEED` decision by Plaid to proceed (Guarantee customers only). (nullable, default: false)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user: record # The legal name and other information for the account holder. — shape: {address?: record, email_address?: string, legal_name: string, phone_number?: string}
]: any -> record<request_id: string, transfer_intent: record<account_id: string, ach_class: string, amount: string, created: string, description: string, funding_account_id: string, id: string, iso_currency_code: string, metadata: record, mode: string, network: string, origination_account_id: string, require_guarantee: bool, status: string, user: record<address: record, email_address: string, legal_name: string, phone_number: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/intent/create")
  let body = {"account_id": $account_id, "ach_class": $ach_class, "amount": $amount, "client_id": $client_id, "description": $description, "funding_account_id": $funding_account_id, "iso_currency_code": $iso_currency_code, "metadata": $metadata, "mode": $mode, "network": $network, "origination_account_id": $origination_account_id, "require_guarantee": $require_guarantee, "secret": $secret, "user": $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve more information about a transfer intent
#
# POST /transfer/intent/get
# Docs: /api/products/transfer/#transferintentget
# operationId: transferIntentGet
export def "transfer-intent-get transferIntentGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  transfer_intent_id: string # Plaid's unique identifier for a transfer intent object.
]: any -> record<request_id: string, transfer_intent: record<account_id: string, ach_class: string, amount: string, authorization_decision: string, authorization_decision_rationale: record<code: string, description: string>, created: string, description: string, failure_reason: record<error_code: string, error_message: string, error_type: string>, funding_account_id: string, guarantee_decision: string, guarantee_decision_rationale: record<code: string, description: string>, id: string, iso_currency_code: string, metadata: record, mode: string, network: string, origination_account_id: string, require_guarantee: bool, status: string, transfer_id: string, user: record<address: record, email_address: string, legal_name: string, phone_number: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/intent/get")
  let body = {"client_id": $client_id, "secret": $secret, "transfer_intent_id": $transfer_intent_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List transfers
#
# POST /transfer/list
# Docs: /api/products/transfer/#transferlist
# operationId: transferList
@deprecated --flag origination-account-id
export def "transfer-list transferList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --count: int # The maximum number of transfers to return. (default: 25)
  --end-date: string # The end datetime of transfers to list. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
  --funding-account-id: string # Filter transfers to only those with the specified `funding_account_id`. (nullable)
  --offset: int # The number of transfers to skip before returning results. (default: 0)
  --origination-account-id: string # Filter transfers to only those originated through the specified origination account. (DEPRECATED, nullable)
  --originator-client-id: string # Filter transfers to only those with the specified originator client. (nullable)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --start-date: string # The start datetime of transfers to list. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
]: any -> record<request_id: string, transfers: table<account_id: string, ach_class: string, amount: string, cancellable: bool, created: string, description: string, expected_settlement_date: string, failure_reason: record, funding_account_id: string, guarantee_decision: string, guarantee_decision_rationale: record, id: string, iso_currency_code: string, metadata: record, network: string, origination_account_id: string, originator_client_id: string, recurring_transfer_id: string, refunds: list, standard_return_window: string, status: string, sweep_status: string, type: string, unauthorized_return_window: string, user: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/list")
  let body = {"client_id": $client_id, "count": $count, "end_date": $end_date, "funding_account_id": $funding_account_id, "offset": $offset, "origination_account_id": $origination_account_id, "originator_client_id": $originator_client_id, "secret": $secret, "start_date": $start_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Migrate account into Transfers
#
# POST /transfer/migrate_account
# Docs: /api/products/transfer/#transfermigrate_account
# operationId: transferMigrateAccount
export def "transfer-migrate-account transferMigrateAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account_number: string # The user's account number.
  account_type: string # The type of the bank account (`checking` or `savings`).
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  routing_number: string # The user's routing number.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --wire-routing-number: string # The user's wire transfer routing number. This is the ABA number; for some institutions, this may differ from the ACH number used in `routing_number`.
]: any -> record<access_token: string, account_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/migrate_account")
  let body = {"account_number": $account_number, "account_type": $account_type, "client_id": $client_id, "routing_number": $routing_number, "secret": $secret, "wire_routing_number": $wire_routing_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a new originator
#
# POST /transfer/originator/create
# Docs: /api/products/transfer/#transferoriginatorcreate
# operationId: transferOriginatorCreate
export def "transfer-originator-create transferOriginatorCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  company_name: string # The company name of the end customer being created. This will be displayed in public-facing surfaces, e.g. Plaid Dashboard.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<company_name: string, originator_client_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/originator/create")
  let body = {"client_id": $client_id, "company_name": $company_name, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get status of an originator's onboarding
#
# POST /transfer/originator/get
# Docs: /api/products/transfer/#transferoriginatorget
# operationId: transferOriginatorGet
export def "transfer-originator-get transferOriginatorGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  originator_client_id: string # Client ID of the end customer (i.e. the originator).
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<originator: record<client_id: string, company_name: string, transfer_diligence_status: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/originator/get")
  let body = {"client_id": $client_id, "originator_client_id": $originator_client_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get status of all originators' onboarding
#
# POST /transfer/originator/list
# Docs: /api/products/transfer/#transferoriginatorlist
# operationId: transferOriginatorList
export def "transfer-originator-list transferOriginatorList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --count: int # The maximum number of originators to return. (nullable, default: 25)
  --offset: int # The number of originators to skip before returning results. (nullable, default: 0)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<originators: table<client_id: string, transfer_diligence_status: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/originator/list")
  let body = {"client_id": $client_id, "count": $count, "offset": $offset, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate a Plaid-hosted onboarding UI URL.
#
# POST /transfer/questionnaire/create
# Docs: /api/products/transfer/#transferquestionnairecreate
# operationId: transferQuestionnaireCreate
export def "transfer-questionnaire-create transferQuestionnaireCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  originator_client_id: string # Client ID of the end customer.
  redirect_uri: string # URL the end customer will be redirected to after completing questions in Plaid-hosted onboarding flow.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<onboarding_url: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/questionnaire/create")
  let body = {"client_id": $client_id, "originator_client_id": $originator_client_id, "redirect_uri": $redirect_uri, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel a recurring transfer.
#
# POST /transfer/recurring/cancel
# Docs: /api/products/transfer/#transferrecurringcancel
# operationId: transferRecurringCancel
export def "transfer-recurring-cancel transferRecurringCancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  recurring_transfer_id: string # Plaid’s unique identifier for a recurring transfer.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/recurring/cancel")
  let body = {"client_id": $client_id, "recurring_transfer_id": $recurring_transfer_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a recurring transfer
#
# POST /transfer/recurring/create
# Docs: /api/products/transfer/#transferrecurringcreate
# operationId: transferRecurringCreate
# --device shape: {ip_address: string, user_agent: string}
# --schedule shape: {end_date?: string, interval_count: int, interval_execution_day: int, interval_unit: "week"|"month", start_date: string}
# --user shape: {address?: record, email_address?: string, legal_name: string, phone_number?: string}
@deprecated --flag iso-currency-code
export def "transfer-recurring-create transferRecurringCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_token: string # The Plaid `access_token` for the account that will be debited or credited. Required if not using `payment_profile_token`.
  account_id: string # The Plaid `account_id` corresponding to the end-user account that will be debited or credited. Returned only if `account_id` was set on intent creation.
  --ach-class: string@ach-class-completer # Specifies the use case of the transfer. Required for transfers on an ACH network.  `"ccd"` - Corporate Credit or Debit - fund transfer between two corporate bank accounts  `"ppd"` - Prearranged Payment or Deposit - the transfer is part of a pre-existing relationship with a consumer, eg. bill payment  `"tel"` - Telephone-Initiated Entry  `"web"` - Internet-Initiated Entry - debits from a consumer’s account where their authorization is obtained over the Internet
  amount: string # The amount of the transfer (decimal string with two digits of precision e.g. "10.00").
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  description: string # The description of the recurring transfer.
  device: record # Information about the device being used to initiate the authorization. — shape: {ip_address: string, user_agent: string}
  --funding-account-id: string # The id of the funding account to use, available in the Plaid Dashboard. This determines which of your business checking accounts will be credited or debited. Defaults to the account configured during onboarding. (nullable)
  idempotency_key: string # A random key provided by the client, per unique recurring transfer. Maximum of 50 characters.  The API supports idempotency for safely retrying requests without accidentally performing the same operation twice. For example, if a request to create a recurring fails due to a network connection error, you can retry the request with the same idempotency key to guarantee that only a single recurring transfer is created.
  --iso-currency-code: string # The currency of the transfer amount. The default value is "USD". (DEPRECATED)
  network: string@network-completer-1 # The network or rails used for the transfer.  For transfers submitted as either `ach` or `same-day-ach` the cutoff for same-day is 9:30 AM Pacific Time and the cutoff for next-day transfers is 5:30 PM Pacific Time. It is recommended to submit a transfer at least 15 minutes before the cutoff time in order to ensure that it will be processed before the cutoff. Any transfer that is indicated as `same-day-ach` and that misses the same-day cutoff, but is submitted in time for the next-day cutoff, will be sent over next-day rails and will not incur same-day charges. Note that both legs of the transfer will be downgraded if applicable.
  schedule: record # The schedule that the recurring transfer will be executed on. — shape: {end_date?: string, interval_count: int, interval_execution_day: int, interval_unit: "week"|"month", start_date: string}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --test-clock-id: string # Plaid’s unique identifier for a test clock. (nullable)
  type: string@type-completer # The type of transfer. This will be either `debit` or `credit`.  A `debit` indicates a transfer of money into the origination account; a `credit` indicates a transfer of money out of the origination account.
  user: record # The legal name and other information for the account holder. — shape: {address?: record, email_address?: string, legal_name: string, phone_number?: string}
  --user-present: oneof<nothing, bool> # If the end user is initiating the specific transfer themselves via an interactive UI, this should be `true`; for automatic recurring payments where the end user is not actually initiating each individual transfer, it should be `false`. (nullable)
]: any -> record<decision: string, decision_rationale: record<code: string, description: string>, recurring_transfer: record, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/recurring/create")
  let body = {"access_token": $access_token, "account_id": $account_id, "ach_class": $ach_class, "amount": $amount, "client_id": $client_id, "description": $description, "device": $device, "funding_account_id": $funding_account_id, "idempotency_key": $idempotency_key, "iso_currency_code": $iso_currency_code, "network": $network, "schedule": $schedule, "secret": $secret, "test_clock_id": $test_clock_id, "type": $type, "user": $user, "user_present": $user_present} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a recurring transfer
#
# POST /transfer/recurring/get
# Docs: /api/products/transfer/#transferrecurringget
# operationId: transferRecurringGet
export def "transfer-recurring-get transferRecurringGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  recurring_transfer_id: string # Plaid’s unique identifier for a recurring transfer.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<recurring_transfer: record<account_id: string, ach_class: string, amount: string, created: string, description: string, funding_account_id: string, iso_currency_code: string, network: string, next_origination_date: string, origination_account_id: string, recurring_transfer_id: string, schedule: record<end_date: string, interval_count: int, interval_execution_day: int, interval_unit: string, start_date: string>, status: string, test_clock_id: string, transfer_ids: list<string>, type: string, user: record<address: record, email_address: string, legal_name: string, phone_number: string>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/recurring/get")
  let body = {"client_id": $client_id, "recurring_transfer_id": $recurring_transfer_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List recurring transfers
#
# POST /transfer/recurring/list
# Docs: /api/products/transfer/#transferrecurringlist
# operationId: transferRecurringList
export def "transfer-recurring-list transferRecurringList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --count: int # The maximum number of recurring transfers to return. (default: 25)
  --end-time: string # The end datetime of recurring transfers to list. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
  --funding-account-id: string # Filter recurring transfers to only those with the specified `funding_account_id`. (nullable)
  --offset: int # The number of recurring transfers to skip before returning results. (default: 0)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --start-time: string # The start datetime of recurring transfers to list. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
]: any -> record<recurring_transfers: table<account_id: string, ach_class: string, amount: string, created: string, description: string, funding_account_id: string, iso_currency_code: string, network: string, next_origination_date: string, origination_account_id: string, recurring_transfer_id: string, schedule: record, status: string, test_clock_id: string, transfer_ids: list, type: string, user: record>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/recurring/list")
  let body = {"client_id": $client_id, "count": $count, "end_time": $end_time, "funding_account_id": $funding_account_id, "offset": $offset, "secret": $secret, "start_time": $start_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel a refund
#
# POST /transfer/refund/cancel
# Docs: /api/products/transfer/#transferrefundcancel
# operationId: transferRefundCancel
export def "transfer-refund-cancel transferRefundCancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  refund_id: string # Plaid’s unique identifier for a refund.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/refund/cancel")
  let body = {"client_id": $client_id, "refund_id": $refund_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a refund
#
# POST /transfer/refund/create
# Docs: /api/products/transfer/#transferrefundcreate
# operationId: transferRefundCreate
export def "transfer-refund-create transferRefundCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: string # The amount of the refund (decimal string with two digits of precision e.g. "10.00").
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  idempotency_key: string # A random key provided by the client, per unique refund. Maximum of 50 characters.  The API supports idempotency for safely retrying requests without accidentally performing the same operation twice. For example, if a request to create a refund fails due to a network connection error, you can retry the request with the same idempotency key to guarantee that only a single refund is created.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  transfer_id: string # The ID of the transfer to refund.
]: any -> record<refund: record<amount: string, created: string, id: string, status: string, transfer_id: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/refund/create")
  let body = {"amount": $amount, "client_id": $client_id, "idempotency_key": $idempotency_key, "secret": $secret, "transfer_id": $transfer_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a refund
#
# POST /transfer/refund/get
# Docs: /api/products/transfer/#transferrefundget
# operationId: transferRefundGet
export def "transfer-refund-get transferRefundGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  refund_id: string # Plaid’s unique identifier for a refund.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<refund: record<amount: string, created: string, id: string, status: string, transfer_id: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/refund/get")
  let body = {"client_id": $client_id, "refund_id": $refund_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists historical repayments
#
# POST /transfer/repayment/list
# Docs: /api/products/transfer/#transferrepaymentlist
# operationId: transferRepaymentList
export def "transfer-repayment-list transferRepaymentList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --count: int # The maximum number of repayments to return. (nullable, default: 25)
  --end-date: string # The end datetime of repayments to return (RFC 3339 format). (nullable, format: date-time)
  --offset: int # The number of repayments to skip before returning results. (default: 0)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --start-date: string # The start datetime of repayments to return (RFC 3339 format). (nullable, format: date-time)
]: any -> record<repayments: table<amount: string, created: string, iso_currency_code: string, repayment_id: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/repayment/list")
  let body = {"client_id": $client_id, "count": $count, "end_date": $end_date, "offset": $offset, "secret": $secret, "start_date": $start_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List the returns included in a repayment
#
# POST /transfer/repayment/return/list
# Docs: /api/products/transfer/#transferrepaymentreturnlist
# operationId: transferRepaymentReturnList
export def "transfer-repayment-return-list transferRepaymentReturnList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --count: int # The maximum number of repayments to return. (nullable, default: 25)
  --offset: int # The number of repayments to skip before returning results. (default: 0)
  repayment_id: string # Identifier of the repayment to query.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<repayment_returns: table<amount: string, event_id: int, iso_currency_code: string, transfer_id: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/repayment/return/list")
  let body = {"client_id": $client_id, "count": $count, "offset": $offset, "repayment_id": $repayment_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a sweep
#
# POST /transfer/sweep/get
# Docs: /api/products/transfer/#transfersweepget
# operationId: transferSweepGet
export def "transfer-sweep-get transferSweepGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  sweep_id: string # Plaid’s unique identifier for a sweep.
]: any -> record<request_id: string, sweep: record<amount: string, created: string, funding_account_id: string, id: string, iso_currency_code: string, settled: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/sweep/get")
  let body = {"client_id": $client_id, "secret": $secret, "sweep_id": $sweep_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List sweeps
#
# POST /transfer/sweep/list
# Docs: /api/products/transfer/#transfersweeplist
# operationId: transferSweepList
export def "transfer-sweep-list transferSweepList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --count: int # The maximum number of sweeps to return. (nullable, default: 25)
  --end-date: string # The end datetime of sweeps to return (RFC 3339 format). (nullable, format: date-time)
  --funding-account-id: string # Filter sweeps to only those with the specified `funding_account_id`. (nullable)
  --offset: int # The number of sweeps to skip before returning results. (default: 0)
  --originator-client-id: string # Filter sweeps to only those with the specified originator client. (nullable)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --start-date: string # The start datetime of sweeps to return (RFC 3339 format). (nullable, format: date-time)
]: any -> record<request_id: string, sweeps: table<amount: string, created: string, funding_account_id: string, id: string, iso_currency_code: string, settled: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/sweep/list")
  let body = {"client_id": $client_id, "count": $count, "end_date": $end_date, "funding_account_id": $funding_account_id, "offset": $offset, "originator_client_id": $originator_client_id, "secret": $secret, "start_date": $start_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create user
#
# POST /user/create
# Docs: /api/products/income/#usercreate
# operationId: userCreate
export def "user-create userCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  client_user_id: string # A unique ID representing the end user. Maximum of 128 characters. Typically this will be a user ID number from your application. Personally identifiable information, such as an email address or phone number, should not be used in the `client_user_id`.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string, user_id: string, user_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/create")
  let body = {"client_id": $client_id, "client_user_id": $client_user_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create an e-wallet
#
# POST /wallet/create
# Docs: /api/products/virtual-accounts/#walletcreate
# operationId: walletCreate
export def "wallet-create walletCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  iso_currency_code: string@iso-currency-code-completer # An ISO-4217 currency code, used with e-wallets and transactions.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wallet/create")
  let body = {"client_id": $client_id, "iso_currency_code": $iso_currency_code, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch an e-wallet
#
# POST /wallet/get
# Docs: /api/products/virtual-accounts/#walletget
# operationId: walletGet
export def "wallet-get walletGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  wallet_id: string # The ID of the e-wallet
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wallet/get")
  let body = {"client_id": $client_id, "secret": $secret, "wallet_id": $wallet_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch a list of e-wallets
#
# POST /wallet/list
# Docs: /api/products/virtual-accounts/#walletlist
# operationId: walletList
export def "wallet-list walletList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --count: int # The number of e-wallets to fetch (default: 10)
  --cursor: string # A base64 value representing the latest e-wallet that has already been requested. Set this to `next_cursor` received from the previous `/wallet/list` request. If provided, the response will only contain e-wallets created before that e-wallet. If omitted, the response will contain e-wallets starting from the most recent, and in descending order.
  --iso-currency-code: string@iso-currency-code-completer # An ISO-4217 currency code, used with e-wallets and transactions.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<next_cursor: string, request_id: string, wallets: table<balance: record, numbers: record, recipient_id: string, status: string, wallet_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wallet/list")
  let body = {"client_id": $client_id, "count": $count, "cursor": $cursor, "iso_currency_code": $iso_currency_code, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Execute a transaction using an e-wallet
#
# POST /wallet/transaction/execute
# Docs: /api/products/virtual-accounts/#wallettransactionexecute
# operationId: walletTransactionExecute
# --amount shape: {iso_currency_code: "GBP"|"EUR", value: float}
# --counterparty shape: {name: string, numbers: record}
export def "wallet-transaction-execute walletTransactionExecute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: record # The amount and currency of a transaction — shape: {iso_currency_code: "GBP"|"EUR", value: float}
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  counterparty: record # An object representing the e-wallet transaction's counterparty — shape: {name: string, numbers: record}
  idempotency_key: string # A random key provided by the client, per unique wallet transaction. Maximum of 128 characters.  The API supports idempotency for safely retrying requests without accidentally performing the same operation twice. If a request to execute a wallet transaction fails due to a network connection error, then after a minimum delay of one minute, you can retry the request with the same idempotency key to guarantee that only a single wallet transaction is created. If the request was successfully processed, it will prevent any transaction that uses the same idempotency key, and was received within 24 hours of the first request, from being processed.
  reference: string # A reference for the transaction. This must be an alphanumeric string with 6 to 18 characters and must not contain any special characters or spaces. Ensure that the `reference` field is unique for each transaction.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  wallet_id: string # The ID of the e-wallet to debit from
]: any -> record<request_id: string, status: string, transaction_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wallet/transaction/execute")
  let body = {"amount": $amount, "client_id": $client_id, "counterparty": $counterparty, "idempotency_key": $idempotency_key, "reference": $reference, "secret": $secret, "wallet_id": $wallet_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch an e-wallet transaction
#
# POST /wallet/transaction/get
# Docs: /api/products/virtual-accounts/#wallettransactionget
# operationId: walletTransactionGet
export def "wallet-transaction-get walletTransactionGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  transaction_id: string # The ID of the transaction to fetch
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wallet/transaction/get")
  let body = {"client_id": $client_id, "secret": $secret, "transaction_id": $transaction_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List e-wallet transactions
#
# POST /wallet/transaction/list
# Docs: /api/products/virtual-accounts/#wallettransactionlist
# operationId: walletTransactionList
# --options shape: {end_time?: string, start_time?: string}
export def "wallet-transaction-list walletTransactionList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --count: int # The number of transactions to fetch (default: 10)
  --cursor: string # A base64 value representing the latest transaction that has already been requested. Set this to `next_cursor` received from the previous `/wallet/transaction/list` request. If provided, the response will only contain transactions created before that transaction. If omitted, the response will contain transactions starting from the most recent, and in descending order by the `created_at` time.
  --options: record # Additional wallet transaction options (nullable) — shape: {end_time?: string, start_time?: string}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  wallet_id: string # The ID of the e-wallet to fetch transactions from
]: any -> record<next_cursor: string, request_id: string, transactions: table<amount: record, counterparty: record, created_at: string, last_status_update: string, payment_id: string, reference: string, status: string, transaction_id: string, type: string, wallet_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wallet/transaction/list")
  let body = {"client_id": $client_id, "count": $count, "cursor": $cursor, "options": $options, "secret": $secret, "wallet_id": $wallet_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a watchlist screening for an entity
#
# POST /watchlist_screening/entity/create
# Docs: /api/products/monitor/#watchlist_screeningentitycreate
# operationId: watchlistScreeningEntityCreate
# --search_terms shape: {country?: string, document_number?: string, email_address?: string, entity_watchlist_program_id: string, legal_name: string, phone_number?: string, url?: string}
export def "watchlist-screening-entity-create watch-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --client-user-id: string # An identifier to help you connect this object to your internal systems. For example, your database ID corresponding to this object. (e.g. your-db-id-3b24110)
  search_terms: record # Search inputs for creating an entity watchlist screening — shape: {country?: string, document_number?: string, email_address?: string, entity_watchlist_program_id: string, legal_name: string, phone_number?: string, url?: string}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<assignee: string, audit_trail: record<dashboard_user_id: string, source: string, timestamp: string>, client_user_id: string, id: string, request_id: string, search_terms: record<country: string, document_number: string, email_address: string, entity_watchlist_program_id: string, legal_name: string, phone_number: string, url: string, version: float>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/entity/create")
  let body = {"client_id": $client_id, "client_user_id": $client_user_id, "search_terms": $search_terms, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an entity screening
#
# POST /watchlist_screening/entity/get
# Docs: /api/products/monitor/#watchlist_screeningentityget
# operationId: watchlistScreeningEntityGet
export def "watchlist-screening-entity-get watch-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  entity_watchlist_screening_id: string # ID of the associated entity screening. (e.g. entscr_52xR9LKo77r1Np)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<assignee: string, audit_trail: record<dashboard_user_id: string, source: string, timestamp: string>, client_user_id: string, id: string, request_id: string, search_terms: record<country: string, document_number: string, email_address: string, entity_watchlist_program_id: string, legal_name: string, phone_number: string, url: string, version: float>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/entity/get")
  let body = {"client_id": $client_id, "entity_watchlist_screening_id": $entity_watchlist_screening_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List history for entity watchlist screenings
#
# POST /watchlist_screening/entity/history/list
# Docs: /api/products/monitor/#watchlist_screeningentityhistorylist
# operationId: watchlistScreeningEntityHistoryList
export def "watchlist-screening-entity-history-list watch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
  entity_watchlist_screening_id: string # ID of the associated entity screening. (e.g. entscr_52xR9LKo77r1Np)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<entity_watchlist_screenings: table<assignee: string, audit_trail: record, client_user_id: string, id: string, search_terms: record, status: string>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/entity/history/list")
  let body = {"client_id": $client_id, "cursor": $cursor, "entity_watchlist_screening_id": $entity_watchlist_screening_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List hits for entity watchlist screenings
#
# POST /watchlist_screening/entity/hit/list
# Docs: /api/products/monitor/#watchlist_screeningentityhitlist
# operationId: watchlistScreeningEntityHitList
export def "watchlist-screening-entity-hit-list watch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
  entity_watchlist_screening_id: string # ID of the associated entity screening. (e.g. entscr_52xR9LKo77r1Np)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<entity_watchlist_screening_hits: table<analysis: record, data: record, first_active: string, historical_since: string, id: string, inactive_since: string, list_code: string, plaid_uid: string, review_status: string, source_uid: string>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/entity/hit/list")
  let body = {"client_id": $client_id, "cursor": $cursor, "entity_watchlist_screening_id": $entity_watchlist_screening_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List entity watchlist screenings
#
# POST /watchlist_screening/entity/list
# Docs: /api/products/monitor/#watchlist_screeningentitylist
# operationId: watchlistScreeningEntityList
export def "watchlist-screening-entity-list watch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignee: string # ID of the associated user. (e.g. 54350110fedcbaf01234ffee)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --client-user-id: string # An identifier to help you connect this object to your internal systems. For example, your database ID corresponding to this object. (e.g. your-db-id-3b24110)
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
  entity_watchlist_program_id: string # ID of the associated entity program. (e.g. entprg_2eRPsDnL66rZ7H)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --status: string@status-completer # A status enum indicating whether a screening is still pending review, has been rejected, or has been cleared. (e.g. cleared)
]: any -> record<entity_watchlist_screenings: table<assignee: string, audit_trail: record, client_user_id: string, id: string, search_terms: record, status: string>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/entity/list")
  let body = {"assignee": $assignee, "client_id": $client_id, "client_user_id": $client_user_id, "cursor": $cursor, "entity_watchlist_program_id": $entity_watchlist_program_id, "secret": $secret, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get entity watchlist screening program
#
# POST /watchlist_screening/entity/program/get
# Docs: /api/products/monitor/#watchlist_screeningentityprogramget
# operationId: watchlistScreeningEntityProgramGet
export def "watchlist-screening-entity-program-get watch-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  entity_watchlist_program_id: string # ID of the associated entity program. (e.g. entprg_2eRPsDnL66rZ7H)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<audit_trail: record<dashboard_user_id: string, source: string, timestamp: string>, created_at: string, id: string, is_archived: bool, is_rescanning_enabled: bool, lists_enabled: list<string>, name: string, name_sensitivity: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/entity/program/get")
  let body = {"client_id": $client_id, "entity_watchlist_program_id": $entity_watchlist_program_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List entity watchlist screening programs
#
# POST /watchlist_screening/entity/program/list
# Docs: /api/products/monitor/#watchlist_screeningentityprogramlist
# operationId: watchlistScreeningEntityProgramList
export def "watchlist-screening-entity-program-list watch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<entity_watchlist_programs: table<audit_trail: record, created_at: string, id: string, is_archived: bool, is_rescanning_enabled: bool, lists_enabled: list, name: string, name_sensitivity: string>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/entity/program/list")
  let body = {"client_id": $client_id, "cursor": $cursor, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a review for an entity watchlist screening
#
# POST /watchlist_screening/entity/review/create
# Docs: /api/products/monitor/#watchlist_screeningentityreviewcreate
# operationId: watchlistScreeningEntityReviewCreate
export def "watchlist-screening-entity-review-create watch-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --comment: string # A comment submitted by a team member as part of reviewing a watchlist screening. (nullable, e.g. These look like legitimate matches, rejecting the customer.)
  confirmed_hits: list # Hits to mark as a true positive after thorough manual review. These hits will never recur or be updated once dismissed. In most cases, confirmed hits indicate that the customer should be rejected.
  dismissed_hits: list # Hits to mark as a false positive after thorough manual review. These hits will never recur or be updated once dismissed.
  entity_watchlist_screening_id: string # ID of the associated entity screening. (e.g. entscr_52xR9LKo77r1Np)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<audit_trail: record<dashboard_user_id: string, source: string, timestamp: string>, comment: string, confirmed_hits: list<string>, dismissed_hits: list<string>, id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/entity/review/create")
  let body = {"client_id": $client_id, "comment": $comment, "confirmed_hits": $confirmed_hits, "dismissed_hits": $dismissed_hits, "entity_watchlist_screening_id": $entity_watchlist_screening_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List reviews for entity watchlist screenings
#
# POST /watchlist_screening/entity/review/list
# Docs: /api/products/monitor/#watchlist_screeningentityreviewlist
# operationId: watchlistScreeningEntityReviewList
export def "watchlist-screening-entity-review-list watch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
  entity_watchlist_screening_id: string # ID of the associated entity screening. (e.g. entscr_52xR9LKo77r1Np)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<entity_watchlist_screening_reviews: table<audit_trail: record, comment: string, confirmed_hits: list, dismissed_hits: list, id: string>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/entity/review/list")
  let body = {"client_id": $client_id, "cursor": $cursor, "entity_watchlist_screening_id": $entity_watchlist_screening_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an entity screening
#
# POST /watchlist_screening/entity/update
# Docs: /api/products/monitor/#watchlist_screeningentityupdate
# operationId: watchlistScreeningEntityUpdate
# --search_terms shape: {client_id: string, country?: string, document_number?: string, email_address?: string, entity_watchlist_program_id: string, legal_name?: string, phone_number?: string, secret: string, url?: string}
export def "watchlist-screening-entity-update watch-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignee: string # ID of the associated user. (e.g. 54350110fedcbaf01234ffee)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --client-user-id: string # An identifier to help you connect this object to your internal systems. For example, your database ID corresponding to this object. (e.g. your-db-id-3b24110)
  entity_watchlist_screening_id: string # ID of the associated entity screening. (e.g. entscr_52xR9LKo77r1Np)
  --reset-fields: list # A list of fields to reset back to null (nullable)
  --search-terms: record # Search terms for editing an entity watchlist screening (nullable) — shape: {client_id: string, country?: string, document_number?: string, email_address?: string, entity_watchlist_program_id: string, legal_name?: string, phone_number?: string, secret: string, url?: string}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --status: string@status-completer # A status enum indicating whether a screening is still pending review, has been rejected, or has been cleared. (e.g. cleared)
]: any -> record<assignee: string, audit_trail: record<dashboard_user_id: string, source: string, timestamp: string>, client_user_id: string, id: string, request_id: string, search_terms: record<country: string, document_number: string, email_address: string, entity_watchlist_program_id: string, legal_name: string, phone_number: string, url: string, version: float>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/entity/update")
  let body = {"assignee": $assignee, "client_id": $client_id, "client_user_id": $client_user_id, "entity_watchlist_screening_id": $entity_watchlist_screening_id, "reset_fields": $reset_fields, "search_terms": $search_terms, "secret": $secret, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a watchlist screening for a person
#
# POST /watchlist_screening/individual/create
# Docs: /api/products/monitor/#watchlist_screeningindividualcreate
# operationId: watchlistScreeningIndividualCreate
# --search_terms shape: {country?: string, date_of_birth?: string, document_number?: string, legal_name: string, watchlist_program_id: string}
export def "watchlist-screening-individual-create watch-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --client-user-id: string # An identifier to help you connect this object to your internal systems. For example, your database ID corresponding to this object. (e.g. your-db-id-3b24110)
  search_terms: record # Search inputs for creating a watchlist screening — shape: {country?: string, date_of_birth?: string, document_number?: string, legal_name: string, watchlist_program_id: string}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<assignee: string, audit_trail: record<dashboard_user_id: string, source: string, timestamp: string>, client_user_id: string, id: string, request_id: string, search_terms: record<country: string, date_of_birth: string, document_number: string, legal_name: string, version: float, watchlist_program_id: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/individual/create")
  let body = {"client_id": $client_id, "client_user_id": $client_user_id, "search_terms": $search_terms, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve an individual watchlist screening
#
# POST /watchlist_screening/individual/get
# Docs: /api/products/monitor/#watchlist_screeningindividualget
# operationId: watchlistScreeningIndividualGet
export def "watchlist-screening-individual-get watch-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  watchlist_screening_id: string # ID of the associated screening. (e.g. scr_52xR9LKo77r1Np)
]: any -> record<assignee: string, audit_trail: record<dashboard_user_id: string, source: string, timestamp: string>, client_user_id: string, id: string, request_id: string, search_terms: record<country: string, date_of_birth: string, document_number: string, legal_name: string, version: float, watchlist_program_id: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/individual/get")
  let body = {"client_id": $client_id, "secret": $secret, "watchlist_screening_id": $watchlist_screening_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List history for individual watchlist screenings
#
# POST /watchlist_screening/individual/history/list
# Docs: /api/products/monitor/#watchlist_screeningindividualhistorylist
# operationId: watchlistScreeningIndividualHistoryList
export def "watchlist-screening-individual-history-list watch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  watchlist_screening_id: string # ID of the associated screening. (e.g. scr_52xR9LKo77r1Np)
]: any -> record<next_cursor: string, request_id: string, watchlist_screenings: table<assignee: string, audit_trail: record, client_user_id: string, id: string, search_terms: record, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/individual/history/list")
  let body = {"client_id": $client_id, "cursor": $cursor, "secret": $secret, "watchlist_screening_id": $watchlist_screening_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List hits for individual watchlist screening
#
# POST /watchlist_screening/individual/hit/list
# Docs: /api/products/monitor/#watchlist_screeningindividualhitlist
# operationId: watchlistScreeningIndividualHitList
export def "watchlist-screening-individual-hit-list watch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  watchlist_screening_id: string # ID of the associated screening. (e.g. scr_52xR9LKo77r1Np)
]: any -> record<next_cursor: string, request_id: string, watchlist_screening_hits: table<analysis: record, data: record, first_active: string, historical_since: string, id: string, inactive_since: string, list_code: string, plaid_uid: string, review_status: string, source_uid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/individual/hit/list")
  let body = {"client_id": $client_id, "cursor": $cursor, "secret": $secret, "watchlist_screening_id": $watchlist_screening_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Individual Watchlist Screenings
#
# POST /watchlist_screening/individual/list
# Docs: /api/products/monitor/#watchlist_screeningindividuallist
# operationId: watchlistScreeningIndividualList
export def "watchlist-screening-individual-list watch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignee: string # ID of the associated user. (e.g. 54350110fedcbaf01234ffee)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --client-user-id: string # An identifier to help you connect this object to your internal systems. For example, your database ID corresponding to this object. (e.g. your-db-id-3b24110)
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --status: string@status-completer # A status enum indicating whether a screening is still pending review, has been rejected, or has been cleared. (e.g. cleared)
  watchlist_program_id: string # ID of the associated program. (e.g. prg_2eRPsDnL66rZ7H)
]: any -> record<next_cursor: string, request_id: string, watchlist_screenings: table<assignee: string, audit_trail: record, client_user_id: string, id: string, search_terms: record, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/individual/list")
  let body = {"assignee": $assignee, "client_id": $client_id, "client_user_id": $client_user_id, "cursor": $cursor, "secret": $secret, "status": $status, "watchlist_program_id": $watchlist_program_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get individual watchlist screening program
#
# POST /watchlist_screening/individual/program/get
# Docs: /api/products/monitor/#watchlist_screeningindividualprogramget
# operationId: watchlistScreeningIndividualProgramGet
export def "watchlist-screening-individual-program-get watch-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  watchlist_program_id: string # ID of the associated program. (e.g. prg_2eRPsDnL66rZ7H)
]: any -> record<audit_trail: record<dashboard_user_id: string, source: string, timestamp: string>, created_at: string, id: string, is_archived: bool, is_rescanning_enabled: bool, lists_enabled: list<string>, name: string, name_sensitivity: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/individual/program/get")
  let body = {"client_id": $client_id, "secret": $secret, "watchlist_program_id": $watchlist_program_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List individual watchlist screening programs
#
# POST /watchlist_screening/individual/program/list
# Docs: /api/products/monitor/#watchlist_screeningindividualprogramlist
# operationId: watchlistScreeningIndividualProgramList
export def "watchlist-screening-individual-program-list watch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<next_cursor: string, request_id: string, watchlist_programs: table<audit_trail: record, created_at: string, id: string, is_archived: bool, is_rescanning_enabled: bool, lists_enabled: list, name: string, name_sensitivity: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/individual/program/list")
  let body = {"client_id": $client_id, "cursor": $cursor, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a review for an individual watchlist screening
#
# POST /watchlist_screening/individual/review/create
# Docs: /api/products/monitor/#watchlist_screeningindividualreviewcreate
# operationId: watchlistScreeningIndividualReviewCreate
export def "watchlist-screening-individual-review-create watch-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --comment: string # A comment submitted by a team member as part of reviewing a watchlist screening. (nullable, e.g. These look like legitimate matches, rejecting the customer.)
  confirmed_hits: list # Hits to mark as a true positive after thorough manual review. These hits will never recur or be updated once dismissed. In most cases, confirmed hits indicate that the customer should be rejected.
  dismissed_hits: list # Hits to mark as a false positive after thorough manual review. These hits will never recur or be updated once dismissed.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  watchlist_screening_id: string # ID of the associated screening. (e.g. scr_52xR9LKo77r1Np)
]: any -> record<audit_trail: record<dashboard_user_id: string, source: string, timestamp: string>, comment: string, confirmed_hits: list<string>, dismissed_hits: list<string>, id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/individual/review/create")
  let body = {"client_id": $client_id, "comment": $comment, "confirmed_hits": $confirmed_hits, "dismissed_hits": $dismissed_hits, "secret": $secret, "watchlist_screening_id": $watchlist_screening_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List reviews for individual watchlist screenings
#
# POST /watchlist_screening/individual/review/list
# Docs: /api/products/monitor/#watchlist_screeningindividualreviewlist
# operationId: watchlistScreeningIndividualReviewList
export def "watchlist-screening-individual-review-list watch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  watchlist_screening_id: string # ID of the associated screening. (e.g. scr_52xR9LKo77r1Np)
]: any -> record<next_cursor: string, request_id: string, watchlist_screening_reviews: table<audit_trail: record, comment: string, confirmed_hits: list, dismissed_hits: list, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/individual/review/list")
  let body = {"client_id": $client_id, "cursor": $cursor, "secret": $secret, "watchlist_screening_id": $watchlist_screening_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update individual watchlist screening
#
# POST /watchlist_screening/individual/update
# Docs: /api/products/monitor/#watchlist_screeningindividualupdate
# operationId: watchlistScreeningIndividualUpdate
# --search_terms shape: {country?: string, date_of_birth?: string, document_number?: string, legal_name?: string, watchlist_program_id?: string}
export def "watchlist-screening-individual-update watch-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --assignee: string # ID of the associated user. (e.g. 54350110fedcbaf01234ffee)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --client-user-id: string # An identifier to help you connect this object to your internal systems. For example, your database ID corresponding to this object. (e.g. your-db-id-3b24110)
  --reset-fields: list # A list of fields to reset back to null (nullable)
  --search-terms: record # Search terms for editing an individual watchlist screening (nullable) — shape: {country?: string, date_of_birth?: string, document_number?: string, legal_name?: string, watchlist_program_id?: string}
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --status: string@status-completer # A status enum indicating whether a screening is still pending review, has been rejected, or has been cleared. (e.g. cleared)
  watchlist_screening_id: string # ID of the associated screening. (e.g. scr_52xR9LKo77r1Np)
]: any -> record<assignee: string, audit_trail: record<dashboard_user_id: string, source: string, timestamp: string>, client_user_id: string, id: string, request_id: string, search_terms: record<country: string, date_of_birth: string, document_number: string, legal_name: string, version: float, watchlist_program_id: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/individual/update")
  let body = {"assignee": $assignee, "client_id": $client_id, "client_user_id": $client_user_id, "reset_fields": $reset_fields, "search_terms": $search_terms, "secret": $secret, "status": $status, "watchlist_screening_id": $watchlist_screening_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get webhook verification key
#
# POST /webhook_verification_key/get
# Docs: /api/webhooks/webhook-verification/#get-webhook-verification-key
# operationId: webhookVerificationKeyGet
export def "webhook-verification-key-get webhookVerificationKeyGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  key_id: string # The key ID ( `kid` ) from the JWT header.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<key: record<alg: string, created_at: int, crv: string, expired_at: int, kid: string, kty: string, use: string, x: string, y: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhook_verification_key/get")
  let body = {"client_id": $client_id, "key_id": $key_id, "secret": $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
