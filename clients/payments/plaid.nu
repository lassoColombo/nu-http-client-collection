# Auto-generated client for The Plaid API v2020-09-14_1.697.4
# Source: https://raw.githubusercontent.com/plaid/plaid-openapi/master/2020-09-14.yml
# Auth: --token flag or $env.PLAID_ACCESS_TOKEN

const BASE_URL = "https://production.plaid.com"
const DEFAULT_AUTH = "plaid-client-id"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PLAID_ACCESS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "plaid-client-id" => { {headers: {PLAID-CLIENT-ID: $token_val}, query: ""} }
    "plaid-secret" => { {headers: {PLAID-SECRET: $token_val}, query: ""} }
    "plaid-version" => { {headers: {Plaid-Version: $token_val}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://production.plaid.com" "https://sandbox.plaid.com"] }
def auth-scheme-completer [] { ["plaid-client-id" "plaid-secret" "plaid-version"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/pdf"] }
def consumer-report-permissible-purpose-completer [] { ["ACCOUNT_REVIEW_CREDIT" "WRITTEN_INSTRUCTION_OTHER"] }
def user-tier-completer [] { ["free" "paid"] }
def consumer-report-permissible-purpose-completer-1 [] { ["ACCOUNT_REVIEW_CREDIT" "ACCOUNT_REVIEW_NON_CREDIT" "ELIGIBILITY_FOR_GOVT_BENEFITS" "EXTENSION_OF_CREDIT" "LEGITIMATE_BUSINESS_NEED_OTHER" "LEGITIMATE_BUSINESS_NEED_TENANT_SCREENING" "WRITTEN_INSTRUCTION_OTHER" "WRITTEN_INSTRUCTION_PREQUALIFICATION"] }
def report-type-completer [] { ["QUALIFY"] }
def inquiry-type-completer [] { ["SOFT_INQUIRY" "STANDARD_INQUIRY"] }
def version-completer [] { ["v1"] }
def grant-type-completer [] { ["client_credentials" "refresh_token" "urn:ietf:params:oauth:grant-type:token-exchange"] }
def subject-token-type-completer [] { ["urn:plaid:params:credit:multi-user" "urn:plaid:params:oauth:user-token" "urn:plaid:params:tokens:user"] }
def context-completer [] { ["ENROLLMENT" "PORTAL"] }
def reason-code-completer [] { ["CONNECTION_IS_NON_FUNCTIONAL" "FRAUD_ABUSE" "FRAUD_FALSE_IDENTITY" "FRAUD_FIRST_PARTY" "FRAUD_OTHER" "OTHER"] }
def webhook-type-completer [] { ["ASSETS" "AUTH" "HOLDINGS" "INVESTMENTS_TRANSACTIONS" "ITEM" "LIABILITIES" "TRANSACTIONS"] }
def webhook-code-completer [] { ["AUTHORIZATION_GRANTED" "DEFAULT_UPDATE" "ERROR" "LOGIN_REPAIRED" "NEW_ACCOUNTS_AVAILABLE" "PENDING_DISCONNECT" "PRODUCT_READY" "RECURRING_TRANSACTIONS_UPDATE" "SMS_MICRODEPOSITS_VERIFICATION" "SYNC_UPDATES_AVAILABLE" "USER_ACCOUNT_REVOKED" "USER_PERMISSION_REVOKED"] }
def strategy-completer [] { ["custom" "incomplete" "infer" "reset"] }
def status-completer [] { ["cleared" "pending_review" "rejected"] }
def evaluation-reason-completer [] { ["DORMANT_USER" "INFORMATION_CHANGE" "NEW_ACCOUNT" "ONBOARDING" "OTHER"] }
def type-completer [] { ["account_takeover" "data_breach" "first_party" "stolen" "synthetic" "unknown"] }
def report-confidence-completer [] { ["CONFIRMED" "SUSPECTED"] }
def report-type-completer-1 [] { ["ACH_RETURN" "BANK_ACCOUNT_TAKEOVER" "BANK_CONNECTION_REVOKED" "CARD_CHARGEBACK" "CARD_TESTING" "DISPUTE" "FALSE_IDENTITY" "FIRST_PARTY_FRAUD" "LOAN_STACKING" "MISSED_PAYMENT" "MONEY_LAUNDERING" "MULTIPLE_USER_ACCOUNTS" "NO_FRAUD" "OTHER" "SCAM_VICTIM" "STOLEN_IDENTITY" "SYNTHETIC_IDENTITY" "UNAUTHORIZED_TRANSACTION" "USER_ACCOUNT_TAKEOVER"] }
def report-source-completer [] { ["AUTOMATED_SYSTEM" "BANK_FEEDBACK" "INTERNAL_REVIEW" "NETWORK_FEEDBACK" "OTHER" "THIRD_PARTY_ALERT" "USER_SELF_REPORTED"] }
def decision-outcome-completer [] { ["APPROVE" "NOT_EVALUATED" "REJECT" "REVIEW" "TAKE_OTHER_RISK_MEASURES"] }
def payment-method-completer [] { ["MULTIPLE_PAYMENT_METHODS" "NEXT_DAY_ACH" "SAME_DAY_ACH" "STANDARD_ACH"] }
def type-completer-1 [] { ["credit" "debit"] }
def network-completer [] { ["ach" "same-day-ach" "wire"] }
def ach-class-completer [] { ["ccd" "ppd" "tel" "web"] }
def type-completer-2 [] { ["COMMERCIAL" "SWEEPING"] }
def processing-mode-completer [] { ["ASYNC" "IMMEDIATE"] }
def verification-status-completer [] { ["automatically_verified" "verification_expired"] }
def processor-completer [] { ["achq" "adp_roll" "adyen" "alloy" "alpaca" "ansa" "apex_clearing" "array" "astra" "atomic" "atomicfi" "bakkt" "bloom_credit" "bond" "boom" "brale" "cardless" "cardlytics" "check" "checkbook" "checkout" "circle" "curinos" "drivewealth" "dwolla" "esusu" "fiant" "finix" "fortress_trust" "frame" "gainbridge" "galileo" "gemini" "gusto" "highnote" "i2c" "interchange" "interchecks" "knot" "layer" "lithic" "loanpro" "marqeta" "modern_treasury" "moov" "nuvei" "oatfi" "ocrolus" "open_ledger" "parafin" "paynote" "pinwheel" "riskified" "rize" "sardine" "scribeup" "sfox" "sila_money" "solid" "stake" "straddle" "svb_api" "taba_pay" "teal" "thread_bank" "treasury_prime" "unit" "utb" "valon" "vesta" "vopay" "wedbush" "wepay" "wyre" "zero_hash"] }
def appearance-mode-completer [] { ["DARK" "LIGHT" "SYSTEM"] }
def network-completer-1 [] { ["ach" "rtp" "same-day-ach" "wire"] }
def type-completer-3 [] { ["prefunded_ach_credits" "prefunded_rtp_credits"] }
def network-completer-2 [] { ["ach" "same-day-ach"] }
def network-completer-3 [] { ["ach" "rtp" "same-day-ach"] }
def direction-completer [] { ["inbound" "outbound"] }
def reason-code-completer-1 [] { ["AC03" "AC14" "AM06" "AM09" "BE05" "CUST" "DUPL" "FOCR" "FRAD" "MS02" "MS03" "RR04" "RUTA" "TECH" "UPAY"] }
def transfer-type-completer [] { ["credit" "debit"] }
def source-type-completer [] { ["REFUND" "SWEEP" "TRANSFER"] }
def bank-transfer-type-completer [] { ["credit" "debit"] }
def status-completer-1 [] { ["failed" "funds_available" "pending" "posted" "returned" "settled"] }
def trigger-completer [] { ["automatic_aggregate" "balance_threshold" "incoming" "manual"] }
def mode-completer [] { ["DISBURSEMENT" "PAYMENT"] }
def purpose-completer [] { ["DUE_DILIGENCE"] }
def event-type-completer [] { ["sweep.failed" "sweep.posted" "sweep.returned" "sweep.settled"] }
def accept-completer-1 [] { ["application/json" "application/zip"] }
def report-type-completer-2 [] { ["asset"] }
def verification-status-completer-1 [] { ["VERIFICATION_STATUS_PENDING_APPROVAL" "VERIFICATION_STATUS_PROCESSING_COMPLETE" "VERIFICATION_STATUS_PROCESSING_FAILED"] }
def webhook-code-completer-1 [] { ["INCOME_VERIFICATION" "INCOME_VERIFICATION_RISK_SIGNALS"] }
def webhook-code-completer-2 [] { ["BANK_INCOME_REFRESH_COMPLETE" "BANK_INCOME_REFRESH_UPDATE"] }
def default-payment-method-completer [] { ["MULTIPLE_PAYMENT_METHODS" "SAME_DAY_ACH" "STANDARD_ACH"] }
def iso-currency-code-completer [] { ["EUR" "GBP"] }
def type-completer-4 [] { ["ACCOUNT_TAKEOVER" "ADDRESS_CHANGED" "BALANCE" "CONSENT_EXPIRED" "CONSENT_GRANTED" "CONSENT_REVOKED" "CONSENT_UPDATED" "CUSTOM" "MFA_TARGET_CHANGED" "PHONE_CHANGED" "PLANNED_OUTAGE" "RISK" "SERVICE" "SUSPECTED_INCIDENT" "TAN_ACTIVATED" "TAN_CREATED" "TAN_REVOKED" "TAN_SUSPENDED"] }
def category-completer [] { ["CONSENT" "FRAUD" "MAINTENANCE" "NEW_DATA" "SECURITY" "TOKENIZED_ACCOUNT_NUMBER"] }
def severity-completer [] { ["ALERT" "EMERGENCY" "INFO" "NOTICE" "WARNING"] }
def priority-completer [] { ["HIGH" "LOW" "MEDIUM"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "asset-report-create assetReportCreate" } } | get name | first)
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

# Create an Asset Report
#
# POST /asset_report/create
# Docs: /api/products/assets/#asset_reportcreate
# operationId: assetReportCreate
# --options shape: {client_report_id?: string, webhook?: string, include_fast_report?: bool, products?: list, add_ons?: list, user?: record, require_all_items?: bool}
export def "asset-report-create assetReportCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --access-tokens: list # An array of access tokens corresponding to the Items that will be included in the report. The `assets` product must have been initialized for the Items during link; the Assets product cannot be added after initialization.
  days_requested: int # The maximum integer number of days of history to include in the Asset Report. If using Fannie Mae Day 1 Certainty, `days_requested` must be at least 61 for new originations or at least 31 for refinancings.  An Asset Report requested with "Additional History" (that is, with more than 61 days of transaction history) will incur an Additional History fee.
  --options: record # An optional object to filter `/asset_report/create` results. If provided, must be non-`null`. The optional `user` object is required for the report to be eligible for Fannie Mae's Day 1 Certainty program. — shape: {client_report_id?: string, webhook?: string, include_fast_report?: bool, products?: list, add_ons?: list, user?: record, require_all_items?: bool}
]: any -> record<asset_report_token: string, asset_report_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset_report/create")
  let body = {client_id: $client_id, secret: $secret, access_tokens: $access_tokens, days_requested: $days_requested, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --asset-report-token: string # A token that can be provided to endpoints such as `/asset_report/get` or `/asset_report/pdf/get` to fetch or update an Asset Report.
  --user-token: string # The user token associated with the User for which to create an asset report for. The latest asset report associated with the User will be returned
  --include-insights: string@bool-completer # `true` if you would like to retrieve the Asset Report with Insights, `false` otherwise. This field defaults to `false` if omitted. (default: false)
  --fast-report: string@bool-completer # `true` to fetch "fast" version of asset report. Defaults to false if omitted. Can only be used if `/asset_report/create` was called with `options.add_ons` set to `["fast_assets"]`. (default: false)
  --options: record # An optional object to filter or add data to `/asset_report/get` results. If provided, must be non-`null`. — shape: {days_to_include?: int}
]: any -> record<report: record<asset_report_id: string, insights: record<risk: record, affordability: record>, client_report_id: string, date_generated: string, days_requested: float, user: record<client_user_id: string, first_name: string, middle_name: string, last_name: string, ssn: string, phone_number: string, email: string>, items: list<record>>, warnings: table<warning_type: string, warning_code: string, cause: record>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset_report/get")
  let body = {client_id: $client_id, secret: $secret, asset_report_token: $asset_report_token, user_token: $user_token, include_insights: $include_insights, fast_report: $fast_report, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --accept: string@accept-completer # Response content type
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  asset_report_token: string # A token that can be provided to endpoints such as `/asset_report/get` or `/asset_report/pdf/get` to fetch or update an Asset Report.
  --options: record # An optional object to filter or add data to `/asset_report/get` results. If provided, must be non-`null`. — shape: {days_to_include?: int}
]: any -> record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list<any>, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list<string>, provided_account_subtypes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset_report/pdf/get")
  let body = {client_id: $client_id, secret: $secret, asset_report_token: $asset_report_token, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Refresh an Asset Report
#
# POST /asset_report/refresh
# Docs: /api/products/assets/#asset_reportrefresh
# operationId: assetReportRefresh
# --options shape: {client_report_id?: string, webhook?: string, user?: record}
export def "asset-report-refresh assetReportRefresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  asset_report_token: string # The `asset_report_token` returned by the original call to `/asset_report/create`
  --days-requested: int # The maximum number of days of history to include in the Asset Report. Must be an integer. If not specified, the value from the original call to `/asset_report/create` will be used. (nullable)
  --options: record # An optional object to filter `/asset_report/refresh` results. If provided, cannot be `null`. If not specified, the `options` from the original call to `/asset_report/create` will be used. — shape: {client_report_id?: string, webhook?: string, user?: record}
]: any -> record<asset_report_id: string, asset_report_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset_report/refresh")
  let body = {client_id: $client_id, secret: $secret, asset_report_token: $asset_report_token, days_requested: $days_requested, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  asset_report_token: string # A token that can be provided to endpoints such as `/asset_report/get` or `/asset_report/pdf/get` to fetch or update an Asset Report.
  account_ids_to_exclude: list # The accounts to exclude from the Asset Report, identified by `account_id`.
]: any -> record<asset_report_token: string, asset_report_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset_report/filter")
  let body = {client_id: $client_id, secret: $secret, asset_report_token: $asset_report_token, account_ids_to_exclude: $account_ids_to_exclude} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  asset_report_token: string # A token that can be provided to endpoints such as `/asset_report/get` or `/asset_report/pdf/get` to fetch or update an Asset Report.
]: any -> record<removed: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset_report/remove")
  let body = {client_id: $client_id, secret: $secret, asset_report_token: $asset_report_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  asset_report_token: string # A token that can be provided to endpoints such as `/asset_report/get` or `/asset_report/pdf/get` to fetch or update an Asset Report.
  --auditor-id: string # The `auditor_id` of the third party with whom you would like to share the Asset Report.
]: any -> record<audit_copy_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset_report/audit_copy/create")
  let body = {client_id: $client_id, secret: $secret, asset_report_token: $asset_report_token, auditor_id: $auditor_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  audit_copy_token: string # The `audit_copy_token` granting access to the Audit Copy you would like to get.
]: any -> record<report: record<asset_report_id: string, insights: record<risk: record, affordability: record>, client_report_id: string, date_generated: string, days_requested: float, user: record<client_user_id: string, first_name: string, middle_name: string, last_name: string, ssn: string, phone_number: string, email: string>, items: list<record>>, warnings: table<warning_type: string, warning_code: string, cause: record>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset_report/audit_copy/get")
  let body = {client_id: $client_id, secret: $secret, audit_copy_token: $audit_copy_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a PDF Asset Report Audit Copy
#
# POST /asset_report/audit_copy/pdf/get
# Docs: /none/
# operationId: assetReportAuditCopyPdfGet
# --options shape: {days_to_include?: int}
export def "asset-report-audit-copy-pdf-get assetReportAuditCopyPdfGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  audit_copy_token: string # The `audit_copy_token` granting access to the Audit Copy you would like to get as a PDF.
  --options: record # An optional object to filter or add data to `/asset_report/get` results. If provided, must be non-`null`. — shape: {days_to_include?: int}
]: any -> record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list<any>, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list<string>, provided_account_subtypes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset_report/audit_copy/pdf/get")
  let body = {client_id: $client_id, secret: $secret, audit_copy_token: $audit_copy_token, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  audit_copy_token: string # The `audit_copy_token` granting access to the Audit Copy you would like to revoke.
]: any -> record<removed: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/asset_report/audit_copy/remove")
  let body = {client_id: $client_id, secret: $secret, audit_copy_token: $audit_copy_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Subscribe to Monitoring Insights
#
# POST /cra/monitoring_insights/subscribe
# Docs: /api/products/check/#cramonitoring_insightssubscribe
# operationId: craMonitoringInsightsSubscribe
export def "cra-monitoring-insights-subscribe craMonitoringInsightsSubscribe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --item-id: string # The Item ID to subscribe for Cash Flow Updates.
  webhook: string # URL to which Plaid will send Cash Flow Updates webhooks, for example when the requested Cash Flow Updates report is ready. (format: url)
  --income-categories: list # Income categories to include in Cash Flow Updates. If empty or `null`, this field will default to including all possible categories. (nullable)
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
]: any -> record<request_id: string, subscription_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cra/monitoring_insights/subscribe")
  let body = {client_id: $client_id, secret: $secret, user_id: $user_id, item_id: $item_id, webhook: $webhook, income_categories: $income_categories, user_token: $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unsubscribe from Monitoring Insights
#
# POST /cra/monitoring_insights/unsubscribe
# Docs: /api/products/check/#cramonitoring_insightsunsubscribe
# operationId: craMonitoringInsightsUnsubscribe
export def "cra-monitoring-insights-unsubscribe craMonitoringInsightsUnsubscribe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  subscription_id: string # A unique identifier for the subscription.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cra/monitoring_insights/unsubscribe")
  let body = {client_id: $client_id, secret: $secret, subscription_id: $subscription_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Monitoring Insights Report
#
# POST /cra/monitoring_insights/get
# Docs: /api/products/check/#cramonitoring_insightsget
# operationId: craMonitoringInsightsGet
export def "cra-monitoring-insights-get craMonitoringInsightsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  consumer_report_permissible_purpose: string@consumer-report-permissible-purpose-completer # Describes the reason you are generating a Consumer Report for this user.  `ACCOUNT_REVIEW_CREDIT`: In connection with a consumer credit transaction for the review or collection of an account pursuant to FCRA Section 604(a)(3)(A).  `WRITTEN_INSTRUCTION_OTHER`: In accordance with the written instructions of the consumer pursuant to FCRA Section 604(a)(2), such as when an individual agrees to act as a guarantor or assumes personal liability for a consumer, business, or commercial loan.
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
]: any -> record<request_id: string, user_insights_id: string, items: table<date_generated: string, item_id: string, institution_id: string, institution_name: string, status: record, insights: record, accounts: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cra/monitoring_insights/get")
  let body = {client_id: $client_id, secret: $secret, user_id: $user_id, consumer_report_permissible_purpose: $consumer_report_permissible_purpose, user_token: $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  audit_copy_token: string # The `audit_copy_token` you would like to update.
  report_tokens: list # Array of tokens which the specified Audit Copy Token will be updated with. The types of token supported are asset report token and employment report token. There can be at most 1 of each token type in the array.
]: any -> record<request_id: string, updated: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/audit_copy_token/update")
  let body = {client_id: $client_id, secret: $secret, audit_copy_token: $audit_copy_token, report_tokens: $report_tokens} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve cash flow insights from the bank accounts used for income verification
#
# POST /cra/partner_insights/get
# Docs: /api/products/income/#crapartner_insightsget
# operationId: craPartnerInsightsGet
export def "cra-partner-insights-get craPartnerInsightsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --user-tier: string@user-tier-completer # The tier of the user. (nullable)
]: any -> record<report: table<report_id: string, generated_time: string, client_report_id: string, fico: record, prism: record, items: list>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cra/partner_insights/get")
  let body = {client_id: $client_id, secret: $secret, user_token: $user_token, user_tier: $user_tier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve cash flow information from your user's banks
#
# POST /cra/check_report/income_insights/get
# Docs: /api/products/check/#cracheck_reportincome_insightsget
# operationId: craCheckReportIncomeInsightsGet
# --options shape: {income_insights_filter?: record, income_insights_version: "II2"}
export def "cra-check-report-income-insights-get craCheckReportIncomeInsightsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --third-party-user-token: string # The third-party user token associated with the requested User data.
  --user-id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --options: record # Defines configuration options to generate Income Insights. (nullable) — shape: {income_insights_filter?: record, income_insights_version: "II2"}
]: any -> record<report: record<report_id: string, generated_time: string, days_requested: int, client_report_id: string, items: list<record>, user_summary: record<income_metrics: list>, income_streams: list<record>, bank_income_summary: record<total_amounts: list, start_date: string, end_date: string, income_sources_count: int, income_categories_count: int, income_transactions_count: int, historical_average_monthly_gross_income: list, historical_average_monthly_income: list, forecasted_average_monthly_income: list, historical_annual_gross_income: list, historical_annual_income: list, forecasted_annual_income: list, historical_summary: list>, warnings: list<record>>, request_id: string, warnings: table<warning_type: string, warning_code: string, cause: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cra/check_report/income_insights/get")
  let body = {client_id: $client_id, secret: $secret, user_token: $user_token, third_party_user_token: $third_party_user_token, user_id: $user_id, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Base Report
#
# POST /cra/check_report/base_report/get
# Docs: /api/products/check/#cracheck_reportbase_reportget
# operationId: craCheckReportBaseReportGet
export def "cra-check-report-base-report-get craCheckReportBaseReportGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --third-party-user-token: string # The third-party user token associated with the requested User data.
  --item-ids: list # The Item IDs to include in the Base Report. If not provided, all Items associated with the user will be included. (nullable)
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --user-tier: string@user-tier-completer # The tier of the user. (nullable)
]: any -> record<report: record<report_id: string, date_generated: string, days_requested: float, client_report_id: string, items: list<record>, attributes: record<nsf_overdraft_transactions_count: int, nsf_overdraft_transactions_count_30d: int, nsf_overdraft_transactions_count_60d: int, nsf_overdraft_transactions_count_90d: int, total_inflow_amount: record, total_inflow_amount_30d: record, total_inflow_amount_60d: record, total_inflow_amount_90d: record, total_outflow_amount: record, total_outflow_amount_30d: record, total_outflow_amount_60d: record, total_outflow_amount_90d: record>>, warnings: table<warning_type: string, warning_code: string, cause: record>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cra/check_report/base_report/get")
  let body = {client_id: $client_id, secret: $secret, user_id: $user_id, third_party_user_token: $third_party_user_token, item_ids: $item_ids, user_token: $user_token, user_tier: $user_tier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Consumer Reports as a PDF
#
# POST /cra/check_report/pdf/get
# Docs: /api/products/check/#cracheck_reportpdfget
# operationId: craCheckReportPdfGet
export def "cra-check-report-pdf-get craCheckReportPdfGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --third-party-user-token: string # The third-party user token associated with the requested User data.
  --add-ons: list # Use this field to include other reports in the PDF.
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
]: any -> record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list<any>, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list<string>, provided_account_subtypes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cra/check_report/pdf/get")
  let body = {client_id: $client_id, secret: $secret, user_id: $user_id, third_party_user_token: $third_party_user_token, add_ons: $add_ons, user_token: $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Refresh or create a Consumer Report
#
# POST /cra/check_report/create
# Docs: /api/products/check/#cracheck_reportcreate
# operationId: craCheckReportCreate
# --base_report shape: {client_report_id?: string, gse_options?: record, require_identity?: bool, home_lending_report_options?: record}
# --cashflow_insights shape: {attributes_version?: "v1.0"|"v2.0"|"CFI1"}
# --partner_insights shape: {prism_versions?: record, fico?: record}
# --lend_score shape: {lend_score_version?: "v1.0"|"v2.0"|"LS1"}
# --network_insights shape: {network_insights_version?: "NI1"}
# --income_insights shape: {income_insights_filter?: record, income_insights_version: "II2"}
export def "cra-check-report-create craCheckReportCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  webhook: string # The destination URL to which webhooks will be sent  (format: url)
  days_requested: int # The number of days of data to request for the report. Default value is 365; maximum is 731; minimum is 180. If a value lower than 180 is provided, a minimum of 180 days of history will be requested.
  --days-required: int # The minimum number of days of data required for the report to be successfully generated.
  --client-report-id: string # Client-generated identifier, which can be used by lenders to track loan applications. (nullable)
  --products: list # Specifies a list of products that will be eagerly generated when creating the report (in addition to the Base Report, which is always eagerly generated). These products will be made available before a success webhook is sent. Use this option to minimize response latency for product `/get` endpoints. Note that specifying `cra_partner_insights` in this field will trigger a billable event. Other products are not billed until the respective reports are fetched via product-specific `/get` endpoints. (nullable)
  --base-report: record # Defines configuration options to generate a Base Report (nullable) — shape: {client_report_id?: string, gse_options?: record, require_identity?: bool, home_lending_report_options?: record}
  --cashflow-insights: record # Defines configuration options to generate Cashflow Insights (nullable) — shape: {attributes_version?: "v1.0"|"v2.0"|"CFI1"}
  --partner-insights: record # Defines configuration to generate Partner Insights. (nullable) — shape: {prism_versions?: record, fico?: record}
  --lend-score: record # Defines configuration options to generate the LendScore (nullable) — shape: {lend_score_version?: "v1.0"|"v2.0"|"LS1"}
  --network-insights: record # Defines configuration options to generate Network Insights (nullable) — shape: {network_insights_version?: "NI1"}
  --include-investments: string@bool-completer # Indicates that investment data should be extracted from the linked account(s). (nullable)
  --income-insights: record # Defines configuration options to generate Income Insights. (nullable) — shape: {income_insights_filter?: record, income_insights_version: "II2"}
  consumer_report_permissible_purpose: string@consumer-report-permissible-purpose-completer-1 # Describes the reason you are generating a Consumer Report for this user. When calling `/link/token/create`, this field is required when using Plaid Check (CRA) products; invalid if not using Plaid Check (CRA) products.  `ACCOUNT_REVIEW_CREDIT`: In connection with a consumer credit transaction for the review or collection of an account pursuant to FCRA Section 604(a)(3)(A).  `ACCOUNT_REVIEW_NON_CREDIT`: For a legitimate business need of the information to review a non-credit account provided primarily for personal, family, or household purposes to determine whether the consumer continues to meet the terms of the account pursuant to FCRA Section 604(a)(3)(F)(2).  `EXTENSION_OF_CREDIT`: In connection with a credit transaction initiated by and involving the consumer pursuant to FCRA Section 604(a)(3)(A).  `LEGITIMATE_BUSINESS_NEED_TENANT_SCREENING`: For a legitimate business need in connection with a business transaction initiated by the consumer primarily for personal, family, or household purposes in connection with a property rental assessment pursuant to FCRA Section 604(a)(3)(F)(i).  `LEGITIMATE_BUSINESS_NEED_OTHER`: For a legitimate business need in connection with a business transaction made primarily for personal, family, or household initiated by the consumer pursuant to FCRA Section 604(a)(3)(F)(i).  `WRITTEN_INSTRUCTION_PREQUALIFICATION`: In accordance with the written instructions of the consumer pursuant to FCRA Section 604(a)(2), to evaluate an application's profile to make an offer to the consumer.  `WRITTEN_INSTRUCTION_OTHER`: In accordance with the written instructions of the consumer pursuant to FCRA Section 604(a)(2), such as when an individual agrees to act as a guarantor or assumes personal liability for a consumer, business, or commercial loan.  `ELIGIBILITY_FOR_GOVT_BENEFITS`:  In connection with an eligibility determination for a government benefit where the entity is required to consider an applicant's financial status pursuant to FCRA Section 604(a)(3)(D).
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cra/check_report/create")
  let body = {client_id: $client_id, secret: $secret, user_id: $user_id, user_token: $user_token, webhook: $webhook, days_requested: $days_requested, days_required: $days_required, client_report_id: $client_report_id, products: $products, base_report: $base_report, cashflow_insights: $cashflow_insights, partner_insights: $partner_insights, lend_score: $lend_score, network_insights: $network_insights, include_investments: $include_investments, income_insights: $income_insights, consumer_report_permissible_purpose: $consumer_report_permissible_purpose} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve cash flow insights from partners
#
# POST /cra/check_report/partner_insights/get
# Docs: /api/products/check/#cracheck_reportpartner_insightsget
# operationId: craCheckReportPartnerInsightsGet
# --partner_insights shape: {prism_versions?: record, fico?: record}
# --options shape: {prism_versions?: record}
@deprecated --flag options
export def "cra-check-report-partner-insights-get craCheckReportPartnerInsightsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --third-party-user-token: string # The third-party user token associated with the requested User data.
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --user-tier: string@user-tier-completer # The tier of the user. (nullable)
  --partner-insights: record # Defines configuration to generate Partner Insights — shape: {prism_versions?: record, fico?: record}
  --options: record # Deprecated, specify `partner_insights.prism_versions` instead. (DEPRECATED, nullable) — shape: {prism_versions?: record}
]: any -> record<report: record<report_id: string, generated_time: string, client_report_id: string, fico: record<lender_application_id: string, ultrafico_score_results: list, report_characteristics: record>, prism: record<insights: record, cash_score: record, extend: record, first_detect: record, detect: record, status: string>, items: list<record>>, request_id: string, warnings: table<warning_type: string, warning_code: string, cause: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cra/check_report/partner_insights/get")
  let body = {client_id: $client_id, secret: $secret, user_id: $user_id, third_party_user_token: $third_party_user_token, user_token: $user_token, user_tier: $user_tier, partner_insights: $partner_insights, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve cash flow insights from your user's banking data
#
# POST /cra/check_report/cashflow_insights/get
# Docs: /api/products/check/#cracheck_reportcashflow_insightsget
# operationId: craCheckReportCashflowInsightsGet
# --options shape: {attributes_version?: "v1.0"|"v2.0"|"CFI1"}
export def "cra-check-report-cashflow-insights-get craCheckReportCashflowInsightsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --third-party-user-token: string # The third-party user token associated with the requested User data.
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --options: record # Defines configuration options to generate Cashflow Insights (nullable) — shape: {attributes_version?: "v1.0"|"v2.0"|"CFI1"}
]: any -> record<report: record<report_id: string, generated_time: string, attributes: record>, request_id: string, warnings: table<warning_type: string, warning_code: string, cause: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cra/check_report/cashflow_insights/get")
  let body = {client_id: $client_id, secret: $secret, user_id: $user_id, third_party_user_token: $third_party_user_token, user_token: $user_token, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the LendScore from your user's banking data
#
# POST /cra/check_report/lend_score/get
# Docs: /api/products/check/#cracheck_reportlend_scoreget
# operationId: craCheckReportLendScoreGet
# --options shape: {lend_score_version?: "v1.0"|"v2.0"|"LS1"}
export def "cra-check-report-lend-score-get craCheckReportLendScoreGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --third-party-user-token: string # The third-party user token associated with the requested User data.
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --options: record # Defines configuration options to generate the LendScore (nullable) — shape: {lend_score_version?: "v1.0"|"v2.0"|"LS1"}
]: any -> record<report: record<report_id: string, generated_time: string, lend_score: record<score: int, reason_codes: list, error_reason: string>>, request_id: string, warnings: table<warning_type: string, warning_code: string, cause: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cra/check_report/lend_score/get")
  let body = {client_id: $client_id, secret: $secret, user_id: $user_id, third_party_user_token: $third_party_user_token, user_token: $user_token, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve network attributes for the user
#
# POST /cra/check_report/network_insights/get
# Docs: /api/products/check/#cracheck_reportnetwork_insightsget
# operationId: craCheckReportNetworkInsightsGet
# --options shape: {network_insights_version?: "NI1"}
export def "cra-check-report-network-insights-get craCheckReportNetworkInsightsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --options: record # Defines configuration options to generate Network Insights (nullable) — shape: {network_insights_version?: "NI1"}
  --third-party-user-token: string # The third-party user token associated with the requested User data.
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
]: any -> record<report: record<report_id: string, generated_time: string, network_attributes: record, items: list<record>>, request_id: string, warnings: table<warning_type: string, warning_code: string, cause: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cra/check_report/network_insights/get")
  let body = {client_id: $client_id, secret: $secret, user_id: $user_id, options: $options, third_party_user_token: $third_party_user_token, user_token: $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve various home lending reports for a user
#
# POST /cra/check_report/verification/get
# Docs: /api/products/check/#cracheck_reportverificationget
# operationId: craCheckReportVerificationGet
# --employment_refresh_options shape: {days_requested: int}
export def "cra-check-report-verification-get craCheckReportVerificationGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  reports_requested: list # Specifies which types of home lending reports are expected in the response
  --employment-refresh-options: record # Defines configuration options for the Employment Refresh Report. (nullable) — shape: {days_requested: int}
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
]: any -> record<report: record<report_id: string, gse_reference_id: string, client_report_id: string, voa: record<generated_time: string, days_requested: float, items: list, attributes: record>, employment_refresh: record<generated_time: string, days_requested: float, items: list>, income: record<generated_time: string, days_requested: int, user_summary: record, income_streams: list, items: list>>, request_id: string, warnings: table<warning_type: string, warning_code: string, cause: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cra/check_report/verification/get")
  let body = {client_id: $client_id, secret: $secret, user_id: $user_id, reports_requested: $reports_requested, employment_refresh_options: $employment_refresh_options, user_token: $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Consumer Reports as a Verification PDF
#
# POST /cra/check_report/verification/pdf/get
# Docs: /api/products/check/#cracheck_reportverificationpdfget
# operationId: craCheckReportVerificationPdfGet
@deprecated --flag report-requested
export def "cra-check-report-verification-pdf-get craCheckReportVerificationPdfGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --third-party-user-token: string # The third-party user token associated with the requested User data.
  --report-requested: any # DEPRECATED
  --reports-requested: list # Specifies which types of verification reports to include in the returned PDF. Supported combinations are: `[voa]`, `[employment_refresh]`, `[income]`, or `[voa, income]`. Other combinations are not supported.
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
]: any -> record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list<any>, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list<string>, provided_account_subtypes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cra/check_report/verification/pdf/get")
  let body = {client_id: $client_id, secret: $secret, user_id: $user_id, third_party_user_token: $third_party_user_token, report_requested: $report_requested, reports_requested: $reports_requested, user_token: $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Register loan applications and decisions
#
# POST /cra/loans/applications/register
# Docs: /none/
# operationId: craLoansApplicationsRegister
# --applications item shape: {user_token: string, application_id: string, type: "PERSONAL"|"CREDIT_CARD"|"BUSINESS"|"MORTGAGE"|"AUTO"|"PAYDAY"|"STUDENT"|"HOME_EQUITY"|"OTHER", decision: "APPROVED"|"DECLINED"|"OTHER", application_date?: string, decision_date?: string}
export def "cra-loans-applications-register craLoansApplicationsRegister" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  applications: list # A list of loan applications to register. — item shape: {user_token: string, application_id: string, type: "PERSONAL"|"CREDIT_CARD"|"BUSINESS"|"MORTGAGE"|"AUTO"|"PAYDAY"|"STUDENT"|"HOME_EQUITY"|"OTHER", decision: "APPROVED"|"DECLINED"|"OTHER", application_date?: string, decision_date?: string}
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cra/loans/applications/register")
  let body = {client_id: $client_id, secret: $secret, applications: $applications} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Register a list of loans to their applicants
#
# POST /cra/loans/register
# Docs: /none/
# operationId: craLoansRegister
# --loans item shape: {user_token: string, loan_id: string, type: "PERSONAL"|"CREDIT_CARD"|"BUSINESS"|"MORTGAGE"|"AUTO"|"PAYDAY"|"STUDENT"|"HOME_EQUITY"|"OTHER", payment_schedule: "DAILY"|"WEEKLY"|"BIWEEKLY"|"MONTHLY"|"QUARTERLY"|"ANNUALLY"|"OTHER", opened_date: string, opened_with_status: record, loan_amount?: float, application?: record}
export def "cra-loans-register craLoansRegister" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  loans: list # A list of loans to register. — item shape: {user_token: string, loan_id: string, type: "PERSONAL"|"CREDIT_CARD"|"BUSINESS"|"MORTGAGE"|"AUTO"|"PAYDAY"|"STUDENT"|"HOME_EQUITY"|"OTHER", payment_schedule: "DAILY"|"WEEKLY"|"BIWEEKLY"|"MONTHLY"|"QUARTERLY"|"ANNUALLY"|"OTHER", opened_date: string, opened_with_status: record, loan_amount?: float, application?: record}
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cra/loans/register")
  let body = {client_id: $client_id, secret: $secret, loans: $loans} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update loan data
#
# POST /cra/loans/update
# Docs: /none/
# operationId: craLoansUpdate
# --loans item shape: {loan_id?: string, status_history?: list, payment_history?: list}
export def "cra-loans-update craLoansUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  loans: list # A list of loans to update. — item shape: {loan_id?: string, status_history?: list, payment_history?: list}
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cra/loans/update")
  let body = {client_id: $client_id, secret: $secret, loans: $loans} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unregister a list of loans
#
# POST /cra/loans/unregister
# Docs: /none/
# operationId: craLoansUnregister
# --loans item shape: {loan_id: string, closed_with_status: record}
export def "cra-loans-unregister craLoansUnregister" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  loans: list # A list of loans to unregister. — item shape: {loan_id: string, closed_with_status: record}
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cra/loans/unregister")
  let body = {client_id: $client_id, secret: $secret, loans: $loans} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the credit profile report for a user
#
# POST /cra/credit_profile/report/get
# Docs: /none/
# operationId: craCreditProfileReportGet
export def "cra-credit-profile-report-get craCreditProfileReportGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  consumer_report_permissible_purpose: string@consumer-report-permissible-purpose-completer-1 # Describes the reason you are generating a Consumer Report for this user. When calling `/link/token/create`, this field is required when using Plaid Check (CRA) products; invalid if not using Plaid Check (CRA) products.  `ACCOUNT_REVIEW_CREDIT`: In connection with a consumer credit transaction for the review or collection of an account pursuant to FCRA Section 604(a)(3)(A).  `ACCOUNT_REVIEW_NON_CREDIT`: For a legitimate business need of the information to review a non-credit account provided primarily for personal, family, or household purposes to determine whether the consumer continues to meet the terms of the account pursuant to FCRA Section 604(a)(3)(F)(2).  `EXTENSION_OF_CREDIT`: In connection with a credit transaction initiated by and involving the consumer pursuant to FCRA Section 604(a)(3)(A).  `LEGITIMATE_BUSINESS_NEED_TENANT_SCREENING`: For a legitimate business need in connection with a business transaction initiated by the consumer primarily for personal, family, or household purposes in connection with a property rental assessment pursuant to FCRA Section 604(a)(3)(F)(i).  `LEGITIMATE_BUSINESS_NEED_OTHER`: For a legitimate business need in connection with a business transaction made primarily for personal, family, or household initiated by the consumer pursuant to FCRA Section 604(a)(3)(F)(i).  `WRITTEN_INSTRUCTION_PREQUALIFICATION`: In accordance with the written instructions of the consumer pursuant to FCRA Section 604(a)(2), to evaluate an application's profile to make an offer to the consumer.  `WRITTEN_INSTRUCTION_OTHER`: In accordance with the written instructions of the consumer pursuant to FCRA Section 604(a)(2), such as when an individual agrees to act as a guarantor or assumes personal liability for a consumer, business, or commercial loan.  `ELIGIBILITY_FOR_GOVT_BENEFITS`:  In connection with an eligibility determination for a government benefit where the entity is required to consider an applicant's financial status pursuant to FCRA Section 604(a)(3)(D).
  client_report_id: string # Client-generated identifier, which can be used by lenders to track loan applications.
  report_type: string@report-type-completer # The product type for the credit profile report request.
  inquiry_type: string@inquiry-type-completer # The inquiry type of credit profile report.
  version: string@version-completer # The version of the credit profile report to retrieve.
]: any -> record<report: record<date_retrieved: string, inquiry_type: string, client_report_id: string, lend_scores: list<record>, cashflow_insights_attributes: record, network_insights_attributes: record, metadata: record<item_count: int, institution_ids: list, account_count: int, primary_account_count: int, depository_account_type_count: int, credit_account_type_count: int, other_account_type_count: int, multiple_owner_account_count: int, generated_at: string, oldest_transaction_date: string, most_recent_transaction_date: string>>, request_id: string, user_id: string, warnings: table<warning_type: string, warning_code: string, cause: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cra/credit_profile/report/get")
  let body = {client_id: $client_id, secret: $secret, user_id: $user_id, consumer_report_permissible_purpose: $consumer_report_permissible_purpose, client_report_id: $client_report_id, report_type: $report_type, inquiry_type: $inquiry_type, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve PDF Reports
#
# POST /consumer_report/pdf/get
# Docs: /none/
# operationId: consumerReportPdfGet
export def "consumer-report-pdf-get consumerReportPdfGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
]: any -> record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list<any>, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list<string>, provided_account_subtypes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/consumer_report/pdf/get")
  let body = {client_id: $client_id, secret: $secret, user_token: $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create or refresh an OAuth access token
#
# POST /oauth/token
# Docs: /api/oauth/#oauthtoken
# operationId: oauthToken
export def "oauth-token oauthToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  grant_type: string@grant-type-completer # The type of OAuth grant being requested:  `client_credentials` allows exchanging a client id and client secret for a refresh and access token. `refresh_token` allows refreshing an access token using a refresh token. When using this grant type, only the `refresh_token` field is required (along with the `client_id` and `client_secret`). `urn:ietf:params:oauth:grant-type:token-exchange` allows exchanging a subject token for an OAuth token. When using this grant type, the `audience`, `subject_token` and `subject_token_type` fields are required. These grants are defined in their respective RFCs. `refresh_token` and `client_credentials` are defined in RFC 6749 and `urn:ietf:params:oauth:grant-type:token-exchange` is defined in RFC 8693.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --client-secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body as either `secret` or `client_secret`.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body as either `secret` or `client_secret`.
  --scope: string # A JSON string containing a space-separated list of scopes associated with this token, in the format described in [https://datatracker.ietf.org/doc/html/rfc6749#section-3.3](https://datatracker.ietf.org/doc/html/rfc6749#section-3.3). Currently accepted values are:  `user:read` allows reading user data. `user:write` allows writing user data. `exchange` allows exchanging a token using the `urn:plaid:params:oauth:user-token` grant type. `mcp:dashboard` allows access to the MCP dashboard server. (e.g. user:read user:write exchange)
  --refresh-token: string # Refresh token for OAuth
  --resource: string # URI of the target resource server (e.g. https://production.plaid.com)
  --audience: string # Used when exchanging a token. The meaning depends on the `subject_token_type`:  - For `urn:plaid:params:tokens:user`: Must be the same as the `client_id`. - For `urn:plaid:params:oauth:user-token`: The other `client_id` to exchange tokens to. - For `urn:plaid:params:credit:multi-user`:  a `client_id` or one of the supported CRA partner URNs: `urn:plaid:params:cra-partner:experian`, `urn:plaid:params:cra-partner:fannie-mae`, or `urn:plaid:params:cra-partner:freddie-mac`. (e.g. 68028ce48d2b0dec68747f6c)
  --subject-token: string # Token representing the subject. The meaning depends on the `subject_token_type`. For `urn:plaid:params:tokens:user`, the `subject_token` must be a Plaid-issued user token from the `/user/create` endpoint. For `urn:plaid:params:oauth:user-token`, the `subject_token` must be an OAuth refresh token issued from the `/oauth/token` endpoint. (e.g. user-sandbox-b0e2c4ee-a763-4df5-bfe9-46a46bce993d)
  --subject-token-type: string@subject-token-type-completer # The type of the subject token. `urn:plaid:params:tokens:user` allows exchanging a Plaid-issued user token for an OAuth token. When using this token type, `audience` must be the same as the `client_id`. `subject_token` must be a Plaid-issued user token issued from the `/user/create` endpoint. `urn:plaid:params:oauth:user-token` allows exchanging a refresh token for an OAuth token to another `client_id`. The other `client_id` is provided in `audience`. `subject_token` must be an OAuth refresh token issued from the `/oauth/token` endpoint. `urn:plaid:params:credit:multi-user` allows exchanging a Plaid-issued user token for an OAuth token. When using this token type, `audience` may be a client id or a supported CRA partner URN. `audience` supports a comma-delimited list of clients. When multiple clients are specified in the `audience` a multi-party token is created which can be used by all parties in the audience in conjunction with their `client_id` and `client_secret`.
]: any -> record<access_token: string, refresh_token: string, token_type: string, expires_in: int, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/token")
  let body = {grant_type: $grant_type, client_id: $client_id, client_secret: $client_secret, secret: $secret, scope: $scope, refresh_token: $refresh_token, resource: $resource, audience: $audience, subject_token: $subject_token, subject_token_type: $subject_token_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get metadata about an OAuth token
#
# POST /oauth/introspect
# Docs: /api/oauth/#oauthintrospect
# operationId: oauthIntrospect
export def "oauth-introspect oauthIntrospect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # An OAuth token of any type (`refresh_token`, `access_token`, etc)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --client-secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body as either `secret` or `client_secret`.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body as either `secret` or `client_secret`.
]: any -> record<active: bool, scope: string, client_id: string, exp: int, iat: int, sub: string, aud: string, iss: string, token_type: string, user_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/introspect")
  let body = {token: $body_token, client_id: $client_id, client_secret: $client_secret, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke an OAuth token
#
# POST /oauth/revoke
# Docs: /api/oauth/#oauthrevoke
# operationId: oauthRevoke
export def "oauth-revoke oauthRevoke" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # An OAuth token of any type (`refresh_token`, `access_token`, etc)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --client-secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body as either `secret` or `client_secret`.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body as either `secret` or `client_secret`.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/revoke")
  let body = {token: $body_token, client_id: $client_id, client_secret: $client_secret, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a list of all statements associated with an Item.
#
# POST /statements/list
# Docs: /api/products/statements#statementslist
# operationId: statementsList
export def "statements-list statementsList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  access_token: string # The access token associated with the Item for which data is being requested.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<accounts: table<account_id: string, account_mask: string, account_name: string, account_official_name: string, account_subtype: string, account_type: string, statements: list>, institution_id: string, institution_name: string, item_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/statements/list")
  let body = {access_token: $access_token, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a single statement.
#
# POST /statements/download
# Docs: /api/products/statements#statementsdownload
# operationId: statementsDownload
export def "statements-download statementsDownload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  access_token: string # The access token associated with the Item for which data is being requested.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  statement_id: string # Plaid's unique identifier for the statement.
]: any -> record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list<any>, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list<string>, provided_account_subtypes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/statements/download")
  let body = {access_token: $access_token, client_id: $client_id, secret: $secret, statement_id: $statement_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Refresh statements data.
#
# POST /statements/refresh
# Docs: /api/products/statements#statementsrefresh
# operationId: statementsRefresh
export def "statements-refresh statementsRefresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  access_token: string # The access token associated with the Item for which data is being requested.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  start_date: string # The start date for statements, in "YYYY-MM-DD" format, e.g. "2023-08-30". To determine whether a statement falls within the specified date range, Plaid will use the statement posted date. The statement posted date is typically either the last day of the statement period, or the following day. (format: date)
  end_date: string # The end date for statements, in "YYYY-MM-DD" format, e.g. "2023-10-30". You can request up to two years of data. To determine whether a statement falls within the specified date range, Plaid will use the statement posted date. The statement posted date is typically either the last day of the statement period, or the following day. (format: date)
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/statements/refresh")
  let body = {access_token: $access_token, client_id: $client_id, secret: $secret, start_date: $start_date, end_date: $end_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a historical log of item consent events
#
# POST /consent/events/get
# Docs: /api/consent/#consenteventsget
# operationId: consentEventsGet
export def "consent-events-get consentEventsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
]: any -> record<request_id: string, consent_events: table<item_id: string, created_at: string, event_type: string, event_code: string, institution_id: string, institution_name: string, initiator: string, consented_use_cases: list, consented_data_scopes: list, consented_accounts: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/consent/events/get")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --access-token: string # The access token associated with the Item for which data is being requested.
  --cursor: string # Cursor used for pagination.
  --count: int # default: 50
]: any -> record<request_id: string, activities: table<activity: string, initiated_date: string, id: string, initiator: string, state: string, target_application_id: string, scopes: record, authentication: string>, last_data_access_times: table<application_id: string, account_balance_info: string, account_routing_number: string, contact_details: string, transactions: string, credit_and_loans: string, investments: string, payroll_info: string, transaction_risk_info: string>, cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/activity/list")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, cursor: $cursor, count: $count} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a user's connected applications
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --access-token: string # The access token associated with the Item for which data is being requested. (nullable)
]: any -> record<request_id: string, applications: table<application_id: string, name: string, display_name: string, logo_url: string, application_url: string, reason_for_access: string, created_at: string, scopes: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/application/list")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unlink a user's connected application
#
# POST /item/application/unlink
# Docs: none
# operationId: itemApplicationUnlink
export def "item-application-unlink itemApplicationUnlink" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  application_id: string # This field will map to the application ID that is returned from `/item/application/list`, or provided to the institution in an oauth redirect.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/application/unlink")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, application_id: $application_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the scopes of access for a particular application
#
# POST /item/application/scopes/update
# operationId: itemApplicationScopesUpdate
# --scopes shape: {product_access?: record, accounts?: list, new_accounts?: bool}
export def "item-application-scopes-update itemApplicationScopesUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  application_id: string # This field will map to the application ID that is returned from `/item/application/list`, or provided to the institution in an oauth redirect.
  scopes: record # The scopes object — shape: {product_access?: record, accounts?: list, new_accounts?: bool}
  --state: string # When scopes are updated during enrollment, this field must be populated with the state sent to the partner in the OAuth Login URI. This field is required when the context is `ENROLLMENT`.
  context: string@context-completer # An indicator for when scopes are being updated. When scopes are updated via enrollment (i.e. OAuth), the partner must send `ENROLLMENT`. When scopes are updated in a post-enrollment view, the partner must send `PORTAL`.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/application/scopes/update")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, application_id: $application_id, scopes: $scopes, state: $state, context: $context} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  client_id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  application_id: string # This field will map to the application ID that is returned from `/item/application/list`, or provided to the institution in an oauth redirect.
]: any -> record<request_id: string, application: record<application_id: string, name: string, display_name: string, join_date: string, logo_url: string, application_url: string, reason_for_access: string, use_case: string, company_legal_name: string, city: string, region: string, postal_code: string, country_code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/application/get")
  let body = {client_id: $client_id, secret: $secret, application_id: $application_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
]: any -> record<item: record, status: record<investments: record<last_successful_update: string, last_failed_update: string>, transactions: record<last_successful_update: string, last_failed_update: string>, last_webhook: record<sent_at: string, code_sent: string>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/get")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve User Account
#
# POST /user_account/session/get
# Docs: /api/products/layer/#user_accountsessionget
# operationId: userAccountSessionGet
export def "user-account-session-get userAccountSessionGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  public_token: string # The public token generated by the end user Layer session.
]: any -> record<identity: record<name: record<first_name: string, last_name: string>, address: record<city: string, region: string, street: string, street2: string, postal_code: string, country: string>, phone_number: string, email: string, date_of_birth: string, ssn: string, ssn_last_4: string>, items: table<item_id: string, access_token: string>, identity_edit_history: record<name: record<edits_current: int, edits_1d: int, edits_30d: int, edits_365d: int, edits_all_time: int>, address: record<edits_current: int, edits_1d: int, edits_30d: int, edits_365d: int, edits_all_time: int>, email: record<edits_current: int, edits_1d: int, edits_30d: int, edits_365d: int, edits_all_time: int>, date_of_birth: record<edits_current: int, edits_1d: int, edits_30d: int, edits_365d: int, edits_all_time: int>, official_document: record<ssn: record>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_account/session/get")
  let body = {client_id: $client_id, secret: $secret, public_token: $public_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send User Account Session Event
#
# POST /user_account/session/event/send
# Docs: /api/products/layer/#user_accountsessioneventsend
# operationId: userAccountSessionEventSend
# --event shape: {name: string, timestamp: string, outcome?: string}
export def "user-account-session-event-send userAccountSessionEventSend" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --cohort-id: string # Optional cohort identifier for the user session.
  link_session_id: string # The Link session identifier.
  event: record # Event data for user account session tracking — shape: {name: string, timestamp: string, outcome?: string}
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user_account/session/event/send")
  let body = {client_id: $client_id, secret: $secret, cohort_id: $cohort_id, link_session_id: $link_session_id, event: $event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check a user's Plaid Network status
#
# POST /profile/network_status/get
# Docs: /api/profile/#networkstatusget
# operationId: profileNetworkStatusGet
# --user shape: {phone_number: string}
export def "profile-network-status-get profileNetworkStatusGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user: record # An object specifying information about the end user for the network status check. — shape: {phone_number: string}
]: any -> record<network_status: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile/network_status/get")
  let body = {client_id: $client_id, secret: $secret, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check a user's Plaid Network status
#
# POST /network/status/get
# Docs: /api/network/#networkstatusget
# operationId: networkStatusGet
# --user shape: {phone_number: string}
export def "network-status-get networkStatusGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user: record # An object specifying information about the end user for the network status check. — shape: {phone_number: string}
  --template-id: string # The id of a template defined in Plaid Dashboard. This field is used if you have additional criteria that you want to check against (e.g. Layer eligibility).
]: any -> record<network_status: string, layer: record<eligible: bool>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/network/status/get")
  let body = {client_id: $client_id, secret: $secret, user: $user, template_id: $template_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  --options: record # An optional object to filter `/auth/get` results. — shape: {account_ids?: list}
]: any -> record<accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record, persistent_account_id: string, holder_category: string>, numbers: record<ach: list<record>, eft: list<record>, international: list<record>, bacs: list<record>>, item: record<item_id: string, institution_id: string, institution_name: string, webhook: string, auth_method: string, error: record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list, provided_account_subtypes: list>, available_products: list<string>, billed_products: list<string>, products: list<string>, consented_products: list<string>, consent_expiration_time: string, update_type: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/get")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Verify auth data
#
# POST /auth/verify
# Docs: /api/products/auth/#authverify
# operationId: authVerify
# --numbers shape: {ach: record}
export def "auth-verify authVerify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --legal-name: string # Account owner's legal name (nullable)
  numbers: record # An object containing identifying account numbers for verification via Database Auth — shape: {ach: record}
]: any -> record<request_id: string, item_id: string, verification_status: string, verification_insights: record<name_match_score: int, network_status: record<has_numbers_match: bool, is_numbers_match_verified: bool>, previous_returns: record<has_previous_administrative_return: bool>, account_number_format: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/verify")
  let body = {client_id: $client_id, secret: $secret, legal_name: $legal_name, numbers: $numbers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get transaction data
#
# POST /transactions/get
# Docs: /api/products/transactions/#transactionsget
# operationId: transactionsGet
# --options shape: {account_ids?: list, count?: int, offset?: int, include_original_description?: bool, include_personal_finance_category_beta?: bool, include_personal_finance_category?: bool, include_logo_and_counterparty_beta?: bool, personal_finance_category_version?: "v1"|"v2", days_requested?: int}
export def "transactions-get transactionsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --options: record # An optional object to be used with the request. If specified, `options` must not be `null`. — shape: {account_ids?: list, count?: int, offset?: int, include_original_description?: bool, include_personal_finance_category_beta?: bool, include_personal_finance_category?: bool, include_logo_and_counterparty_beta?: bool, personal_finance_category_version?: "v1"|"v2", days_requested?: int}
  access_token: string # The access token associated with the Item for which data is being requested.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  start_date: string # The earliest date for which data should be returned. Dates should be formatted as YYYY-MM-DD. (format: date)
  end_date: string # The latest date for which data should be returned. Dates should be formatted as YYYY-MM-DD. (format: date)
]: any -> record<accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record, persistent_account_id: string, holder_category: string>, transactions: table<account_id: string, amount: float, iso_currency_code: string, unofficial_currency_code: string, category: list, category_id: string, check_number: string, date: string, location: record, name: string, merchant_name: string, original_description: string, payment_meta: record, pending: bool, pending_transaction_id: string, account_owner: string, transaction_id: string, transaction_type: string, logo_url: string, website: string, authorized_date: string, authorized_datetime: string, datetime: string, payment_channel: string, personal_finance_category: record, business_finance_category: record, transaction_code: string, personal_finance_category_icon_url: string, counterparties: list, merchant_entity_id: string, client_customization: record>, total_transactions: int, item: record<item_id: string, institution_id: string, institution_name: string, webhook: string, auth_method: string, error: record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list, provided_account_subtypes: list>, available_products: list<string>, billed_products: list<string>, products: list<string>, consented_products: list<string>, consent_expiration_time: string, update_type: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactions/get")
  let body = {client_id: $client_id, options: $options, access_token: $access_token, secret: $secret, start_date: $start_date, end_date: $end_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactions/refresh")
  let body = {client_id: $client_id, access_token: $access_token, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create sandbox transactions
#
# POST /sandbox/transactions/create
# Docs: /api/sandbox/#sandboxtransactionscreate
# operationId: sandboxTransactionsCreate
# --transactions item shape: {date_transacted: string, date_posted: string, amount: float, description: string, iso_currency_code?: string}
export def "sandbox-transactions-create sandboxTransactionsCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  transactions: list # List of transactions to be added — item shape: {date_transacted: string, date_posted: string, amount: float, description: string, iso_currency_code?: string}
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/transactions/create")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, transactions: $transactions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Refresh transaction data in `cashflow_report`
#
# POST /cashflow_report/refresh
# Docs: /api/products/transactions/#cashflowReportRefresh
# operationId: cashflowReportRefresh
export def "cashflow-report-refresh cashflowReportRefresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  days_requested: int # Number of days to retrieve transactions data for (1 to 730) (default: 365)
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cashflow_report/refresh")
  let body = {client_id: $client_id, access_token: $access_token, secret: $secret, days_requested: $days_requested} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets transaction data in `cashflow_report`
#
# POST /cashflow_report/get
# Docs: /api/products/transactions/#cashflowReportGet
# operationId: cashflowReportGet
# --options shape: {account_ids?: list}
export def "cashflow-report-get cashflowReportGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  days_requested: int # Number of days to retrieve transactions data for (1 to 730)
  --count: int # Number of transactions to fetch per call (default: 100)
  --cursor: string # The cursor value represents the last update requested. Pass in the empty string "" in the first call.
  --options: record # An optional object to be used with the request. If specified, `options` must not be `null`. — shape: {account_ids?: list}
]: any -> record<accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record, persistent_account_id: string, holder_category: string, owners: list>, transactions: table<account_id: string, amount: float, iso_currency_code: string, unofficial_currency_code: string, check_number: string, date: string, location: record, name: string, merchant_name: string, original_description: string, payment_meta: record, pending: bool, pending_transaction_id: string, account_owner: string, transaction_id: string, logo_url: string, website: string, authorized_date: string, authorized_datetime: string, datetime: string, payment_channel: string, personal_finance_category: record, business_finance_category: record, credit_category: record, transaction_code: string, personal_finance_category_icon_url: string, counterparties: list, merchant_entity_id: string>, total_transactions: int, item: record<item_id: string, institution_id: string, institution_name: string, webhook: string, auth_method: string, error: record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list, provided_account_subtypes: list>, available_products: list<string>, billed_products: list<string>, products: list<string>, consented_products: list<string>, consent_expiration_time: string, update_type: string>, next_cursor: string, has_more: bool, last_successful_update_time: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cashflow_report/get")
  let body = {client_id: $client_id, access_token: $access_token, secret: $secret, days_requested: $days_requested, count: $count, cursor: $cursor, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets transaction data in `cashflow_report`
#
# POST /cashflow_report/transactions/get
# Docs: /api/products/transactions/#cashflowReportTransactionsGet
# operationId: cashflowReportTransactionsGet
# --options shape: {account_ids?: list}
export def "cashflow-report-transactions-get cashflowReportTransactionsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --count: int # Number of transactions to fetch per call (default: 100)
  --cursor: string # The cursor value represents the last update requested. Pass in the empty string "" in the first call.
  --options: record # An optional object to be used with the request. If specified, `options` must not be `null`. — shape: {account_ids?: list}
]: any -> record<accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record, persistent_account_id: string, holder_category: string, owners: list>, transactions: table<account_id: string, amount: float, iso_currency_code: string, unofficial_currency_code: string, check_number: string, date: string, location: record, name: string, merchant_name: string, original_description: string, payment_meta: record, pending: bool, pending_transaction_id: string, account_owner: string, transaction_id: string, logo_url: string, website: string, authorized_date: string, authorized_datetime: string, datetime: string, payment_channel: string, personal_finance_category: record, business_finance_category: record, credit_category: record, transaction_code: string, personal_finance_category_icon_url: string, counterparties: list, merchant_entity_id: string>, total_transactions: int, item: record<item_id: string, institution_id: string, institution_name: string, webhook: string, auth_method: string, error: record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list, provided_account_subtypes: list>, available_products: list<string>, billed_products: list<string>, products: list<string>, consented_products: list<string>, consent_expiration_time: string, update_type: string>, next_cursor: string, has_more: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cashflow_report/transactions/get")
  let body = {client_id: $client_id, access_token: $access_token, secret: $secret, count: $count, cursor: $cursor, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets insights data in Cashflow Report
#
# POST /cashflow_report/insights/get
# Docs: /api/products/transactions/#cashflowReportInsightsGet
# operationId: cashflowReportInsightsGet
export def "cashflow-report-insights-get cashflowReportInsightsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<item: record<item_id: string, institution_id: string, institution_name: string, webhook: string, auth_method: string, error: record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list, provided_account_subtypes: list>, available_products: list<string>, billed_products: list<string>, products: list<string>, consented_products: list<string>, consent_expiration_time: string, update_type: string>, accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record, persistent_account_id: string, holder_category: string, owners: list>, account_insights: record<historical_balances: list<record>, monthly_summaries: list<record>>, last_generated_time: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cashflow_report/insights/get")
  let body = {client_id: $client_id, access_token: $access_token, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch recurring transaction streams
#
# POST /transactions/recurring/get
# Docs: /api/products/transactions/#transactionsrecurringget
# operationId: transactionsRecurringGet
# --options shape: {include_personal_finance_category?: bool, personal_finance_category_version?: "v1"|"v2"}
export def "transactions-recurring-get transactionsRecurringGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --options: record # An optional object to be used with the request. If specified, `options` must not be `null`. — shape: {include_personal_finance_category?: bool, personal_finance_category_version?: "v1"|"v2"}
  --account-ids: list # An optional list of `account_ids` to retrieve for the Item. Retrieves all active accounts on item if no `account_id`s are provided.  Note: An error will be returned if a provided `account_id` is not associated with the Item.
]: any -> record<inflow_streams: table<account_id: string, stream_id: string, category: list, category_id: string, description: string, merchant_name: string, first_date: string, last_date: string, predicted_next_date: string, frequency: string, transaction_ids: list, average_amount: record, last_amount: record, is_active: bool, status: string, personal_finance_category: record, is_user_modified: bool, last_user_modified_datetime: string>, outflow_streams: table<account_id: string, stream_id: string, category: list, category_id: string, description: string, merchant_name: string, first_date: string, last_date: string, predicted_next_date: string, frequency: string, transaction_ids: list, average_amount: record, last_amount: record, is_active: bool, status: string, personal_finance_category: record, is_user_modified: bool, last_user_modified_datetime: string>, updated_datetime: string, personal_finance_category_version: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactions/recurring/get")
  let body = {client_id: $client_id, access_token: $access_token, secret: $secret, options: $options, account_ids: $account_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get incremental transaction updates on an Item
#
# POST /transactions/sync
# Docs: /api/products/transactions/#transactionssync
# operationId: transactionsSync
# --options shape: {include_original_description?: bool, include_personal_finance_category?: bool, include_logo_and_counterparty_beta?: bool, personal_finance_category_version?: "v1"|"v2", days_requested?: int, account_id?: string}
export def "transactions-sync transactionsSync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --cursor: string # The cursor value represents the last update requested. Providing it will cause the response to only return changes after this update. If omitted, the entire history of updates will be returned, starting with the first-added transactions on the Item. The cursor also accepts the special value of `"now"`, which can be used to fast-forward the cursor as part of migrating an existing Item from `/transactions/get` to `/transactions/sync`. For more information, see the [Transactions sync migration guide](https://plaid.com/docs/transactions/sync-migration/). Note that using the `"now"` value is not supported for any use case other than migrating existing Items from `/transactions/get`.  The upper-bound length of this cursor is 256 characters of base64.
  --count: int # The number of transaction updates to fetch. (default: 100)
  --options: record # An optional object to be used with the request. If specified, `options` must not be `null`. — shape: {include_original_description?: bool, include_personal_finance_category?: bool, include_logo_and_counterparty_beta?: bool, personal_finance_category_version?: "v1"|"v2", days_requested?: int, account_id?: string}
]: any -> record<transactions_update_status: string, accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record, persistent_account_id: string, holder_category: string>, added: table<account_id: string, amount: float, iso_currency_code: string, unofficial_currency_code: string, category: list, category_id: string, check_number: string, date: string, location: record, name: string, merchant_name: string, original_description: string, payment_meta: record, pending: bool, pending_transaction_id: string, account_owner: string, transaction_id: string, transaction_type: string, logo_url: string, website: string, authorized_date: string, authorized_datetime: string, datetime: string, payment_channel: string, personal_finance_category: record, business_finance_category: record, transaction_code: string, personal_finance_category_icon_url: string, counterparties: list, merchant_entity_id: string, client_customization: record>, modified: table<account_id: string, amount: float, iso_currency_code: string, unofficial_currency_code: string, category: list, category_id: string, check_number: string, date: string, location: record, name: string, merchant_name: string, original_description: string, payment_meta: record, pending: bool, pending_transaction_id: string, account_owner: string, transaction_id: string, transaction_type: string, logo_url: string, website: string, authorized_date: string, authorized_datetime: string, datetime: string, payment_channel: string, personal_finance_category: record, business_finance_category: record, transaction_code: string, personal_finance_category_icon_url: string, counterparties: list, merchant_entity_id: string, client_customization: record>, removed: table<transaction_id: string, account_id: string>, next_cursor: string, has_more: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactions/sync")
  let body = {client_id: $client_id, access_token: $access_token, secret: $secret, cursor: $cursor, count: $count, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enrich locally-held transaction data
#
# POST /transactions/enrich
# Docs: /api/products/enrich/#transactionsenrich
# operationId: transactionsEnrich
# --transactions item shape: {id: string, user_id?: string, client_user_id?: string, client_account_id?: string, account_type?: string, account_subtype?: string, description: string, amount: float, direction: "INFLOW"|"OUTFLOW", iso_currency_code: string, location?: record, mcc?: string, date_posted?: string}
# --options shape: {include_legacy_category?: bool, personal_finance_category_version?: "v1"|"v2"}
export def "transactions-enrich transactionsEnrich" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  account_type: string # The account type for the requested transactions (either `depository` or `credit`).
  transactions: list # An array of transaction objects to be enriched by Plaid. Maximum of 100 transactions per request. — item shape: {id: string, user_id?: string, client_user_id?: string, client_account_id?: string, account_type?: string, account_subtype?: string, description: string, amount: float, direction: "INFLOW"|"OUTFLOW", iso_currency_code: string, location?: record, mcc?: string, date_posted?: string}
  --options: record # An optional object to be used with the request. — shape: {include_legacy_category?: bool, personal_finance_category_version?: "v1"|"v2"}
]: any -> record<enriched_transactions: table<id: string, client_user_id: string, client_account_id: string, account_type: string, account_subtype: string, description: string, amount: float, direction: string, iso_currency_code: string, enrichments: record, client_customization: record>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactions/enrich")
  let body = {client_id: $client_id, secret: $secret, account_type: $account_type, transactions: $transactions, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Refresh user items for Transactions bundle
#
# POST /user/transactions/refresh
# Docs: /api/products/transactions/#usertransactionsrefresh
# operationId: userTransactionsRefresh
export def "user-transactions-refresh userTransactionsRefresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: string # A Plaid-generated ID that identifies the end user.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string, user_id: string, results: table<item_id: string, product: string, error: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/transactions/refresh")
  let body = {user_id: $user_id, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Refresh user items for Financial-Insights bundle
#
# POST /user/financial_data/refresh
# Docs: /api/products/transactions/#userfinancialdatarefresh
# operationId: userFinancialDataRefresh
export def "user-financial-data-refresh userFinancialDataRefresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: string # A Plaid-generated ID that identifies the end user.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string, user_id: string, results: table<item_id: string, product: string, error: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/financial_data/refresh")
  let body = {user_id: $user_id, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get details of all supported institutions
#
# POST /institutions/get
# Docs: /api/institutions/#institutionsget
# operationId: institutionsGet
# --options shape: {products?: list, routing_numbers?: list, oauth?: bool, include_optional_metadata?: bool, include_auth_metadata?: bool, include_payment_initiation_metadata?: bool}
export def "institutions-get institutionsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  count: int # The total number of Institutions to return.
  offset: int # The number of Institutions to skip.
  country_codes: list # Specify which country or countries to include institutions from, using the ISO-3166-1 alpha-2 country code standard.  In API versions 2019-05-29 and earlier, the `country_codes` parameter is an optional parameter within the `options` object and will default to `[US]` if it is not supplied.
  --options: record # An optional object to filter `/institutions/get` results. — shape: {products?: list, routing_numbers?: list, oauth?: bool, include_optional_metadata?: bool, include_auth_metadata?: bool, include_payment_initiation_metadata?: bool}
]: any -> record<institutions: table<institution_id: string, name: string, products: list, country_codes: list, url: string, primary_color: string, logo: string, routing_numbers: list, dtc_numbers: list, oauth: bool, status: record, payment_initiation_metadata: record, auth_metadata: record>, total: int, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/institutions/get")
  let body = {client_id: $client_id, secret: $secret, count: $count, offset: $offset, country_codes: $country_codes, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search institutions
#
# POST /institutions/search
# Docs: /api/institutions/#institutionssearch
# operationId: institutionsSearch
# --options shape: {oauth?: bool, include_optional_metadata?: bool, include_auth_metadata?: bool, include_payment_initiation_metadata?: bool, payment_initiation?: record}
export def "institutions-search institutionsSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --body-query: string # The search query. Institutions with names matching the query are returned
  --products: list # Filter the Institutions based on whether they support all products listed in `products`. Provide `null` to get institutions regardless of supported products. Note that when `auth` is specified as a product, if you are enabled for Instant Match or Automated Micro-deposits, institutions that support those products will be returned even if `auth` is not present in their product array. To search for Transfer support, use `auth`; to search for Signal Transaction Scores support, use `balance`. (nullable)
  country_codes: list # Specify which country or countries to include institutions from, using the ISO-3166-1 alpha-2 country code standard. In API versions 2019-05-29 and earlier, the `country_codes` parameter is an optional parameter within the `options` object and will default to `[US]` if it is not supplied.
  --options: record # An optional object to filter `/institutions/search` results. — shape: {oauth?: bool, include_optional_metadata?: bool, include_auth_metadata?: bool, include_payment_initiation_metadata?: bool, payment_initiation?: record}
]: any -> record<institutions: table<institution_id: string, name: string, products: list, country_codes: list, url: string, primary_color: string, logo: string, routing_numbers: list, dtc_numbers: list, oauth: bool, status: record, payment_initiation_metadata: record, auth_metadata: record>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/institutions/search")
  let body = {client_id: $client_id, secret: $secret, query: $body_query, products: $products, country_codes: $country_codes, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get details of an institution
#
# POST /institutions/get_by_id
# Docs: /api/institutions/#institutionsget_by_id
# operationId: institutionsGetById
# --options shape: {include_optional_metadata?: bool, include_status?: bool, include_auth_metadata?: bool, include_payment_initiation_metadata?: bool}
export def "institutions-get-by-id institutionsGetById" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  institution_id: string # The ID of the institution to get details about
  country_codes: list # Specify which country or countries to include institutions from, using the ISO-3166-1 alpha-2 country code standard. In API versions 2019-05-29 and earlier, the `country_codes` parameter is an optional parameter within the `options` object and will default to `[US]` if it is not supplied.
  --options: record # Specifies optional parameters for `/institutions/get_by_id`. If provided, must not be `null`. — shape: {include_optional_metadata?: bool, include_status?: bool, include_auth_metadata?: bool, include_payment_initiation_metadata?: bool}
]: any -> record<institution: record<institution_id: string, name: string, products: list<string>, country_codes: list<string>, url: string, primary_color: string, logo: string, routing_numbers: list<string>, dtc_numbers: list<string>, oauth: bool, status: record<item_logins: record, transactions_updates: record, auth: record, identity: record, investments_updates: record, liabilities_updates: record, liabilities: record, investments: record, health_incidents: list>, payment_initiation_metadata: record<supports_international_payments: bool, supports_sepa_instant: bool, maximum_payment_amount: record, supports_refund_details: bool, standing_order_metadata: record, supports_payment_consents: bool>, auth_metadata: record<supported_methods: record>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/institutions/get_by_id")
  let body = {client_id: $client_id, secret: $secret, institution_id: $institution_id, country_codes: $country_codes, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  --reason-code: string@reason-code-completer # The reason for removing the Item  `FRAUD_FIRST_PARTY`: The end user who owns the connected bank account committed fraud `FRAUD_FALSE_IDENTITY`: The end user created the connection using false identity information or stolen credentials `FRAUD_ABUSE`: The end user is abusing the client's service or platform through their connected account `FRAUD_OTHER`: Other fraud-related reasons involving the end user not covered by the specific fraud categories `CONNECTION_IS_NON_FUNCTIONAL`: The connection to the end user's financial institution is broken and cannot be restored `OTHER`: Any other reason for removing the connection not covered by the above categories  (nullable)
  --reason-note: string # Additional context or details about the reason for removing the Item. Personally identifiable information, such as an email address or phone number, should not be included in the `reason_note`. (nullable)
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/remove")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, reason_code: $reason_code, reason_note: $reason_note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Terminate products for an Item
#
# POST /item/products/terminate
# Docs: /api/items/#itemproductsterminate
# operationId: itemProductsTerminate
export def "item-products-terminate itemProductsTerminate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  reason_code: any # The reason for terminating products on the Item.
  --reason-note: string # Additional context or details about the reason for terminating products on the Item. Personally identifiable information, such as an email address or phone number, should not be included in the `reason_note`. (nullable)
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/products/terminate")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, reason_code: $reason_code, reason_note: $reason_note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  --options: record # An optional object to filter `/accounts/get` results. — shape: {account_ids?: list}
]: any -> record<accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record, persistent_account_id: string, holder_category: string>, item: record<item_id: string, institution_id: string, institution_name: string, webhook: string, auth_method: string, error: record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list, provided_account_subtypes: list>, available_products: list<string>, billed_products: list<string>, products: list<string>, consented_products: list<string>, consent_expiration_time: string, update_type: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts/get")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# (Deprecated) Get legacy categories
#
# POST /categories/get
# DEPRECATED
# Docs: /api/products/transactions/#categoriesget
# operationId: categoriesGet
@deprecated
export def "categories-get categoriesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<categories: table<category_id: string, group: string, hierarchy: list>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/categories/get")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a test Item and processor token
#
# POST /sandbox/processor_token/create
# Docs: /api/sandbox/#sandboxprocessor_tokencreate
# operationId: sandboxProcessorTokenCreate
# --options shape: {override_username?: string, override_password?: string}
export def "sandbox-processor-token-create sandboxProcessorTokenCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  institution_id: string # The ID of the institution the Item will be associated with
  --options: record # An optional set of options to be used when configuring the Item. If specified, must not be `null`. — shape: {override_username?: string, override_password?: string}
]: any -> record<processor_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/processor_token/create")
  let body = {client_id: $client_id, secret: $secret, institution_id: $institution_id, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a test Item
#
# POST /sandbox/public_token/create
# Docs: /api/sandbox/#sandboxpublic_tokencreate
# operationId: sandboxPublicTokenCreate
# --options shape: {webhook?: string, override_username?: string, override_password?: string, transactions?: record, statements?: record, income_verification?: record}
export def "sandbox-public-token-create sandboxPublicTokenCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  institution_id: string # The ID of the institution the Item will be associated with
  initial_products: list # The products to initially pull for the Item. May be any products that the specified `institution_id` supports. This array may not be empty.
  --options: record # An optional set of options to be used when configuring the Item. If specified, must not be `null`. — shape: {webhook?: string, override_username?: string, override_password?: string, transactions?: record, statements?: record, income_verification?: record}
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --user-id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
]: any -> record<public_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/public_token/create")
  let body = {client_id: $client_id, secret: $secret, institution_id: $institution_id, initial_products: $initial_products, options: $options, user_token: $user_token, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  --webhook-type: string@webhook-type-completer # The webhook types that can be fired by this test endpoint.
  webhook_code: string@webhook-code-completer # The webhook codes that can be fired by this test endpoint.
]: any -> record<webhook_fired: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/item/fire_webhook")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, webhook_type: $webhook_type, webhook_code: $webhook_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve real-time balance data
#
# POST /accounts/balance/get
# Docs: /api/products/signal/#accountsbalanceget
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
  access_token: string # The access token associated with the Item for which data is being requested.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --options: record # Optional parameters to `/accounts/balance/get`. — shape: {account_ids?: list, min_last_updated_datetime?: string}
]: any -> record<accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record, persistent_account_id: string, holder_category: string>, item: record<item_id: string, institution_id: string, institution_name: string, webhook: string, auth_method: string, error: record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list, provided_account_subtypes: list>, available_products: list<string>, billed_products: list<string>, products: list<string>, consented_products: list<string>, consent_expiration_time: string, update_type: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts/balance/get")
  let body = {access_token: $access_token, secret: $secret, client_id: $client_id, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  --options: record # An optional object to filter `/identity/get` results. — shape: {account_ids?: list}
]: any -> record<accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record, persistent_account_id: string, holder_category: string, owners: list>, item: record<item_id: string, institution_id: string, institution_name: string, webhook: string, auth_method: string, error: record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list, provided_account_subtypes: list>, available_products: list<string>, billed_products: list<string>, products: list<string>, consented_products: list<string>, consent_expiration_time: string, update_type: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/identity/get")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns uploaded document identity
#
# POST /identity/documents/uploads/get
# Docs: /api/products/identity/#identitydocumentsuploadsget
# operationId: identityDocumentsUploadsGet
# --options shape: {account_ids?: list}
export def "identity-documents-uploads-get identityDocumentsUploadsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  --options: record # An optional object to filter `/identity/documents/uploads/get` results. — shape: {account_ids?: list}
]: any -> record<accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record, persistent_account_id: string, holder_category: string, owners: list, documents: list>, item: record<item_id: string, institution_id: string, institution_name: string, webhook: string, auth_method: string, error: record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list, provided_account_subtypes: list>, available_products: list<string>, billed_products: list<string>, products: list<string>, consented_products: list<string>, consent_expiration_time: string, update_type: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/identity/documents/uploads/get")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve identity match score
#
# POST /identity/match
# Docs: /api/products/identity/#identitymatch
# operationId: identityMatch
# --user shape: {legal_name?: string, phone_number?: string, email_address?: string, address?: any}
# --options shape: {account_ids?: list}
export def "identity-match identityMatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  --user: record # The user's legal name, phone number, email address and address used to perform fuzzy match. If Financial Account Matching is enabled in the Identity Verification product, leave this field empty to automatically match against PII collected from the Identity Verification checks. — shape: {legal_name?: string, phone_number?: string, email_address?: string, address?: any}
  --options: record # An optional object to filter `/identity/match` results — shape: {account_ids?: list}
]: any -> record<accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record, persistent_account_id: string, holder_category: string, legal_name: record, phone_number: record, email_address: record, address: record>, item: record<item_id: string, institution_id: string, institution_name: string, webhook: string, auth_method: string, error: record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list, provided_account_subtypes: list>, available_products: list<string>, billed_products: list<string>, products: list<string>, consented_products: list<string>, consent_expiration_time: string, update_type: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/identity/match")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, user: $user, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Refresh identity data
#
# POST /identity/refresh
# Docs: /api/products/identity/#identityrefresh
# operationId: identityRefresh
export def "identity-refresh identityRefresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/identity/refresh")
  let body = {client_id: $client_id, access_token: $access_token, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Dashboard user
#
# POST /dashboard_user/get
# Docs: /api/kyc-aml-users/#dashboard_userget
# operationId: dashboardUserGet
export def "dashboard-user-get dashboardUserGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  dashboard_user_id: string # ID of the associated user. To retrieve the email address or other details of the person corresponding to this ID, use `/dashboard_user/get`. (e.g. 54350110fedcbaf01234ffee)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
]: any -> record<id: string, created_at: string, email_address: string, status: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dashboard_user/get")
  let body = {dashboard_user_id: $dashboard_user_id, secret: $secret, client_id: $client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Dashboard users
#
# POST /dashboard_user/list
# Docs: /api/kyc-aml-users/#dashboard_userlist
# operationId: dashboardUserList
export def "dashboard-user-list dashboardUserList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
]: any -> record<dashboard_users: table<id: string, created_at: string, email_address: string, status: string>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dashboard_user/list")
  let body = {secret: $secret, client_id: $client_id, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Identity Verification
#
# POST /identity_verification/create
# Docs: /api/products/identity-verification/#identity_verificationcreate
# operationId: identityVerificationCreate
# --user shape: {email_address?: string, phone_number?: string, date_of_birth?: string, name?: record, address?: record, id_number?: record, client_user_id?: string}
export def "identity-verification-create identityVerificationCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-user-id: string # A unique ID that identifies the end user in your system. Either a `user_id` or the `client_user_id` must be provided. This ID can also be used to associate user-specific data from other Plaid products. Financial Account Matching requires this field and the `/link/token/create` `client_user_id` to be consistent. Personally identifiable information, such as an email address or phone number, should not be used in the `client_user_id`. (e.g. your-db-id-3b24110)
  --user-id: string # Unique user identifier, created by calling `/user/create`. Either a `user_id` or the `client_user_id` must be provided. The `user_id` may only be used instead of the `client_user_id` if you were not a pre-existing user of `/user/create` as of December 10, 2025; for more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis). If both this field and a `client_user_id` are present in a request, the `user_id` must have been created from the provided `client_user_id`. (e.g. usr_dddAs9ewdcDQQQ)
  --is-shareable: string@bool-completer # A flag specifying whether you would like Plaid to expose a shareable URL for the verification being created. (e.g. true)
  template_id: string # ID of the associated Identity Verification template. Like all Plaid identifiers, this is case-sensitive. (e.g. idvtmp_4FrXJvfQU3zGUR)
  --gave-consent: string@bool-completer # A flag specifying whether the end user has already agreed to a privacy policy specifying that their data will be shared with Plaid for verification purposes.  If `gave_consent` is set to `true`, the `accept_tos` step will be marked as `skipped` and the end user's session will start at the next step requirement. (default: false, e.g. true)
  --user: record # User information collected outside of Link, most likely via your own onboarding process.  Each of the following identity fields are optional:  `email_address`  `phone_number`  `date_of_birth`  `name`  `address`  `id_number`  Specifically, these fields are optional in that they can either be fully provided (satisfying every required field in their subschema) or omitted from the request entirely by not providing the key or value. Providing these fields via the API will result in Link skipping the data collection process for the associated user. All verification steps enabled in the associated Identity Verification Template will still be run. Verification steps will either be run immediately, or once the user completes the `accept_tos` step, depending on the value provided to the `gave_consent` field. If you are not using the shareable URL feature, you can optionally provide these fields via `/link/token/create` instead; both `/identity_verification/create` and `/link/token/create` are valid ways to provide this information. Note that if you provide a non-`null` user data object via `/identity_verification/create`, any user data fields entered via `/link/token/create` for the same `client_user_id` will be ignored when prefilling Link. (nullable) — shape: {email_address?: string, phone_number?: string, date_of_birth?: string, name?: record, address?: record, id_number?: record, client_user_id?: string}
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --is-idempotent: string@bool-completer # An optional flag specifying how you would like Plaid to handle attempts to create an Identity Verification when an Identity Verification already exists for the provided `client_user_id` and `template_id`. If idempotency is enabled, Plaid will return the existing Identity Verification. If idempotency is disabled, Plaid will reject the request with a `400 Bad Request` status code if an Identity Verification already exists for the supplied `client_user_id` and `template_id`. (nullable, e.g. true)
]: any -> record<id: string, client_user_id: string, created_at: string, completed_at: string, previous_attempt_id: string, shareable_url: string, template: record<id: string, version: int>, user: record<phone_number: string, date_of_birth: string, ip_address: string, email_address: string, name: record<given_name: string, family_name: string>, address: record<street: string, street2: string, city: string, region: string, postal_code: string, country: string>, id_number: record<value: string, type: string>>, status: string, steps: record<accept_tos: string, verify_sms: string, kyc_check: string, documentary_verification: string, selfie_check: string, watchlist_screening: string, risk_check: string>, documentary_verification: record<status: string, documents: list<record>>, selfie_check: record<status: string, selfies: list<record>>, kyc_check: record<status: string, address: record<summary: string, po_box: string, type: string, street: string, city: string, region: string, postal_code: string, international_details: record>, name: record<summary: string, given_name: string, family_name: string>, date_of_birth: record<summary: string, day: string, month: string, year: string>, id_number: record<summary: string>, phone_number: record<summary: string, area_code: string>>, risk_check: record<status: string, behavior: record<user_interactions: string, fraud_ring_detected: string, bot_detected: string, risk_level: string>, email: record<is_deliverable: string, breach_count: int, first_breached_at: string, last_breached_at: string, domain_registered_at: string, domain_is_free_provider: string, domain_is_custom: string, domain_is_disposable: string, top_level_domain_is_suspicious: string, is_edu: string, includes_date_of_birth: string, linked_services: list, risk_level: string, factors: list>, phone: record<linked_services: list, risk_level: string, factors: list>, devices: list<record>, identity_abuse_signals: record<synthetic_identity: record, stolen_identity: record>, network: record<risk_level: string, factors: list>, facial_duplicates: list<record>, trust_index_score: int>, verify_sms: record<status: string, verifications: list<record>>, watchlist_screening_id: string, beacon_user_id: string, user_id: string, redacted_at: string, latest_scored_protect_event: record<event_id: string, timestamp: string, trust_index: record<score: int, model: string, subscores: record>, fraud_attributes: record>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/identity_verification/create")
  let body = {client_user_id: $client_user_id, user_id: $user_id, is_shareable: $is_shareable, template_id: $template_id, gave_consent: $gave_consent, user: $user, client_id: $client_id, secret: $secret, is_idempotent: $is_idempotent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  identity_verification_id: string # ID of the associated Identity Verification attempt. (e.g. idv_52xR9LKo77r1Np)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
]: any -> record<id: string, client_user_id: string, created_at: string, completed_at: string, previous_attempt_id: string, shareable_url: string, template: record<id: string, version: int>, user: record<phone_number: string, date_of_birth: string, ip_address: string, email_address: string, name: record<given_name: string, family_name: string>, address: record<street: string, street2: string, city: string, region: string, postal_code: string, country: string>, id_number: record<value: string, type: string>>, status: string, steps: record<accept_tos: string, verify_sms: string, kyc_check: string, documentary_verification: string, selfie_check: string, watchlist_screening: string, risk_check: string>, documentary_verification: record<status: string, documents: list<record>>, selfie_check: record<status: string, selfies: list<record>>, kyc_check: record<status: string, address: record<summary: string, po_box: string, type: string, street: string, city: string, region: string, postal_code: string, international_details: record>, name: record<summary: string, given_name: string, family_name: string>, date_of_birth: record<summary: string, day: string, month: string, year: string>, id_number: record<summary: string>, phone_number: record<summary: string, area_code: string>>, risk_check: record<status: string, behavior: record<user_interactions: string, fraud_ring_detected: string, bot_detected: string, risk_level: string>, email: record<is_deliverable: string, breach_count: int, first_breached_at: string, last_breached_at: string, domain_registered_at: string, domain_is_free_provider: string, domain_is_custom: string, domain_is_disposable: string, top_level_domain_is_suspicious: string, is_edu: string, includes_date_of_birth: string, linked_services: list, risk_level: string, factors: list>, phone: record<linked_services: list, risk_level: string, factors: list>, devices: list<record>, identity_abuse_signals: record<synthetic_identity: record, stolen_identity: record>, network: record<risk_level: string, factors: list>, facial_duplicates: list<record>, trust_index_score: int>, verify_sms: record<status: string, verifications: list<record>>, watchlist_screening_id: string, beacon_user_id: string, user_id: string, redacted_at: string, latest_scored_protect_event: record<event_id: string, timestamp: string, trust_index: record<score: int, model: string, subscores: record>, fraud_attributes: record>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/identity_verification/get")
  let body = {identity_verification_id: $identity_verification_id, secret: $secret, client_id: $client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  template_id: string # ID of the associated Identity Verification template. Like all Plaid identifiers, this is case-sensitive. (e.g. idvtmp_4FrXJvfQU3zGUR)
  --client-user-id: string # A unique ID that identifies the end user in your system. Either a `user_id` or the `client_user_id` must be provided. This ID can also be used to associate user-specific data from other Plaid products. Financial Account Matching requires this field and the `/link/token/create` `client_user_id` to be consistent. Personally identifiable information, such as an email address or phone number, should not be used in the `client_user_id`. (e.g. your-db-id-3b24110)
  --user-id: any # A unique user identifier, created by calling `/user/create`. Either a `user_id` or the `client_user_id` must be provided. The `user_id` may only be used instead of the `client_user_id` if you were not a pre-existing user of `/user/create` as of December 10, 2025; for more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis). If both this field and the `client_user_id` are present in the request, the `user_id` must have been created from the provided `client_user_id`. (nullable)
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
]: any -> record<identity_verifications: table<id: string, client_user_id: string, created_at: string, completed_at: string, previous_attempt_id: string, shareable_url: string, template: record, user: record, status: string, steps: record, documentary_verification: record, selfie_check: record, kyc_check: record, risk_check: record, verify_sms: record, watchlist_screening_id: string, beacon_user_id: string, user_id: string, redacted_at: string, latest_scored_protect_event: record>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/identity_verification/list")
  let body = {secret: $secret, client_id: $client_id, template_id: $template_id, client_user_id: $client_user_id, user_id: $user_id, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retry an Identity Verification
#
# POST /identity_verification/retry
# Docs: /api/products/identity-verification/#identity_verificationretry
# operationId: identityVerificationRetry
# --user shape: {email_address?: string, phone_number?: string, date_of_birth?: string, name?: record, address?: record, id_number?: record}
# --steps shape: {verify_sms: bool, kyc_check: bool, documentary_verification: bool, selfie_check: bool}
export def "identity-verification-retry identityVerificationRetry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_user_id: string # A unique ID that identifies the end user in your system. Either a `user_id` or the `client_user_id` must be provided. This ID can also be used to associate user-specific data from other Plaid products. Financial Account Matching requires this field and the `/link/token/create` `client_user_id` to be consistent. Personally identifiable information, such as an email address or phone number, should not be used in the `client_user_id`. (e.g. your-db-id-3b24110)
  template_id: string # ID of the associated Identity Verification template. Like all Plaid identifiers, this is case-sensitive. (e.g. idvtmp_4FrXJvfQU3zGUR)
  strategy: string@strategy-completer # An instruction specifying what steps the new Identity Verification attempt should require the user to complete:   `reset` - Restart the user at the beginning of the session, regardless of whether they successfully completed part of their previous session.  `incomplete` - Start the new session at the step that the user failed in the previous session, skipping steps that have already been successfully completed.  `infer` - If the most recent Identity Verification attempt associated with the given `client_user_id` has a status of `failed` or `expired`, retry using the `incomplete` strategy. Otherwise, use the `reset` strategy.  `custom` - Start the new session with a custom configuration, specified by the value of the `steps` field  Note:  The `incomplete` strategy cannot be applied if the session's failing step is `screening` or `risk_check`.  The `infer` strategy cannot be applied if the session's status is still `active`
  --user: record # User information collected outside of Link, most likely via your own onboarding process.  Each of the following identity fields are optional:  `email_address`  `phone_number`  `date_of_birth`  `name`  `address`  `id_number`  Specifically, these fields are optional in that they can either be fully provided (satisfying every required field in their subschema) or omitted from the request entirely by not providing the key or value. Providing these fields via the API will result in Link skipping the data collection process for the associated user. All verification steps enabled in the associated Identity Verification Template will still be run. Verification steps will either be run immediately, or once the user completes the `accept_tos` step, depending on the value provided to the `gave_consent` field. (nullable) — shape: {email_address?: string, phone_number?: string, date_of_birth?: string, name?: record, address?: record, id_number?: record}
  --steps: record # Instructions for the `custom` retry strategy specifying which steps should be required or skipped.   Note:   This field must be provided when the retry strategy is `custom` and must be omitted otherwise.  Custom retries override settings in your Plaid Template. For example, if your Plaid Template has `verify_sms` disabled, a custom retry with `verify_sms` enabled will still require the step.  The `selfie_check` step is currently not supported on the sandbox server. Sandbox requests will silently disable the `selfie_check` step when provided. (nullable) — shape: {verify_sms: bool, kyc_check: bool, documentary_verification: bool, selfie_check: bool}
  --is-shareable: string@bool-completer # A flag specifying whether you would like Plaid to expose a shareable URL for the verification being retried. If a value for this flag is not specified, the `is_shareable` setting from the original verification attempt will be used. (nullable, e.g. true)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<id: string, client_user_id: string, created_at: string, completed_at: string, previous_attempt_id: string, shareable_url: string, template: record<id: string, version: int>, user: record<phone_number: string, date_of_birth: string, ip_address: string, email_address: string, name: record<given_name: string, family_name: string>, address: record<street: string, street2: string, city: string, region: string, postal_code: string, country: string>, id_number: record<value: string, type: string>>, status: string, steps: record<accept_tos: string, verify_sms: string, kyc_check: string, documentary_verification: string, selfie_check: string, watchlist_screening: string, risk_check: string>, documentary_verification: record<status: string, documents: list<record>>, selfie_check: record<status: string, selfies: list<record>>, kyc_check: record<status: string, address: record<summary: string, po_box: string, type: string, street: string, city: string, region: string, postal_code: string, international_details: record>, name: record<summary: string, given_name: string, family_name: string>, date_of_birth: record<summary: string, day: string, month: string, year: string>, id_number: record<summary: string>, phone_number: record<summary: string, area_code: string>>, risk_check: record<status: string, behavior: record<user_interactions: string, fraud_ring_detected: string, bot_detected: string, risk_level: string>, email: record<is_deliverable: string, breach_count: int, first_breached_at: string, last_breached_at: string, domain_registered_at: string, domain_is_free_provider: string, domain_is_custom: string, domain_is_disposable: string, top_level_domain_is_suspicious: string, is_edu: string, includes_date_of_birth: string, linked_services: list, risk_level: string, factors: list>, phone: record<linked_services: list, risk_level: string, factors: list>, devices: list<record>, identity_abuse_signals: record<synthetic_identity: record, stolen_identity: record>, network: record<risk_level: string, factors: list>, facial_duplicates: list<record>, trust_index_score: int>, verify_sms: record<status: string, verifications: list<record>>, watchlist_screening_id: string, beacon_user_id: string, user_id: string, redacted_at: string, latest_scored_protect_event: record<event_id: string, timestamp: string, trust_index: record<score: int, model: string, subscores: record>, fraud_attributes: record>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/identity_verification/retry")
  let body = {client_user_id: $client_user_id, template_id: $template_id, strategy: $strategy, user: $user, steps: $steps, is_shareable: $is_shareable, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a watchlist screening for an entity
#
# POST /watchlist_screening/entity/create
# Docs: /api/products/monitor/#watchlist_screeningentitycreate
# operationId: watchlistScreeningEntityCreate
# --search_terms shape: {entity_watchlist_program_id: string, legal_name: string, document_number?: string, email_address?: string, country?: string, phone_number?: string, url?: string}
export def "watchlist-screening-entity-create watchlistScreeningEntityCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  search_terms: record # Search inputs for creating an entity watchlist screening — shape: {entity_watchlist_program_id: string, legal_name: string, document_number?: string, email_address?: string, country?: string, phone_number?: string, url?: string}
  --client-user-id: string # A unique ID that identifies the end user in your system. Either a `user_id` or the `client_user_id` must be provided. This ID can also be used to associate user-specific data from other Plaid products. Financial Account Matching requires this field and the `/link/token/create` `client_user_id` to be consistent. Personally identifiable information, such as an email address or phone number, should not be used in the `client_user_id`. (e.g. your-db-id-3b24110)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<id: string, search_terms: record<entity_watchlist_program_id: string, legal_name: string, document_number: string, email_address: string, country: string, phone_number: string, url: string, version: int>, assignee: string, status: string, client_user_id: string, audit_trail: record<source: string, dashboard_user_id: string, timestamp: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/entity/create")
  let body = {search_terms: $search_terms, client_user_id: $client_user_id, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an entity screening
#
# POST /watchlist_screening/entity/get
# Docs: /api/products/monitor/#watchlist_screeningentityget
# operationId: watchlistScreeningEntityGet
export def "watchlist-screening-entity-get watchlistScreeningEntityGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  entity_watchlist_screening_id: string # ID of the associated entity screening. (e.g. entscr_52xR9LKo77r1Np)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
]: any -> record<id: string, search_terms: record<entity_watchlist_program_id: string, legal_name: string, document_number: string, email_address: string, country: string, phone_number: string, url: string, version: int>, assignee: string, status: string, client_user_id: string, audit_trail: record<source: string, dashboard_user_id: string, timestamp: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/entity/get")
  let body = {entity_watchlist_screening_id: $entity_watchlist_screening_id, secret: $secret, client_id: $client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List history for entity watchlist screenings
#
# POST /watchlist_screening/entity/history/list
# Docs: /api/products/monitor/#watchlist_screeningentityhistorylist
# operationId: watchlistScreeningEntityHistoryList
export def "watchlist-screening-entity-history-list watchlistScreeningEntityHistoryList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  entity_watchlist_screening_id: string # ID of the associated entity screening. (e.g. entscr_52xR9LKo77r1Np)
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
]: any -> record<entity_watchlist_screenings: table<id: string, search_terms: record, assignee: string, status: string, client_user_id: string, audit_trail: record>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/entity/history/list")
  let body = {secret: $secret, client_id: $client_id, entity_watchlist_screening_id: $entity_watchlist_screening_id, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List hits for entity watchlist screenings
#
# POST /watchlist_screening/entity/hit/list
# Docs: /api/products/monitor/#watchlist_screeningentityhitlist
# operationId: watchlistScreeningEntityHitList
export def "watchlist-screening-entity-hit-list watchlistScreeningEntityHitList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  entity_watchlist_screening_id: string # ID of the associated entity screening. (e.g. entscr_52xR9LKo77r1Np)
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
]: any -> record<entity_watchlist_screening_hits: table<id: string, review_status: string, first_active: string, inactive_since: string, historical_since: string, list_code: string, plaid_uid: string, source_uid: string, sub_programs: list, analysis: record, data: record>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/entity/hit/list")
  let body = {secret: $secret, client_id: $client_id, entity_watchlist_screening_id: $entity_watchlist_screening_id, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List entity watchlist screenings
#
# POST /watchlist_screening/entity/list
# Docs: /api/products/monitor/#watchlist_screeningentitylist
# operationId: watchlistScreeningEntityList
export def "watchlist-screening-entity-list watchlistScreeningEntityList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  entity_watchlist_program_id: string # ID of the associated entity program. (e.g. entprg_2eRPsDnL66rZ7H)
  --client-user-id: string # A unique ID that identifies the end user in your system. Either a `user_id` or the `client_user_id` must be provided. This ID can also be used to associate user-specific data from other Plaid products. Financial Account Matching requires this field and the `/link/token/create` `client_user_id` to be consistent. Personally identifiable information, such as an email address or phone number, should not be used in the `client_user_id`. (e.g. your-db-id-3b24110)
  --status: string@status-completer # A status enum indicating whether a screening is still pending review, has been rejected, or has been cleared. (e.g. cleared)
  --assignee: string # ID of the associated user. To retrieve the email address or other details of the person corresponding to this ID, use `/dashboard_user/get`. (e.g. 54350110fedcbaf01234ffee)
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
]: any -> record<entity_watchlist_screenings: table<id: string, search_terms: record, assignee: string, status: string, client_user_id: string, audit_trail: record>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/entity/list")
  let body = {secret: $secret, client_id: $client_id, entity_watchlist_program_id: $entity_watchlist_program_id, client_user_id: $client_user_id, status: $status, assignee: $assignee, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get entity watchlist screening program
#
# POST /watchlist_screening/entity/program/get
# Docs: /api/products/monitor/#watchlist_screeningentityprogramget
# operationId: watchlistScreeningEntityProgramGet
export def "watchlist-screening-entity-program-get watchlistScreeningEntityProgramGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  entity_watchlist_program_id: string # ID of the associated entity program. (e.g. entprg_2eRPsDnL66rZ7H)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
]: any -> record<id: string, created_at: string, is_rescanning_enabled: bool, lists_enabled: list<string>, name: string, name_sensitivity: string, audit_trail: record<source: string, dashboard_user_id: string, timestamp: string>, is_archived: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/entity/program/get")
  let body = {entity_watchlist_program_id: $entity_watchlist_program_id, secret: $secret, client_id: $client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List entity watchlist screening programs
#
# POST /watchlist_screening/entity/program/list
# Docs: /api/products/monitor/#watchlist_screeningentityprogramlist
# operationId: watchlistScreeningEntityProgramList
export def "watchlist-screening-entity-program-list watchlistScreeningEntityProgramList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
]: any -> record<entity_watchlist_programs: table<id: string, created_at: string, is_rescanning_enabled: bool, lists_enabled: list, name: string, name_sensitivity: string, audit_trail: record, is_archived: bool>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/entity/program/list")
  let body = {secret: $secret, client_id: $client_id, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a review for an entity watchlist screening
#
# POST /watchlist_screening/entity/review/create
# Docs: /api/products/monitor/#watchlist_screeningentityreviewcreate
# operationId: watchlistScreeningEntityReviewCreate
export def "watchlist-screening-entity-review-create watchlistScreeningEntityReviewCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  confirmed_hits: list # Hits to mark as a true positive after thorough manual review. These hits will never recur or be updated once confirmed. In most cases, confirmed hits indicate that the customer should be rejected.
  dismissed_hits: list # Hits to mark as a false positive after thorough manual review. These hits will never recur or be updated once dismissed.
  --comment: string # A comment submitted by a team member as part of reviewing a watchlist screening. (nullable, e.g. These look like legitimate matches, rejecting the customer.)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  entity_watchlist_screening_id: string # ID of the associated entity screening. (e.g. entscr_52xR9LKo77r1Np)
]: any -> record<id: string, confirmed_hits: list<string>, dismissed_hits: list<string>, comment: string, audit_trail: record<source: string, dashboard_user_id: string, timestamp: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/entity/review/create")
  let body = {confirmed_hits: $confirmed_hits, dismissed_hits: $dismissed_hits, comment: $comment, client_id: $client_id, secret: $secret, entity_watchlist_screening_id: $entity_watchlist_screening_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List reviews for entity watchlist screenings
#
# POST /watchlist_screening/entity/review/list
# Docs: /api/products/monitor/#watchlist_screeningentityreviewlist
# operationId: watchlistScreeningEntityReviewList
export def "watchlist-screening-entity-review-list watchlistScreeningEntityReviewList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  entity_watchlist_screening_id: string # ID of the associated entity screening. (e.g. entscr_52xR9LKo77r1Np)
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
]: any -> record<entity_watchlist_screening_reviews: table<id: string, confirmed_hits: list, dismissed_hits: list, comment: string, audit_trail: record>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/entity/review/list")
  let body = {secret: $secret, client_id: $client_id, entity_watchlist_screening_id: $entity_watchlist_screening_id, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an entity screening
#
# POST /watchlist_screening/entity/update
# Docs: /api/products/monitor/#watchlist_screeningentityupdate
# operationId: watchlistScreeningEntityUpdate
# --search_terms shape: {entity_watchlist_program_id: string, legal_name?: string, document_number?: string, email_address?: string, country?: string, phone_number?: string, url?: string}
export def "watchlist-screening-entity-update watchlistScreeningEntityUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  entity_watchlist_screening_id: string # ID of the associated entity screening. (e.g. entscr_52xR9LKo77r1Np)
  --search-terms: record # Search terms for editing an entity watchlist screening (nullable) — shape: {entity_watchlist_program_id: string, legal_name?: string, document_number?: string, email_address?: string, country?: string, phone_number?: string, url?: string}
  --assignee: string # ID of the associated user. To retrieve the email address or other details of the person corresponding to this ID, use `/dashboard_user/get`. (e.g. 54350110fedcbaf01234ffee)
  --status: string@status-completer # A status enum indicating whether a screening is still pending review, has been rejected, or has been cleared. (e.g. cleared)
  --client-user-id: string # A unique ID that identifies the end user in your system. Either a `user_id` or the `client_user_id` must be provided. This ID can also be used to associate user-specific data from other Plaid products. Financial Account Matching requires this field and the `/link/token/create` `client_user_id` to be consistent. Personally identifiable information, such as an email address or phone number, should not be used in the `client_user_id`. (e.g. your-db-id-3b24110)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --reset-fields: list # A list of fields to reset back to null (nullable)
]: any -> record<id: string, search_terms: record<entity_watchlist_program_id: string, legal_name: string, document_number: string, email_address: string, country: string, phone_number: string, url: string, version: int>, assignee: string, status: string, client_user_id: string, audit_trail: record<source: string, dashboard_user_id: string, timestamp: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/entity/update")
  let body = {entity_watchlist_screening_id: $entity_watchlist_screening_id, search_terms: $search_terms, assignee: $assignee, status: $status, client_user_id: $client_user_id, client_id: $client_id, secret: $secret, reset_fields: $reset_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a watchlist screening for a person
#
# POST /watchlist_screening/individual/create
# Docs: /api/products/monitor/#watchlist_screeningindividualcreate
# operationId: watchlistScreeningIndividualCreate
# --search_terms shape: {watchlist_program_id: string, legal_name: string, date_of_birth?: string, document_number?: string, country?: string}
export def "watchlist-screening-individual-create watchlistScreeningIndividualCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  search_terms: record # Search inputs for creating a watchlist screening — shape: {watchlist_program_id: string, legal_name: string, date_of_birth?: string, document_number?: string, country?: string}
  --client-user-id: string # A unique ID that identifies the end user in your system. Either a `user_id` or the `client_user_id` must be provided. This ID can also be used to associate user-specific data from other Plaid products. Financial Account Matching requires this field and the `/link/token/create` `client_user_id` to be consistent. Personally identifiable information, such as an email address or phone number, should not be used in the `client_user_id`. (e.g. your-db-id-3b24110)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<id: string, search_terms: record<watchlist_program_id: string, legal_name: string, date_of_birth: string, document_number: string, country: string, version: int>, assignee: string, status: string, client_user_id: string, audit_trail: record<source: string, dashboard_user_id: string, timestamp: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/individual/create")
  let body = {search_terms: $search_terms, client_user_id: $client_user_id, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an individual watchlist screening
#
# POST /watchlist_screening/individual/get
# Docs: /api/products/monitor/#watchlist_screeningindividualget
# operationId: watchlistScreeningIndividualGet
export def "watchlist-screening-individual-get watchlistScreeningIndividualGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  watchlist_screening_id: string # ID of the associated screening. (e.g. scr_52xR9LKo77r1Np)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
]: any -> record<id: string, search_terms: record<watchlist_program_id: string, legal_name: string, date_of_birth: string, document_number: string, country: string, version: int>, assignee: string, status: string, client_user_id: string, audit_trail: record<source: string, dashboard_user_id: string, timestamp: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/individual/get")
  let body = {watchlist_screening_id: $watchlist_screening_id, secret: $secret, client_id: $client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List history for individual watchlist screenings
#
# POST /watchlist_screening/individual/history/list
# Docs: /api/products/monitor/#watchlist_screeningindividualhistorylist
# operationId: watchlistScreeningIndividualHistoryList
export def "watchlist-screening-individual-history-list watchlistScreeningIndividualHistoryList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  watchlist_screening_id: string # ID of the associated screening. (e.g. scr_52xR9LKo77r1Np)
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
]: any -> record<watchlist_screenings: table<id: string, search_terms: record, assignee: string, status: string, client_user_id: string, audit_trail: record>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/individual/history/list")
  let body = {secret: $secret, client_id: $client_id, watchlist_screening_id: $watchlist_screening_id, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List hits for individual watchlist screening
#
# POST /watchlist_screening/individual/hit/list
# Docs: /api/products/monitor/#watchlist_screeningindividualhitlist
# operationId: watchlistScreeningIndividualHitList
export def "watchlist-screening-individual-hit-list watchlistScreeningIndividualHitList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  watchlist_screening_id: string # ID of the associated screening. (e.g. scr_52xR9LKo77r1Np)
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
]: any -> record<watchlist_screening_hits: table<id: string, review_status: string, first_active: string, inactive_since: string, historical_since: string, list_code: string, plaid_uid: string, source_uid: string, sub_programs: list, analysis: record, data: record>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/individual/hit/list")
  let body = {secret: $secret, client_id: $client_id, watchlist_screening_id: $watchlist_screening_id, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Individual Watchlist Screenings
#
# POST /watchlist_screening/individual/list
# Docs: /api/products/monitor/#watchlist_screeningindividuallist
# operationId: watchlistScreeningIndividualList
export def "watchlist-screening-individual-list watchlistScreeningIndividualList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  watchlist_program_id: string # ID of the associated program. (e.g. prg_2eRPsDnL66rZ7H)
  --client-user-id: string # A unique ID that identifies the end user in your system. Either a `user_id` or the `client_user_id` must be provided. This ID can also be used to associate user-specific data from other Plaid products. Financial Account Matching requires this field and the `/link/token/create` `client_user_id` to be consistent. Personally identifiable information, such as an email address or phone number, should not be used in the `client_user_id`. (e.g. your-db-id-3b24110)
  --status: string@status-completer # A status enum indicating whether a screening is still pending review, has been rejected, or has been cleared. (e.g. cleared)
  --assignee: string # ID of the associated user. To retrieve the email address or other details of the person corresponding to this ID, use `/dashboard_user/get`. (e.g. 54350110fedcbaf01234ffee)
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
]: any -> record<watchlist_screenings: table<id: string, search_terms: record, assignee: string, status: string, client_user_id: string, audit_trail: record>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/individual/list")
  let body = {secret: $secret, client_id: $client_id, watchlist_program_id: $watchlist_program_id, client_user_id: $client_user_id, status: $status, assignee: $assignee, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get individual watchlist screening program
#
# POST /watchlist_screening/individual/program/get
# Docs: /api/products/monitor/#watchlist_screeningindividualprogramget
# operationId: watchlistScreeningIndividualProgramGet
export def "watchlist-screening-individual-program-get watchlistScreeningIndividualProgramGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  watchlist_program_id: string # ID of the associated program. (e.g. prg_2eRPsDnL66rZ7H)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
]: any -> record<id: string, created_at: string, is_rescanning_enabled: bool, lists_enabled: list<string>, name: string, name_sensitivity: string, audit_trail: record<source: string, dashboard_user_id: string, timestamp: string>, is_archived: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/individual/program/get")
  let body = {watchlist_program_id: $watchlist_program_id, secret: $secret, client_id: $client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List individual watchlist screening programs
#
# POST /watchlist_screening/individual/program/list
# Docs: /api/products/monitor/#watchlist_screeningindividualprogramlist
# operationId: watchlistScreeningIndividualProgramList
export def "watchlist-screening-individual-program-list watchlistScreeningIndividualProgramList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
]: any -> record<watchlist_programs: table<id: string, created_at: string, is_rescanning_enabled: bool, lists_enabled: list, name: string, name_sensitivity: string, audit_trail: record, is_archived: bool>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/individual/program/list")
  let body = {secret: $secret, client_id: $client_id, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a review for an individual watchlist screening
#
# POST /watchlist_screening/individual/review/create
# Docs: /api/products/monitor/#watchlist_screeningindividualreviewcreate
# operationId: watchlistScreeningIndividualReviewCreate
export def "watchlist-screening-individual-review-create watchlistScreeningIndividualReviewCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  confirmed_hits: list # Hits to mark as a true positive after thorough manual review. These hits will never recur or be updated once confirmed. In most cases, confirmed hits indicate that the customer should be rejected.
  dismissed_hits: list # Hits to mark as a false positive after thorough manual review. These hits will never recur or be updated once dismissed.
  --comment: string # A comment submitted by a team member as part of reviewing a watchlist screening. (nullable, e.g. These look like legitimate matches, rejecting the customer.)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  watchlist_screening_id: string # ID of the associated screening. (e.g. scr_52xR9LKo77r1Np)
]: any -> record<id: string, confirmed_hits: list<string>, dismissed_hits: list<string>, comment: string, audit_trail: record<source: string, dashboard_user_id: string, timestamp: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/individual/review/create")
  let body = {confirmed_hits: $confirmed_hits, dismissed_hits: $dismissed_hits, comment: $comment, client_id: $client_id, secret: $secret, watchlist_screening_id: $watchlist_screening_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List reviews for individual watchlist screenings
#
# POST /watchlist_screening/individual/review/list
# Docs: /api/products/monitor/#watchlist_screeningindividualreviewlist
# operationId: watchlistScreeningIndividualReviewList
export def "watchlist-screening-individual-review-list watchlistScreeningIndividualReviewList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  watchlist_screening_id: string # ID of the associated screening. (e.g. scr_52xR9LKo77r1Np)
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
]: any -> record<watchlist_screening_reviews: table<id: string, confirmed_hits: list, dismissed_hits: list, comment: string, audit_trail: record>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/individual/review/list")
  let body = {secret: $secret, client_id: $client_id, watchlist_screening_id: $watchlist_screening_id, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update individual watchlist screening
#
# POST /watchlist_screening/individual/update
# Docs: /api/products/monitor/#watchlist_screeningindividualupdate
# operationId: watchlistScreeningIndividualUpdate
# --search_terms shape: {watchlist_program_id?: string, legal_name?: string, date_of_birth?: string, document_number?: string, country?: string}
export def "watchlist-screening-individual-update watchlistScreeningIndividualUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  watchlist_screening_id: string # ID of the associated screening. (e.g. scr_52xR9LKo77r1Np)
  --search-terms: record # Search terms for editing an individual watchlist screening (nullable) — shape: {watchlist_program_id?: string, legal_name?: string, date_of_birth?: string, document_number?: string, country?: string}
  --assignee: string # ID of the associated user. To retrieve the email address or other details of the person corresponding to this ID, use `/dashboard_user/get`. (e.g. 54350110fedcbaf01234ffee)
  --status: string@status-completer # A status enum indicating whether a screening is still pending review, has been rejected, or has been cleared. (e.g. cleared)
  --client-user-id: string # A unique ID that identifies the end user in your system. Either a `user_id` or the `client_user_id` must be provided. This ID can also be used to associate user-specific data from other Plaid products. Financial Account Matching requires this field and the `/link/token/create` `client_user_id` to be consistent. Personally identifiable information, such as an email address or phone number, should not be used in the `client_user_id`. (e.g. your-db-id-3b24110)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --reset-fields: list # A list of fields to reset back to null (nullable)
]: any -> record<id: string, search_terms: record<watchlist_program_id: string, legal_name: string, date_of_birth: string, document_number: string, country: string, version: int>, assignee: string, status: string, client_user_id: string, audit_trail: record<source: string, dashboard_user_id: string, timestamp: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/watchlist_screening/individual/update")
  let body = {watchlist_screening_id: $watchlist_screening_id, search_terms: $search_terms, assignee: $assignee, status: $status, client_user_id: $client_user_id, client_id: $client_id, secret: $secret, reset_fields: $reset_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Evaluate risk of a bank account
#
# POST /beacon/account_risk/v1/evaluate
# Docs: none
# operationId: beaconAccountRiskEvaluate
# --options shape: {account_ids?: list}
# --device shape: {ip_address?: string, user_agent?: string}
export def "beacon-account-risk-evaluate beaconAccountRiskEvaluate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --access-token: string # The access token associated with the Item for which data is being requested.
  --options: record # An optional object to filter `/beacon/account_risk/v1/evaluate` results to a subset of the accounts on the linked Item. — shape: {account_ids?: list}
  --client-user-id: string # A unique ID that identifies the end user in your system. This ID is used to correlate requests by a user with multiple evaluations and/or multiple linked accounts. Personally identifiable information, such as an email address or phone number, should not be used in the `client_user_id`.
  --client-evaluation-id: string # Unique identifier of what you are looking to evaluate (account add, information change, etc.) to allow us to tie the activity to the decisions and possible fraud outcome sent via our feedback endpoints. You can use your internal request ID or similar.
  --evaluation-reason: string@evaluation-reason-completer # Description of the reason you want to evaluate risk. `ONBOARDING`: user links a first bank account as part of the onboarding flow of your platform. `NEW_ACCOUNT`: user links another bank account or replaces the currently linked bank account on your platform. `INFORMATION_CHANGE`: user changes their information on your platform, e.g., updating their phone number. `DORMANT_USER`:  you decide to re-evaluate a user that becomes active after a period of inactivity. `OTHER`: any other reasons not listed here Possible values:  `ONBOARDING`, `NEW_ACCOUNT`, `INFORMATION_CHANGE`, `DORMANT_USER`, `OTHER`
  --device: record # Details about the end user's device. These fields are optional, but strongly recommended to increase the accuracy of results when using Signal Transaction Scores. When using a Balance-only Ruleset, these fields are ignored if the Signal Addendum has been signed; if it has not been signed, using these fields will result in an error. — shape: {ip_address?: string, user_agent?: string}
  --evaluate-time: string # The time the event for evaluation has occurred. Populate this field for backfilling data. If you don't populate this field, we'll use the timestamp at the time of receipt. Use ISO 8601 format (YYYY-MM-DDTHH:mm:ssZ).
]: any -> record<request_id: string, accounts: table<account_id: string, type: string, subtype: string, attributes: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beacon/account_risk/v1/evaluate")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, options: $options, client_user_id: $client_user_id, client_evaluation_id: $client_evaluation_id, evaluation_reason: $evaluation_reason, device: $device, evaluate_time: $evaluate_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a Beacon User
#
# POST /beacon/user/create
# Docs: /api/products/beacon/#beaconusercreate
# operationId: beaconUserCreate
# --user shape: {date_of_birth?: string, name: record, address?: record, email_address?: string, phone_number?: string, id_number?: record, ip_address?: string, depository_accounts?: list}
export def "beacon-user-create beaconUserCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  program_id: string # ID of the associated Beacon Program. (e.g. becprg_11111111111111)
  client_user_id: string # A unique ID that identifies the end user in your system. Either a `user_id` or the `client_user_id` must be provided. This ID can also be used to associate user-specific data from other Plaid products. Financial Account Matching requires this field and the `/link/token/create` `client_user_id` to be consistent. Personally identifiable information, such as an email address or phone number, should not be used in the `client_user_id`. (e.g. your-db-id-3b24110)
  user: record # A Beacon User's data which is used to check against duplicate records and the Beacon Fraud Network.  In order to create a Beacon User, in addition to the `name`, _either_ the `date_of_birth` _or_ the `depository_accounts` field must be provided. — shape: {date_of_birth?: string, name: record, address?: record, email_address?: string, phone_number?: string, id_number?: record, ip_address?: string, depository_accounts?: list}
  --access-tokens: list # Send this array of access tokens to link accounts to the Beacon User and have them evaluated for Account Insights. A maximum of 50 accounts total can be added to a single Beacon User. (nullable)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<item_ids: list<string>, id: string, version: int, created_at: string, updated_at: string, status: string, program_id: string, client_user_id: string, user: record<date_of_birth: string, name: record<given_name: string, family_name: string>, address: record<street: string, street2: string, city: string, region: string, postal_code: string, country: string>, email_address: string, phone_number: string, id_number: record<value: string, type: string>, ip_address: string, depository_accounts: list<record>>, audit_trail: record<source: string, dashboard_user_id: string, timestamp: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beacon/user/create")
  let body = {program_id: $program_id, client_user_id: $client_user_id, user: $user, access_tokens: $access_tokens, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Beacon User
#
# POST /beacon/user/get
# Docs: /api/products/beacon/#beaconuserget
# operationId: beaconUserGet
export def "beacon-user-get beaconUserGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  beacon_user_id: string # ID of the associated Beacon User. (e.g. becusr_42cF1MNo42r9Xj)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<item_ids: list<string>, id: string, version: int, created_at: string, updated_at: string, status: string, program_id: string, client_user_id: string, user: record<date_of_birth: string, name: record<given_name: string, family_name: string>, address: record<street: string, street2: string, city: string, region: string, postal_code: string, country: string>, email_address: string, phone_number: string, id_number: record<value: string, type: string>, ip_address: string, depository_accounts: list<record>>, audit_trail: record<source: string, dashboard_user_id: string, timestamp: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beacon/user/get")
  let body = {beacon_user_id: $beacon_user_id, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Review a Beacon User
#
# POST /beacon/user/review
# Docs: /api/products/beacon/#beaconuserreview
# operationId: beaconUserReview
export def "beacon-user-review beaconUserReview" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  beacon_user_id: string # ID of the associated Beacon User. (e.g. becusr_42cF1MNo42r9Xj)
  status: string@status-completer # A status of a Beacon User.  `rejected`: The Beacon User has been rejected for fraud. Users can be automatically or manually rejected.  `pending_review`: The Beacon User has been marked for review.  `cleared`: The Beacon User has been cleared of fraud. (e.g. cleared)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<item_ids: list<string>, id: string, version: int, created_at: string, updated_at: string, status: string, program_id: string, client_user_id: string, user: record<date_of_birth: string, name: record<given_name: string, family_name: string>, address: record<street: string, street2: string, city: string, region: string, postal_code: string, country: string>, email_address: string, phone_number: string, id_number: record<value: string, type: string>, ip_address: string, depository_accounts: list<record>>, audit_trail: record<source: string, dashboard_user_id: string, timestamp: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beacon/user/review")
  let body = {beacon_user_id: $beacon_user_id, status: $status, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a Beacon Report
#
# POST /beacon/report/create
# Docs: /api/products/beacon/#beaconreportcreate
# operationId: beaconReportCreate
# --fraud_amount shape: {iso_currency_code: "USD", value: float}
export def "beacon-report-create beaconReportCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  beacon_user_id: string # ID of the associated Beacon User. (e.g. becusr_42cF1MNo42r9Xj)
  type: string@type-completer # The type of Beacon Report.  `first_party`: If this is the same individual as the one who submitted the KYC.  `stolen`: If this is a different individual from the one who submitted the KYC.  `synthetic`: If this is an individual using fabricated information.  `account_takeover`: If this individual's account was compromised.  `unknown`: If you aren't sure who committed the fraud.
  fraud_date: string # A date in the format YYYY-MM-DD (RFC 3339 Section 5.6). (format: date, e.g. 1990-05-29)
  --fraud-amount: record # The amount and currency of the fraud or attempted fraud. `fraud_amount` should be omitted to indicate an unknown fraud amount. (nullable) — shape: {iso_currency_code: "USD", value: float}
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<id: string, beacon_user_id: string, created_at: string, type: string, fraud_date: string, event_date: string, fraud_amount: record<iso_currency_code: string, value: float>, audit_trail: record<source: string, dashboard_user_id: string, timestamp: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beacon/report/create")
  let body = {beacon_user_id: $beacon_user_id, type: $type, fraud_date: $fraud_date, fraud_amount: $fraud_amount, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Beacon Reports for a Beacon User
#
# POST /beacon/report/list
# Docs: /api/products/beacon/#beaconreportlist
# operationId: beaconReportList
export def "beacon-report-list beaconReportList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  beacon_user_id: string # ID of the associated Beacon User. (e.g. becusr_42cF1MNo42r9Xj)
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<beacon_reports: table<id: string, beacon_user_id: string, created_at: string, type: string, fraud_date: string, event_date: string, fraud_amount: record, audit_trail: record>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beacon/report/list")
  let body = {beacon_user_id: $beacon_user_id, cursor: $cursor, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Beacon Report Syndications for a Beacon User
#
# POST /beacon/report_syndication/list
# Docs: /api/products/beacon/#beaconreport_syndicationlist
# operationId: beaconReportSyndicationList
export def "beacon-report-syndication-list beaconReportSyndicationList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  beacon_user_id: string # ID of the associated Beacon User. (e.g. becusr_42cF1MNo42r9Xj)
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<beacon_report_syndications: table<id: string, beacon_user_id: string, report: record, analysis: record>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beacon/report_syndication/list")
  let body = {beacon_user_id: $beacon_user_id, cursor: $cursor, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Beacon Report
#
# POST /beacon/report/get
# Docs: /api/products/beacon/#beaconreportget
# operationId: beaconReportGet
export def "beacon-report-get beaconReportGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  beacon_report_id: string # ID of the associated Beacon Report. (e.g. becrpt_11111111111111)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<id: string, beacon_user_id: string, created_at: string, type: string, fraud_date: string, event_date: string, fraud_amount: record<iso_currency_code: string, value: float>, audit_trail: record<source: string, dashboard_user_id: string, timestamp: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beacon/report/get")
  let body = {beacon_report_id: $beacon_report_id, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Beacon Report Syndication
#
# POST /beacon/report_syndication/get
# Docs: /api/products/beacon/#beaconreport_syndicationget
# operationId: beaconReportSyndicationGet
export def "beacon-report-syndication-get beaconReportSyndicationGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  beacon_report_syndication_id: string # ID of the associated Beacon Report Syndication. (e.g. becrsn_11111111111111)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<id: string, beacon_user_id: string, report: record<id: string, created_at: string, type: string, fraud_date: string, event_date: string>, analysis: record<address: string, date_of_birth: string, email_address: string, name: string, id_number: string, ip_address: string, phone_number: string, depository_accounts: list<record>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beacon/report_syndication/get")
  let body = {beacon_report_syndication_id: $beacon_report_syndication_id, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the identity data of a Beacon User
#
# POST /beacon/user/update
# Docs: /api/products/beacon/#beaconuserupdate
# operationId: beaconUserUpdate
# --user shape: {date_of_birth?: string, name?: record, address?: record, email_address?: string, phone_number?: string, id_number?: record, ip_address?: string, depository_accounts?: list}
export def "beacon-user-update beaconUserUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  beacon_user_id: string # ID of the associated Beacon User. (e.g. becusr_42cF1MNo42r9Xj)
  --user: record # A subset of a Beacon User's data which is used to patch the existing identity data associated with a Beacon User. At least one field must be provided. If left unset or null, user data will not be patched. (nullable) — shape: {date_of_birth?: string, name?: record, address?: record, email_address?: string, phone_number?: string, id_number?: record, ip_address?: string, depository_accounts?: list}
  --access-tokens: list # Send this array of access tokens to add accounts to this user for evaluation. This will add accounts to this Beacon User. If left null only existing accounts will be returned in response. A maximum of 50 accounts total can be added to a Beacon User. (nullable)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<item_ids: list<string>, id: string, version: int, created_at: string, updated_at: string, status: string, program_id: string, client_user_id: string, user: record<date_of_birth: string, name: record<given_name: string, family_name: string>, address: record<street: string, street2: string, city: string, region: string, postal_code: string, country: string>, email_address: string, phone_number: string, id_number: record<value: string, type: string>, ip_address: string, depository_accounts: list<record>>, audit_trail: record<source: string, dashboard_user_id: string, timestamp: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beacon/user/update")
  let body = {beacon_user_id: $beacon_user_id, user: $user, access_tokens: $access_tokens, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Beacon Duplicate
#
# POST /beacon/duplicate/get
# Docs: /api/products/beacon/#beaconduplicateget
# operationId: beaconDuplicateGet
export def "beacon-duplicate-get beaconDuplicateGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  beacon_duplicate_id: string # ID of the associated Beacon Duplicate. (e.g. becdup_11111111111111)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<id: string, beacon_user1: record<id: string, version: int>, beacon_user2: record<id: string, version: int>, analysis: record<address: string, date_of_birth: string, email_address: string, name: string, id_number: string, ip_address: string, phone_number: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beacon/duplicate/get")
  let body = {beacon_duplicate_id: $beacon_duplicate_id, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create autofill for an Identity Verification
#
# POST /identity_verification/autofill/create
# Docs: /api/products/identity-verification/#identity_verificationautofillcreate
# operationId: identityVerificationAutofillCreate
export def "identity-verification-autofill-create identityVerificationAutofillCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  identity_verification_id: string # ID of the associated Identity Verification attempt. (e.g. idv_52xR9LKo77r1Np)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<status: string, user: record<name: record<given_name: string, family_name: string>, address: record<street: string, street2: string, city: string, region: string, postal_code: string, country: string, po_box: string, type: string>, id_number: record<value: string, type: string>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/identity_verification/autofill/create")
  let body = {identity_verification_id: $identity_verification_id, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List a Beacon User's history
#
# POST /beacon/user/history/list
# Docs: /api/products/beacon/#beaconuserhistorylist
# operationId: beaconUserHistoryList
export def "beacon-user-history-list beaconUserHistoryList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  beacon_user_id: string # ID of the associated Beacon User. (e.g. becusr_42cF1MNo42r9Xj)
  --cursor: string # An identifier that determines which page of results you receive. (nullable, e.g. eyJkaXJlY3Rpb24iOiJuZXh0Iiwib2Zmc2V0IjoiMTU5NDM)
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<beacon_users: table<item_ids: list, id: string, version: int, created_at: string, updated_at: string, status: string, program_id: string, client_user_id: string, user: record, audit_trail: record>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beacon/user/history/list")
  let body = {beacon_user_id: $beacon_user_id, cursor: $cursor, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Account Insights for a Beacon User
#
# POST /beacon/user/account_insights/get
# Docs: /api/products/beacon/#beaconuseraccount_insightsget
# operationId: beaconUserAccountInsightsGet
export def "beacon-user-account-insights-get beaconUserAccountInsightsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  beacon_user_id: string # ID of the associated Beacon User. (e.g. becusr_42cF1MNo42r9Xj)
  access_token: string # The access token associated with the Item for which data is being requested.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<beacon_user_id: string, created_at: string, updated_at: string, bank_account_insights: record<item_id: string, accounts: list<record>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beacon/user/account_insights/get")
  let body = {beacon_user_id: $beacon_user_id, access_token: $access_token, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Protect user insights
#
# POST /protect/user/insights/get
# Docs: /api/products/protect/#protectuserinsightsget
# operationId: protectUserInsightsGet
export def "protect-user-insights-get protectUserInsightsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-id: string # The Plaid User ID. Either `user_id` or `client_user_id` must be provided.
  --client-user-id: string # A unique ID representing the end user. Either `user_id` or `client_user_id` must be provided.
]: any -> record<user_id: string, latest_scored_event: record<event_id: string, timestamp: string, event_type: string, trust_index: record<score: int, model: string, subscores: record>, fraud_attributes: record>, reports: table<report_id: string, incident_event: record, report_confidence: string, report_type: string, report_source: string, bank_account: record, ach_return_code: string, notes: string, created_at: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/protect/user/insights/get")
  let body = {client_id: $client_id, secret: $secret, user_id: $user_id, client_user_id: $client_user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a Protect report
#
# POST /protect/report/create
# Docs: /api/products/protect/#protectreportcreate
# operationId: protectReportCreate
# --incident_event shape: {protect_event_id?: string, link_session_id?: string, idv_session_id?: string, signal_client_transaction_id?: string, internal_reference?: string, time?: string, amount?: record, access_token?: any}
# --bank_account shape: {account_id?: string, account_number?: string, routing_number?: string}
export def "protect-report-create protectReportCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-id: string # The Plaid User ID associated with the report.
  --incident-event: record # Details about the incident event. (nullable) — shape: {protect_event_id?: string, link_session_id?: string, idv_session_id?: string, signal_client_transaction_id?: string, internal_reference?: string, time?: string, amount?: record, access_token?: any}
  report_confidence: string@report-confidence-completer # The confidence level of the incident report. `CONFIRMED` indicates the incident has been verified and definitively occurred.  `SUSPECTED` indicates the incident is believed to have occurred but has not been fully verified.
  report_type: string@report-type-completer-1 # The type of incident being reported.  `USER_ACCOUNT_TAKEOVER` - Indicates that a legitimate user's account was accessed or controlled by an unauthorized party.  `FALSE_IDENTITY` - Indicates that a user created an account using stolen or fabricated identity information.  `STOLEN_IDENTITY` - Indicates that a user created an account using identity information belonging to a real individual without their consent.  `SYNTHETIC_IDENTITY` - Indicates that a user created an account using a fake or partially fabricated identity (e.g., combining real and fake information to form a new persona).  `MULTIPLE_USER_ACCOUNTS` - Indicates that the same individual is operating multiple accounts in violation of policy.  `SCAM_VICTIM` - Indicates that the user was tricked into authorizing or sending funds as part of a scam.  `BANK_ACCOUNT_TAKEOVER` - Indicates that a user's linked bank account was accessed or misused by an unauthorized party.  `BANK_CONNECTION_REVOKED` - Indicates that a linked bank account connection was revoked by the financial institution, often due to suspected misuse, fraud, or security concerns.  `CARD_TESTING` - Indicates that a card was used in small or repeated transactions to test its validity.  `UNAUTHORIZED_TRANSACTION` - Indicates that a transaction was made without the user's consent or authorization.  `CARD_CHARGEBACK` - Indicates that a card transaction was reversed via a chargeback claim.  `ACH_RETURN` - Indicates that an ACH transaction was returned or reversed by the bank.  `DISPUTE` - Indicates that a user filed a dispute regarding a transaction or account activity.  `FIRST_PARTY_FRAUD` - Indicates that a user intentionally misrepresented themselves or their actions for financial gain.  `MISSED_PAYMENT` - Indicates that a user failed to make a required payment on time.  `LOAN_STACKING` - Indicates that a user applied for or took out multiple loans simultaneously beyond their ability to repay.  `MONEY_LAUNDERING` - Indicates that funds are being moved through accounts to obscure their illicit origin.  `NO_FRAUD` - Indicates that an investigation determined no fraudulent activity occurred on user/event (positive label).  `OTHER` - Indicates that the case involves fraud or financial risk not covered by other report types. Requires notes describing the report.
  report_source: string@report-source-completer # The source that identified or reported the incident.  `INTERNAL_REVIEW` - Incident was identified through internal fraud investigations or review processes.  `USER_SELF_REPORTED` - Incident was reported directly by the affected user.  `BANK_FEEDBACK` - Incident was identified through bank feedback, including ACH returns and connection revocations.  `NETWORK_FEEDBACK` - Incident was identified through card network alerts or chargebacks.  `AUTOMATED_SYSTEM` - Incident was detected by automated systems such as fraud models or rule engines.  `THIRD_PARTY_ALERT` - Incident was identified through external vendor or consortium alerts.  `OTHER` - Incident was identified through a source not covered by other categories.
  --bank-account: record # Bank account information associated with the incident. (nullable) — shape: {account_id?: string, account_number?: string, routing_number?: string}
  --ach-return-code: string # Must be a valid ACH return code (e.g. `R01`), required if `report_type` is `ACH_RETURN`. (nullable)
  --notes: string # Additional context or details about the report, required if `report_type` is `OTHER`. (nullable)
]: any -> record<report_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/protect/report/create")
  let body = {client_id: $client_id, secret: $secret, user_id: $user_id, incident_event: $incident_event, report_confidence: $report_confidence, report_type: $report_type, report_source: $report_source, bank_account: $bank_account, ach_return_code: $ach_return_code, notes: $notes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Compute Protect Trust Index scores and subscores
#
# POST /protect/compute
# Docs: /api/products/protect/#protectcompute
# operationId: protectCompute
# --user shape: {user_id?: string, client_user_id?: string}
# --model_inputs shape: {link?: record, sdk?: record}
export def "protect-compute protectCompute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  model: string # The name of the Trust Index model to use for scoring, with a major.minor version suffix. Examples: `ti-link-session-2.0` (link-session fraud), `ti-identity-2.0` (identity fraud), `cash-advance-onboarding-1.0` (first cash advance), and `cash-advance-ongoing-1.0` (subsequent cash advances). The model specified may require certain fields within `model_inputs`; for example, `ti-link-session-2.0` requires the `link` field. Cash-advance models do not use `model_inputs`.
  user: record # Represents an end user for `/protect/compute` requests. — shape: {user_id?: string, client_user_id?: string}
  --model-inputs: record # Inputs required by certain Trust Index models. The `link` field is required for link-session models. Other model families (including cash-advance) are identified by `user` alone and do not use this object. (nullable) — shape: {link?: record, sdk?: record}
]: any -> record<score: int, model: string, attributes: record, subscores: record<cash_advance_bucket_0_25: int, cash_advance_bucket_25_50: int, cash_advance_bucket_50_100: int, cash_advance_bucket_100_200: int, cash_advance_bucket_200_300: int, cash_advance_bucket_300_400: int, cash_advance_bucket_400_500: int>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/protect/compute")
  let body = {client_id: $client_id, secret: $secret, model: $model, user: $user, model_inputs: $model_inputs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send a new event to enrich user data
#
# POST /protect/event/send
# DEPRECATED
# Docs: none
# operationId: protectEventSend
# --event shape: {timestamp: string, protect_session_id?: string, app_visit?: record, user_sign_in?: record, user_sign_up?: record}
@deprecated
export def "protect-event-send protectEventSend" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --timestamp: string # Timestamp of the event. Might be the current moment or a time in the past. In [ISO 8601](https://wikipedia.org/wiki/ISO_8601) format, e.g. `"2017-09-14T14:42:19.350Z"` (format: date-time)
  --event: record # Event data for Protect events. (nullable) — shape: {timestamp: string, protect_session_id?: string, app_visit?: record, user_sign_in?: record, user_sign_up?: record}
  --protect-session-id: string # Protect Session ID should be provided for any event correlated with a frontend user session started via the Protect SDK.
  --request-trust-index: string@bool-completer # Whether this event should be scored with Trust Index. The default is false.
]: any -> record<event_id: string, trust_index: record<score: int, model: string, subscores: record<device_and_connection: record, bank_account_insights: record>>, fraud_attributes: record, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/protect/event/send")
  let body = {client_id: $client_id, secret: $secret, timestamp: $timestamp, event: $event, protect_session_id: $protect_session_id, request_trust_index: $request_trust_index} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get information about a user event
#
# POST /protect/event/get
# DEPRECATED
# Docs: none
# operationId: protectEventGet
@deprecated
export def "protect-event-get protectEventGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  event_id: string # The event ID to retrieve information for.
]: any -> record<event_id: string, timestamp: string, trust_index: record<score: int, model: string, subscores: record<device_and_connection: record, bank_account_insights: record>>, fraud_attributes: record, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/protect/event/get")
  let body = {client_id: $client_id, secret: $secret, event_id: $event_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a Business Verification
#
# POST /business_verification/get
# Docs: /api/products/business-verification/#businessverificationget
# operationId: businessVerificationGet
export def "business-verification-get businessVerificationGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  business_verification_id: string # ID of the associated business verification. (format: cognito_id, e.g. busver_52xR9LKo77r1Np)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
]: any -> record<id: string, client_user_id: string, created_at: string, completed_at: string, redacted_at: string, status: string, search_terms: record<name: string, alternative_names: list<string>, address: record<street: string, street2: string, city: string, region: string, postal_code: string, country: string>, website: string, phone_number: string, email_address: string>, kyb_check: record<status: string, score: int, name: record<summary: string>, address: record<summary: string>, website: record<summary: string>, match_details: record<names: list, entity_type: string, addresses: list, phone_numbers: list, email_addresses: list, websites: list, formation_date: string>>, risk_check: record<status: string, score: int, industry_prediction: record>, digital_presence_check: record<status: string, score: int, address: record<summary: string>, phone_number: record<summary: string>, email_address: record<summary: string>, website: record<summary: string>, website_analysis: record<is_parked: string, email_is_deliverable: string, website_build_status: string, whois_record: record, ssl: record>>, request_id: string, shareable_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/business_verification/get")
  let body = {business_verification_id: $business_verification_id, secret: $secret, client_id: $client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a Business Verification
#
# POST /business_verification/create
# Docs: /api/products/business-verification/#businessverificationcreate
# operationId: businessVerificationCreate
# --business shape: {name?: string, alternative_name?: string, address?: record, website?: string, phone_number?: string, email_address?: string}
export def "business-verification-create businessVerificationCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_user_id: string # A unique ID that identifies the end user in your system. Either a `user_id` or the `client_user_id` must be provided. This ID can also be used to associate user-specific data from other Plaid products. Financial Account Matching requires this field and the `/link/token/create` `client_user_id` to be consistent. Personally identifiable information, such as an email address or phone number, should not be used in the `client_user_id`. (e.g. your-db-id-3b24110)
  --business: record # Business information provided in the verification request (nullable) — shape: {name?: string, alternative_name?: string, address?: record, website?: string, phone_number?: string, email_address?: string}
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<id: string, client_user_id: string, created_at: string, completed_at: string, redacted_at: string, status: string, search_terms: record<name: string, alternative_names: list<string>, address: record<street: string, street2: string, city: string, region: string, postal_code: string, country: string>, website: string, phone_number: string, email_address: string>, kyb_check: record<status: string, score: int, name: record<summary: string>, address: record<summary: string>, website: record<summary: string>, match_details: record<names: list, entity_type: string, addresses: list, phone_numbers: list, email_addresses: list, websites: list, formation_date: string>>, risk_check: record<status: string, score: int, industry_prediction: record>, digital_presence_check: record<status: string, score: int, address: record<summary: string>, phone_number: record<summary: string>, email_address: record<summary: string>, website: record<summary: string>, website_analysis: record<is_parked: string, email_is_deliverable: string, website_build_status: string, whois_record: record, ssl: record>>, request_id: string, shareable_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/business_verification/create")
  let body = {client_user_id: $client_user_id, business: $business, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Auth data
#
# POST /processor/auth/get
# Docs: /api/processor-partners/#processorauthget
# operationId: processorAuthGet
export def "processor-auth-get processorAuthGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
]: any -> record<request_id: string, numbers: record<ach: record<account_id: string, account: string, is_tokenized_account_number: bool, routing: string, wire_routing: string, can_transfer_in: bool, can_transfer_out: bool>, eft: record<account_id: string, account: string, institution: string, branch: string>, international: record<account_id: string, iban: string, bic: string>, bacs: record<account_id: string, account: string, sort_code: string>>, account: record<account_id: string, balances: record<available: float, current: float, limit: float, iso_currency_code: string, unofficial_currency_code: string, last_updated_datetime: string>, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record<name_match_score: int, network_status: record, previous_returns: record, account_number_format: string>, persistent_account_id: string, holder_category: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/auth/get")
  let body = {client_id: $client_id, secret: $secret, processor_token: $processor_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the account associated with a processor token
#
# POST /processor/account/get
# Docs: /api/processor-partners/#processoraccountget
# operationId: processorAccountGet
export def "processor-account-get processorAccountGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<account: record<account_id: string, balances: record<available: float, current: float, limit: float, iso_currency_code: string, unofficial_currency_code: string, last_updated_datetime: string>, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record<name_match_score: int, network_status: record, previous_returns: record, account_number_format: string>, persistent_account_id: string, holder_category: string>, institution_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/account/get")
  let body = {client_id: $client_id, processor_token: $processor_token, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Investment Holdings
#
# POST /processor/investments/holdings/get
# Docs: /api/processor-partners/#processorinvestmentsholdingsget
# operationId: processorInvestmentsHoldingsGet
export def "processor-investments-holdings-get processorInvestmentsHoldingsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<account: record<account_id: string, balances: record<available: float, current: float, limit: float, iso_currency_code: string, unofficial_currency_code: string, last_updated_datetime: string, margin_loan_amount: float>, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record<name_match_score: int, network_status: record, previous_returns: record, account_number_format: string>, persistent_account_id: string, holder_category: string>, holdings: table<account_id: string, security_id: string, institution_price: float, institution_price_as_of: string, institution_price_datetime: string, institution_value: float, cost_basis: float, quantity: float, iso_currency_code: string, unofficial_currency_code: string, vested_quantity: float, vested_value: float, tax_lots: list>, securities: table<security_id: string, isin: string, cusip: string, sedol: string, institution_security_id: string, institution_id: string, proxy_security_id: string, name: string, ticker_symbol: string, is_cash_equivalent: bool, type: string, subtype: string, close_price: float, close_price_as_of: string, update_datetime: string, iso_currency_code: string, unofficial_currency_code: string, market_identifier_code: string, sector: string, industry: string, cfi_code: string, option_contract: record, fixed_income: record>, is_investments_fallback_item: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/investments/holdings/get")
  let body = {client_id: $client_id, processor_token: $processor_token, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get investment account authentication data
#
# POST /processor/investments/auth/get
# Docs: /api/processor-partners/#processorinvestmentsauthget
# operationId: processorInvestmentsAuthGet
export def "processor-investments-auth-get processorInvestmentsAuthGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
]: any -> record<account: record<account_id: string, balances: record<available: float, current: float, limit: float, iso_currency_code: string, unofficial_currency_code: string, last_updated_datetime: string>, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record<name_match_score: int, network_status: record, previous_returns: record, account_number_format: string>, persistent_account_id: string, holder_category: string>, holdings: table<account_id: string, security_id: string, institution_price: float, institution_price_as_of: string, institution_price_datetime: string, institution_value: float, cost_basis: float, quantity: float, iso_currency_code: string, unofficial_currency_code: string, vested_quantity: float, vested_value: float, tax_lots: list>, securities: table<security_id: string, isin: string, cusip: string, sedol: string, institution_security_id: string, institution_id: string, proxy_security_id: string, name: string, ticker_symbol: string, is_cash_equivalent: bool, type: string, subtype: string, close_price: float, close_price_as_of: string, update_datetime: string, iso_currency_code: string, unofficial_currency_code: string, market_identifier_code: string, sector: string, industry: string, cfi_code: string, option_contract: record, fixed_income: record>, owners: table<account_id: string, names: list>, numbers: record<acats: list<record>, aton: list<record>, retirement_401k: list<record>>, data_sources: record<numbers: string, owners: string, holdings: string>, account_details_401k: table<account_id: string, fee_details: record, contribution_details: record>, is_investments_fallback_item: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/investments/auth/get")
  let body = {client_id: $client_id, secret: $secret, processor_token: $processor_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get investment transactions data
#
# POST /processor/investments/transactions/get
# Docs: /api/processor-partners/#processorinvestmentstransactionsget
# operationId: processorInvestmentsTransactionsGet
# --options shape: {account_ids?: list, count?: int, offset?: int, async_update?: bool}
export def "processor-investments-transactions-get processorInvestmentsTransactionsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --options: record # An optional object to filter `/investments/transactions/get` results. If provided, must be non-`null`. — shape: {account_ids?: list, count?: int, offset?: int, async_update?: bool}
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  start_date: string # The earliest date for which data should be returned. Dates should be formatted as YYYY-MM-DD. (format: date)
  end_date: string # The latest date for which data should be returned. Dates should be formatted as YYYY-MM-DD. (format: date)
]: any -> record<account: record<account_id: string, balances: record<available: float, current: float, limit: float, iso_currency_code: string, unofficial_currency_code: string, last_updated_datetime: string, margin_loan_amount: float>, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record<name_match_score: int, network_status: record, previous_returns: record, account_number_format: string>, persistent_account_id: string, holder_category: string>, investment_transactions: table<investment_transaction_id: string, cancel_transaction_id: string, account_id: string, security_id: string, date: string, transaction_datetime: string, name: string, quantity: float, amount: float, price: float, fees: float, type: string, subtype: string, iso_currency_code: string, unofficial_currency_code: string>, securities: table<security_id: string, isin: string, cusip: string, sedol: string, institution_security_id: string, institution_id: string, proxy_security_id: string, name: string, ticker_symbol: string, is_cash_equivalent: bool, type: string, subtype: string, close_price: float, close_price_as_of: string, update_datetime: string, iso_currency_code: string, unofficial_currency_code: string, market_identifier_code: string, sector: string, industry: string, cfi_code: string, option_contract: record, fixed_income: record>, total_investment_transactions: int, request_id: string, is_investments_fallback_item: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/investments/transactions/get")
  let body = {client_id: $client_id, options: $options, processor_token: $processor_token, secret: $secret, start_date: $start_date, end_date: $end_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get transaction data
#
# POST /processor/transactions/get
# Docs: /api/processor-partners/#processortransactionsget
# operationId: processorTransactionsGet
# --options shape: {count?: int, offset?: int, include_original_description?: bool, include_personal_finance_category_beta?: bool, include_personal_finance_category?: bool, include_logo_and_counterparty_beta?: bool}
export def "processor-transactions-get processorTransactionsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --options: record # An optional object to be used with the request. If specified, `options` must not be `null`. — shape: {count?: int, offset?: int, include_original_description?: bool, include_personal_finance_category_beta?: bool, include_personal_finance_category?: bool, include_logo_and_counterparty_beta?: bool}
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  start_date: string # The earliest date for which data should be returned. Dates should be formatted as YYYY-MM-DD. (format: date)
  end_date: string # The latest date for which data should be returned. Dates should be formatted as YYYY-MM-DD. (format: date)
]: any -> record<account: record<account_id: string, balances: record<available: float, current: float, limit: float, iso_currency_code: string, unofficial_currency_code: string, last_updated_datetime: string>, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record<name_match_score: int, network_status: record, previous_returns: record, account_number_format: string>, persistent_account_id: string, holder_category: string>, transactions: table<account_id: string, amount: float, iso_currency_code: string, unofficial_currency_code: string, category: list, category_id: string, check_number: string, date: string, location: record, name: string, merchant_name: string, original_description: string, payment_meta: record, pending: bool, pending_transaction_id: string, account_owner: string, transaction_id: string, transaction_type: string, logo_url: string, website: string, authorized_date: string, authorized_datetime: string, datetime: string, payment_channel: string, personal_finance_category: record, business_finance_category: record, transaction_code: string, personal_finance_category_icon_url: string, counterparties: list, merchant_entity_id: string, client_customization: record>, total_transactions: int, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/transactions/get")
  let body = {client_id: $client_id, options: $options, processor_token: $processor_token, secret: $secret, start_date: $start_date, end_date: $end_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get incremental transaction updates on a processor token
#
# POST /processor/transactions/sync
# Docs: /api/processor-partners/#processortransactionssync
# operationId: processorTransactionsSync
# --options shape: {include_original_description?: bool, include_personal_finance_category?: bool, include_logo_and_counterparty_beta?: bool, personal_finance_category_version?: "v1"|"v2", days_requested?: int, account_id?: string}
export def "processor-transactions-sync processorTransactionsSync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --cursor: string # The cursor value represents the last update requested. Providing it will cause the response to only return changes after this update. If omitted, the entire history of updates will be returned, starting with the first-added transactions on the Item. Note: The upper-bound length of this cursor is 256 characters of base64.
  --count: int # The number of transaction updates to fetch. (default: 100)
  --options: record # An optional object to be used with the request. If specified, `options` must not be `null`. — shape: {include_original_description?: bool, include_personal_finance_category?: bool, include_logo_and_counterparty_beta?: bool, personal_finance_category_version?: "v1"|"v2", days_requested?: int, account_id?: string}
]: any -> record<transactions_update_status: string, account: record, added: table<account_id: string, amount: float, iso_currency_code: string, unofficial_currency_code: string, category: list, category_id: string, check_number: string, date: string, location: record, name: string, merchant_name: string, original_description: string, payment_meta: record, pending: bool, pending_transaction_id: string, account_owner: string, transaction_id: string, transaction_type: string, logo_url: string, website: string, authorized_date: string, authorized_datetime: string, datetime: string, payment_channel: string, personal_finance_category: record, business_finance_category: record, transaction_code: string, personal_finance_category_icon_url: string, counterparties: list, merchant_entity_id: string, client_customization: record>, modified: table<account_id: string, amount: float, iso_currency_code: string, unofficial_currency_code: string, category: list, category_id: string, check_number: string, date: string, location: record, name: string, merchant_name: string, original_description: string, payment_meta: record, pending: bool, pending_transaction_id: string, account_owner: string, transaction_id: string, transaction_type: string, logo_url: string, website: string, authorized_date: string, authorized_datetime: string, datetime: string, payment_channel: string, personal_finance_category: record, business_finance_category: record, transaction_code: string, personal_finance_category_icon_url: string, counterparties: list, merchant_entity_id: string, client_customization: record>, removed: table<transaction_id: string, account_id: string>, next_cursor: string, has_more: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/transactions/sync")
  let body = {client_id: $client_id, processor_token: $processor_token, secret: $secret, cursor: $cursor, count: $count, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Refresh transaction data
#
# POST /processor/transactions/refresh
# Docs: /api/processor-partners/#processortransactionsrefresh
# operationId: processorTransactionsRefresh
export def "processor-transactions-refresh processorTransactionsRefresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/transactions/refresh")
  let body = {client_id: $client_id, processor_token: $processor_token, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch recurring transaction streams
#
# POST /processor/transactions/recurring/get
# Docs: /api/processor-partners/#processortransactionsrecurringget
# operationId: processorTransactionsRecurringGet
# --options shape: {include_personal_finance_category?: bool, personal_finance_category_version?: "v1"|"v2"}
export def "processor-transactions-recurring-get processorTransactionsRecurringGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --options: record # An optional object to be used with the request. If specified, `options` must not be `null`. — shape: {include_personal_finance_category?: bool, personal_finance_category_version?: "v1"|"v2"}
]: any -> record<inflow_streams: table<account_id: string, stream_id: string, category: list, category_id: string, description: string, merchant_name: string, first_date: string, last_date: string, predicted_next_date: string, frequency: string, transaction_ids: list, average_amount: record, last_amount: record, is_active: bool, status: string, personal_finance_category: record, is_user_modified: bool, last_user_modified_datetime: string>, outflow_streams: table<account_id: string, stream_id: string, category: list, category_id: string, description: string, merchant_name: string, first_date: string, last_date: string, predicted_next_date: string, frequency: string, transaction_ids: list, average_amount: record, last_amount: record, is_active: bool, status: string, personal_finance_category: record, is_user_modified: bool, last_user_modified_datetime: string>, updated_datetime: string, personal_finance_category_version: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/transactions/recurring/get")
  let body = {client_id: $client_id, processor_token: $processor_token, secret: $secret, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Evaluate a planned ACH transaction
#
# POST /processor/signal/evaluate
# Docs: /api/processor-partners/#processorsignalevaluate
# operationId: processorSignalEvaluate
# --user shape: {name?: record, phone_number?: string, email_address?: string, address?: record}
# --device shape: {ip_address?: string, user_agent?: string}
export def "processor-signal-evaluate processorSignalEvaluate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  client_transaction_id: string # The unique ID that you would like to use to refer to this transaction. For your convenience mapping your internal data, you could use your internal ID/identifier for this transaction. The max length for this field is 36 characters.
  amount: float # The transaction amount, in USD (e.g. `102.05`) (format: double)
  --user-present: string@bool-completer # `true` if the end user is present while initiating the ACH transfer and the endpoint is being called; `false` otherwise (for example, when the ACH transfer is scheduled and the end user is not present, or you call this endpoint after the ACH transfer but before submitting the Nacha file for ACH processing). (nullable)
  --client-user-id: string # A unique ID that identifies the end user in your system. This ID is used to correlate requests by a user with multiple Items. Personally identifiable information, such as an email address or phone number, should not be used in the `client_user_id`.
  --is-recurring: string@bool-completer # **true** if the ACH transaction is a recurring transaction; **false** otherwise. (nullable)
  --default-payment-method: string # The default ACH or non-ACH payment method to complete the transaction. `SAME_DAY_ACH`: Same Day ACH by Nacha. The debit transaction is processed and settled on the same day. `STANDARD_ACH`: Standard ACH by Nacha. `MULTIPLE_PAYMENT_METHODS`: If there is no default debit rail or there are multiple payment methods. Possible values:  `SAME_DAY_ACH`, `STANDARD_ACH`, `MULTIPLE_PAYMENT_METHODS` (nullable)
  --user: record # Details about the end user initiating the transaction (i.e., the account holder). These fields are optional, but strongly recommended to increase the accuracy of results when using Signal Transaction Scores. When using a Balance-only ruleset, if the Signal Addendum has been signed, these fields are ignored; if the Addendum has not been signed, using these fields will result in an error. — shape: {name?: record, phone_number?: string, email_address?: string, address?: record}
  --device: record # Details about the end user's device. These fields are optional, but strongly recommended to increase the accuracy of results when using Signal Transaction Scores. When using a Balance-only Ruleset, these fields are ignored if the Signal Addendum has been signed; if it has not been signed, using these fields will result in an error. — shape: {ip_address?: string, user_agent?: string}
  --ruleset-key: string # The key of the ruleset to use for this transaction. You can configure a ruleset using the Plaid Dashboard, under [Signal->Rules](https://dashboard.plaid.com/signal/risk-profiles). If not provided, for customers who began using Signal Transaction Scores before October 15, 2025, by default, no ruleset will be used; for customers who began using Signal Transaction Scores after that date, or for Balance customers, the `default` ruleset will be used. For more details, or to opt out of using a ruleset, see [Signal Rules](https://plaid.com/docs/signal/signal-rules/). (nullable)
]: any -> record<request_id: string, scores: record<customer_initiated_return_risk: record<score: int, risk_tier: int>, bank_initiated_return_risk: record<score: int, risk_tier: int>>, core_attributes: record<unauthorized_transactions_count_7d: int, unauthorized_transactions_count_30d: int, unauthorized_transactions_count_60d: int, unauthorized_transactions_count_90d: int, nsf_overdraft_transactions_count_7d: int, nsf_overdraft_transactions_count_30d: int, nsf_overdraft_transactions_count_60d: int, nsf_overdraft_transactions_count_90d: int, days_since_first_plaid_connection: int, plaid_connections_count_7d: int, plaid_connections_count_30d: int, total_plaid_connections_count: int, is_savings_or_money_market_account: bool, total_credit_transactions_amount_10d: float, total_debit_transactions_amount_10d: float, p50_credit_transactions_amount_28d: float, p50_debit_transactions_amount_28d: float, p95_credit_transactions_amount_28d: float, p95_debit_transactions_amount_28d: float, days_with_negative_balance_count_90d: int, p90_eod_balance_30d: float, p90_eod_balance_60d: float, p90_eod_balance_90d: float, p10_eod_balance_30d: float, p10_eod_balance_60d: float, p10_eod_balance_90d: float, available_balance: float, current_balance: float, balance_last_updated: string, phone_change_count_28d: int, phone_change_count_90d: int, email_change_count_28d: int, email_change_count_90d: int, address_change_count_28d: int, address_change_count_90d: int, plaid_non_oauth_authentication_attempts_count_3d: int, plaid_non_oauth_authentication_attempts_count_7d: int, plaid_non_oauth_authentication_attempts_count_30d: int, failed_plaid_non_oauth_authentication_attempts_count_3d: int, failed_plaid_non_oauth_authentication_attempts_count_7d: int, failed_plaid_non_oauth_authentication_attempts_count_30d: int, debit_transactions_count_10d: int, credit_transactions_count_10d: int, debit_transactions_count_30d: int, credit_transactions_count_30d: int, debit_transactions_count_60d: int, credit_transactions_count_60d: int, debit_transactions_count_90d: int, credit_transactions_count_90d: int, total_debit_transactions_amount_30d: float, total_credit_transactions_amount_30d: float, total_debit_transactions_amount_60d: float, total_credit_transactions_amount_60d: float, total_debit_transactions_amount_90d: float, total_credit_transactions_amount_90d: float, p50_eod_balance_30d: float, p50_eod_balance_60d: float, p50_eod_balance_90d: float, p50_eod_balance_31d_to_60d: float, p50_eod_balance_61d_to_90d: float, p90_eod_balance_31d_to_60d: float, p90_eod_balance_61d_to_90d: float, p10_eod_balance_31d_to_60d: float, p10_eod_balance_61d_to_90d: float, transactions_last_updated: string, is_account_closed: bool, is_account_frozen_or_restricted: bool, distinct_ip_addresses_count_3d: int, distinct_ip_addresses_count_7d: int, distinct_ip_addresses_count_30d: int, distinct_ip_addresses_count_90d: int, distinct_user_agents_count_3d: int, distinct_user_agents_count_7d: int, distinct_user_agents_count_30d: int, distinct_user_agents_count_90d: int, distinct_ssl_tls_connection_sessions_count_3d: int, distinct_ssl_tls_connection_sessions_count_7d: int, distinct_ssl_tls_connection_sessions_count_30d: int, distinct_ssl_tls_connection_sessions_count_90d: int, days_since_account_opening: int, balance_to_transaction_amount_ratio: float>, ruleset: record<ruleset_key: string, result: string, triggered_rule_details: record<internal_note: string, custom_action_key: string>, outcome: string>, warnings: table<warning_type: string, warning_code: string, warning_message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/signal/evaluate")
  let body = {client_id: $client_id, secret: $secret, processor_token: $processor_token, client_transaction_id: $client_transaction_id, amount: $amount, user_present: $user_present, client_user_id: $client_user_id, is_recurring: $is_recurring, default_payment_method: $default_payment_method, user: $user, device: $device, ruleset_key: $ruleset_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Report whether you initiated an ACH transaction
#
# POST /processor/signal/decision/report
# Docs: /api/processor-partners/#processorsignaldecisionreport
# operationId: processorSignalDecisionReport
export def "processor-signal-decision-report processorSignalDecisionReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  client_transaction_id: string # Must be the same as the `client_transaction_id` supplied when calling `/processor/signal/evaluate`
  --initiated: string@bool-completer # `true` if the ACH transaction was initiated, `false` otherwise.  This field must be returned as a boolean. If formatted incorrectly, this will result in an [`INVALID_FIELD`](https://plaid.com/docs/errors/invalid-request/#invalid_field) error.
  --days-funds-on-hold: int # The actual number of days (hold time) since the ACH debit transaction that you wait before making funds available to your customers. The holding time could affect the ACH return rate.  For example, use 0 if you make funds available to your customers instantly or the same day following the debit transaction, or 1 if you make funds available the next day following the debit initialization. (nullable)
  --decision-outcome: string@decision-outcome-completer # The payment decision from the risk assessment.  `APPROVE`: approve the transaction without requiring further actions from your customers. For example, use this field if you are placing a standard hold for all the approved transactions before making funds available to your customers. You should also use this field if you decide to accelerate the fund availability for your customers.  `REVIEW`: the transaction requires manual review  `REJECT`: reject the transaction  `TAKE_OTHER_RISK_MEASURES`: for example, placing a longer hold on funds than those approved transactions or introducing customer frictions such as step-up verification/authentication  `NOT_EVALUATED`: if only logging the results without using them  (nullable)
  --payment-method: string@payment-method-completer # The payment method to complete the transaction after the risk assessment. It may be different from the default payment method.  `SAME_DAY_ACH`: Same Day ACH by Nacha. The debit transaction is processed and settled on the same day.  `STANDARD_ACH`: Standard ACH by Nacha.  `MULTIPLE_PAYMENT_METHODS`: if there is no default debit rail or there are multiple payment methods.  (nullable)
  --amount-instantly-available: float # The amount (in USD) made available to your customers instantly following the debit transaction. It could be a partial amount of the requested transaction (example: 102.05). (nullable, format: double)
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/signal/decision/report")
  let body = {client_id: $client_id, secret: $secret, processor_token: $processor_token, client_transaction_id: $client_transaction_id, initiated: $initiated, days_funds_on_hold: $days_funds_on_hold, decision_outcome: $decision_outcome, payment_method: $payment_method, amount_instantly_available: $amount_instantly_available} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Report a return for an ACH transaction
#
# POST /processor/signal/return/report
# Docs: /api/processor-partners/#processorsignalreturnreport
# operationId: processorSignalReturnReport
export def "processor-signal-return-report processorSignalReturnReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  client_transaction_id: string # Must be the same as the `client_transaction_id` supplied when calling `/processor/signal/evaluate`
  return_code: string # Must be a valid ACH return code (e.g. "R01")  If formatted incorrectly, this will result in an [`INVALID_FIELD`](https://plaid.com/docs/errors/invalid-request/#invalid_field) error.
  --returned-at: string # Date and time when you receive the returns from your payment processors, in ISO 8601 format (`YYYY-MM-DDTHH:mm:ssZ`). (nullable, format: date-time)
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/signal/return/report")
  let body = {client_id: $client_id, secret: $secret, processor_token: $processor_token, client_transaction_id: $client_transaction_id, return_code: $return_code, returned_at: $returned_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Opt-in a processor token to Signal
#
# POST /processor/signal/prepare
# Docs: /api/processor-partners/#processorsignalprepare
# operationId: processorSignalPrepare
export def "processor-signal-prepare processorSignalPrepare" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/signal/prepare")
  let body = {client_id: $client_id, secret: $secret, processor_token: $processor_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a bank transfer as a processor
#
# POST /processor/bank_transfer/create
# Docs: /api/processor-partners/#bank_transfercreate
# operationId: processorBankTransferCreate
# --user shape: {legal_name: string, email_address?: string}
export def "processor-bank-transfer-create processorBankTransferCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  idempotency_key: string # A random key provided by the client, per unique bank transfer. Maximum of 50 characters.  The API supports idempotency for safely retrying requests without accidentally performing the same operation twice. For example, if a request to create a bank transfer fails due to a network connection error, you can retry the request with the same idempotency key to guarantee that only a single bank transfer is created.
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  type: string@type-completer-1 # The type of bank transfer. This will be either `debit` or `credit`.  A `debit` indicates a transfer of money into the origination account; a `credit` indicates a transfer of money out of the origination account.
  network: string@network-completer # The network or rails used for the transfer. Valid options are `ach`, `same-day-ach`, or `wire`.
  amount: string # The amount of the bank transfer (decimal string with two digits of precision e.g. "10.00").
  iso_currency_code: string # The currency of the transfer amount - should be set to "USD".
  description: string # The transfer description. Maximum of 10 characters.
  --ach-class: string@ach-class-completer # Specifies the use case of the transfer. Required for transfers on an ACH network. For more details, see [ACH SEC codes](https://plaid.com/docs/transfer/creating-transfers/#ach-sec-codes).  Codes supported for credits: `ccd`, `ppd` Codes supported for debits: `ccd`, `tel`, `web`  `"ccd"` - Corporate Credit or Debit - fund transfer between two corporate bank accounts  `"ppd"` - Prearranged Payment or Deposit - The transfer is part of a pre-existing relationship with a consumer. Authorization was obtained in writing either in person or via an electronic document signing, e.g. Docusign, by the consumer. Can be used for credits or debits.  `"web"` - Internet-Initiated Entry. The transfer debits a consumer's bank account. Authorization from the consumer is obtained over the Internet (e.g. a web or mobile application). Can be used for single debits or recurring debits.  `"tel"` - Telephone-Initiated Entry. The transfer debits a consumer. Debit authorization has been received orally over the telephone via a recorded call.
  user: record # The legal name and other information for the account holder. — shape: {legal_name: string, email_address?: string}
  --custom-tag: string # An arbitrary string provided by the client for storage with the bank transfer. May be up to 100 characters. (nullable)
  --metadata: record # The Metadata object is a mapping of client-provided string fields to any string value. The following limitations apply: The JSON values must be Strings (no nested JSON objects allowed) Only ASCII characters may be used Maximum of 50 key/value pairs Maximum key length of 40 characters Maximum value length of 500 characters  (nullable)
  --origination-account-id: string # Plaid's unique identifier for the origination account for this transfer. If you have more than one origination account, this value must be specified. (nullable)
]: any -> record<bank_transfer: record<id: string, ach_class: string, account_id: string, type: string, user: record<legal_name: string, email_address: string, routing_number: string>, amount: string, iso_currency_code: string, description: string, created: string, status: string, network: string, cancellable: bool, failure_reason: record<ach_return_code: string, description: string>, custom_tag: string, metadata: record, origination_account_id: string, direction: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/bank_transfer/create")
  let body = {client_id: $client_id, secret: $secret, idempotency_key: $idempotency_key, processor_token: $processor_token, type: $type, network: $network, amount: $amount, iso_currency_code: $iso_currency_code, description: $description, ach_class: $ach_class, user: $user, custom_tag: $custom_tag, metadata: $metadata, origination_account_id: $origination_account_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Liabilities data
#
# POST /processor/liabilities/get
# Docs: /api/processor-partners/#processorliabilitiesget
# operationId: processorLiabilitiesGet
export def "processor-liabilities-get processorLiabilitiesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
]: any -> record<account: record<account_id: string, balances: record<available: float, current: float, limit: float, iso_currency_code: string, unofficial_currency_code: string, last_updated_datetime: string>, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record<name_match_score: int, network_status: record, previous_returns: record, account_number_format: string>, persistent_account_id: string, holder_category: string>, liabilities: record<credit: list<record>, mortgage: list<record>, student: list<record>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/liabilities/get")
  let body = {client_id: $client_id, secret: $secret, processor_token: $processor_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Identity data
#
# POST /processor/identity/get
# Docs: /api/processor-partners/#processoridentityget
# operationId: processorIdentityGet
export def "processor-identity-get processorIdentityGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
]: any -> record<account: record<account_id: string, balances: record<available: float, current: float, limit: float, iso_currency_code: string, unofficial_currency_code: string, last_updated_datetime: string>, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record<name_match_score: int, network_status: record, previous_returns: record, account_number_format: string>, persistent_account_id: string, holder_category: string, owners: list<record>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/identity/get")
  let body = {client_id: $client_id, secret: $secret, processor_token: $processor_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve identity match score
#
# POST /processor/identity/match
# Docs: /api/processor-partners/#processoridentitymatch
# operationId: processorIdentityMatch
# --user shape: {legal_name?: string, phone_number?: string, email_address?: string, address?: any}
export def "processor-identity-match processorIdentityMatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  --user: record # The user's legal name, phone number, email address and address used to perform fuzzy match. If Financial Account Matching is enabled in the Identity Verification product, leave this field empty to automatically match against PII collected from the Identity Verification checks. — shape: {legal_name?: string, phone_number?: string, email_address?: string, address?: any}
]: any -> record<account: record<account_id: string, balances: record<available: float, current: float, limit: float, iso_currency_code: string, unofficial_currency_code: string, last_updated_datetime: string>, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record<name_match_score: int, network_status: record, previous_returns: record, account_number_format: string>, persistent_account_id: string, holder_category: string, legal_name: record<score: int, is_first_name_or_last_name_match: bool, is_nickname_match: bool, is_business_name_detected: bool>, phone_number: record<score: int>, email_address: record<score: int>, address: record<score: int, is_postal_code_match: bool>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/identity/match")
  let body = {client_id: $client_id, secret: $secret, processor_token: $processor_token, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Balance data
#
# POST /processor/balance/get
# Docs: /api/processor-partners/#processorbalanceget
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  --options: record # Optional parameters to `/processor/balance/get`. — shape: {min_last_updated_datetime?: string}
]: any -> record<account: record<account_id: string, balances: record<available: float, current: float, limit: float, iso_currency_code: string, unofficial_currency_code: string, last_updated_datetime: string>, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record<name_match_score: int, network_status: record, previous_returns: record, account_number_format: string>, persistent_account_id: string, holder_category: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/balance/get")
  let body = {client_id: $client_id, secret: $secret, processor_token: $processor_token, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  --webhook: string # The new webhook URL to associate with the Item. To remove a webhook from an Item, set to `null`. (nullable, format: url)
]: any -> record<item: record<item_id: string, institution_id: string, institution_name: string, webhook: string, auth_method: string, error: record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list, provided_account_subtypes: list>, available_products: list<string>, billed_products: list<string>, products: list<string>, consented_products: list<string>, consent_expiration_time: string, update_type: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/webhook/update")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, webhook: $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Invalidate access_token
#
# POST /item/access_token/invalidate
# Docs: /api/items/#itemaccess_tokeninvalidate
# operationId: itemAccessTokenInvalidate
export def "item-access-token-invalidate itemAccessTokenInvalidate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
]: any -> record<new_access_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/access_token/invalidate")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  key_id: string # The key ID ( `kid` ) from the JWT header.
]: any -> record<key: record<alg: string, crv: string, kid: string, kty: string, use: string, x: string, y: string, created_at: int, expired_at: int>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhook_verification_key/get")
  let body = {client_id: $client_id, secret: $secret, key_id: $key_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  --options: record # An optional object to filter `/liabilities/get` results. If provided, `options` cannot be null. — shape: {account_ids?: list}
]: any -> record<accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record, persistent_account_id: string, holder_category: string>, item: record<item_id: string, institution_id: string, institution_name: string, webhook: string, auth_method: string, error: record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list, provided_account_subtypes: list>, available_products: list<string>, billed_products: list<string>, products: list<string>, consented_products: list<string>, consent_expiration_time: string, update_type: string>, liabilities: record<credit: list<record>, mortgage: list<record>, student: list<record>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/liabilities/get")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create payment recipient
#
# POST /payment_initiation/recipient/create
# Docs: /api/products/payment-initiation/#payment_initiationrecipientcreate
# operationId: paymentInitiationRecipientCreate
# --address shape: {street: list, city: string, postal_code: string, country: string}
export def "payment-initiation-recipient-create paymentInitiationRecipientCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  name: string # The name of the recipient. We recommend using strings of length 18 or less and avoid special characters to ensure compatibility with all institutions.
  --iban: string # The International Bank Account Number (IBAN) for the recipient. If BACS data is not provided, an IBAN is required. (nullable)
  --bacs: any # An object containing a BACS account number and sort code. If an IBAN is not provided or if this recipient needs to accept domestic GBP-denominated payments, BACS data is required. (nullable)
  --address: record # The optional address of the payment recipient's bank account. Required by most institutions outside of the UK. (nullable) — shape: {street: list, city: string, postal_code: string, country: string}
]: any -> record<recipient_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/recipient/create")
  let body = {client_id: $client_id, secret: $secret, name: $name, iban: $iban, bacs: $bacs, address: $address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reverse an existing payment
#
# POST /payment_initiation/payment/reverse
# Docs: /api/products/payment-initiation/#payment_initiationpaymentreverse
# operationId: paymentInitiationPaymentReverse
# --counterparty_address shape: {street: list, city: string, postal_code: string, country: string}
export def "payment-initiation-payment-reverse paymentInitiationPaymentReverse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  payment_id: string # The ID of the payment to reverse
  idempotency_key: string # A random key provided by the client, per unique wallet transaction. Maximum of 128 characters.  The API supports idempotency for safely retrying requests without accidentally performing the same operation twice. If a request to execute a wallet transaction fails due to a network connection error, then after a minimum delay of one minute, you can retry the request with the same idempotency key to guarantee that only a single wallet transaction is created. If the request was successfully processed, it will prevent any transaction that uses the same idempotency key, and was received within 24 hours of the first request, from being processed.
  reference: string # A reference for the refund. This must be an alphanumeric string with 6 to 18 characters and must not contain any special characters or spaces.
  --amount: any # The amount and currency of a payment
  --counterparty-date-of-birth: string # The counterparty's birthdate, in [ISO 8601](https://wikipedia.org/wiki/ISO_8601) (YYYY-MM-DD) format. (nullable, format: date)
  --counterparty-address: record # The optional address of the payment recipient's bank account. Required by most institutions outside of the UK. (nullable) — shape: {street: list, city: string, postal_code: string, country: string}
]: any -> record<refund_id: string, status: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/payment/reverse")
  let body = {client_id: $client_id, secret: $secret, payment_id: $payment_id, idempotency_key: $idempotency_key, reference: $reference, amount: $amount, counterparty_date_of_birth: $counterparty_date_of_birth, counterparty_address: $counterparty_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  recipient_id: string # The ID of the recipient
]: any -> record<recipient_id: string, name: string, address: record<street: list<string>, city: string, postal_code: string, country: string>, iban: string, bacs: record<account: string, sort_code: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/recipient/get")
  let body = {client_id: $client_id, secret: $secret, recipient_id: $recipient_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --count: int # The maximum number of recipients to return. If `count` is not specified, a maximum of 100 recipients will be returned, beginning with the recipient at the cursor (if specified). (nullable, default: 100)
  --cursor: string # A value representing the latest recipient to be included in the response. Set this from `next_cursor` received from the previous `/payment_initiation/recipient/list` request. If provided, the response will only contain that recipient and recipients created before it. If omitted, the response will contain recipients starting from the most recent, and in descending order by the `created_at` time.
]: any -> record<recipients: table<recipient_id: string, name: string, address: record, iban: string, bacs: record>, request_id: string, next_cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/recipient/list")
  let body = {client_id: $client_id, secret: $secret, count: $count, cursor: $cursor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a payment
#
# POST /payment_initiation/payment/create
# Docs: /api/products/payment-initiation/#payment_initiationpaymentcreate
# operationId: paymentInitiationPaymentCreate
# --amount shape: {currency: "GBP"|"EUR"|"PLN"|"SEK"|"DKK"|"NOK", value: float}
# --options shape: {request_refund_details?: bool, iban?: string, bacs?: any, scheme?: "LOCAL_DEFAULT"|"LOCAL_INSTANT"|"SEPA_CREDIT_TRANSFER"|"SEPA_CREDIT_TRANSFER_INSTANT"}
export def "payment-initiation-payment-create paymentInitiationPaymentCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  recipient_id: string # The ID of the recipient the payment is for.
  reference: string # A reference for the payment. This must be an alphanumeric string with at most 18 characters and must not contain any special characters (since not all institutions support them). In order to track settlement via Payment Confirmation, each payment must have a unique reference. If the reference provided through the API is not unique, Plaid will adjust it. Some institutions may limit the reference to less than 18 characters. If necessary, Plaid will adjust the reference by truncating it to fit the institution's requirements. Both the originally provided and automatically adjusted references (if any) can be found in the `reference` and `adjusted_reference` fields, respectively.
  amount: record # The amount and currency of a payment — shape: {currency: "GBP"|"EUR"|"PLN"|"SEK"|"DKK"|"NOK", value: float}
  --schedule: any # The schedule that the payment will be executed on. If a schedule is provided, the payment is automatically set up as a standing order. If no schedule is specified, the payment will be executed only once.
  --options: record # Additional payment options (nullable) — shape: {request_refund_details?: bool, iban?: string, bacs?: any, scheme?: "LOCAL_DEFAULT"|"LOCAL_INSTANT"|"SEPA_CREDIT_TRANSFER"|"SEPA_CREDIT_TRANSFER_INSTANT"}
]: any -> record<payment_id: string, status: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/payment/create")
  let body = {client_id: $client_id, secret: $secret, recipient_id: $recipient_id, reference: $reference, amount: $amount, schedule: $schedule, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create payment token
#
# POST /payment_initiation/payment/token/create
# DEPRECATED
# Docs: /link/maintain-legacy-integration/#creating-a-payment-token
# operationId: createPaymentToken
@deprecated
export def "payment-initiation-payment-token-create createPaymentToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  payment_id: string # The `payment_id` returned from `/payment_initiation/payment/create`.
]: any -> record<payment_token: string, payment_token_expiration_time: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/payment/token/create")
  let body = {client_id: $client_id, secret: $secret, payment_id: $payment_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create payment consent
#
# POST /payment_initiation/consent/create
# Docs: /api/products/payment-initiation/#payment_initiationconsentcreate
# operationId: paymentInitiationConsentCreate
# --constraints shape: {valid_date_time?: record, max_payment_amount: any, periodic_amounts: list}
# --options shape: {request_refund_details?: bool, iban?: string, bacs?: any}
# --payer_details shape: {name: string, numbers: record, address?: record, date_of_birth?: string, phone_numbers?: list, emails?: list}
@deprecated --flag scopes
@deprecated --flag options
export def "payment-initiation-consent-create paymentInitiationConsentCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  recipient_id: string # The ID of the recipient the payment consent is for. The created consent can be used to transfer funds to this recipient only.
  reference: string # A reference for the payment consent. This must be an alphanumeric string with at most 18 characters and must not contain any special characters.
  --scopes: list # An array of payment consent scopes. (DEPRECATED)
  --type: string@type-completer-2 # Payment consent type. Defines possible use case for payments made with the given consent.  `SWEEPING`: Allows moving money between accounts owned by the same user.  `COMMERCIAL`: Allows initiating payments from the user's account to third parties.
  constraints: record # Limitations that will be applied to payments initiated using the payment consent. — shape: {valid_date_time?: record, max_payment_amount: any, periodic_amounts: list}
  --options: record # (Deprecated) Additional payment consent options. Please use `payer_details` to specify the account. (DEPRECATED, nullable) — shape: {request_refund_details?: bool, iban?: string, bacs?: any}
  --payer-details: record # An object representing the payment consent payer details. Payer `name` and account `numbers` are required to lock the account to which the consent can be created. (nullable) — shape: {name: string, numbers: record, address?: record, date_of_birth?: string, phone_numbers?: list, emails?: list}
]: any -> record<consent_id: string, status: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/consent/create")
  let body = {client_id: $client_id, secret: $secret, recipient_id: $recipient_id, reference: $reference, scopes: $scopes, type: $type, constraints: $constraints, options: $options, payer_details: $payer_details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  consent_id: string # The `consent_id` returned from `/payment_initiation/consent/create`.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/consent/get")
  let body = {client_id: $client_id, secret: $secret, consent_id: $consent_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  consent_id: string # The consent ID.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/consent/revoke")
  let body = {client_id: $client_id, secret: $secret, consent_id: $consent_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Execute a single payment using consent
#
# POST /payment_initiation/consent/payment/execute
# Docs: /api/products/payment-initiation/#payment_initiationconsentpaymentexecute
# operationId: paymentInitiationConsentPaymentExecute
# --amount shape: {currency: "GBP"|"EUR"|"PLN"|"SEK"|"DKK"|"NOK", value: float}
@deprecated --flag scope
export def "payment-initiation-consent-payment-execute paymentInitiationConsentPaymentExecute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  consent_id: string # The consent ID.
  amount: record # The amount and currency of a payment — shape: {currency: "GBP"|"EUR"|"PLN"|"SEK"|"DKK"|"NOK", value: float}
  idempotency_key: string # A random key provided by the client, per unique consent payment. Maximum of 128 characters.  The API supports idempotency for safely retrying requests without accidentally performing the same operation twice. If a request to execute a consent payment fails due to a network connection error, you can retry the request with the same idempotency key to guarantee that only a single payment is created. If the request was successfully processed, it will prevent any payment that uses the same idempotency key, and was received within 48 hours of the first request, from being processed.
  --reference: string # A reference for the payment. This must be an alphanumeric string with at most 18 characters and must not contain any special characters (since not all institutions support them). If not provided, Plaid will automatically fall back to the reference from consent. In order to track settlement via Payment Confirmation, each payment must have a unique reference. If the reference provided through the API is not unique, Plaid will adjust it. Some institutions may limit the reference to less than 18 characters. If necessary, Plaid will adjust the reference by truncating it to fit the institution's requirements. Both the originally provided and automatically adjusted references (if any) can be found in the `reference` and `adjusted_reference` fields, respectively. (nullable)
  --scope: any # DEPRECATED
  --processing-mode: string@processing-mode-completer # Decides the mode under which the payment processing should be performed, using `IMMEDIATE` as default.  `IMMEDIATE`: Will immediately execute the payment, waiting for a response from the ASPSP before returning the result of the payment initiation. This is ideal for user-present flows.   `ASYNC`: Will accept a payment execution request and schedule it for processing, immediately returning the new `payment_id`. Listen for webhooks to obtain real-time updates on the payment status. This is ideal for non user-present flows.
]: any -> record<payment_id: string, status: string, request_id: string, error: record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list<any>, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list<string>, provided_account_subtypes: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/consent/payment/execute")
  let body = {client_id: $client_id, secret: $secret, consent_id: $consent_id, amount: $amount, idempotency_key: $idempotency_key, reference: $reference, scope: $scope, processing_mode: $processing_mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
]: any -> record<reset_login: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/item/reset_login")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Seed a connected application for a Permissions Manager sandbox item
#
# POST /sandbox/item/application/seed
# operationId: sandboxItemApplicationSeed
export def "sandbox-item-application-seed sandboxItemApplicationSeed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  application_id: string # This field will map to the application ID that is returned from `/item/application/list`, or provided to the institution in an oauth redirect.
]: any -> record<item_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/item/application/seed")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, application_id: $application_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  account_id: string # The `account_id` of the account whose verification status is to be modified
  verification_status: string@verification-status-completer # The verification status to set the account to.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/item/set_verification_status")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, account_id: $account_id, verification_status: $verification_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Force item(s) for a Sandbox User into an error state
#
# POST /sandbox/user/reset_login
# Docs: /api/sandbox/#sandboxuserreset_login
# operationId: sandboxUserResetLogin
export def "sandbox-user-reset-login sandboxUserResetLogin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --item-ids: list # An array of `item_id`s associated with the User to be reset.  If empty or `null`, this field will default to resetting all Items associated with the User. (nullable)
  --user-id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/user/reset_login")
  let body = {client_id: $client_id, secret: $secret, user_token: $user_token, item_ids: $item_ids, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Exchange public token for an access token
#
# POST /item/public_token/exchange
# Docs: /api/items/#itempublic_tokenexchange
# operationId: itemPublicTokenExchange
export def "item-public-token-exchange itemPublicTokenExchange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  public_token: string # Your `public_token`, obtained from the Link `onSuccess` callback or `/sandbox/public_token/create`.
]: any -> record<access_token: string, item_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/public_token/exchange")
  let body = {client_id: $client_id, secret: $secret, public_token: $public_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create public token
#
# POST /item/public_token/create
# Docs: /api/link/#itempublic_tokencreate
# operationId: itemCreatePublicToken
export def "item-public-token-create itemCreatePublicToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
]: any -> record<public_token: string, expiration: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/public_token/create")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create user
#
# POST /user/create
# Docs: /api/users/#usercreate
# operationId: userCreate
# --identity shape: {name?: record, date_of_birth?: string, emails?: list, phone_numbers?: list, addresses?: list, id_numbers?: list}
# --consumer_report_user_identity shape: {first_name: string, last_name: string, phone_numbers: list, emails: list, ssn_full?: string, ssn_last_4?: string, date_of_birth: string, primary_address: record}
export def "user-create userCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Plaid-New-User-API-Enabled: string@bool-completer # The HTTP header used in API requests to determine which set of User APIs to invoke: the legacy CRA version or the new User API version.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  client_user_id: string # A unique ID representing the end user. Maximum of 128 characters. Typically this will be a user ID number from your application. Personally identifiable information, such as an email address or phone number, should not be used in the `client_user_id`.
  --identity: record # The identity fields associated with a user. For a user to be eligible for a Plaid Check Consumer Report, all fields are required except `id_number`. Providing a partial SSN is strongly recommended, and improves the accuracy of matching user records during compliance processes such as file disclosure, dispute, or security freeze requests. If creating a report that will be shared with GSEs such as Fannie or Freddie, a full Social Security Number must be provided via the `id_number` field. (nullable) — shape: {name?: record, date_of_birth?: string, emails?: list, phone_numbers?: list, addresses?: list, id_numbers?: list}
  --end-customer: string # A unique ID representing a CRA reseller's end customer. Maximum of 128 characters.
  --consumer-report-user-identity: record # This field is only used by integrations created before December 10, 2025. All other integrations must use the `identity` object instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis). To create a Plaid Check Consumer Report for a user when using a `user_token`, this field must be present. If this field is not provided during user token creation, you can add it to the user later by calling `/user/update`. Once the field has been added to the user, you will be able to call `/link/token/create` with a non-empty `consumer_report_permissible_purpose` (which will automatically create a Plaid Check Consumer Report), or call `/cra/check_report/create` for that user. (nullable) — shape: {first_name: string, last_name: string, phone_numbers: list, emails: list, ssn_full?: string, ssn_last_4?: string, date_of_birth: string, primary_address: record}
  --with-upgraded-user: string@bool-completer # If your integration with the User API predates December 10, 2025, set this field to `true` to opt into the [New User APIs](https://plaid.com/docs/api/users/user-apis/). When enabled, you can use the `identity` field instead of `consumer_report_user_identity`.
]: any -> record<user_token: string, user_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/create")
  let body = {client_id: $client_id, secret: $secret, client_user_id: $client_user_id, identity: $identity, end_customer: $end_customer, consumer_report_user_identity: $consumer_report_user_identity, with_upgraded_user: $with_upgraded_user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Plaid-New-User-API-Enabled": $Plaid_New_User_API_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve user identity and information
#
# POST /user/get
# Docs: /api/users/#userget
# operationId: userGet
export def "user-get userGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Plaid-New-User-API-Enabled: string@bool-completer # The HTTP header used in API requests to determine which set of User APIs to invoke: the legacy CRA version or the new User API version.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
]: any -> record<request_id: string, user_id: string, client_user_id: string, created_at: string, updated_at: string, identity: record<name: record<given_name: string, family_name: string>, date_of_birth: string, emails: list<record>, phone_numbers: list<record>, addresses: list<record>, id_numbers: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/get")
  let body = {client_id: $client_id, secret: $secret, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Plaid-New-User-API-Enabled": $Plaid_New_User_API_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove user identity data
#
# POST /user/identity/remove
# Docs: /api/users/#useridentityremove
# operationId: userIdentityRemove
export def "user-identity-remove userIdentityRemove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Plaid-New-User-API-Enabled: string@bool-completer # The HTTP header used in API requests to determine which set of User APIs to invoke: the legacy CRA version or the new User API version.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/identity/remove")
  let body = {client_id: $client_id, secret: $secret, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Plaid-New-User-API-Enabled": $Plaid_New_User_API_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update user information
#
# POST /user/update
# Docs: /api/users/#userupdate
# operationId: userUpdate
# --identity shape: {name?: record, date_of_birth?: string, emails?: list, phone_numbers?: list, addresses?: list, id_numbers?: list}
# --consumer_report_user_identity shape: {first_name: string, last_name: string, phone_numbers: list, emails: list, ssn_full?: string, ssn_last_4?: string, date_of_birth: string, primary_address: record}
export def "user-update userUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Plaid-New-User-API-Enabled: string@bool-completer # The HTTP header used in API requests to determine which set of User APIs to invoke: the legacy CRA version or the new User API version.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --identity: record # The identity fields associated with a user. For a user to be eligible for a Plaid Check Consumer Report, all fields are required except `id_number`. Providing a partial SSN is strongly recommended, and improves the accuracy of matching user records during compliance processes such as file disclosure, dispute, or security freeze requests. If creating a report that will be shared with GSEs such as Fannie or Freddie, a full Social Security Number must be provided via the `id_number` field. (nullable) — shape: {name?: record, date_of_birth?: string, emails?: list, phone_numbers?: list, addresses?: list, id_numbers?: list}
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --consumer-report-user-identity: record # This field is only used by integrations created before December 10, 2025. All other integrations must use the `identity` object instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis). To create a Plaid Check Consumer Report for a user when using a `user_token`, this field must be present. If this field is not provided during user token creation, you can add it to the user later by calling `/user/update`. Once the field has been added to the user, you will be able to call `/link/token/create` with a non-empty `consumer_report_permissible_purpose` (which will automatically create a Plaid Check Consumer Report), or call `/cra/check_report/create` for that user. (nullable) — shape: {first_name: string, last_name: string, phone_numbers: list, emails: list, ssn_full?: string, ssn_last_4?: string, date_of_birth: string, primary_address: record}
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/update")
  let body = {client_id: $client_id, secret: $secret, user_id: $user_id, identity: $identity, user_token: $user_token, consumer_report_user_identity: $consumer_report_user_identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Plaid-New-User-API-Enabled": $Plaid_New_User_API_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove user
#
# POST /user/remove
# Docs: /api/users/#userremove
# operationId: userRemove
export def "user-remove userRemove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Plaid-New-User-API-Enabled: string@bool-completer # The HTTP header used in API requests to determine which set of User APIs to invoke: the legacy CRA version or the new User API version.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/remove")
  let body = {client_id: $client_id, secret: $secret, user_id: $user_id, user_token: $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Plaid-New-User-API-Enabled": $Plaid_New_User_API_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Terminate user-based products
#
# POST /user/products/terminate
# Docs: /api/users/#userproductsterminate
# operationId: userProductsTerminate
export def "user-products-terminate userProductsTerminate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  reason_code: any # The reason for terminating user-based products.
  --reason-note: string # Additional context or details about the reason for terminating user-based products. Personally identifiable information, such as an email address or phone number, should not be included in the `reason_note`. (nullable)
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/products/terminate")
  let body = {client_id: $client_id, secret: $secret, user_id: $user_id, reason_code: $reason_code, reason_note: $reason_note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Items associated with a User
#
# POST /user/items/get
# Docs: /api/users/#useritemsget
# operationId: userItemsGet
export def "user-items-get userItemsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --user-id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
]: any -> record<items: table<item_id: string, institution_id: string, institution_name: string, webhook: string, auth_method: string, error: record, available_products: list, billed_products: list, products: list, consented_products: list, consent_expiration_time: string, update_type: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/items/get")
  let body = {client_id: $client_id, secret: $secret, user_token: $user_token, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Associate Items to a User
#
# POST /user/items/associate
# Docs: /api/users/#useritemsassociate
# operationId: userItemsAssociate
export def "user-items-associate userItemsAssociate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  item_ids: list # An array of `item_id`s to be associated with the `user_id`.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/items/associate")
  let body = {client_id: $client_id, secret: $secret, user_id: $user_id, item_ids: $item_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove Items from a User
#
# POST /user/items/remove
# Docs: /api/users/#useritemsremove
# operationId: userItemsRemove
export def "user-items-remove userItemsRemove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --user-id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  item_ids: list # An array of `item_id`s to be deleted. All Items for removal must be currently associated with the provided `user_id` or `user_token`. Otherwise, the entire operation will error and no Items will be deleted.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/items/remove")
  let body = {client_id: $client_id, secret: $secret, user_token: $user_token, user_id: $user_id, item_ids: $item_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a third-party user token
#
# POST /user/third_party_token/create
# Docs: /api/users/#userthirdpartytokencreate
# operationId: userThirdPartyTokenCreate
export def "user-third-party-token-create userThirdPartyTokenCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  third_party_client_id: string # The Plaid API `client_id` of the third-party client the token will be shared with. The token will only be valid for the specified client.
  --expiration-time: string # The expiration date and time for the third-party user token in [ISO 8601](https://wikipedia.org/wiki/ISO_8601) format (`YYYY-MM-DDThh:mm:ssZ`). The expiration is restricted to a maximum of 24 hours from the token's creation time. If not provided, the token will automatically expire after 24 hours. (nullable, format: date-time)
  --user-id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
]: any -> record<request_id: string, third_party_user_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/third_party_token/create")
  let body = {client_id: $client_id, secret: $secret, user_token: $user_token, third_party_client_id: $third_party_client_id, expiration_time: $expiration_time, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a third-party user token
#
# POST /user/third_party_token/remove
# Docs: /api/users/#userthirdpartytokenremove
# operationId: userThirdPartyTokenRemove
export def "user-third-party-token-remove userThirdPartyTokenRemove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  third_party_user_token: string # The third-party user token associated with the requested User data.
]: any -> record<removed: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/third_party_token/remove")
  let body = {client_id: $client_id, secret: $secret, third_party_user_token: $third_party_user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
]: any -> record<sessions: table<link_session_id: string, session_start_time: string, results: record, errors: list>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/sessions/get")
  let body = {client_id: $client_id, secret: $secret, user_token: $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  payment_id: string # The `payment_id` returned from `/payment_initiation/payment/create`.
]: any -> record<payment_id: string, amount: record<currency: string, value: float>, status: string, recipient_id: string, reference: string, adjusted_reference: string, last_status_update: string, schedule: record<interval: string, interval_execution_day: int, start_date: string, end_date: string, adjusted_start_date: string>, refund_details: record<name: string, iban: string, bacs: record<account: string, sort_code: string>>, bacs: record<account: string, sort_code: string>, iban: string, refund_ids: list<string>, amount_refunded: record<currency: string, value: float>, wallet_id: string, scheme: string, adjusted_scheme: string, consent_id: string, transaction_id: string, end_to_end_id: string, error: record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list<any>, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list<string>, provided_account_subtypes: list<string>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/payment/get")
  let body = {client_id: $client_id, secret: $secret, payment_id: $payment_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --count: int # The maximum number of payments to return. If `count` is not specified, a maximum of 10 payments will be returned, beginning with the most recent payment before the cursor (if specified). (nullable, default: 10)
  --cursor: string # A string in RFC 3339 format (i.e. "2019-12-06T22:35:49Z"). Only payments created before the cursor will be returned. (nullable, format: date-time)
  --consent-id: string # The consent ID. If specified, only payments, executed using this consent, will be returned. (nullable)
]: any -> record<payments: table<payment_id: string, amount: record, status: string, recipient_id: string, reference: string, adjusted_reference: string, last_status_update: string, schedule: record, refund_details: record, bacs: record, iban: string, refund_ids: list, amount_refunded: record, wallet_id: string, scheme: string, adjusted_scheme: string, consent_id: string, transaction_id: string, end_to_end_id: string, error: record>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_initiation/payment/list")
  let body = {client_id: $client_id, secret: $secret, count: $count, cursor: $cursor, consent_id: $consent_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  --options: record # An optional object to filter `/investments/holdings/get` results. If provided, must not be `null`. — shape: {account_ids?: list}
]: any -> record<accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record, persistent_account_id: string, holder_category: string>, holdings: table<account_id: string, security_id: string, institution_price: float, institution_price_as_of: string, institution_price_datetime: string, institution_value: float, cost_basis: float, quantity: float, iso_currency_code: string, unofficial_currency_code: string, vested_quantity: float, vested_value: float, tax_lots: list>, securities: table<security_id: string, isin: string, cusip: string, sedol: string, institution_security_id: string, institution_id: string, proxy_security_id: string, name: string, ticker_symbol: string, is_cash_equivalent: bool, type: string, subtype: string, close_price: float, close_price_as_of: string, update_datetime: string, iso_currency_code: string, unofficial_currency_code: string, market_identifier_code: string, sector: string, industry: string, cfi_code: string, option_contract: record, fixed_income: record>, item: record<item_id: string, institution_id: string, institution_name: string, webhook: string, auth_method: string, error: record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list, provided_account_subtypes: list>, available_products: list<string>, billed_products: list<string>, products: list<string>, consented_products: list<string>, consent_expiration_time: string, update_type: string>, request_id: string, is_investments_fallback_item: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/investments/holdings/get")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get investment transactions
#
# POST /investments/transactions/get
# Docs: /api/products/investments/#investmentstransactionsget
# operationId: investmentsTransactionsGet
# --options shape: {account_ids?: list, count?: int, offset?: int, async_update?: bool}
export def "investments-transactions-get investmentsTransactionsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  start_date: string # The earliest date for which to fetch transaction history. Dates should be formatted as YYYY-MM-DD. (format: date)
  end_date: string # The most recent date for which to fetch transaction history. Dates should be formatted as YYYY-MM-DD. (format: date)
  --options: record # An optional object to filter `/investments/transactions/get` results. If provided, must be non-`null`. — shape: {account_ids?: list, count?: int, offset?: int, async_update?: bool}
]: any -> record<item: record<item_id: string, institution_id: string, institution_name: string, webhook: string, auth_method: string, error: record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list, provided_account_subtypes: list>, available_products: list<string>, billed_products: list<string>, products: list<string>, consented_products: list<string>, consent_expiration_time: string, update_type: string>, accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record, persistent_account_id: string, holder_category: string>, securities: table<security_id: string, isin: string, cusip: string, sedol: string, institution_security_id: string, institution_id: string, proxy_security_id: string, name: string, ticker_symbol: string, is_cash_equivalent: bool, type: string, subtype: string, close_price: float, close_price_as_of: string, update_datetime: string, iso_currency_code: string, unofficial_currency_code: string, market_identifier_code: string, sector: string, industry: string, cfi_code: string, option_contract: record, fixed_income: record>, investment_transactions: table<investment_transaction_id: string, cancel_transaction_id: string, account_id: string, security_id: string, date: string, transaction_datetime: string, name: string, quantity: float, amount: float, price: float, fees: float, type: string, subtype: string, iso_currency_code: string, unofficial_currency_code: string>, total_investment_transactions: int, request_id: string, is_investments_fallback_item: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/investments/transactions/get")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, start_date: $start_date, end_date: $end_date, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Refresh investment data
#
# POST /investments/refresh
# Docs: /api/products/investments/#investmentsrefresh
# operationId: investmentsRefresh
export def "investments-refresh investmentsRefresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/investments/refresh")
  let body = {client_id: $client_id, access_token: $access_token, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get data needed to authorize an investments transfer
#
# POST /investments/auth/get
# Docs: /api/products/investments-move/#investmentsauthget
# operationId: investmentsAuthGet
# --options shape: {account_ids?: list}
export def "investments-auth-get investmentsAuthGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  --options: record # An optional object to filter `/investments/auth/get` results. — shape: {account_ids?: list}
]: any -> record<accounts: table<account_id: string, balances: record, mask: string, name: string, official_name: string, type: string, subtype: string, verification_status: string, verification_name: string, verification_insights: record, persistent_account_id: string, holder_category: string>, holdings: table<account_id: string, security_id: string, institution_price: float, institution_price_as_of: string, institution_price_datetime: string, institution_value: float, cost_basis: float, quantity: float, iso_currency_code: string, unofficial_currency_code: string, vested_quantity: float, vested_value: float, tax_lots: list>, securities: table<security_id: string, isin: string, cusip: string, sedol: string, institution_security_id: string, institution_id: string, proxy_security_id: string, name: string, ticker_symbol: string, is_cash_equivalent: bool, type: string, subtype: string, close_price: float, close_price_as_of: string, update_datetime: string, iso_currency_code: string, unofficial_currency_code: string, market_identifier_code: string, sector: string, industry: string, cfi_code: string, option_contract: record, fixed_income: record>, owners: table<account_id: string, names: list>, numbers: record<acats: list<record>, aton: list<record>, retirement_401k: list<record>>, data_sources: record<numbers: string, owners: string, holdings: string>, account_details_401k: table<account_id: string, fee_details: record, contribution_details: record>, item: record<item_id: string, institution_id: string, institution_name: string, webhook: string, auth_method: string, error: record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list, provided_account_subtypes: list>, available_products: list<string>, billed_products: list<string>, products: list<string>, consented_products: list<string>, consent_expiration_time: string, update_type: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/investments/auth/get")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  account_id: string # The `account_id` value obtained from the `onSuccess` callback in Link
  processor: string@processor-completer # The processor you are integrating with.
]: any -> record<processor_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/token/create")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, account_id: $account_id, processor: $processor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Control a processor's access to products
#
# POST /processor/token/permissions/set
# Docs: /api/processors/#processortokenpermissionsset
# operationId: processorTokenPermissionsSet
export def "processor-token-permissions-set processorTokenPermissionsSet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  products: list # A list of products the processor token should have access to. An empty list will grant access to all products.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/token/permissions/set")
  let body = {client_id: $client_id, secret: $secret, processor_token: $processor_token, products: $products} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a processor token's product permissions
#
# POST /processor/token/permissions/get
# Docs: /api/processors/#processortokenpermissionsget
# operationId: processorTokenPermissionsGet
export def "processor-token-permissions-get processorTokenPermissionsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
]: any -> record<request_id: string, products: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/token/permissions/get")
  let body = {client_id: $client_id, secret: $secret, processor_token: $processor_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a processor token's webhook URL
#
# POST /processor/token/webhook/update
# Docs: /api/processor-partners/#processortokenwebhookupdate
# operationId: processorTokenWebhookUpdate
export def "processor-token-webhook-update processorTokenWebhookUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  processor_token: string # The processor token obtained from the Plaid integration partner. Processor tokens are in the format: `processor-<environment>-<identifier>`
  --webhook: string # The new webhook URL to associate with the processor token. To remove a webhook from a processor token, set to `null`. (nullable, format: url)
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/token/webhook/update")
  let body = {client_id: $client_id, secret: $secret, processor_token: $processor_token, webhook: $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  account_id: string # The `account_id` value obtained from the `onSuccess` callback in Link
]: any -> record<stripe_bank_account_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/stripe/bank_account_token/create")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, account_id: $account_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  account_id: string # The `account_id` value obtained from the `onSuccess` callback in Link
]: any -> record<processor_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/processor/apex/processor_token/create")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, account_id: $account_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import Item
#
# POST /item/import
# operationId: itemImport
# --user_auth shape: {user_id: string, auth_token: string}
# --options shape: {webhook?: string}
export def "item-import itemImport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --institution-id: string # The Plaid Institution ID associated with the Item.
  products: list # Array of product strings
  user_auth: record # Object of user ID and auth token pair, permitting Plaid to aggregate a user's accounts — shape: {user_id: string, auth_token: string}
  --options: record # An optional object to configure `/item/import` request. — shape: {webhook?: string}
]: any -> record<access_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/item/import")
  let body = {client_id: $client_id, secret: $secret, institution_id: $institution_id, products: $products, user_auth: $user_auth, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Link Token
#
# POST /link/token/create
# Docs: /api/link/#linktokencreate
# operationId: linkTokenCreate
# --user shape: {client_user_id: string, legal_name?: string, name?: any, phone_number?: string, phone_number_verified_time?: string, email_address?: string, email_address_verified_time?: string, ssn?: string, date_of_birth?: string, address?: any, id_number?: any}
# --institution_data shape: {routing_number?: string}
# --card_switch shape: {card_bin: string}
# --account_filters shape: {depository?: record, credit?: record, loan?: record, investment?: record, other?: record}
# --eu_config shape: {headless?: bool}
# --payment_configuration shape: {amount: string, description?: string}
# --payment_initiation shape: {payment_id?: string, consent_id?: string}
# --employment shape: {employment_source_types?: list, bank_employment?: record}
# --income_verification shape: {income_verification_id?: string, asset_report_id?: string, access_tokens?: list, income_source_types?: list, bank_income?: record, payroll_income?: record, stated_income_sources?: list}
# --base_report shape: {days_requested: int, client_report_id?: string}
# --credit_partner_insights shape: {days_requested?: int}
# --cra_options shape: {days_requested: int, days_required?: int, client_report_id?: string, partner_insights?: record, base_report?: record, cashflow_insights?: record, lend_score?: record, network_insights?: record, include_investments?: bool, income_insights?: record}
# --auth shape: {auth_type_select_enabled?: bool, automated_microdeposits_enabled?: bool, instant_match_enabled?: bool, same_day_microdeposits_enabled?: bool, instant_microdeposits_enabled?: bool, reroute_to_credentials?: "OFF"|"OPTIONAL"|"FORCED", database_match_enabled?: bool, database_insights_enabled?: bool, flow_type?: "FLEXIBLE_AUTH", sms_microdeposits_verification_enabled?: bool}
# --transfer shape: {intent_id?: string, authorization_id?: string, payment_profile_token?: string}
# --update shape: {account_selection_enabled?: bool, reauthorization_enabled?: bool, user?: bool, item_ids?: list}
# --identity_verification shape: {template_id: any, consent?: any, gave_consent?: bool}
# --statements shape: {start_date: string, end_date: string}
# --investments shape: {allow_unverified_crypto_wallets?: bool, allow_manual_entry?: bool}
# --investments_auth shape: {manual_entry_enabled?: bool, masked_number_match_enabled?: bool, stated_account_number_enabled?: bool, rollover_401k_enabled?: bool}
# --hosted_link shape: {delivery_method?: "sms"|"email", completion_redirect_uri?: string, url_lifetime_seconds?: int, is_mobile_app?: bool}
# --transactions shape: {days_requested?: int}
# --cashflow_report shape: {days_requested?: int}
# --identity shape: {is_document_upload?: bool, account_ids?: list, parsing_configs?: list}
@deprecated --flag eu-config
@deprecated --flag base-report
export def "link-token-create linkTokenCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  client_name: string # The name of your application, as it should be displayed in Link. Maximum length of 30 characters. If a value longer than 30 characters is provided, Link will display "This Application" instead.
  language: string # The language that Link should be displayed in. When initializing with Identity Verification, this field is not used; for more details, see [Identity Verification supported languages](https://plaid.com/docs/identity-verification/#supported-languages).  Supported languages are: - Danish (`'da'`) - Dutch (`'nl'`) - English (`'en'`) - Estonian (`'et'`) - French (`'fr'`) - German (`'de'`) - Hindi (`'hi'`) - Italian (`'it'`) - Latvian (`'lv'`) - Lithuanian (`'lt'`) - Norwegian (`'no'`) - Polish (`'pl'`) - Portuguese (`'pt'`) - Romanian (`'ro'`) - Spanish (`'es'`) - Swedish (`'sv'`) - Vietnamese (`'vi'`)  When using a Link customization, the language configured here must match the setting in the customization, or the customization will not be applied.
  country_codes: list # Specify an array of Plaid-supported country codes using the ISO-3166-1 alpha-2 country code standard. Institutions from all listed countries will be shown. For a complete mapping of supported products by country, see https://plaid.com/global/. For access to additional countries beyond what you have been approved for, [contact sales](https://plaid.com/contact/), your account manager, or support.  If using Identity Verification, `country_codes` should be set to the country where your company is based, not the country where your user is located. For all other products, `country_codes` represents the location of your user's financial institution.  If Link is launched with multiple country codes, only products that you are enabled for in all countries will be used by Link. While all countries are enabled by default in Sandbox, in Production only the countries you have requested access for are shown. To request access to additional countries, [file a product access Support ticket](https://dashboard.plaid.com/support/new/product-and-development/product-troubleshooting/request-product-access) via the Plaid dashboard.  If using a Link customization, make sure the country codes in the customization match those specified in `country_codes`, or the customization may not be applied.  If using the Auth features Instant Match, Instant Micro-deposits, Same-Day Micro-deposits, Automated Micro-deposits, or Database Auth, `country_codes` must be set to `['US']`.
  --user: record # An object specifying information about the end user who will be linking their account. **Required** if `user_id` isn't included. — shape: {client_user_id: string, legal_name?: string, name?: any, phone_number?: string, phone_number_verified_time?: string, email_address?: string, email_address_verified_time?: string, ssn?: string, date_of_birth?: string, address?: any, id_number?: any}
  --user-id: string # A `user_id` generated using `/user/create`. Required for integrations that began using Plaid Protect, Multi-Item Link, or Plaid Check Consumer Report after December 10, 2025. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis). One of either the `user_id` or the `user` field is required.
  --products: list # List of Plaid product(s) that the linked Item must support. If launching Link in update mode, should be omitted (unless you are using update mode to add a credit product, such as Assets, Statements, Income, or Plaid Check Consumer Report, to an existing Item); at least one `product` is required otherwise.  To maximize the number of institutions and accounts available, initialize Link with the minimal product set required for your use case, as the products specified will limit which institutions and account types will be available to your users in Link. Only institutions that support *all* requested products can be selected; if a user attempts to select an institution that does not support a listed product, a "Connectivity not supported" error message will appear in Link. For each specified product, the Item connected by the user must contain at least one compatible account. For details on compatible product / account type combinations, see [the account type/product support matrix](https://plaid.com/docs/api/accounts/#account-type--product-support-matrix).  To add products without limiting the institution list or account types, use the [`optional_products`](https://plaid.com/docs/api/link/#link-token-create-request-optional-products) or  [`required_if_supported_products`](https://plaid.com/docs/api/link/#link-token-create-request-required-if-supported-products) fields. Products can also be added to an Item by calling the product endpoint after obtaining an access token; this may require the product to be listed in the [`additional_consented_products`](https://plaid.com/docs/api/link/#link-token-create-request-additional-consented-products) array. For details, see [Choosing when to initialize products](https://plaid.com/docs/link/initializing-products/).  `balance` is *not* a valid value, the Balance product does not require explicit initialization and will automatically be initialized when any other product is initialized.  If launching Link with CRA products, `cra_base_reports` is required and must be included in the `products` array.  Note that, unless you have opted to disable Instant Match support, institutions that support Instant Match will also be shown in Link if `auth` is specified as a product, even though these institutions do not contain `auth` in their product array.  In Production, you will be billed for each product that you specify when initializing Link. Note that a product cannot be removed from an Item once the Item has been initialized with that product. To stop billing on an Item for subscription-based products, such as Liabilities, Investments, and Transactions, remove the Item via `/item/remove`. (nullable)
  --required-if-supported-products: list # List of Plaid product(s) you wish to use only if the institution and account(s) selected by the user support the product. Institutions that do not support these products will still be shown in Link. The products will only be extracted and billed if the user selects an institution and account type that supports them.  There should be no overlap between this array and the `products`, `optional_products`, or `additional_consented_products` arrays. The `products` array must have at least one product.  For more details on using this feature, see [Required if Supported Products](https://plaid.com/docs/link/initializing-products/#required-if-supported-products). (nullable)
  --optional-products: list # List of Plaid product(s) that will enhance the consumer's use case, but that your app can function without. Plaid will attempt to fetch data for these products on a best-effort basis, and failure to support these products will not affect Item creation.  There should be no overlap between this array and the `products`, `required_if_supported_products`, or `additional_consented_products` arrays. The `products` array must have at least one product.  For more details on using this feature, see [Optional Products](https://plaid.com/docs/link/initializing-products/#optional-products). (nullable)
  --additional-consented-products: list # List of additional Plaid product(s) you wish to collect consent for to support your use case. These products will not be billed until you start using them by calling the relevant endpoints.  `balance` is *not* a valid value, the Balance product does not require explicit initialization and will automatically have consent collected.  Institutions that do not support these products will still be shown in Link.  There should be no overlap between this array and the `products` or `required_if_supported_products` arrays.  If you include `signal` in `additional_consented_products`, you will need to call [`/signal/prepare`](https://plaid.com/docs/api/products/signal/#signalprepare) before calling `/signal/evaluate` for the first time on an Item in order to get the most accurate results. For more details, see [`/signal/prepare`](https://plaid.com/docs/api/products/signal/#signalprepare). (nullable)
  --webhook: string # The destination URL to which any webhooks should be sent. Note that webhooks for Payment Initiation (e-wallet transactions only), Transfer, Bank Transfer (including Auth micro-deposit notification webhooks), Monitor, and Identity Verification are configured via the Dashboard instead. In update mode, this field will not have an effect; to update the webhook receiver endpoint for an existing Item, use `/item/webhook/update` instead. (format: url)
  --access-token: string # The `access_token` associated with the Item to update or reference, used when updating, modifying, or accessing an existing `access_token`. Used when launching Link in update mode, when completing the Same-Day Micro-deposit (manual) flow, or (optionally) when initializing Link for a returning user as part of the Transfer UI flow. (nullable)
  --access-tokens: list # A list of access tokens associated with the items to update in Link update mode for the Assets product. Using this instead of the `access_token` field allows the updating of multiple items at once. This feature is in closed beta, please contact your account manager for more info.
  --link-customization-name: string # The name of the Link customization from the Plaid Dashboard to be applied to Link. If not specified, the `default` customization will be used. When using a Link customization, the language in the customization must match the language selected via the `language` parameter, and the countries in the customization should match the country codes selected via `country_codes`.
  --appearance-mode: string@appearance-mode-completer # Enum representing the desired appearance mode for Link, used to force light or dark modes or set Link to change depending on user system settings. Currently in closed beta. (nullable)
  --redirect-uri: string # A URI indicating the destination where a user should be forwarded after completing the Link flow; used to support OAuth authentication flows when launching Link in the browser or another app. The `redirect_uri` should not contain any query parameters. When used in Production, must be an https URI. Note that any redirect URI must also be added to the Allowed redirect URIs list in the [developer dashboard](https://dashboard.plaid.com/team/api). If initializing on Android, `android_package_name` must be specified instead and `redirect_uri` should be left blank.
  --android-package-name: string # The name of your app's Android package. Required if using the `link_token` to initialize Link on Android. Any package name specified here must also be added to the Allowed Android package names setting on the [developer dashboard](https://dashboard.plaid.com/team/api). When creating a `link_token` for initializing Link on other platforms, `android_package_name` must be left blank and `redirect_uri` should be used instead.
  --institution-data: record # A map containing data used to highlight institutions in Link. — shape: {routing_number?: string}
  --card-switch: record # A map containing data to pass in for the Card Switch flow. — shape: {card_bin: string}
  --account-filters: record # By default, Link will provide limited account filtering: it will only display Institutions that are compatible with all products supplied in the `products` parameter of `/link/token/create`, and, if `auth` is specified in the `products` array, will also filter out accounts other than `checking`, `savings`, and `cash management` accounts on the Account Select pane. You can further limit the accounts shown in Link by using `account_filters` to specify the account subtypes to be shown in Link. Only the specified subtypes will be shown. This filtering applies to both the Account Select view (if enabled) and the Institution Select view. Institutions that do not support the selected subtypes will be omitted from Link. To indicate that all subtypes should be shown, use the value `"all"`. If the `account_filters` filter is used, any account type for which a filter is not specified will be entirely omitted from Link. For a full list of valid types and subtypes, see the [Account schema](https://plaid.com/docs/api/accounts#account-type-schema).  The filter may or may not impact the list of accounts shown by the institution in the OAuth account selection flow, depending on the specific institution. If the user selects excluded account subtypes in the OAuth flow, these accounts will not be added to the Item. If the user selects only excluded account subtypes, the link attempt will fail and the user will be prompted to try again. — shape: {depository?: record, credit?: record, loan?: record, investment?: record, other?: record}
  --eu-config: record # Configuration parameters for EU flows (DEPRECATED) — shape: {headless?: bool}
  --institution-id: string # Used for certain legacy use cases
  --payment-configuration: record # Specifies options for initializing Link for use with the Pay By Bank flow. This is an optional field to configure the user experience, and currently requires the amount field to be set. — shape: {amount: string, description?: string}
  --payment-initiation: record # Specifies options for initializing Link for use with the Payment Initiation (Europe) product. This field is required if `payment_initiation` is included in the `products` array. Either `payment_id` or `consent_id` must be provided. — shape: {payment_id?: string, consent_id?: string}
  --employment: record # Specifies options for initializing Link for use with the Employment product. This field is required if `employment` is included in the `products` array. — shape: {employment_source_types?: list, bank_employment?: record}
  --income-verification: record # Specifies options for initializing Link for use with the Income product. This field is required if `income_verification` is included in the `products` array. — shape: {income_verification_id?: string, asset_report_id?: string, access_tokens?: list, income_source_types?: list, bank_income?: record, payroll_income?: record, stated_income_sources?: list}
  --base-report: record # Specifies options for initializing Link for use with the Base Report product. This field is required if `assets` is included in the `products` array and the client is CRA-enabled. (DEPRECATED) — shape: {days_requested: int, client_report_id?: string}
  --credit-partner-insights: record # Specifies options for initializing Link for use with the Credit Partner Insights product. — shape: {days_requested?: int}
  --cra-options: record # Specifies options for initializing Link for use with Plaid Check products — shape: {days_requested: int, days_required?: int, client_report_id?: string, partner_insights?: record, base_report?: record, cashflow_insights?: record, lend_score?: record, network_insights?: record, include_investments?: bool, income_insights?: record}
  --consumer-report-permissible-purpose: string@consumer-report-permissible-purpose-completer-1 # Describes the reason you are generating a Consumer Report for this user. When calling `/link/token/create`, this field is required when using Plaid Check (CRA) products; invalid if not using Plaid Check (CRA) products.  `ACCOUNT_REVIEW_CREDIT`: In connection with a consumer credit transaction for the review or collection of an account pursuant to FCRA Section 604(a)(3)(A).  `ACCOUNT_REVIEW_NON_CREDIT`: For a legitimate business need of the information to review a non-credit account provided primarily for personal, family, or household purposes to determine whether the consumer continues to meet the terms of the account pursuant to FCRA Section 604(a)(3)(F)(2).  `EXTENSION_OF_CREDIT`: In connection with a credit transaction initiated by and involving the consumer pursuant to FCRA Section 604(a)(3)(A).  `LEGITIMATE_BUSINESS_NEED_TENANT_SCREENING`: For a legitimate business need in connection with a business transaction initiated by the consumer primarily for personal, family, or household purposes in connection with a property rental assessment pursuant to FCRA Section 604(a)(3)(F)(i).  `LEGITIMATE_BUSINESS_NEED_OTHER`: For a legitimate business need in connection with a business transaction made primarily for personal, family, or household initiated by the consumer pursuant to FCRA Section 604(a)(3)(F)(i).  `WRITTEN_INSTRUCTION_PREQUALIFICATION`: In accordance with the written instructions of the consumer pursuant to FCRA Section 604(a)(2), to evaluate an application's profile to make an offer to the consumer.  `WRITTEN_INSTRUCTION_OTHER`: In accordance with the written instructions of the consumer pursuant to FCRA Section 604(a)(2), such as when an individual agrees to act as a guarantor or assumes personal liability for a consumer, business, or commercial loan.  `ELIGIBILITY_FOR_GOVT_BENEFITS`:  In connection with an eligibility determination for a government benefit where the entity is required to consider an applicant's financial status pursuant to FCRA Section 604(a)(3)(D).
  --body-auth: record # Specifies options for initializing Link for use with the Auth product. This field can be used to enable or disable extended Auth flows for the resulting Link session. Omitting any field will result in a default that can be configured by your account manager. The default behavior described in the documentation is the default behavior that will apply if you have not requested your account manager to apply a different default. If you have enabled the [Dashboard Account Verification pane](https://dashboard.plaid.com/account-verification), the settings enabled there will override any settings in this object. — shape: {auth_type_select_enabled?: bool, automated_microdeposits_enabled?: bool, instant_match_enabled?: bool, same_day_microdeposits_enabled?: bool, instant_microdeposits_enabled?: bool, reroute_to_credentials?: "OFF"|"OPTIONAL"|"FORCED", database_match_enabled?: bool, database_insights_enabled?: bool, flow_type?: "FLEXIBLE_AUTH", sms_microdeposits_verification_enabled?: bool}
  --transfer: record # Specifies options for initializing Link for use with the Transfer product. — shape: {intent_id?: string, authorization_id?: string, payment_profile_token?: string}
  --update: record # Specifies options for initializing Link for [update mode](https://plaid.com/docs/link/update-mode). — shape: {account_selection_enabled?: bool, reauthorization_enabled?: bool, user?: bool, item_ids?: list}
  --identity-verification: record # Specifies option for initializing Link for use with the Identity Verification product. — shape: {template_id: any, consent?: any, gave_consent?: bool}
  --statements: record # Specifies options for initializing Link for use with the Statements product. This field is required for the statements product. — shape: {start_date: string, end_date: string}
  --third-party-user-token: string # A third party user token associated with the current user.
  --investments: record # Configuration parameters for the Investments product — shape: {allow_unverified_crypto_wallets?: bool, allow_manual_entry?: bool}
  --investments-auth: record # Configuration parameters for the Investments Move product — shape: {manual_entry_enabled?: bool, masked_number_match_enabled?: bool, stated_account_number_enabled?: bool, rollover_401k_enabled?: bool}
  --hosted-link: record # Configuration parameters for Hosted Link. To enable the session for Hosted Link, send this object in the request. It can be empty. — shape: {delivery_method?: "sms"|"email", completion_redirect_uri?: string, url_lifetime_seconds?: int, is_mobile_app?: bool}
  --transactions: record # Configuration parameters for the Transactions product — shape: {days_requested?: int}
  --cashflow-report: record # Configuration parameters for the Cashflow Report product. Currently in closed beta. — shape: {days_requested?: int}
  --cra-enabled: string@bool-completer # If `true`, request a CRA connection. Defaults to `false`.
  --identity: record # Identity object used to specify document upload — shape: {is_document_upload?: bool, account_ids?: list, parsing_configs?: list}
  --financekit-supported: string@bool-completer # If `true`, indicates that client supports linking FinanceKit / AppleCard items. Defaults to `false`.
  --enable-multi-item-link: string@bool-completer # If `true`, enable linking multiple items in the same Link session. Defaults to `false`.
  --user-token: string # A user token generated using `/user/create`. Any Item created during the Link session will be associated with the user. Integrations that began using Plaid Protect, Multi-Item Link, or Plaid Check Consumer Report before December 10, 2025 use this field instead of the `user_id`.
]: any -> record<link_token: string, expiration: string, request_id: string, hosted_link_url: string, user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/link/token/create")
  let body = {client_id: $client_id, secret: $secret, client_name: $client_name, language: $language, country_codes: $country_codes, user: $user, user_id: $user_id, products: $products, required_if_supported_products: $required_if_supported_products, optional_products: $optional_products, additional_consented_products: $additional_consented_products, webhook: $webhook, access_token: $access_token, access_tokens: $access_tokens, link_customization_name: $link_customization_name, appearance_mode: $appearance_mode, redirect_uri: $redirect_uri, android_package_name: $android_package_name, institution_data: $institution_data, card_switch: $card_switch, account_filters: $account_filters, eu_config: $eu_config, institution_id: $institution_id, payment_configuration: $payment_configuration, payment_initiation: $payment_initiation, employment: $employment, income_verification: $income_verification, base_report: $base_report, credit_partner_insights: $credit_partner_insights, cra_options: $cra_options, consumer_report_permissible_purpose: $consumer_report_permissible_purpose, auth: $body_auth, transfer: $transfer, update: $update, identity_verification: $identity_verification, statements: $statements, third_party_user_token: $third_party_user_token, investments: $investments, investments_auth: $investments_auth, hosted_link: $hosted_link, transactions: $transactions, cashflow_report: $cashflow_report, cra_enabled: $cra_enabled, identity: $identity, financekit_supported: $financekit_supported, enable_multi_item_link: $enable_multi_item_link, user_token: $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Link Token
#
# POST /link/token/get
# Docs: /api/link/#linktokenget
# operationId: linkTokenGet
export def "link-token-get linkTokenGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  link_token: string # A `link_token` from a previous invocation of `/link/token/create`
]: any -> record<link_token: string, created_at: string, expiration: string, link_sessions: table<link_session_id: string, started_at: string, finished_at: string, on_success: record, on_exit: record, exit: record, events: list, results: record>, metadata: record<initial_products: list<string>, webhook: string, country_codes: list<string>, language: string, institution_data: record<routing_number: string>, account_filters: record<depository: record, credit: record, loan: record, investment: record>, redirect_uri: string, client_name: string>, user_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/link/token/get")
  let body = {client_id: $client_id, secret: $secret, link_token: $link_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Exchange the Link Correlation ID for a Link Token
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  link_correlation_id: string # A `link_correlation_id` from a received OAuth redirect URI callback
]: any -> record<link_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/link/oauth/correlation_id/exchange")
  let body = {client_id: $client_id, secret: $secret, link_correlation_id: $link_correlation_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a Link token for Layer
#
# POST /session/token/create
# Docs: /api/products/layer/#sessiontokencreate
# operationId: sessionTokenCreate
# --user shape: {client_user_id: string, user_id?: any}
export def "session-token-create sessionTokenCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  template_id: string # The id of a template defined in Plaid Dashboard
  --user: record # Details about the end user. Required if a root-level `user_id` is not provided. — shape: {client_user_id: string, user_id?: any}
  --redirect-uri: string # A URI indicating the destination where a user should be forwarded after completing the Link flow; used to support OAuth authentication flows when launching Link in the browser or another app. The `redirect_uri` should not contain any query parameters. When used in Production, must be an https URI. Note that any redirect URI must also be added to the Allowed redirect URIs list in the [developer dashboard](https://dashboard.plaid.com/team/api). If initializing on Android, `android_package_name` must be specified instead and `redirect_uri` should be left blank.
  --android-package-name: string # The name of your app's Android package. Required if using the session token to initialize Layer on Android. Any package name specified here must also be added to the Allowed Android package names setting on the [developer dashboard](https://dashboard.plaid.com/team/api). When creating a session token for initializing Layer on other platforms, `android_package_name` must be left blank and `redirect_uri` should be used instead.
  --webhook: string # The destination URL to which any webhooks should be sent. If you use the same webhook listener for all Sandbox or all Production activity, set this value in the Layer template editor in the Dashboard instead. Only provide a value in this field if you need to use multiple webhook URLs per environment (an uncommon use case). If provided, a value in this field will take priority over webhook values set in the Layer template editor. (format: url)
  --user-id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
]: any -> record<request_id: string, link: record<link_token: string, expiration: string, user_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/session/token/create")
  let body = {client_id: $client_id, secret: $secret, template_id: $template_id, user: $user, redirect_uri: $redirect_uri, android_package_name: $android_package_name, webhook: $webhook, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a transfer
#
# POST /transfer/get
# Docs: /api/products/transfer/reading-transfers/#transferget
# operationId: transferGet
@deprecated --flag originator-client-id
export def "transfer-get transferGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --transfer-id: string # Plaid's unique identifier for a transfer.
  --authorization-id: string # Plaid's unique identifier for a transfer authorization.
  --originator-client-id: string # The Plaid client ID of the transfer originator. Should only be present if `client_id` is a third-party sender (TPS). (DEPRECATED, nullable)
]: any -> record<transfer: record<id: string, authorization_id: string, ach_class: string, account_id: string, funding_account_id: string, ledger_id: string, type: string, user: record<legal_name: string, phone_number: string, email_address: string, address: record>, amount: string, description: string, created: string, status: string, sweep_status: string, network: string, wire_details: record<message_to_beneficiary: string, wire_return_fee: string>, cancellable: bool, failure_reason: record<failure_code: string, ach_return_code: string, description: string>, metadata: record, origination_account_id: string, guarantee_decision: string, guarantee_decision_rationale: record<code: string, description: string>, iso_currency_code: string, standard_return_window: string, unauthorized_return_window: string, expected_settlement_date: string, expected_funds_available_date: string, originator_client_id: string, refunds: list<record>, recurring_transfer_id: string, expected_sweep_settlement_schedule: list<record>, credit_funds_source: record, facilitator_fee: string, network_trace_id: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/get")
  let body = {client_id: $client_id, secret: $secret, transfer_id: $transfer_id, authorization_id: $authorization_id, originator_client_id: $originator_client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a recurring transfer
#
# POST /transfer/recurring/get
# Docs: /api/products/transfer/recurring-transfers/#transferrecurringget
# operationId: transferRecurringGet
export def "transfer-recurring-get transferRecurringGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  recurring_transfer_id: string # Plaid's unique identifier for a recurring transfer.
]: any -> record<recurring_transfer: record<recurring_transfer_id: string, created: string, next_origination_date: string, test_clock_id: string, type: string, amount: string, status: string, ach_class: string, network: string, origination_account_id: string, account_id: string, funding_account_id: string, iso_currency_code: string, description: string, transfer_ids: list<string>, user: record<legal_name: string, phone_number: string, email_address: string, address: record>, schedule: record<interval_unit: string, interval_count: int, interval_execution_day: int, start_date: string, end_date: string>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/recurring/get")
  let body = {client_id: $client_id, secret: $secret, recurring_transfer_id: $recurring_transfer_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  bank_transfer_id: string # Plaid's unique identifier for a bank transfer.
]: any -> record<bank_transfer: record<id: string, ach_class: string, account_id: string, type: string, user: record<legal_name: string, email_address: string, routing_number: string>, amount: string, iso_currency_code: string, description: string, created: string, status: string, network: string, cancellable: bool, failure_reason: record<ach_return_code: string, description: string>, custom_tag: string, metadata: record, origination_account_id: string, direction: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank_transfer/get")
  let body = {client_id: $client_id, secret: $secret, bank_transfer_id: $bank_transfer_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a transfer authorization
#
# POST /transfer/authorization/create
# Docs: /api/products/transfer/initiating-transfers/#transferauthorizationcreate
# operationId: transferAuthorizationCreate
# --wire_details shape: {message_to_beneficiary?: string, wire_return_fee?: string}
# --user shape: {legal_name: string, phone_number?: string, email_address?: string, address?: record}
# --device shape: {ip_address?: string, user_agent?: string}
@deprecated --flag origination-account-id
@deprecated --flag with-guarantee
@deprecated --flag credit-funds-source
export def "transfer-authorization-create transferAuthorizationCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The Plaid `access_token` for the account that will be debited or credited.
  account_id: string # The Plaid `account_id` corresponding to the end-user account that will be debited or credited.
  --funding-account-id: string # Specify the account used to fund the transfer. Should be specified if using legacy funding methods only. If using Plaid Ledger, leave this field blank. Customers can find a list of `funding_account_id`s in the Accounts page of your Plaid Dashboard, under the "Account ID" column. If this field is left blank and you are using legacy funding methods, this will default to the default `funding_account_id` specified during onboarding. Otherwise, Plaid Ledger will be used. (nullable)
  --ledger-id: string # Specify which ledger balance should be used to fund the transfer. You can find a list of `ledger_id`s in the Accounts page of your Plaid Dashboard. If this field is left blank, this will default to id of the default ledger balance. (nullable)
  --payment-profile-token: string # The payment profile token associated with the Payment Profile that will be debited or credited. Required if not using `access_token`.
  type: string@type-completer-1 # The type of transfer. This will be either `debit` or `credit`.  A `debit` indicates a transfer of money into the origination account; a `credit` indicates a transfer of money out of the origination account.
  network: string@network-completer-1 # The network or rails used for the transfer.  For transfers submitted as `ach` or `same-day-ach`, the Standard ACH cutoff is 8:30 PM Eastern Time.  For transfers submitted as `same-day-ach`, the Same Day ACH cutoff is 3:00 PM Eastern Time.  It is recommended to send the request 15 minutes prior to the cutoff to ensure that it will be processed in time for submission before the cutoff. If the transfer is processed after this cutoff but before the Standard ACH cutoff, it will be sent over Standard ACH rails and will not incur same-day charges; this will apply to both legs of the transfer if applicable. The transaction limit for a Same Day ACH transfer is $1,000,000. Authorization requests sent with an amount greater than $1,000,000 will fail.  For transfers submitted as `rtp`,  Plaid will automatically route between Real Time Payment rail by TCH or FedNow rails as necessary. If a transfer is submitted as `rtp` and the counterparty account is not eligible for RTP, the `/transfer/authorization/create` request will fail with an `INVALID_FIELD` error code. To pre-check to determine whether a counterparty account can support RTP, call `/transfer/capabilities/get` before calling `/transfer/authorization/create`.  Wire transfers are currently in early availability. To request access to `wire` as a payment network, contact your account manager. For transfers submitted as `wire`, the `type` must be `credit`; wire debits are not supported. The cutoff to submit a wire payment is 6:30 PM Eastern Time on a business day; wires submitted after that time will be processed on the next business day. The transaction limit for a wire is $999,999.99. Authorization requests sent with an amount greater than $999,999.99 will fail.
  amount: string # The amount of the transfer (decimal string with two digits of precision e.g. "10.00"). When calling `/transfer/authorization/create`, specify the maximum amount to authorize. When calling `/transfer/create`, specify the exact amount of the transfer, up to a maximum of the amount authorized. If this field is left blank when calling `/transfer/create`, the maximum amount authorized in the `authorization_id` will be sent.
  --ach-class: string@ach-class-completer # Specifies the use case of the transfer. Required for transfers on an ACH network. For more details, see [ACH SEC codes](https://plaid.com/docs/transfer/creating-transfers/#ach-sec-codes).  Codes supported for credits: `ccd`, `ppd` Codes supported for debits: `ccd`, `tel`, `web`  `"ccd"` - Corporate Credit or Debit - fund transfer between two corporate bank accounts  `"ppd"` - Prearranged Payment or Deposit - The transfer is part of a pre-existing relationship with a consumer. Authorization was obtained in writing either in person or via an electronic document signing, e.g. Docusign, by the consumer. Can be used for credits or debits.  `"web"` - Internet-Initiated Entry. The transfer debits a consumer's bank account. Authorization from the consumer is obtained over the Internet (e.g. a web or mobile application). Can be used for single debits or recurring debits.  `"tel"` - Telephone-Initiated Entry. The transfer debits a consumer. Debit authorization has been received orally over the telephone via a recorded call.
  --wire-details: record # Information specific to wire transfers. (nullable) — shape: {message_to_beneficiary?: string, wire_return_fee?: string}
  user: record # The legal name and other information for the account holder.  If the account has multiple account holders, provide the information for the account holder on whose behalf the authorization is being requested. The `user.legal_name` field is required. Other fields are not currently used and are present to support planned future functionality. — shape: {legal_name: string, phone_number?: string, email_address?: string, address?: record}
  --device: record # Information about the device being used to initiate the authorization. These fields are not currently incorporated into the risk check. — shape: {ip_address?: string, user_agent?: string}
  --origination-account-id: string # Plaid's unique identifier for the origination account for this authorization. If not specified, the default account will be used. (DEPRECATED)
  --iso-currency-code: string # The currency of the transfer amount. The default value is "USD".
  --idempotency-key: string # A random key provided by the client, per unique authorization, which expires after 48 hours. Maximum of 50 characters.  The API supports idempotency for safely retrying requests without accidentally performing the same operation twice. For example, if a request to create an authorization fails due to a network connection error, you can retry the request with the same idempotency key to guarantee that only a single authorization is created.  Idempotency does not apply to authorizations whose decisions are `user_action_required`. Therefore you may re-attempt the authorization after completing the required user action without changing `idempotency_key`.  This idempotency key expires after 48 hours, after which the same key can be reused. Failure to provide this key may result in duplicate charges. (nullable)
  --user-present: string@bool-completer # If the end user is initiating the specific transfer themselves via an interactive UI, this should be `true`; for automatic recurring payments where the end user is not actually initiating each individual transfer, it should be `false`. This field is not currently used and is present to support planned future functionality. (nullable)
  --with-guarantee: string@bool-completer # If set to `false`, Plaid will not offer a `guarantee_decision` for this request (Guarantee customers only). This field is deprecated in favor for `guarantee`. (DEPRECATED, nullable, default: true)
  --request-guarantee: string@bool-completer # Indicates whether the transfer should be evaluated for guarantee coverage. When set to `true`, Plaid assesses the transfer for guarantee coverage and returns a decision in the authorization response. When omitted or set to `false`, the authorization is evaluated without guarantee coverage. (nullable)
  --beacon-session-id: string # The unique identifier returned by Plaid's [beacon](https://plaid.com/docs/transfer/guarantee/#using-a-beacon) when it is run on your webpage. (nullable)
  --originator-client-id: string # The Plaid client ID that is the originator of this transfer. Only needed if creating transfers on behalf of another client as a [Platform customer](https://plaid.com/docs/transfer/application/#originators-vs-platforms). (nullable)
  --credit-funds-source: any # DEPRECATED
  --test-clock-id: string # Plaid's unique identifier for a test clock. This field may only be used when using `sandbox` environment. If provided, the `authorization` is created at the `virtual_time` on the provided test clock. (nullable)
  --ruleset-key: string # The key of the Ruleset for the transaction. If not provided, Signal will use the `default` ruleset. (nullable)
  --custom-attributes: record # A free-form map of client-supplied risk-relevant context for this authorization. Plaid may use these attributes to inform future versions of our risk models.  The following limitations apply: Keys must match the regular expression `^[A-Za-z0-9_.-]{1,40}$` Values must be strings (no nested objects, arrays, numbers, or booleans allowed; stringify non-string values client-side) Maximum of 50 key/value pairs Maximum value length of 500 characters  Do not include personally identifiable information or other sensitive data.  (nullable)
]: any -> record<authorization: record<id: string, created: string, decision: string, decision_rationale: record<code: string, description: string>, guarantee_decision: string, guarantee_decision_rationale: record<code: string, description: string>, payment_risk: record<bank_initiated_return_score: int, customer_initiated_return_score: int, risk_level: string, warnings: list>, proposed_transfer: record<ach_class: string, account_id: string, funding_account_id: string, ledger_id: string, type: string, user: record, amount: string, network: string, wire_details: record, origination_account_id: string, iso_currency_code: string, originator_client_id: string, credit_funds_source: record>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/authorization/create")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, account_id: $account_id, funding_account_id: $funding_account_id, ledger_id: $ledger_id, payment_profile_token: $payment_profile_token, type: $type, network: $network, amount: $amount, ach_class: $ach_class, wire_details: $wire_details, user: $user, device: $device, origination_account_id: $origination_account_id, iso_currency_code: $iso_currency_code, idempotency_key: $idempotency_key, user_present: $user_present, with_guarantee: $with_guarantee, request_guarantee: $request_guarantee, beacon_session_id: $beacon_session_id, originator_client_id: $originator_client_id, credit_funds_source: $credit_funds_source, test_clock_id: $test_clock_id, ruleset_key: $ruleset_key, custom_attributes: $custom_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel a transfer authorization
#
# POST /transfer/authorization/cancel
# Docs: /api/products/transfer/initiating-transfers/#transferauthorizationcancel
# operationId: transferAuthorizationCancel
export def "transfer-authorization-cancel transferAuthorizationCancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  authorization_id: string # Plaid's unique identifier for a transfer authorization.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/authorization/cancel")
  let body = {client_id: $client_id, secret: $secret, authorization_id: $authorization_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# (Deprecated) Retrieve a balance held with Plaid
#
# POST /transfer/balance/get
# DEPRECATED
# Docs: /api/products/transfer/balance/#transferbalanceget
# operationId: transferBalanceGet
@deprecated
@deprecated --flag originator-client-id
export def "transfer-balance-get transferBalanceGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --originator-client-id: string # Client ID of the end customer. (DEPRECATED, nullable)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --type: string@type-completer-3 # The type of balance.  `prefunded_rtp_credits` - Your prefunded RTP credit balance with Plaid `prefunded_ach_credits` - Your prefunded ACH credit balance with Plaid
]: any -> record<balance: record<available: string, current: string, type: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/balance/get")
  let body = {client_id: $client_id, originator_client_id: $originator_client_id, secret: $secret, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get RTP eligibility information of a transfer
#
# POST /transfer/capabilities/get
# Docs: /api/products/transfer/account-linking/#transfercapabilitiesget
# operationId: transferCapabilitiesGet
export def "transfer-capabilities-get transferCapabilitiesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The Plaid `access_token` for the account that will be debited or credited.
  account_id: string # The Plaid `account_id` corresponding to the end-user account that will be debited or credited.
  --payment-profile-token: string # A payment profile token associated with the Payment Profile data that is being requested.
]: any -> record<institution_supported_networks: record<rtp: record<credit: bool>, rfp: record<debit: bool, max_amount: string, iso_currency_code: string>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/capabilities/get")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, account_id: $account_id, payment_profile_token: $payment_profile_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get transfer product configuration
#
# POST /transfer/configuration/get
# Docs: /api/products/transfer/metrics/#transferconfigurationget
# operationId: transferConfigurationGet
export def "transfer-configuration-get transferConfigurationGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --originator-client-id: string # The Plaid client ID of the transfer originator. Should only be present if `client_id` is a [Platform customer](https://plaid.com/docs/transfer/application/#originators-vs-platforms). (nullable)
]: any -> record<request_id: string, max_single_transfer_amount: string, max_single_transfer_credit_amount: string, max_single_transfer_debit_amount: string, max_daily_credit_amount: string, max_daily_debit_amount: string, max_monthly_amount: string, max_monthly_credit_amount: string, max_monthly_debit_amount: string, iso_currency_code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/configuration/get")
  let body = {client_id: $client_id, secret: $secret, originator_client_id: $originator_client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Plaid Ledger balance
#
# POST /transfer/ledger/get
# Docs: /api/products/transfer/ledger/#transferledgerget
# operationId: transferLedgerGet
export def "transfer-ledger-get transferLedgerGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --ledger-id: string # Specify which ledger balance to get. Customers can find a list of `ledger_id`s in the Accounts page of your Plaid Dashboard. If this field is left blank, this will default to id of the default ledger balance. (nullable)
  --originator-client-id: string # Client ID of the end customer. (nullable)
]: any -> record<ledger_id: string, balance: record<available: string, pending: string>, name: string, is_default: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/ledger/get")
  let body = {client_id: $client_id, secret: $secret, ledger_id: $ledger_id, originator_client_id: $originator_client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Move available balance between ledgers
#
# POST /transfer/ledger/distribute
# Docs: /api/products/transfer/ledger/#transferledgerdistribute
# operationId: transferLedgerDistribute
export def "transfer-ledger-distribute transferLedgerDistribute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  from_ledger_id: string # The Ledger to pull money from.
  to_ledger_id: string # The Ledger to credit money to.
  amount: string # The amount to move (decimal string with two digits of precision e.g. "10.00"). Amount must be positive.
  idempotency_key: string # A unique key provided by the client, per unique ledger distribute. Maximum of 50 characters.  The API supports idempotency for safely retrying the request without accidentally performing the same operation twice. For example, if a request to create a ledger distribute fails due to a network connection error, you can retry the request with the same idempotency key to guarantee that only a single distribute is created.
  --description: string # An optional description for the ledger distribute operation.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/ledger/distribute")
  let body = {client_id: $client_id, secret: $secret, from_ledger_id: $from_ledger_id, to_ledger_id: $to_ledger_id, amount: $amount, idempotency_key: $idempotency_key, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deposit funds into a Plaid Ledger balance
#
# POST /transfer/ledger/deposit
# Docs: /api/products/transfer/ledger/#transferledgerdeposit
# operationId: transferLedgerDeposit
export def "transfer-ledger-deposit transferLedgerDeposit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --originator-client-id: string # Client ID of the customer that owns the Ledger balance. This is so Plaid knows which of your customers to payout or collect funds. Only applicable for [Platform customers](https://plaid.com/docs/transfer/application/#originators-vs-platforms). Do not include if you're paying out to yourself. (nullable)
  --funding-account-id: string # Specify which funding account to use. Customers can find a list of `funding_account_id`s in the Accounts page of the Plaid Dashboard, under the "Account ID" column. If this field is left blank, the funding account associated with the specified Ledger will be used. If an `originator_client_id` is specified, the `funding_account_id` must belong to the specified originator. (nullable)
  --ledger-id: string # Specify which ledger balance to deposit to. Customers can find a list of `ledger_id`s in the Accounts page of your Plaid Dashboard. If this field is left blank, this will default to id of the default ledger balance. (nullable)
  amount: string # A positive amount of how much will be deposited into ledger (decimal string with two digits of precision e.g. "5.50").
  --description: string # The description of the deposit that will be passed to the receiving bank (up to 10 characters). Note that banks utilize this field differently, and may or may not show it on the bank statement. (nullable)
  idempotency_key: string # A unique key provided by the client, per unique ledger deposit. Maximum of 50 characters.  The API supports idempotency for safely retrying the request without accidentally performing the same operation twice. For example, if a request to create a ledger deposit fails due to a network connection error, you can retry the request with the same idempotency key to guarantee that only a single deposit is created.
  network: string@network-completer-2 # The ACH networks used for the funds flow.  For requests submitted as either `ach` or `same-day-ach` the cutoff for Same Day ACH is 3:00 PM Eastern Time and the cutoff for Standard ACH transfers is 8:30 PM Eastern Time. It is recommended to submit a request at least 15 minutes before the cutoff time in order to ensure that it will be processed before the cutoff. Any request that is indicated as `same-day-ach` and that misses the Same Day ACH cutoff, but is submitted in time for the Standard ACH cutoff, will be sent over Standard ACH rails and will not incur same-day charges.
]: any -> record<sweep: record<id: string, funding_account_id: string, ledger_id: string, created: string, amount: string, iso_currency_code: string, settled: string, expected_funds_available_date: string, status: string, trigger: string, description: string, network_trace_id: string, failure_reason: record<failure_code: string, description: string>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/ledger/deposit")
  let body = {client_id: $client_id, secret: $secret, originator_client_id: $originator_client_id, funding_account_id: $funding_account_id, ledger_id: $ledger_id, amount: $amount, description: $description, idempotency_key: $idempotency_key, network: $network} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Withdraw funds from a Plaid Ledger balance
#
# POST /transfer/ledger/withdraw
# Docs: /api/products/transfer/ledger/#transferledgerwithdraw
# operationId: transferLedgerWithdraw
export def "transfer-ledger-withdraw transferLedgerWithdraw" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --originator-client-id: string # Client ID of the customer that owns the Ledger balance. This is so Plaid knows which of your customers to payout or collect funds. Only applicable for [Platform customers](https://plaid.com/docs/transfer/application/#originators-vs-platforms). Do not include if you're paying out to yourself. (nullable)
  --funding-account-id: string # Specify which funding account to use. Customers can find a list of `funding_account_id`s in the Accounts page of the Plaid Dashboard, under the "Account ID" column. If this field is left blank, the funding account associated with the specified Ledger will be used. If an `originator_client_id` is specified, the `funding_account_id` must belong to the specified originator. (nullable)
  --ledger-id: string # Specify which ledger balance to withdraw from. Customers can find a list of `ledger_id`s in the Accounts page of your Plaid Dashboard. If this field is left blank, this will default to id of the default ledger balance. (nullable)
  amount: string # A positive amount of how much will be withdrawn from the ledger balance (decimal string with two digits of precision e.g. "5.50").
  --description: string # The description of the deposit that will be passed to the receiving bank (up to 10 characters). Note that banks utilize this field differently, and may or may not show it on the bank statement. (nullable)
  idempotency_key: string # A unique key provided by the client, per unique ledger withdraw. Maximum of 50 characters.  The API supports idempotency for safely retrying the request without accidentally performing the same operation twice. For example, if a request to create a ledger withdraw fails due to a network connection error, you can retry the request with the same idempotency key to guarantee that only a single withdraw is created.
  network: string@network-completer-1 # The network or rails used for the transfer.  For transfers submitted as `ach` or `same-day-ach`, the Standard ACH cutoff is 8:30 PM Eastern Time.  For transfers submitted as `same-day-ach`, the Same Day ACH cutoff is 3:00 PM Eastern Time.  It is recommended to send the request 15 minutes prior to the cutoff to ensure that it will be processed in time for submission before the cutoff. If the transfer is processed after this cutoff but before the Standard ACH cutoff, it will be sent over Standard ACH rails and will not incur same-day charges; this will apply to both legs of the transfer if applicable. The transaction limit for a Same Day ACH transfer is $1,000,000. Authorization requests sent with an amount greater than $1,000,000 will fail.  For transfers submitted as `rtp`,  Plaid will automatically route between Real Time Payment rail by TCH or FedNow rails as necessary. If a transfer is submitted as `rtp` and the counterparty account is not eligible for RTP, the `/transfer/authorization/create` request will fail with an `INVALID_FIELD` error code. To pre-check to determine whether a counterparty account can support RTP, call `/transfer/capabilities/get` before calling `/transfer/authorization/create`.  Wire transfers are currently in early availability. To request access to `wire` as a payment network, contact your account manager. For transfers submitted as `wire`, the `type` must be `credit`; wire debits are not supported. The cutoff to submit a wire payment is 6:30 PM Eastern Time on a business day; wires submitted after that time will be processed on the next business day. The transaction limit for a wire is $999,999.99. Authorization requests sent with an amount greater than $999,999.99 will fail.
]: any -> record<sweep: record<id: string, funding_account_id: string, ledger_id: string, created: string, amount: string, iso_currency_code: string, settled: string, expected_funds_available_date: string, status: string, trigger: string, description: string, network_trace_id: string, failure_reason: record<failure_code: string, description: string>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/ledger/withdraw")
  let body = {client_id: $client_id, secret: $secret, originator_client_id: $originator_client_id, funding_account_id: $funding_account_id, ledger_id: $ledger_id, amount: $amount, description: $description, idempotency_key: $idempotency_key, network: $network} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the funding account associated with the originator
#
# POST /transfer/originator/funding_account/update
# Docs: /api/products/transfer/platform-payments/#transferoriginatorfunding_accountupdate
# operationId: transferOriginatorFundingAccountUpdate
# --funding_account shape: {access_token: string, account_id: string}
export def "transfer-originator-funding-account-update transferOriginatorFundingAccountUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  originator_client_id: string # The Plaid client ID of the transfer originator.
  funding_account: record # The originator's funding account, linked with Plaid Link or `/transfer/migrate_account`. — shape: {access_token: string, account_id: string}
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/originator/funding_account/update")
  let body = {client_id: $client_id, secret: $secret, originator_client_id: $originator_client_id, funding_account: $funding_account} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new funding account for an originator
#
# POST /transfer/originator/funding_account/create
# Docs: /api/products/transfer/platform-payments/#transferoriginatorfunding_accountcreate
# operationId: transferOriginatorFundingAccountCreate
# --funding_account shape: {access_token: string, account_id: string, display_name?: string}
export def "transfer-originator-funding-account-create transferOriginatorFundingAccountCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  originator_client_id: string # The Plaid client ID of the transfer originator.
  funding_account: record # The originator's funding account, linked with Plaid Link or `/transfer/migrate_account`. — shape: {access_token: string, account_id: string, display_name?: string}
]: any -> record<funding_account_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/originator/funding_account/create")
  let body = {client_id: $client_id, secret: $secret, originator_client_id: $originator_client_id, funding_account: $funding_account} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get transfer product usage metrics
#
# POST /transfer/metrics/get
# Docs: /api/products/transfer/metrics/#transfermetricsget
# operationId: transferMetricsGet
export def "transfer-metrics-get transferMetricsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --originator-client-id: string # The Plaid client ID of the transfer originator. Should only be present if `client_id` is a [Platform customer](https://plaid.com/docs/transfer/application/#originators-vs-platforms). (nullable)
]: any -> record<request_id: string, daily_debit_transfer_volume: string, daily_credit_transfer_volume: string, monthly_transfer_volume: string, monthly_debit_transfer_volume: string, monthly_credit_transfer_volume: string, iso_currency_code: string, return_rates: record<last_60d: record<overall_return_rate: string, unauthorized_return_rate: string, administrative_return_rate: string>>, authorization_usage: record<daily_credit_utilization: string, daily_debit_utilization: string, monthly_credit_utilization: string, monthly_debit_utilization: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/metrics/get")
  let body = {client_id: $client_id, secret: $secret, originator_client_id: $originator_client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a transfer
#
# POST /transfer/create
# Docs: /api/products/transfer/initiating-transfers/#transfercreate
# operationId: transferCreate
# --user shape: {legal_name?: string, phone_number?: string, email_address?: string, address?: record}
@deprecated --flag idempotency-key
@deprecated --flag type
@deprecated --flag network
@deprecated --flag ach-class
@deprecated --flag user
@deprecated --flag origination-account-id
@deprecated --flag iso-currency-code
export def "transfer-create transferCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --idempotency-key: string # Deprecated. `authorization_id` is now used as idempotency instead.  A random key provided by the client, per unique transfer. Maximum of 50 characters.  The API supports idempotency for safely retrying requests without accidentally performing the same operation twice. For example, if a request to create a transfer fails due to a network connection error, you can retry the request with the same idempotency key to guarantee that only a single transfer is created. (DEPRECATED)
  access_token: string # The Plaid `access_token` for the account that will be debited or credited.
  account_id: string # The Plaid `account_id` corresponding to the end-user account that will be debited or credited.
  authorization_id: string # Plaid's unique identifier for a transfer authorization. This parameter also serves the purpose of acting as an idempotency identifier.
  --type: any # DEPRECATED
  --network: any # DEPRECATED
  --amount: string # The amount of the transfer (decimal string with two digits of precision e.g. "10.00"). When calling `/transfer/authorization/create`, specify the maximum amount to authorize. When calling `/transfer/create`, specify the exact amount of the transfer, up to a maximum of the amount authorized. If this field is left blank when calling `/transfer/create`, the maximum amount authorized in the `authorization_id` will be sent.
  description: string # The transfer description, maximum of 15 characters (RTP transactions) or 10 characters (ACH transactions). Should represent why the money is moving, not your company name. For recommendations on setting the `description` field to avoid ACH returns, see [Description field recommendations](https://www.plaid.com/docs/transfer/creating-transfers/#description-field-recommendations).  If reprocessing a returned transfer, the `description` field must be `"Retry 1"` or `"Retry 2"`. You may retry a transfer up to 2 times, within 180 days of creating the original transfer. Only transfers that were returned with code `R01` or `R09` may be retried.
  --ach-class: any # DEPRECATED
  --user: record # The legal name and other information for the account holder. (DEPRECATED, nullable) — shape: {legal_name?: string, phone_number?: string, email_address?: string, address?: record}
  --metadata: record # The Metadata object is a mapping of client-provided string fields to any string value. The following limitations apply: The JSON values must be Strings (no nested JSON objects allowed) Only ASCII characters may be used Maximum of 50 key/value pairs Maximum key length of 40 characters Maximum value length of 500 characters  (nullable)
  --origination-account-id: string # Plaid's unique identifier for the origination account for this transfer. If you have more than one origination account, this value must be specified. Otherwise, this field should be left blank. (DEPRECATED, nullable)
  --iso-currency-code: string # The currency of the transfer amount. The default value is "USD". (DEPRECATED)
  --test-clock-id: string # Plaid's unique identifier for a test clock. This field may only be used when using `sandbox` environment. If provided, the `transfer` is created at the `virtual_time` on the provided `test_clock`. (nullable)
  --facilitator-fee: string # The amount to deduct from `transfer.amount` and distribute to the platform's Ledger balance as a facilitator fee (decimal string with two digits of precision e.g. "10.00"). The remainder will go to the end-customer's Ledger balance. This must be value greater than 0 and less than or equal to the `transfer.amount`.
]: any -> record<transfer: record<id: string, authorization_id: string, ach_class: string, account_id: string, funding_account_id: string, ledger_id: string, type: string, user: record<legal_name: string, phone_number: string, email_address: string, address: record>, amount: string, description: string, created: string, status: string, sweep_status: string, network: string, wire_details: record<message_to_beneficiary: string, wire_return_fee: string>, cancellable: bool, failure_reason: record<failure_code: string, ach_return_code: string, description: string>, metadata: record, origination_account_id: string, guarantee_decision: string, guarantee_decision_rationale: record<code: string, description: string>, iso_currency_code: string, standard_return_window: string, unauthorized_return_window: string, expected_settlement_date: string, expected_funds_available_date: string, originator_client_id: string, refunds: list<record>, recurring_transfer_id: string, expected_sweep_settlement_schedule: list<record>, credit_funds_source: record, facilitator_fee: string, network_trace_id: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/create")
  let body = {client_id: $client_id, secret: $secret, idempotency_key: $idempotency_key, access_token: $access_token, account_id: $account_id, authorization_id: $authorization_id, type: $type, network: $network, amount: $amount, description: $description, ach_class: $ach_class, user: $user, metadata: $metadata, origination_account_id: $origination_account_id, iso_currency_code: $iso_currency_code, test_clock_id: $test_clock_id, facilitator_fee: $facilitator_fee} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a recurring transfer
#
# POST /transfer/recurring/create
# Docs: /api/products/transfer/recurring-transfers/#transferrecurringcreate
# operationId: transferRecurringCreate
# --schedule shape: {interval_unit: "week"|"month", interval_count: int, interval_execution_day: int, start_date: string, end_date?: string}
# --user shape: {legal_name: string, phone_number?: string, email_address?: string, address?: record}
# --device shape: {ip_address: string, user_agent: string}
@deprecated --flag funding-account-id
@deprecated --flag iso-currency-code
export def "transfer-recurring-create transferRecurringCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The Plaid `access_token` for the account that will be debited or credited.
  idempotency_key: string # A random key provided by the client, per unique recurring transfer. Maximum of 50 characters.  The API supports idempotency for safely retrying requests without accidentally performing the same operation twice. For example, if a request to create a recurring fails due to a network connection error, you can retry the request with the same idempotency key to guarantee that only a single recurring transfer is created.
  account_id: string # The Plaid `account_id` corresponding to the end-user account that will be debited or credited.
  --funding-account-id: string # Specify the account used to fund the transfer. Customers can find a list of `funding_account_id`s in the Accounts page of your Plaid Dashboard, under the "Account ID" column. If this field is left blank, it will default to the default `funding_account_id` specified during onboarding. (DEPRECATED, nullable)
  type: string@type-completer-1 # The type of transfer. This will be either `debit` or `credit`.  A `debit` indicates a transfer of money into the origination account; a `credit` indicates a transfer of money out of the origination account.
  network: string@network-completer-3 # Networks eligible for recurring transfers.
  --ach-class: string@ach-class-completer # Specifies the use case of the transfer. Required for transfers on an ACH network. For more details, see [ACH SEC codes](https://plaid.com/docs/transfer/creating-transfers/#ach-sec-codes).  Codes supported for credits: `ccd`, `ppd` Codes supported for debits: `ccd`, `tel`, `web`  `"ccd"` - Corporate Credit or Debit - fund transfer between two corporate bank accounts  `"ppd"` - Prearranged Payment or Deposit - The transfer is part of a pre-existing relationship with a consumer. Authorization was obtained in writing either in person or via an electronic document signing, e.g. Docusign, by the consumer. Can be used for credits or debits.  `"web"` - Internet-Initiated Entry. The transfer debits a consumer's bank account. Authorization from the consumer is obtained over the Internet (e.g. a web or mobile application). Can be used for single debits or recurring debits.  `"tel"` - Telephone-Initiated Entry. The transfer debits a consumer. Debit authorization has been received orally over the telephone via a recorded call.
  amount: string # The amount of the transfer (decimal string with two digits of precision e.g. "10.00"). When calling `/transfer/authorization/create`, specify the maximum amount to authorize. When calling `/transfer/create`, specify the exact amount of the transfer, up to a maximum of the amount authorized. If this field is left blank when calling `/transfer/create`, the maximum amount authorized in the `authorization_id` will be sent.
  --user-present: string@bool-completer # If the end user is initiating the specific transfer themselves via an interactive UI, this should be `true`; for automatic recurring payments where the end user is not actually initiating each individual transfer, it should be `false`. (nullable)
  --iso-currency-code: string # The currency of the transfer amount. The default value is "USD". (DEPRECATED)
  description: string # The description of the recurring transfer.
  --test-clock-id: string # Plaid's unique identifier for a test clock. This field may only be used when using the `sandbox` environment. If provided, the created `recurring_transfer` is associated with the `test_clock`. New originations are automatically generated when the associated `test_clock` advances. For more details, see [Simulating recurring transfers](https://plaid.com/docs/transfer/sandbox/#simulating-recurring-transfers). (nullable)
  schedule: record # The schedule that the recurring transfer will be executed on. — shape: {interval_unit: "week"|"month", interval_count: int, interval_execution_day: int, start_date: string, end_date?: string}
  user: record # The legal name and other information for the account holder. — shape: {legal_name: string, phone_number?: string, email_address?: string, address?: record}
  --device: record # Information about the device being used to initiate the authorization. — shape: {ip_address: string, user_agent: string}
]: any -> record<recurring_transfer: record, decision: string, decision_rationale: record<code: string, description: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/recurring/create")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, idempotency_key: $idempotency_key, account_id: $account_id, funding_account_id: $funding_account_id, type: $type, network: $network, ach_class: $ach_class, amount: $amount, user_present: $user_present, iso_currency_code: $iso_currency_code, description: $description, test_clock_id: $test_clock_id, schedule: $schedule, user: $user, device: $device} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a bank transfer
#
# POST /bank_transfer/create
# Docs: /bank-transfers/reference#bank_transfercreate
# operationId: bankTransferCreate
# --user shape: {legal_name: string, email_address?: string}
export def "bank-transfer-create bankTransferCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  idempotency_key: string # A random key provided by the client, per unique bank transfer. Maximum of 50 characters.  The API supports idempotency for safely retrying requests without accidentally performing the same operation twice. For example, if a request to create a bank transfer fails due to a network connection error, you can retry the request with the same idempotency key to guarantee that only a single bank transfer is created.
  access_token: string # The Plaid `access_token` for the account that will be debited or credited.
  account_id: string # The Plaid `account_id` for the account that will be debited or credited.
  type: string@type-completer-1 # The type of bank transfer. This will be either `debit` or `credit`.  A `debit` indicates a transfer of money into the origination account; a `credit` indicates a transfer of money out of the origination account.
  network: string@network-completer # The network or rails used for the transfer. Valid options are `ach`, `same-day-ach`, or `wire`.
  amount: string # The amount of the bank transfer (decimal string with two digits of precision e.g. "10.00").
  iso_currency_code: string # The currency of the transfer amount - should be set to "USD".
  description: string # The transfer description. Maximum of 10 characters.
  --ach-class: string@ach-class-completer # Specifies the use case of the transfer. Required for transfers on an ACH network. For more details, see [ACH SEC codes](https://plaid.com/docs/transfer/creating-transfers/#ach-sec-codes).  Codes supported for credits: `ccd`, `ppd` Codes supported for debits: `ccd`, `tel`, `web`  `"ccd"` - Corporate Credit or Debit - fund transfer between two corporate bank accounts  `"ppd"` - Prearranged Payment or Deposit - The transfer is part of a pre-existing relationship with a consumer. Authorization was obtained in writing either in person or via an electronic document signing, e.g. Docusign, by the consumer. Can be used for credits or debits.  `"web"` - Internet-Initiated Entry. The transfer debits a consumer's bank account. Authorization from the consumer is obtained over the Internet (e.g. a web or mobile application). Can be used for single debits or recurring debits.  `"tel"` - Telephone-Initiated Entry. The transfer debits a consumer. Debit authorization has been received orally over the telephone via a recorded call.
  user: record # The legal name and other information for the account holder. — shape: {legal_name: string, email_address?: string}
  --custom-tag: string # An arbitrary string provided by the client for storage with the bank transfer. May be up to 100 characters. (nullable)
  --metadata: record # The Metadata object is a mapping of client-provided string fields to any string value. The following limitations apply: The JSON values must be Strings (no nested JSON objects allowed) Only ASCII characters may be used Maximum of 50 key/value pairs Maximum key length of 40 characters Maximum value length of 500 characters  (nullable)
  --origination-account-id: string # Plaid's unique identifier for the origination account for this transfer. If you have more than one origination account, this value must be specified. Otherwise, this field should be left blank. (nullable)
]: any -> record<bank_transfer: record<id: string, ach_class: string, account_id: string, type: string, user: record<legal_name: string, email_address: string, routing_number: string>, amount: string, iso_currency_code: string, description: string, created: string, status: string, network: string, cancellable: bool, failure_reason: record<ach_return_code: string, description: string>, custom_tag: string, metadata: record, origination_account_id: string, direction: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank_transfer/create")
  let body = {client_id: $client_id, secret: $secret, idempotency_key: $idempotency_key, access_token: $access_token, account_id: $account_id, type: $type, network: $network, amount: $amount, iso_currency_code: $iso_currency_code, description: $description, ach_class: $ach_class, user: $user, custom_tag: $custom_tag, metadata: $metadata, origination_account_id: $origination_account_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List transfers
#
# POST /transfer/list
# Docs: /api/products/transfer/reading-transfers/#transferlist
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --start-date: string # The start `created` datetime of transfers to list. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
  --end-date: string # The end `created` datetime of transfers to list. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
  --count: int # The maximum number of transfers to return. (default: 25)
  --offset: int # The number of transfers to skip before returning results. (default: 0)
  --origination-account-id: string # Filter transfers to only those originated through the specified origination account. (DEPRECATED, nullable)
  --originator-client-id: string # Filter transfers to only those with the specified originator client. (nullable)
  --funding-account-id: string # Filter transfers to only those with the specified `funding_account_id`. (nullable)
]: any -> record<transfers: table<id: string, authorization_id: string, ach_class: string, account_id: string, funding_account_id: string, ledger_id: string, type: string, user: record, amount: string, description: string, created: string, status: string, sweep_status: string, network: string, wire_details: record, cancellable: bool, failure_reason: record, metadata: record, origination_account_id: string, guarantee_decision: string, guarantee_decision_rationale: record, iso_currency_code: string, standard_return_window: string, unauthorized_return_window: string, expected_settlement_date: string, expected_funds_available_date: string, originator_client_id: string, refunds: list, recurring_transfer_id: string, expected_sweep_settlement_schedule: list, credit_funds_source: record, facilitator_fee: string, network_trace_id: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/list")
  let body = {client_id: $client_id, secret: $secret, start_date: $start_date, end_date: $end_date, count: $count, offset: $offset, origination_account_id: $origination_account_id, originator_client_id: $originator_client_id, funding_account_id: $funding_account_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List recurring transfers
#
# POST /transfer/recurring/list
# Docs: /api/products/transfer/recurring-transfers/#transferrecurringlist
# operationId: transferRecurringList
export def "transfer-recurring-list transferRecurringList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --start-time: string # The start `created` datetime of recurring transfers to list. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
  --end-time: string # The end `created` datetime of recurring transfers to list. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
  --count: int # The maximum number of recurring transfers to return. (default: 25)
  --offset: int # The number of recurring transfers to skip before returning results. (default: 0)
  --funding-account-id: string # Filter recurring transfers to only those with the specified `funding_account_id`. (nullable)
]: any -> record<recurring_transfers: table<recurring_transfer_id: string, created: string, next_origination_date: string, test_clock_id: string, type: string, amount: string, status: string, ach_class: string, network: string, origination_account_id: string, account_id: string, funding_account_id: string, iso_currency_code: string, description: string, transfer_ids: list, user: record, schedule: record>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/recurring/list")
  let body = {client_id: $client_id, secret: $secret, start_time: $start_time, end_time: $end_time, count: $count, offset: $offset, funding_account_id: $funding_account_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --start-date: string # The start datetime of bank transfers to list. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
  --end-date: string # The end datetime of bank transfers to list. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
  --count: int # The maximum number of bank transfers to return. (default: 25)
  --offset: int # The number of bank transfers to skip before returning results. (default: 0)
  --origination-account-id: string # Filter bank transfers to only those originated through the specified origination account. (nullable)
  --direction: string@direction-completer # Indicates the direction of the transfer: `outbound` for API-initiated transfers, or `inbound` for payments received by the FBO account. (nullable)
]: any -> record<bank_transfers: table<id: string, ach_class: string, account_id: string, type: string, user: record, amount: string, iso_currency_code: string, description: string, created: string, status: string, network: string, cancellable: bool, failure_reason: record, custom_tag: string, metadata: record, origination_account_id: string, direction: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank_transfer/list")
  let body = {client_id: $client_id, secret: $secret, start_date: $start_date, end_date: $end_date, count: $count, offset: $offset, origination_account_id: $origination_account_id, direction: $direction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel a transfer
#
# POST /transfer/cancel
# Docs: /api/products/transfer/initiating-transfers/#transfercancel
# operationId: transferCancel
@deprecated --flag originator-client-id
export def "transfer-cancel transferCancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  transfer_id: string # Plaid's unique identifier for a transfer.
  --originator-client-id: string # The Plaid client ID of the transfer originator. Should only be present if `client_id` is a third-party sender (TPS). (DEPRECATED, nullable)
  --reason-code: string@reason-code-completer-1 # Specifies the reason for cancelling transfer. This is required for RfP transfers, and will be ignored for other networks.  `"AC03"` - Invalid Creditor Account Number  `"AM09"` - Incorrect Amount  `"CUST"` - Requested By Customer - Cancellation requested  `"DUPL"` - Duplicate Payment  `"FRAD"` - Fraudulent Payment - Unauthorized or fraudulently induced  `"TECH"` - Technical Problem - Cancellation due to system issues  `"UPAY"` - Undue Payment - Payment was made through another channel  `"AC14"` - Invalid or Missing Creditor Account Type  `"AM06"` - Amount Too Low  `"BE05"` - Unrecognized Initiating Party  `"FOCR"` - Following Refund Request  `"MS02"` - No Specified Reason - Customer  `"MS03"` - No Specified Reason - Agent  `"RR04"` - Regulatory Reason  `"RUTA"` - Return Upon Unable To Apply
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/cancel")
  let body = {client_id: $client_id, secret: $secret, transfer_id: $transfer_id, originator_client_id: $originator_client_id, reason_code: $reason_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel a recurring transfer.
#
# POST /transfer/recurring/cancel
# Docs: /api/products/transfer/recurring-transfers/#transferrecurringcancel
# operationId: transferRecurringCancel
export def "transfer-recurring-cancel transferRecurringCancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  recurring_transfer_id: string # Plaid's unique identifier for a recurring transfer.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/recurring/cancel")
  let body = {client_id: $client_id, secret: $secret, recurring_transfer_id: $recurring_transfer_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  bank_transfer_id: string # Plaid's unique identifier for a bank transfer.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank_transfer/cancel")
  let body = {client_id: $client_id, secret: $secret, bank_transfer_id: $bank_transfer_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List transfer events
#
# POST /transfer/event/list
# Docs: /api/products/transfer/reading-transfers/#transfereventlist
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --start-date: string # The start `created` datetime of transfers to list. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
  --end-date: string # The end `created` datetime of transfers to list. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
  --transfer-id: string # Plaid's unique identifier for a transfer. (nullable)
  --account-id: string # The account ID to get events for all transactions to/from an account. (nullable)
  --transfer-type: string@transfer-type-completer # The type of transfer. This will be either `debit` or `credit`.  A `debit` indicates a transfer of money into your origination account; a `credit` indicates a transfer of money out of your origination account. (nullable)
  --event-types: list # Filter events by event type.
  --sweep-id: string # Plaid's unique identifier for a sweep.
  --count: int # The maximum number of transfer events to return. If the number of events matching the above parameters is greater than `count`, the most recent events will be returned. (nullable, default: 25)
  --offset: int # The offset into the list of transfer events. When `count`=25 and `offset`=0, the first 25 events will be returned. When `count`=25 and `offset`=25, the next 25 events will be returned. (nullable, default: 0)
  --origination-account-id: string # The origination account ID to get events for transfers from a specific origination account. (DEPRECATED, nullable)
  --originator-client-id: string # Filter transfer events to only those with the specified originator client. (nullable)
  --funding-account-id: string # Filter transfer events to only those with the specified `funding_account_id`. (nullable)
]: any -> record<transfer_events: table<event_id: int, timestamp: string, event_type: string, account_id: string, funding_account_id: string, ledger_id: string, transfer_id: string, origination_account_id: string, transfer_type: string, transfer_amount: string, failure_reason: record, sweep_id: string, sweep_amount: string, refund_id: string, originator_client_id: string, intent_id: string, wire_return_fee: string>, has_more: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/event/list")
  let body = {client_id: $client_id, secret: $secret, start_date: $start_date, end_date: $end_date, transfer_id: $transfer_id, account_id: $account_id, transfer_type: $transfer_type, event_types: $event_types, sweep_id: $sweep_id, count: $count, offset: $offset, origination_account_id: $origination_account_id, originator_client_id: $originator_client_id, funding_account_id: $funding_account_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List transfer ledger events
#
# POST /transfer/ledger/event/list
# Docs: /api/products/transfer/ledger/#transferledgereventlist
# operationId: transferLedgerEventList
export def "transfer-ledger-event-list transferLedgerEventList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --originator-client-id: string # Filter transfer events to only those with the specified originator client. (This field is specifically for resellers. Caller's client ID will be used if this field is not specified.) (nullable)
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --start-date: string # The start created datetime of transfers to list. This should be in RFC 3339 format (i.e. 2019-12-06T22:35:49Z) (nullable, format: date-time)
  --end-date: string # The end created datetime of transfers to list. This should be in RFC 3339 format (i.e. 2019-12-06T22:35:49Z) (nullable, format: date-time)
  --ledger-id: string # Plaid's unique identifier for a Plaid Ledger Balance. (nullable)
  --ledger-event-id: string # Plaid's unique identifier for the ledger event. (nullable)
  --source-type: string@source-type-completer # Source of the ledger event.  `"TRANSFER"` - The source of the ledger event is a transfer `"SWEEP"` - The source of the ledger event is a sweep `"REFUND"` - The source of the ledger event is a refund (nullable)
  --source-id: string # Plaid's unique identifier for a transfer, sweep, or refund. (nullable)
  --count: int # The maximum number of transfer events to return. If the number of events matching the above parameters is greater than `count`, the most recent events will be returned. (nullable, default: 25)
  --offset: int # The offset into the list of transfer events. When `count`=25 and `offset`=0, the first 25 events will be returned. When `count`=25 and `offset`=25, the next 25 events will be returned. (nullable, default: 0)
]: any -> record<ledger_events: table<ledger_event_id: string, ledger_id: string, amount: string, transfer_id: string, refund_id: string, sweep_id: string, description: string, pending_balance: string, available_balance: string, type: string, timestamp: string>, has_more: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/ledger/event/list")
  let body = {client_id: $client_id, originator_client_id: $originator_client_id, secret: $secret, start_date: $start_date, end_date: $end_date, ledger_id: $ledger_id, ledger_event_id: $ledger_event_id, source_type: $source_type, source_id: $source_id, count: $count, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --start-date: string # The start datetime of bank transfers to list. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
  --end-date: string # The end datetime of bank transfers to list. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
  --bank-transfer-id: string # Plaid's unique identifier for a bank transfer. (nullable)
  --account-id: string # The account ID to get events for all transactions to/from an account. (nullable)
  --bank-transfer-type: string@bank-transfer-type-completer # The type of bank transfer. This will be either `debit` or `credit`.  A `debit` indicates a transfer of money into your origination account; a `credit` indicates a transfer of money out of your origination account. (nullable)
  --event-types: list # Filter events by event type.
  --count: int # The maximum number of bank transfer events to return. If the number of events matching the above parameters is greater than `count`, the most recent events will be returned. (nullable, default: 25)
  --offset: int # The offset into the list of bank transfer events. When `count`=25 and `offset`=0, the first 25 events will be returned. When `count`=25 and `offset`=25, the next 25 bank transfer events will be returned. (nullable, default: 0)
  --origination-account-id: string # The origination account ID to get events for transfers from a specific origination account. (nullable)
  --direction: string@direction-completer # Indicates the direction of the transfer: `outbound`: for API-initiated transfers `inbound`: for payments received by the FBO account. (nullable)
]: any -> record<bank_transfer_events: table<event_id: int, timestamp: string, event_type: string, account_id: string, bank_transfer_id: string, origination_account_id: string, bank_transfer_type: string, bank_transfer_amount: string, bank_transfer_iso_currency_code: string, failure_reason: record, direction: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank_transfer/event/list")
  let body = {client_id: $client_id, secret: $secret, start_date: $start_date, end_date: $end_date, bank_transfer_id: $bank_transfer_id, account_id: $account_id, bank_transfer_type: $bank_transfer_type, event_types: $event_types, count: $count, offset: $offset, origination_account_id: $origination_account_id, direction: $direction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Sync transfer events
#
# POST /transfer/event/sync
# Docs: /api/products/transfer/reading-transfers/#transfereventsync
# operationId: transferEventSync
export def "transfer-event-sync transferEventSync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  after_id: int # The latest (largest) `event_id` fetched via the sync endpoint, or 0 initially.
  --count: int # The maximum number of transfer events to return. (nullable, default: 100)
]: any -> record<transfer_events: table<event_id: int, timestamp: string, event_type: string, account_id: string, funding_account_id: string, ledger_id: string, transfer_id: string, origination_account_id: string, transfer_type: string, transfer_amount: string, failure_reason: record, sweep_id: string, sweep_amount: string, refund_id: string, originator_client_id: string, intent_id: string, wire_return_fee: string>, has_more: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/event/sync")
  let body = {client_id: $client_id, secret: $secret, after_id: $after_id, count: $count} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  after_id: int # The latest (largest) `event_id` fetched via the sync endpoint, or 0 initially.
  --count: int # The maximum number of bank transfer events to return. (nullable, default: 25)
]: any -> record<bank_transfer_events: table<event_id: int, timestamp: string, event_type: string, account_id: string, bank_transfer_id: string, origination_account_id: string, bank_transfer_type: string, bank_transfer_amount: string, bank_transfer_iso_currency_code: string, failure_reason: record, direction: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank_transfer/event/sync")
  let body = {client_id: $client_id, secret: $secret, after_id: $after_id, count: $count} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a sweep
#
# POST /transfer/sweep/get
# Docs: /api/products/transfer/reading-transfers/#transfersweepget
# operationId: transferSweepGet
export def "transfer-sweep-get transferSweepGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  sweep_id: string # Plaid's unique identifier for the sweep (UUID) or a shortened form consisting of the first 8 characters of the identifier (8-digit hexadecimal string).
]: any -> record<sweep: record<id: string, funding_account_id: string, ledger_id: string, created: string, amount: string, iso_currency_code: string, settled: string, expected_funds_available_date: string, status: string, trigger: string, description: string, network_trace_id: string, failure_reason: record<failure_code: string, description: string>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/sweep/get")
  let body = {client_id: $client_id, secret: $secret, sweep_id: $sweep_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  sweep_id: string # Identifier of the sweep.
]: any -> record<sweep: record<id: string, created_at: string, amount: string, iso_currency_code: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank_transfer/sweep/get")
  let body = {client_id: $client_id, secret: $secret, sweep_id: $sweep_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List sweeps
#
# POST /transfer/sweep/list
# Docs: /api/products/transfer/reading-transfers/#transfersweeplist
# operationId: transferSweepList
export def "transfer-sweep-list transferSweepList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --start-date: string # The start `created` datetime of sweeps to return (RFC 3339 format). (nullable, format: date-time)
  --end-date: string # The end `created` datetime of sweeps to return (RFC 3339 format). (nullable, format: date-time)
  --count: int # The maximum number of sweeps to return. (nullable, default: 25)
  --offset: int # The number of sweeps to skip before returning results. (default: 0)
  --amount: string # Filter sweeps to only those with the specified amount. (nullable)
  --status: string@status-completer-1 # The status of a sweep transfer  `"pending"` - The sweep is currently pending `"posted"` - The sweep has been posted `"settled"` - The sweep has settled. This is the terminal state of a successful credit sweep. `"returned"` - The sweep has been returned. This is the terminal state of a returned sweep. Returns of a sweep are extremely rare, since sweeps are money movement between your own bank account and your own Ledger. `"funds_available"` - Funds from the sweep have been released from hold and applied to the ledger's available balance. (Only applicable to deposits.) This is the terminal state of a successful deposit sweep. `"failed"` - The sweep has failed. This is the terminal state of a failed sweep. (nullable)
  --originator-client-id: string # Filter sweeps to only those with the specified originator client. (nullable)
  --funding-account-id: string # Filter sweeps to only those with the specified `funding_account_id`. (nullable)
  --transfer-id: string # Filter sweeps to only those with the included `transfer_id`. (nullable)
  --trigger: string@trigger-completer # The trigger of the sweep  `"manual"` - The sweep is created manually by the customer `"incoming"` - The sweep is created by incoming funds flow (e.g. Incoming Wire) `"balance_threshold"` - The sweep is created by balance threshold setting `"automatic_aggregate"` - The sweep is created by the Plaid automatic aggregation process. These funds did not pass through the Plaid Ledger balance. (nullable)
]: any -> record<sweeps: table<id: string, funding_account_id: string, ledger_id: string, created: string, amount: string, iso_currency_code: string, settled: string, expected_funds_available_date: string, status: string, trigger: string, description: string, network_trace_id: string, failure_reason: record>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/sweep/list")
  let body = {client_id: $client_id, secret: $secret, start_date: $start_date, end_date: $end_date, count: $count, offset: $offset, amount: $amount, status: $status, originator_client_id: $originator_client_id, funding_account_id: $funding_account_id, transfer_id: $transfer_id, trigger: $trigger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --origination-account-id: string # If multiple origination accounts are available, `origination_account_id` must be used to specify the account that the sweeps belong to. (nullable)
  --start-time: string # The start `created` datetime of sweeps to return (RFC 3339 format). (nullable, format: date-time)
  --end-time: string # The end `created` datetime of sweeps to return (RFC 3339 format). (nullable, format: date-time)
  --count: int # The maximum number of sweeps to return. (nullable, default: 25)
]: any -> record<sweeps: table<id: string, created_at: string, amount: string, iso_currency_code: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank_transfer/sweep/list")
  let body = {client_id: $client_id, secret: $secret, origination_account_id: $origination_account_id, start_time: $start_time, end_time: $end_time, count: $count} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --origination-account-id: string # If multiple origination accounts are available, `origination_account_id` must be used to specify the account for which balance will be returned. (nullable)
]: any -> record<balance: record<available: string, transactable: string>, origination_account_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank_transfer/balance/get")
  let body = {client_id: $client_id, secret: $secret, origination_account_id: $origination_account_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  account_number: string # The user's account number.
  routing_number: string # The user's routing number.
  --wire-routing-number: string # The user's wire transfer routing number. This is the ABA number; for some institutions, this may differ from the ACH number used in `routing_number`.
  account_type: string # The type of the bank account (`checking` or `savings`).
]: any -> record<access_token: string, account_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bank_transfer/migrate_account")
  let body = {client_id: $client_id, secret: $secret, account_number: $account_number, routing_number: $routing_number, wire_routing_number: $wire_routing_number, account_type: $account_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Migrate account into Transfers
#
# POST /transfer/migrate_account
# Docs: /api/products/transfer/account-linking/#transfermigrate_account
# operationId: transferMigrateAccount
export def "transfer-migrate-account transferMigrateAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  account_number: string # The user's account number.
  routing_number: string # The user's routing number.
  --wire-routing-number: string # The user's wire transfer routing number. This is the ABA number; for some institutions, this may differ from the ACH number used in `routing_number`. This field must be set for the created item to be eligible for wire transfers.
  account_type: string # The type of the bank account (`checking` or `savings`).
]: any -> record<access_token: string, account_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/migrate_account")
  let body = {client_id: $client_id, secret: $secret, account_number: $account_number, routing_number: $routing_number, wire_routing_number: $wire_routing_number, account_type: $account_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a transfer intent object to invoke the Transfer UI
#
# POST /transfer/intent/create
# Docs: /api/products/transfer/account-linking/#transferintentcreate
# operationId: transferIntentCreate
# --user shape: {legal_name: string, phone_number?: string, email_address?: string, address?: record}
@deprecated --flag origination-account-id
export def "transfer-intent-create transferIntentCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --account-id: string # The Plaid `account_id` corresponding to the end-user account that will be debited or credited. (nullable)
  --funding-account-id: string # Specify the account used to fund the transfer. Should be specified if using legacy funding methods only. If using Plaid Ledger, leave this field blank. Customers can find a list of `funding_account_id`s in the Accounts page of your Plaid Dashboard, under the "Account ID" column. If this field is left blank and you are using legacy funding methods, this will default to the default `funding_account_id` specified during onboarding. Otherwise, Plaid Ledger will be used. (nullable)
  mode: string@mode-completer # The direction of the flow of transfer funds.  `PAYMENT`: Transfers funds from an end user's account to your business account.  `DISBURSEMENT`: Transfers funds from your business account to an end user's account.
  --network: string@network-completer-3 # The network or rails used for the transfer. Defaults to `same-day-ach`.  For transfers submitted using `ach`, the Standard ACH cutoff is 8:30 PM Eastern Time.  For transfers submitted using `same-day-ach`, the Same Day ACH cutoff is 3:00 PM Eastern Time. It is recommended to send the request 15 minutes prior to the cutoff to ensure that it will be processed in time for submission before the cutoff. If the transfer is processed after this cutoff but before the Standard ACH cutoff, it will be sent over Standard ACH rails and will not incur same-day charges.  For transfers submitted using `rtp`, in the case that the account being credited does not support RTP, the transfer will be sent over ACH as long as an `ach_class` is provided in the request. If RTP isn't supported by the account and no `ach_class` is provided, the transfer will fail to be submitted. (default: same-day-ach)
  amount: string # The amount of the transfer (decimal string with two digits of precision e.g. "10.00"). When calling `/transfer/authorization/create`, specify the maximum amount to authorize. When calling `/transfer/create`, specify the exact amount of the transfer, up to a maximum of the amount authorized. If this field is left blank when calling `/transfer/create`, the maximum amount authorized in the `authorization_id` will be sent.
  description: string # A description for the underlying transfer. Maximum of 15 characters.
  --ach-class: string@ach-class-completer # Specifies the use case of the transfer. Required for transfers on an ACH network. For more details, see [ACH SEC codes](https://plaid.com/docs/transfer/creating-transfers/#ach-sec-codes).  Codes supported for credits: `ccd`, `ppd` Codes supported for debits: `ccd`, `tel`, `web`  `"ccd"` - Corporate Credit or Debit - fund transfer between two corporate bank accounts  `"ppd"` - Prearranged Payment or Deposit - The transfer is part of a pre-existing relationship with a consumer. Authorization was obtained in writing either in person or via an electronic document signing, e.g. Docusign, by the consumer. Can be used for credits or debits.  `"web"` - Internet-Initiated Entry. The transfer debits a consumer's bank account. Authorization from the consumer is obtained over the Internet (e.g. a web or mobile application). Can be used for single debits or recurring debits.  `"tel"` - Telephone-Initiated Entry. The transfer debits a consumer. Debit authorization has been received orally over the telephone via a recorded call.
  --origination-account-id: string # Plaid's unique identifier for the origination account for the intent. If not provided, the default account will be used. (DEPRECATED, nullable)
  user: record # The legal name and other information for the account holder. — shape: {legal_name: string, phone_number?: string, email_address?: string, address?: record}
  --metadata: record # The Metadata object is a mapping of client-provided string fields to any string value. The following limitations apply: The JSON values must be Strings (no nested JSON objects allowed) Only ASCII characters may be used Maximum of 50 key/value pairs Maximum key length of 40 characters Maximum value length of 500 characters  (nullable)
  --iso-currency-code: string # The currency of the transfer amount, e.g. "USD"
  --require-guarantee: string@bool-completer # When `true`, the transfer requires a `GUARANTEED` decision by Plaid to proceed (Guarantee customers only). (nullable, default: false)
]: any -> record<transfer_intent: record<id: string, created: string, status: string, account_id: string, origination_account_id: string, funding_account_id: string, amount: string, mode: string, network: string, ach_class: string, user: record<legal_name: string, phone_number: string, email_address: string, address: record>, description: string, metadata: record, iso_currency_code: string, require_guarantee: bool>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/intent/create")
  let body = {client_id: $client_id, secret: $secret, account_id: $account_id, funding_account_id: $funding_account_id, mode: $mode, network: $network, amount: $amount, description: $description, ach_class: $ach_class, origination_account_id: $origination_account_id, user: $user, metadata: $metadata, iso_currency_code: $iso_currency_code, require_guarantee: $require_guarantee} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve more information about a transfer intent
#
# POST /transfer/intent/get
# Docs: /api/products/transfer/account-linking/#transferintentget
# operationId: transferIntentGet
export def "transfer-intent-get transferIntentGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  transfer_intent_id: string # Plaid's unique identifier for a transfer intent object.
]: any -> record<transfer_intent: record<id: string, created: string, status: string, transfer_id: string, failure_reason: record<error_type: string, error_code: string, error_message: string>, authorization_decision: string, authorization_decision_rationale: record<code: string, description: string>, account_id: string, origination_account_id: string, funding_account_id: string, amount: string, mode: string, network: string, ach_class: string, user: record<legal_name: string, phone_number: string, email_address: string, address: record>, description: string, metadata: record, iso_currency_code: string, require_guarantee: bool, guarantee_decision: string, guarantee_decision_rationale: record<code: string, description: string>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/intent/get")
  let body = {client_id: $client_id, secret: $secret, transfer_intent_id: $transfer_intent_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --start-date: string # The start `created` datetime of repayments to return (RFC 3339 format). (nullable, format: date-time)
  --end-date: string # The end `created` datetime of repayments to return (RFC 3339 format). (nullable, format: date-time)
  --count: int # The maximum number of repayments to return. (nullable, default: 25)
  --offset: int # The number of repayments to skip before returning results. (default: 0)
]: any -> record<repayments: table<repayment_id: string, created: string, amount: string, iso_currency_code: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/repayment/list")
  let body = {client_id: $client_id, secret: $secret, start_date: $start_date, end_date: $end_date, count: $count, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  repayment_id: string # Identifier of the repayment to query.
  --count: int # The maximum number of repayments to return. (nullable, default: 25)
  --offset: int # The number of repayments to skip before returning results. (default: 0)
]: any -> record<repayment_returns: table<transfer_id: string, event_id: int, amount: string, iso_currency_code: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/repayment/return/list")
  let body = {client_id: $client_id, secret: $secret, repayment_id: $repayment_id, count: $count, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Submit additional onboarding information on behalf of an originator
#
# POST /transfer/platform/requirement/submit
# Docs: /api/products/transfer/platform-payments/#transferplatformrequirementsubmit
# operationId: transferPlatformRequirementSubmit
# --requirement_submissions item shape: {requirement_type: string, value: string, person_id?: string}
export def "transfer-platform-requirement-submit transferPlatformRequirementSubmit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  originator_client_id: string # The client ID of the originator
  requirement_submissions: list # Use the `/transfer/platform/requirement/submit` endpoint to submit a list of requirement submissions that all relate to the originator. Must contain between 1 and 50 requirement submissions. See [Requirement type schema documentation](https://docs.google.com/document/d/1NEQkTD0sVK50iAQi6xHigrexDUxZ4QxXqSEfV_FFTiU/) for a list of requirements and possible values. — item shape: {requirement_type: string, value: string, person_id?: string}
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/platform/requirement/submit")
  let body = {client_id: $client_id, secret: $secret, originator_client_id: $originator_client_id, requirement_submissions: $requirement_submissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new originator
#
# POST /transfer/originator/create
# Docs: /api/products/transfer/platform-payments/#transferoriginatorcreate
# operationId: transferOriginatorCreate
export def "transfer-originator-create transferOriginatorCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  company_name: string # The company name of the end customer being created. This will be displayed in public-facing surfaces, e.g. Plaid Dashboard.
]: any -> record<originator_client_id: string, company_name: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/originator/create")
  let body = {client_id: $client_id, secret: $secret, company_name: $company_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a Plaid-hosted onboarding UI URL.
#
# POST /transfer/questionnaire/create
# Docs: /api/products/transfer/platform-payments/#transferquestionnairecreate
# operationId: transferQuestionnaireCreate
export def "transfer-questionnaire-create transferQuestionnaireCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  originator_client_id: string # Client ID of the end customer.
  redirect_uri: string # URL the end customer will be redirected to after completing questions in Plaid-hosted onboarding flow. (format: url)
]: any -> record<onboarding_url: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/questionnaire/create")
  let body = {client_id: $client_id, secret: $secret, originator_client_id: $originator_client_id, redirect_uri: $redirect_uri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Submit transfer diligence on behalf of the originator
#
# POST /transfer/diligence/submit
# Docs: /api/products/transfer/platform-payments/#transferdiligencesubmit
# operationId: transferDiligenceSubmit
# --originator_diligence shape: {dba: string, tax_id: string, credit_usage_configuration?: record, debit_usage_configuration?: record, address: record, website: string, naics_code: string, funding_account: record}
export def "transfer-diligence-submit transferDiligenceSubmit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  originator_client_id: string # Client ID of the originator whose diligence that you want to submit.
  originator_diligence: record # The diligence information for the originator. — shape: {dba: string, tax_id: string, credit_usage_configuration?: record, debit_usage_configuration?: record, address: record, website: string, naics_code: string, funding_account: record}
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/diligence/submit")
  let body = {client_id: $client_id, secret: $secret, originator_client_id: $originator_client_id, originator_diligence: $originator_diligence} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload transfer diligence document on behalf of the originator
#
# POST /transfer/diligence/document/upload
# Docs: /api/products/transfer/platform-payments/#transferdiligencedocumentupload
# operationId: transferDiligenceDocumentUpload
export def "transfer-diligence-document-upload transferDiligenceDocumentUpload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  originator_client_id: string # The Client ID of the originator whose document that you want to upload.
  file: string # A file to upload. The file size must be less than 20MB. Supported file extensions: .pdf. (format: binary)
  purpose: string@purpose-completer # Specifies the purpose of the uploaded file.  `"DUE_DILIGENCE"` - The transfer due diligence document of the originator.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/diligence/document/upload")
  let body = {originator_client_id: $originator_client_id, file: $file, purpose: $purpose} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get status of an originator's onboarding
#
# POST /transfer/originator/get
# Docs: /api/products/transfer/platform-payments/#transferoriginatorget
# operationId: transferOriginatorGet
export def "transfer-originator-get transferOriginatorGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  originator_client_id: string # Client ID of the end customer (i.e. the originator).
]: any -> record<originator: record<client_id: string, transfer_diligence_status: string, company_name: string, outstanding_requirements: list<record>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/originator/get")
  let body = {client_id: $client_id, secret: $secret, originator_client_id: $originator_client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get status of all originators' onboarding
#
# POST /transfer/originator/list
# Docs: /api/products/transfer/platform-payments/#transferoriginatorlist
# operationId: transferOriginatorList
export def "transfer-originator-list transferOriginatorList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --count: int # The maximum number of originators to return. (nullable, default: 25)
  --offset: int # The number of originators to skip before returning results. (nullable, default: 0)
]: any -> record<originators: table<client_id: string, transfer_diligence_status: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/originator/list")
  let body = {client_id: $client_id, secret: $secret, count: $count, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a refund
#
# POST /transfer/refund/create
# Docs: /api/products/transfer/refunds/#transferrefundcreate
# operationId: transferRefundCreate
export def "transfer-refund-create transferRefundCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  transfer_id: string # The ID of the transfer to refund.
  amount: string # The amount of the refund (decimal string with two digits of precision e.g. "10.00").
  idempotency_key: string # A random key provided by the client, per unique refund. Maximum of 50 characters.  The API supports idempotency for safely retrying requests without accidentally performing the same operation twice. For example, if a request to create a refund fails due to a network connection error, you can retry the request with the same idempotency key to guarantee that only a single refund is created.
]: any -> record<refund: record<id: string, transfer_id: string, amount: string, status: string, failure_reason: record<failure_code: string, ach_return_code: string, description: string>, ledger_id: string, created: string, network_trace_id: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/refund/create")
  let body = {client_id: $client_id, secret: $secret, transfer_id: $transfer_id, amount: $amount, idempotency_key: $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a refund
#
# POST /transfer/refund/get
# Docs: /api/products/transfer/refunds/#transferrefundget
# operationId: transferRefundGet
export def "transfer-refund-get transferRefundGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  refund_id: string # Plaid's unique identifier for a refund.
]: any -> record<refund: record<id: string, transfer_id: string, amount: string, status: string, failure_reason: record<failure_code: string, ach_return_code: string, description: string>, ledger_id: string, created: string, network_trace_id: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/refund/get")
  let body = {client_id: $client_id, secret: $secret, refund_id: $refund_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel a refund
#
# POST /transfer/refund/cancel
# Docs: /api/products/transfer/refunds/#transferrefundcancel
# operationId: transferRefundCancel
export def "transfer-refund-cancel transferRefundCancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  refund_id: string # Plaid's unique identifier for a refund.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/refund/cancel")
  let body = {client_id: $client_id, secret: $secret, refund_id: $refund_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an originator for Transfer for Platforms customers
#
# POST /transfer/platform/originator/create
# Docs: /api/products/transfer/platform-payments/#transferplatformoriginatorcreate
# operationId: transferPlatformOriginatorCreate
# --tos_acceptance_metadata shape: {agreement_accepted: bool, originator_ip_address: string, agreement_accepted_at: string}
export def "transfer-platform-originator-create transferPlatformOriginatorCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  originator_client_id: string # The client ID of the originator
  tos_acceptance_metadata: record # Metadata related to the acceptance of Terms of Service — shape: {agreement_accepted: bool, originator_ip_address: string, agreement_accepted_at: string}
  originator_reviewed_at: string # ISO8601 timestamp indicating the most recent time the platform collected onboarding data from the originator (format: date-time)
  --webhook: string # The webhook URL to which a `PLATFORM_ONBOARDING_UPDATE` webhook should be sent. (format: url)
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/platform/originator/create")
  let body = {client_id: $client_id, secret: $secret, originator_client_id: $originator_client_id, tos_acceptance_metadata: $tos_acceptance_metadata, originator_reviewed_at: $originator_reviewed_at, webhook: $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a person associated with an originator
#
# POST /transfer/platform/person/create
# Docs: /api/products/transfer/platform-payments/#transferplatformpersoncreate
# operationId: transferPlatformPersonCreate
# --name shape: {given_name: string, family_name: string}
# --address shape: {city: string, country: string, postal_code: string, region: string, street: string, street2?: string}
# --id_number shape: {value: string, type: "ar_dni"|"au_drivers_license"|"au_passport"|"br_cpf"|"ca_sin"|"cl_run"|"cn_resident_card"|"co_nit"|"dk_cpr"|"eg_national_id"|"es_dni"|"es_nie"|"hk_hkid"|"in_pan"|"it_cf"|"jo_civil_id"|"jp_my_number"|"ke_huduma_namba"|"kw_civil_id"|"mx_curp"|"mx_rfc"|"my_nric"|"ng_nin"|"nz_drivers_license"|"om_civil_id"|"ph_psn"|"pl_pesel"|"ro_cnp"|"sa_national_id"|"se_pin"|"sg_nric"|"tr_tc_kimlik"|"us_ssn"|"us_ssn_last_4"|"za_smart_id"}
export def "transfer-platform-person-create transferPlatformPersonCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  originator_client_id: string # The client ID of the originator
  --name: record # The person's legal name — shape: {given_name: string, family_name: string}
  --email-address: string # A valid email address. Must not have leading or trailing spaces. (e.g. user@example.com)
  --phone-number: string # A valid phone number in E.164 format. Phone number input may be validated against valid number ranges; number strings that do not match a real-world phone numbering scheme may cause the request to fail, even in the Sandbox test environment. (e.g. +12345678909)
  --address: record # Home address of a person — shape: {city: string, country: string, postal_code: string, region: string, street: string, street2?: string}
  --id-number: record # ID number of the person — shape: {value: string, type: "ar_dni"|"au_drivers_license"|"au_passport"|"br_cpf"|"ca_sin"|"cl_run"|"cn_resident_card"|"co_nit"|"dk_cpr"|"eg_national_id"|"es_dni"|"es_nie"|"hk_hkid"|"in_pan"|"it_cf"|"jo_civil_id"|"jp_my_number"|"ke_huduma_namba"|"kw_civil_id"|"mx_curp"|"mx_rfc"|"my_nric"|"ng_nin"|"nz_drivers_license"|"om_civil_id"|"ph_psn"|"pl_pesel"|"ro_cnp"|"sa_national_id"|"se_pin"|"sg_nric"|"tr_tc_kimlik"|"us_ssn"|"us_ssn_last_4"|"za_smart_id"}
  --date-of-birth: string # The date of birth of the person. Formatted as YYYY-MM-DD. (format: date)
  --relationship-to-originator: string # The relationship between this person and the originator they are related to.
  --ownership-percentage: int # The percentage of ownership this person has in the onboarding business. Only applicable to beneficial owners with 25% or more ownership.
  --title: string # The title of the person at the business. Only applicable to control persons - for example, "CEO", "President", "Owner", etc.
]: any -> record<request_id: string, person_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/platform/person/create")
  let body = {client_id: $client_id, secret: $secret, originator_client_id: $originator_client_id, name: $name, email_address: $email_address, phone_number: $phone_number, address: $address, id_number: $id_number, date_of_birth: $date_of_birth, relationship_to_originator: $relationship_to_originator, ownership_percentage: $ownership_percentage, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  bank_transfer_id: string # Plaid's unique identifier for a bank transfer.
  event_type: string # The asynchronous event to be simulated. May be: `posted`, `failed`, or `reversed`.  An error will be returned if the event type is incompatible with the current transfer status. Compatible status --> event type transitions include:  `pending` --> `failed`  `pending` --> `posted`  `posted` --> `reversed`
  --failure-reason: record # The failure reason if the type of this transfer is `"failed"` or `"reversed"`. Null value otherwise. (nullable) — shape: {ach_return_code?: string, description?: string}
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/bank_transfer/simulate")
  let body = {client_id: $client_id, secret: $secret, bank_transfer_id: $bank_transfer_id, event_type: $event_type, failure_reason: $failure_reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --test-clock-id: string # Plaid's unique identifier for a test clock. If provided, the sweep to be simulated is created on the day of the `virtual_time` on the `test_clock`. If the date of `virtual_time` is on weekend or a federal holiday, the next available banking day is used. (nullable)
  --webhook: string # The webhook URL to which a `TRANSFER_EVENTS_UPDATE` webhook should be sent. (format: url)
]: any -> record<sweep: record, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/transfer/sweep/simulate")
  let body = {client_id: $client_id, secret: $secret, test_clock_id: $test_clock_id, webhook: $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Simulate a transfer event in Sandbox
#
# POST /sandbox/transfer/simulate
# Docs: /api/sandbox/#sandboxtransfersimulate
# operationId: sandboxTransferSimulate
# --failure_reason shape: {failure_code?: string, ach_return_code?: string, description?: string}
export def "sandbox-transfer-simulate sandboxTransferSimulate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  transfer_id: string # Plaid's unique identifier for a transfer.
  --test-clock-id: string # Plaid's unique identifier for a test clock. If provided, the event to be simulated is created at the `virtual_time` on the provided `test_clock`. (nullable)
  event_type: string # The asynchronous event to be simulated. May be: `posted`, `settled`, `failed`, `funds_available`, or `returned`.  An error will be returned if the event type is incompatible with the current transfer status. Compatible status --> event type transitions include:  `pending` --> `failed`  `pending` --> `posted`  `posted` --> `returned`  `posted` --> `settled`  `settled` --> `funds_available` (only applicable to ACH debits.)
  --failure-reason: record # The failure reason if the event type for a transfer is `"failed"` or `"returned"`. Null value otherwise. (nullable) — shape: {failure_code?: string, ach_return_code?: string, description?: string}
  --webhook: string # The webhook URL to which a `TRANSFER_EVENTS_UPDATE` webhook should be sent. (format: url)
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/transfer/simulate")
  let body = {client_id: $client_id, secret: $secret, transfer_id: $transfer_id, test_clock_id: $test_clock_id, event_type: $event_type, failure_reason: $failure_reason, webhook: $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Simulate a refund event in Sandbox
#
# POST /sandbox/transfer/refund/simulate
# Docs: /api/sandbox/#sandboxtransferrefundsimulate
# operationId: sandboxTransferRefundSimulate
# --failure_reason shape: {failure_code?: string, ach_return_code?: string, description?: string}
export def "sandbox-transfer-refund-simulate sandboxTransferRefundSimulate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  refund_id: string # Plaid's unique identifier for a refund.
  --test-clock-id: string # Plaid's unique identifier for a test clock. If provided, the event to be simulated is created at the `virtual_time` on the provided `test_clock`. (nullable)
  event_type: string # The asynchronous event to be simulated. May be: `refund.posted`, `refund.settled`, `refund.failed`, or `refund.returned`.  An error will be returned if the event type is incompatible with the current refund status. Compatible status --> event type transitions include:  `refund.pending` --> `refund.failed`  `refund.pending` --> `refund.posted`  `refund.posted` --> `refund.returned`  `refund.posted` --> `refund.settled`  `refund.posted` events can only be simulated if the refunded transfer has been transitioned to settled. This mimics the ordering of events in Production.
  --failure-reason: record # The failure reason if the event type for a transfer is `"failed"` or `"returned"`. Null value otherwise. (nullable) — shape: {failure_code?: string, ach_return_code?: string, description?: string}
  --webhook: string # The webhook URL to which a `TRANSFER_EVENTS_UPDATE` webhook should be sent. (format: url)
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/transfer/refund/simulate")
  let body = {client_id: $client_id, secret: $secret, refund_id: $refund_id, test_clock_id: $test_clock_id, event_type: $event_type, failure_reason: $failure_reason, webhook: $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Simulate converting pending balance to available balance
#
# POST /sandbox/transfer/ledger/simulate_available
# Docs: /api/sandbox/#sandboxtransferledgersimulate_available
# operationId: sandboxTransferLedgerSimulateAvailable
export def "sandbox-transfer-ledger-simulate-available sandboxTransferLedgerSimulateAvailable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --ledger-id: string # Specify which ledger balance to simulate converting pending balance to available balance. If this field is left blank, this will default to id of the default ledger balance. (nullable)
  --originator-client-id: string # Client ID of the end customer (i.e. the originator). Only applicable to Transfer for Platforms customers. (nullable)
  --test-clock-id: string # Plaid's unique identifier for a test clock. If provided, only the pending balance that is due before the `virtual_time` on the test clock will be converted. (nullable)
  --webhook: string # The webhook URL to which a `TRANSFER_EVENTS_UPDATE` webhook should be sent. (format: url)
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/transfer/ledger/simulate_available")
  let body = {client_id: $client_id, secret: $secret, ledger_id: $ledger_id, originator_client_id: $originator_client_id, test_clock_id: $test_clock_id, webhook: $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Simulate a ledger deposit event in Sandbox
#
# POST /sandbox/transfer/ledger/deposit/simulate
# Docs: /api/sandbox/#sandboxtransferledgerdepositsimulate
# operationId: sandboxTransferLedgerDepositSimulate
# --failure_reason shape: {failure_code?: string, ach_return_code?: string, description?: string}
export def "sandbox-transfer-ledger-deposit-simulate sandboxTransferLedgerDepositSimulate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  sweep_id: string # Plaid's unique identifier for a sweep.
  event_type: string@event-type-completer # The asynchronous event to be simulated. May be: `posted`, `settled`, `failed`, or `returned`.  An error will be returned if the event type is incompatible with the current ledger sweep status. Compatible status --> event type transitions include:  `sweep.pending` --> `sweep.posted`  `sweep.pending` --> `sweep.failed`  `sweep.posted` --> `sweep.settled`  `sweep.posted` --> `sweep.returned`  `sweep.settled` --> `sweep.returned`
  --failure-reason: record # The failure reason if the event type for a transfer is `"failed"` or `"returned"`. Null value otherwise. (nullable) — shape: {failure_code?: string, ach_return_code?: string, description?: string}
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/transfer/ledger/deposit/simulate")
  let body = {client_id: $client_id, secret: $secret, sweep_id: $sweep_id, event_type: $event_type, failure_reason: $failure_reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Simulate a ledger withdraw event in Sandbox
#
# POST /sandbox/transfer/ledger/withdraw/simulate
# Docs: /api/sandbox/#sandboxtransferledgerwithdrawsimulate
# operationId: sandboxTransferLedgerWithdrawSimulate
# --failure_reason shape: {failure_code?: string, ach_return_code?: string, description?: string}
export def "sandbox-transfer-ledger-withdraw-simulate sandboxTransferLedgerWithdrawSimulate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  sweep_id: string # Plaid's unique identifier for a sweep.
  event_type: string@event-type-completer # The asynchronous event to be simulated. May be: `posted`, `settled`, `failed`, or `returned`.  An error will be returned if the event type is incompatible with the current ledger sweep status. Compatible status --> event type transitions include:  `sweep.pending` --> `sweep.posted`  `sweep.pending` --> `sweep.failed`  `sweep.posted` --> `sweep.settled`  `sweep.posted` --> `sweep.returned`  `sweep.settled` --> `sweep.returned`
  --failure-reason: record # The failure reason if the event type for a transfer is `"failed"` or `"returned"`. Null value otherwise. (nullable) — shape: {failure_code?: string, ach_return_code?: string, description?: string}
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/transfer/ledger/withdraw/simulate")
  let body = {client_id: $client_id, secret: $secret, sweep_id: $sweep_id, event_type: $event_type, failure_reason: $failure_reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/transfer/repayment/simulate")
  let body = {client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  webhook: string # The URL to which the webhook should be sent. (format: url)
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/transfer/fire_webhook")
  let body = {client_id: $client_id, secret: $secret, webhook: $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --virtual-time: string # The virtual timestamp on the test clock. If not provided, the current timestamp will be used. This will be of the form `2006-01-02T15:04:05Z`. (nullable, format: date-time)
]: any -> record<test_clock: record<test_clock_id: string, virtual_time: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/transfer/test_clock/create")
  let body = {client_id: $client_id, secret: $secret, virtual_time: $virtual_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  test_clock_id: string # Plaid's unique identifier for a test clock. This field is only populated in the Sandbox environment, and only if a `test_clock_id` was included in the `/transfer/recurring/create` request. For more details, see [Simulating recurring transfers](https://plaid.com/docs/transfer/sandbox/#simulating-recurring-transfers).
  new_virtual_time: string # The virtual timestamp on the test clock. This will be of the form `2006-01-02T15:04:05Z`. (format: date-time)
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/transfer/test_clock/advance")
  let body = {client_id: $client_id, secret: $secret, test_clock_id: $test_clock_id, new_virtual_time: $new_virtual_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  test_clock_id: string # Plaid's unique identifier for a test clock. This field is only populated in the Sandbox environment, and only if a `test_clock_id` was included in the `/transfer/recurring/create` request. For more details, see [Simulating recurring transfers](https://plaid.com/docs/transfer/sandbox/#simulating-recurring-transfers).
]: any -> record<test_clock: record<test_clock_id: string, virtual_time: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/transfer/test_clock/get")
  let body = {client_id: $client_id, secret: $secret, test_clock_id: $test_clock_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --start-virtual-time: string # The start virtual timestamp of test clocks to return. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
  --end-virtual-time: string # The end virtual timestamp of test clocks to return. This should be in RFC 3339 format (i.e. `2019-12-06T22:35:49Z`) (nullable, format: date-time)
  --count: int # The maximum number of test clocks to return. (nullable, default: 25)
  --offset: int # The number of test clocks to skip before returning results. (default: 0)
]: any -> record<test_clocks: table<test_clock_id: string, virtual_time: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/transfer/test_clock/list")
  let body = {client_id: $client_id, secret: $secret, start_virtual_time: $start_virtual_time, end_virtual_time: $end_virtual_time, count: $count, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset the login of a Payment Profile
#
# POST /sandbox/payment_profile/reset_login
# DEPRECATED
# Docs: /api/sandbox/#sandboxpayment_profilereset_login
# operationId: sandboxPaymentProfileResetLogin
@deprecated
export def "sandbox-payment-profile-reset-login sandboxPaymentProfileResetLogin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  payment_profile_token: string # A payment profile token associated with the Payment Profile data that is being requested.
]: any -> record<reset_login: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/payment_profile/reset_login")
  let body = {client_id: $client_id, secret: $secret, payment_profile_token: $payment_profile_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Simulate a payment event in Sandbox
#
# POST /sandbox/payment/simulate
# Docs: /api/sandbox/#sandboxpaymentsimulate
# operationId: sandboxPaymentSimulate
export def "sandbox-payment-simulate sandboxPaymentSimulate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  payment_id: string # The ID of the payment to simulate
  webhook: string # The webhook url to use for any payment events triggered by the simulated status change.
  status: string # The status to set the payment to.  Valid statuses include: - `PAYMENT_STATUS_INITIATED` - `PAYMENT_STATUS_INSUFFICIENT_FUNDS` - `PAYMENT_STATUS_FAILED` - `PAYMENT_STATUS_EXECUTED` - `PAYMENT_STATUS_SETTLED` - `PAYMENT_STATUS_CANCELLED` - `PAYMENT_STATUS_REJECTED`
]: any -> record<request_id: string, old_status: string, new_status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/payment/simulate")
  let body = {client_id: $client_id, secret: $secret, payment_id: $payment_id, webhook: $webhook, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --body-query: string # The employer name to be searched for.
  products: list # The Plaid products the returned employers should support. Currently, this field must be set to `"deposit_switch"`.
]: any -> record<employers: table<employer_id: string, name: string, address: record, confidence_score: float>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/employers/search")
  let body = {client_id: $client_id, secret: $secret, query: $body_query, products: $products} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  webhook: string # The URL endpoint to which Plaid should send webhooks related to the progress of the income verification process.
  --precheck-id: string # The ID of a precheck created with `/income/verification/precheck`. Will be used to improve conversion of the income verification flow.
  --options: record # Optional arguments for `/income/verification/create` — shape: {access_tokens?: list}
]: any -> record<income_verification_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/income/verification/create")
  let body = {client_id: $client_id, secret: $secret, webhook: $webhook, precheck_id: $precheck_id, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --income-verification-id: string # The ID of the verification for which to get paystub information. (DEPRECATED, nullable)
  --access-token: string # The access token associated with the Item for which data is being requested. (nullable)
]: any -> record<document_metadata: table<name: string, status: string, doc_id: string, doc_type: string>, paystubs: table<deductions: record, doc_id: string, earnings: record, employee: record, employer: record, employment_details: record, net_pay: record, pay_period_details: record, paystub_details: record, income_breakdown: list, ytd_earnings: record>, error: record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list<any>, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list<string>, provided_account_subtypes: list<string>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/income/verification/paystubs/get")
  let body = {client_id: $client_id, secret: $secret, income_verification_id: $income_verification_id, access_token: $access_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --accept: string@accept-completer-1 # Response content type
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --income-verification-id: string # The ID of the verification. (DEPRECATED, nullable)
  --access-token: string # The access token associated with the Item for which data is being requested. (nullable)
  --document-id: string # The document ID to download. If passed, a single document will be returned in the resulting zip file, rather than all document (nullable)
]: any -> record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list<any>, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list<string>, provided_account_subtypes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/income/verification/documents/download")
  let body = {client_id: $client_id, secret: $secret, income_verification_id: $income_verification_id, access_token: $access_token, document_id: $document_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/zip")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --income-verification-id: string # The ID of the verification. (DEPRECATED, nullable)
  --access-token: string # The access token associated with the Item for which data is being requested. (nullable)
]: any -> record<request_id: string, document_metadata: table<name: string, status: string, doc_id: string, doc_type: string>, taxforms: table<doc_id: string, document_type: string, w2: record>, error: record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list<any>, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list<string>, provided_account_subtypes: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/income/verification/taxforms/get")
  let body = {client_id: $client_id, secret: $secret, income_verification_id: $income_verification_id, access_token: $access_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# (Deprecated) Check digital income verification eligibility and optimize conversion
#
# POST /income/verification/precheck
# DEPRECATED
# Docs: /api/products/income/#incomeverificationprecheck
# operationId: incomeVerificationPrecheck
# --user shape: {first_name?: string, last_name?: string, email_address?: string, home_address?: record}
# --employer shape: {name?: string, address?: record, tax_id?: string, url?: string}
# --payroll_institution shape: {name?: string}
# --us_military_info shape: {is_active_duty?: bool, branch?: string}
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user: record # Information about the user whose eligibility is being evaluated. (nullable) — shape: {first_name?: string, last_name?: string, email_address?: string, home_address?: record}
  --employer: record # Information about the end user's employer (nullable) — shape: {name?: string, address?: record, tax_id?: string, url?: string}
  --payroll-institution: record # Information about the end user's payroll institution (nullable) — shape: {name?: string}
  --transactions-access-token: any # DEPRECATED
  --transactions-access-tokens: list # An array of access tokens corresponding to Items belonging to the user whose eligibility is being checked. Note that if the Items specified here are not already initialized with `transactions`, providing them in this field will cause these Items to be initialized with (and billed for) the Transactions product.
  --us-military-info: record # Data about military info in the income verification precheck. (nullable) — shape: {is_active_duty?: bool, branch?: string}
]: any -> record<precheck_id: string, request_id: string, confidence: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/income/verification/precheck")
  let body = {client_id: $client_id, secret: $secret, user: $user, employer: $employer, payroll_institution: $payroll_institution, transactions_access_token: $transactions_access_token, transactions_access_tokens: $transactions_access_tokens, us_military_info: $us_military_info} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
]: any -> record<employments: table<status: string, start_date: string, end_date: string, employer: record, title: string, platform_ids: record>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/employment/verification/get")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  report_tokens: list # List of report tokens; can include at most one VOA/standard Asset Report tokens and one VOE Asset Report Token.
]: any -> record<audit_copy_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/audit_copy_token/create")
  let body = {client_id: $client_id, secret: $secret, report_tokens: $report_tokens} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  audit_copy_token: string # The `audit_copy_token` granting access to the Audit Copy you would like to revoke.
]: any -> record<removed: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/audit_copy_token/remove")
  let body = {client_id: $client_id, secret: $secret, audit_copy_token: $audit_copy_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  audit_copy_token: string # A token that can be shared with a third party auditor to allow them to obtain access to the Asset Report. This token should be stored securely.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<DEAL: record<LOANS: record<LOAN: record>, PARTIES: record<PARTY: list>, SERVICES: record<SERVICE: record>>, request_id: string, SchemaVersion: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/asset_report/freddie_mac/get")
  let body = {audit_copy_token: $audit_copy_token, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  audit_copy_token: string # A token that can be shared with a third party auditor to allow them to obtain access to the Asset Report. This token should be stored securely.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<DEAL: record<LOANS: record<LOAN: record>, PARTIES: record<PARTY: list>, SERVICES: record<SERVICE: record>>, request_id: string, SchemaVersion: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/freddie_mac/reports/get")
  let body = {audit_copy_token: $audit_copy_token, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
]: any -> record<bank_employment_reports: table<bank_employment_report_id: string, generated_time: string, days_requested: int, items: list, warnings: list>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beta/credit/v1/bank_employment/get")
  let body = {client_id: $client_id, secret: $secret, user_token: $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --user-id: any
  --options: record # An optional object for `/credit/bank_income/get` request options. — shape: {count?: int}
]: any -> record<bank_income: table<bank_income_id: string, generated_time: string, days_requested: int, items: list, bank_income_summary: record, warnings: list>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/bank_income/get")
  let body = {client_id: $client_id, secret: $secret, user_token: $user_token, user_id: $user_id, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --accept: string@accept-completer # Response content type
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --user-id: any
]: any -> record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list<any>, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list<string>, provided_account_subtypes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/bank_income/pdf/get")
  let body = {client_id: $client_id, secret: $secret, user_token: $user_token, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Refresh a user's bank income information
#
# POST /credit/bank_income/refresh
# DEPRECATED
# Docs: /api/products/income/#creditbank_incomerefresh
# operationId: creditBankIncomeRefresh
# --options shape: {days_requested?: int}
@deprecated
export def "credit-bank-income-refresh creditBankIncomeRefresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --user-id: any
  --options: record # An optional object for `/credit/bank_income/refresh` request options. — shape: {days_requested?: int}
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/bank_income/refresh")
  let body = {client_id: $client_id, secret: $secret, user_token: $user_token, user_id: $user_id, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Subscribe and unsubscribe to proactive notifications for a user's income profile
#
# POST /credit/bank_income/webhook/update
# Docs: /api/products/income/#creditbank_incomewebhookupdate
# operationId: creditBankIncomeWebhookUpdate
export def "credit-bank-income-webhook-update creditBankIncomeWebhookUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --user-id: any
  --enable-webhooks: string@bool-completer # Whether the user should be enabled for proactive webhook notifications when their income changes
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/bank_income/webhook/update")
  let body = {client_id: $client_id, secret: $secret, user_token: $user_token, user_id: $user_id, enable_webhooks: $enable_webhooks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the parsing configuration for a document income verification
#
# POST /credit/payroll_income/parsing_config/update
# Docs: /api/products/income/#creditpayroll_incomeparsing_configupdate
# operationId: creditPayrollIncomeParsingConfigUpdate
export def "credit-payroll-income-parsing-config-update creditPayrollIncomeParsingConfigUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --user-id: any
  --item-id: string # The `item_id` of the Item associated with this webhook, warning, or error
  parsing_config: list # The types of analysis to enable for the document income verification session
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/payroll_income/parsing_config/update")
  let body = {client_id: $client_id, secret: $secret, user_token: $user_token, user_id: $user_id, item_id: $item_id, parsing_config: $parsing_config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve data for a user's uploaded bank statements
#
# POST /credit/bank_statements/uploads/get
# Docs: /api/products/income/#creditbank_statementsuploadsget
# operationId: creditBankStatementsUploadsGet
# --options shape: {item_ids?: list}
export def "credit-bank-statements-uploads-get creditBankStatementsUploadsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --options: record # An optional object for `/credit/bank_statements/uploads/get` request options. — shape: {item_ids?: list}
]: any -> record<items: table<item_id: string, bank_statements: list, status: record, updated_at: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/bank_statements/uploads/get")
  let body = {client_id: $client_id, secret: $secret, user_token: $user_token, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a user's payroll information
#
# POST /credit/payroll_income/get
# Docs: /api/products/income/#creditpayroll_incomeget
# operationId: creditPayrollIncomeGet
# --options shape: {item_ids?: list}
export def "credit-payroll-income-get creditPayrollIncomeGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --user-id: any
  --options: record # An optional object for `/credit/payroll_income/get` request options. — shape: {item_ids?: list}
]: any -> record<items: table<item_id: string, institution_id: string, institution_name: string, accounts: list, payroll_income: list, status: record, updated_at: string>, error: record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list<any>, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list<string>, provided_account_subtypes: list<string>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/payroll_income/get")
  let body = {client_id: $client_id, secret: $secret, user_token: $user_token, user_id: $user_id, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve fraud insights for a user's manually uploaded document(s).
#
# POST /credit/payroll_income/risk_signals/get
# Docs: /api/products/income/#creditpayroll_incomerisk_signalsget
# operationId: creditPayrollIncomeRiskSignalsGet
export def "credit-payroll-income-risk-signals-get creditPayrollIncomeRiskSignalsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --user-id: any
]: any -> record<items: table<item_id: string, verification_risk_signals: list>, error: record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list<any>, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list<string>, provided_account_subtypes: list<string>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/payroll_income/risk_signals/get")
  let body = {client_id: $client_id, secret: $secret, user_token: $user_token, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check income verification eligibility and optimize conversion
#
# POST /credit/payroll_income/precheck
# DEPRECATED
# Docs: /api/products/income/#creditpayroll_incomeprecheck
# operationId: creditPayrollIncomePrecheck
# --employer shape: {name?: string, address?: record, tax_id?: string, url?: string}
# --us_military_info shape: {is_active_duty?: bool, branch?: string}
# --payroll_institution shape: {name?: string}
@deprecated
export def "credit-payroll-income-precheck creditPayrollIncomePrecheck" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --user-id: any
  --access-tokens: list # An array of access tokens corresponding to Items belonging to the user whose eligibility is being checked. Note that if the Items specified here are not already initialized with `transactions`, providing them in this field will cause these Items to be initialized with (and billed for) the Transactions product.
  --employer: record # Information about the end user's employer (nullable) — shape: {name?: string, address?: record, tax_id?: string, url?: string}
  --us-military-info: record # Data about military info in the income verification precheck. (nullable) — shape: {is_active_duty?: bool, branch?: string}
  --payroll-institution: record # Information about the end user's payroll institution (nullable) — shape: {name?: string}
]: any -> record<request_id: string, confidence: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/payroll_income/precheck")
  let body = {client_id: $client_id, secret: $secret, user_token: $user_token, user_id: $user_id, access_tokens: $access_tokens, employer: $employer, us_military_info: $us_military_info, payroll_institution: $payroll_institution} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
]: any -> record<items: table<item_id: string, employments: list, employment_report_token: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/employment/get")
  let body = {client_id: $client_id, secret: $secret, user_token: $user_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Refresh a digital payroll income verification
#
# POST /credit/payroll_income/refresh
# Docs: /api/products/income/#creditpayroll_incomerefresh
# operationId: creditPayrollIncomeRefresh
# --options shape: {item_ids?: list, webhook?: string}
export def "credit-payroll-income-refresh creditPayrollIncomeRefresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  user_token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --user-id: any
  --options: record # An optional object for `/credit/payroll_income/refresh` request options. — shape: {item_ids?: list, webhook?: string}
]: any -> record<request_id: string, verification_refresh_status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/payroll_income/refresh")
  let body = {client_id: $client_id, secret: $secret, user_token: $user_token, user_id: $user_id, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a relay token to share an Asset Report with a partner client
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  report_tokens: list # List of report token strings, with at most one token of each report type. Currently only Asset Report token is supported.
  secondary_client_id: string # The `secondary_client_id` is the client id of the third party with whom you would like to share the relay token.
  --webhook: string # URL to which Plaid will send webhooks when the Secondary Client successfully retrieves an Asset Report by calling `/credit/relay/get`. (nullable, format: url)
]: any -> record<relay_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/relay/create")
  let body = {client_id: $client_id, secret: $secret, report_tokens: $report_tokens, secondary_client_id: $secondary_client_id, webhook: $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the reports associated with a relay token that was shared with you
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  relay_token: string # The `relay_token` granting access to the report you would like to get.
  report_type: string@report-type-completer-2 # The report type. It can be `asset`. Income report types are not yet supported.
  --include-insights: string@bool-completer # `true` if you would like to retrieve the Asset Report with Insights, `false` otherwise. This field defaults to `false` if omitted. (default: false)
]: any -> record<report: record<asset_report_id: string, insights: record<risk: record, affordability: record>, client_report_id: string, date_generated: string, days_requested: float, user: record<client_user_id: string, first_name: string, middle_name: string, last_name: string, ssn: string, phone_number: string, email: string>, items: list<record>>, warnings: table<warning_type: string, warning_code: string, cause: record>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/relay/get")
  let body = {client_id: $client_id, secret: $secret, relay_token: $relay_token, report_type: $report_type, include_insights: $include_insights} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the pdf reports associated with a relay token that was shared with you (beta)
#
# POST /credit/relay/pdf/get
# Docs: /api/products/assets/#creditrelaypdfget
# operationId: creditRelayPdfGet
export def "credit-relay-pdf-get creditRelayPdfGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  relay_token: string # The `relay_token` granting access to the report you would like to get.
  report_type: string@report-type-completer-2 # The report type. It can be `asset`. Income report types are not yet supported.
]: any -> record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list<any>, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list<string>, provided_account_subtypes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/relay/pdf/get")
  let body = {client_id: $client_id, secret: $secret, relay_token: $relay_token, report_type: $report_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Refresh a report of a relay token
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  relay_token: string # The `relay_token` granting access to the report you would like to refresh.
  report_type: string@report-type-completer-2 # The report type. It can be `asset`. Income report types are not yet supported.
  --webhook: string # The URL registered to receive webhooks when the report of a relay token has been refreshed. (nullable, format: url)
]: any -> record<relay_token: string, asset_report_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/relay/refresh")
  let body = {client_id: $client_id, secret: $secret, relay_token: $relay_token, report_type: $report_type, webhook: $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove relay token
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  relay_token: string # The `relay_token` you would like to revoke.
]: any -> record<removed: bool, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/relay/remove")
  let body = {client_id: $client_id, secret: $secret, relay_token: $relay_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  webhook: string # The URL to which the webhook should be sent. (format: url)
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/bank_transfer/fire_webhook")
  let body = {client_id: $client_id, secret: $secret, webhook: $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  item_id: string # The Item ID associated with the verification.
  --user-id: string # The Plaid `user_id` of the User associated with this webhook, warning, or error.
  webhook: string # The URL to which the webhook should be sent. (format: url)
  --verification-status: string@verification-status-completer-1 # `VERIFICATION_STATUS_PROCESSING_COMPLETE`: The income verification status processing has completed. If the user uploaded multiple documents, this webhook will fire when all documents have finished processing. Call the `/income/verification/paystubs/get` endpoint and check the document metadata to see which documents were successfully parsed.  `VERIFICATION_STATUS_PROCESSING_FAILED`: A failure occurred when attempting to process the verification documentation.  `VERIFICATION_STATUS_PENDING_APPROVAL`: (deprecated) The income verification has been sent to the user for review.
  webhook_code: string@webhook-code-completer-1 # The webhook codes that can be fired by this test endpoint.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/income/fire_webhook")
  let body = {client_id: $client_id, secret: $secret, item_id: $item_id, user_id: $user_id, webhook: $webhook, verification_status: $verification_status, webhook_code: $webhook_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Manually fire a Bank Income webhook in Sandbox
#
# POST /sandbox/bank_income/fire_webhook
# Docs: /api/sandbox/#sandboxbankincomefire_webhook
# operationId: sandboxBankIncomeFireWebhook
# --webhook_fields shape: {user_id: string, bank_income_refresh_complete_result?: "SUCCESS"|"FAILURE"}
export def "sandbox-bank-income-fire-webhook sandboxBankIncomeFireWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --webhook-override: string # The URL to which the webhook should be sent. If provided, this will override the URL set in the dashboard. (format: url)
  webhook_code: string@webhook-code-completer-2 # The webhook codes this endpoint can be used to test
  webhook_fields: record # Optional fields which will be populated in the simulated webhook — shape: {user_id: string, bank_income_refresh_complete_result?: "SUCCESS"|"FAILURE"}
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/bank_income/fire_webhook")
  let body = {client_id: $client_id, secret: $secret, webhook_override: $webhook_override, webhook_code: $webhook_code, webhook_fields: $webhook_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Trigger an update for Cash Flow Updates
#
# POST /sandbox/cra/cashflow_updates/update
# Docs: /api/sandbox/#sandboxcracashflow_updatesupdate
# operationId: sandboxCraCashflowUpdatesUpdate
export def "sandbox-cra-cashflow-updates-update sandboxCraCashflowUpdatesUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --user-token: string # The user token associated with the user for which data is being requested. This field is used only by customers with pre-existing integrations that already use the `user_token` field. All other customers should use the `user_id` instead. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
  --webhook-codes: list # Webhook codes corresponding to the Cash Flow Updates events to be simulated. (nullable)
  --user-id: string # A unique user identifier, created by `/user/create`. Integrations that began using `/user/create` after December 10, 2025 use this field to identify a user instead of the `user_token`. For more details, see [New User APIs](https://plaid.com/docs/api/users/user-apis).
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/cra/cashflow_updates/update")
  let body = {client_id: $client_id, secret: $secret, user_token: $user_token, webhook_codes: $webhook_codes, user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Save the selected accounts when connecting to the Platypus OAuth institution
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
  oauth_state_id: string
  accounts: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/oauth/select_accounts")
  let body = {oauth_state_id: $oauth_state_id, accounts: $accounts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Evaluate a planned ACH transaction
#
# POST /signal/evaluate
# Docs: /api/products/signal#signalevaluate
# operationId: signalEvaluate
# --user shape: {name?: record, phone_number?: string, email_address?: string, address?: record}
# --device shape: {ip_address?: string, user_agent?: string}
@deprecated --flag user-present
@deprecated --flag risk-profile-key
export def "signal-evaluate signalEvaluate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  account_id: string # The Plaid `account_id` of the account that is the funding source for the proposed transaction. The `account_id` is returned in the `/accounts/get` endpoint as well as the [`onSuccess`](https://plaid.com/docs/link/ios/#link-ios-onsuccess-linkSuccess-metadata-accounts-id) callback metadata.  This will return an [`INVALID_ACCOUNT_ID`](https://plaid.com/docs/errors/invalid-input/#invalid_account_id) error if the account has been removed at the bank or if the `account_id` is no longer valid.
  client_transaction_id: string # The unique ID that you would like to use to refer to this evaluation attempt - for example, a payment attempt ID. You will use this later to debug this evaluation, and/or report an ACH return, etc. The max length for this field is 36 characters.
  amount: float # The transaction amount, in USD (e.g. `102.05`) (format: double)
  --user-present: string@bool-completer # `true` if the end user is present while initiating the ACH transfer and the endpoint is being called; `false` otherwise (for example, when the ACH transfer is scheduled and the end user is not present, or you call this endpoint after the ACH transfer but before submitting the Nacha file for ACH processing). When using a Balance-only ruleset, this field is ignored. This field is not currently used as part of Signal Transaction Score evaluations, but may be used in the future. (DEPRECATED, nullable)
  --client-user-id: string # A unique ID that identifies the end user in your system. This ID is used to correlate requests by a user with multiple Items. Personally identifiable information, such as an email address or phone number, should not be used in the `client_user_id`.
  --is-recurring: string@bool-completer # Use `true` if the ACH transaction is a part of recurring schedule (for example, a monthly repayment); `false` otherwise. When using a Balance-only ruleset, this field is ignored. (nullable)
  --default-payment-method: string # The default ACH payment method to complete the transaction. When using a Balance-only ruleset, this field is ignored. `SAME_DAY_ACH`: Same Day ACH by Nacha. The debit transaction is processed and settled on the same day. `STANDARD_ACH`: Standard ACH by Nacha. `MULTIPLE_PAYMENT_METHODS`: If there is no default debit rail or there are multiple payment methods. Possible values:  `SAME_DAY_ACH`, `STANDARD_ACH`, `MULTIPLE_PAYMENT_METHODS` (nullable)
  --user: record # Details about the end user initiating the transaction (i.e., the account holder). These fields are optional, but strongly recommended to increase the accuracy of results when using Signal Transaction Scores. When using a Balance-only ruleset, if the Signal Addendum has been signed, these fields are ignored; if the Addendum has not been signed, using these fields will result in an error. — shape: {name?: record, phone_number?: string, email_address?: string, address?: record}
  --device: record # Details about the end user's device. These fields are optional, but strongly recommended to increase the accuracy of results when using Signal Transaction Scores. When using a Balance-only Ruleset, these fields are ignored if the Signal Addendum has been signed; if it has not been signed, using these fields will result in an error. — shape: {ip_address?: string, user_agent?: string}
  --risk-profile-key: string # Specifying `risk_profile_key` is deprecated. Please provide `ruleset` instead. (DEPRECATED, nullable)
  --ruleset-key: string # The key of the ruleset to use for evaluating this transaction. You can create a ruleset using the Plaid Dashboard, under [Signal->Rules](https://dashboard.plaid.com/signal/risk-profiles). If not provided, for all new customers as of October 15, 2025, the `default` ruleset will be used. For existing Signal Transaction Scores customers as of October 15, 2025, by default, no ruleset will be used if the `ruleset_key` is not provided. For more information, or to opt out of using rulesets, see [Signal Rules](https://plaid.com/docs/signal/signal-rules/). (nullable)
]: any -> record<request_id: string, scores: record<customer_initiated_return_risk: record<score: int, risk_tier: int>, bank_initiated_return_risk: record<score: int, risk_tier: int>>, core_attributes: record<unauthorized_transactions_count_7d: int, unauthorized_transactions_count_30d: int, unauthorized_transactions_count_60d: int, unauthorized_transactions_count_90d: int, nsf_overdraft_transactions_count_7d: int, nsf_overdraft_transactions_count_30d: int, nsf_overdraft_transactions_count_60d: int, nsf_overdraft_transactions_count_90d: int, days_since_first_plaid_connection: int, plaid_connections_count_7d: int, plaid_connections_count_30d: int, total_plaid_connections_count: int, is_savings_or_money_market_account: bool, total_credit_transactions_amount_10d: float, total_debit_transactions_amount_10d: float, p50_credit_transactions_amount_28d: float, p50_debit_transactions_amount_28d: float, p95_credit_transactions_amount_28d: float, p95_debit_transactions_amount_28d: float, days_with_negative_balance_count_90d: int, p90_eod_balance_30d: float, p90_eod_balance_60d: float, p90_eod_balance_90d: float, p10_eod_balance_30d: float, p10_eod_balance_60d: float, p10_eod_balance_90d: float, available_balance: float, current_balance: float, balance_last_updated: string, phone_change_count_28d: int, phone_change_count_90d: int, email_change_count_28d: int, email_change_count_90d: int, address_change_count_28d: int, address_change_count_90d: int, plaid_non_oauth_authentication_attempts_count_3d: int, plaid_non_oauth_authentication_attempts_count_7d: int, plaid_non_oauth_authentication_attempts_count_30d: int, failed_plaid_non_oauth_authentication_attempts_count_3d: int, failed_plaid_non_oauth_authentication_attempts_count_7d: int, failed_plaid_non_oauth_authentication_attempts_count_30d: int, debit_transactions_count_10d: int, credit_transactions_count_10d: int, debit_transactions_count_30d: int, credit_transactions_count_30d: int, debit_transactions_count_60d: int, credit_transactions_count_60d: int, debit_transactions_count_90d: int, credit_transactions_count_90d: int, total_debit_transactions_amount_30d: float, total_credit_transactions_amount_30d: float, total_debit_transactions_amount_60d: float, total_credit_transactions_amount_60d: float, total_debit_transactions_amount_90d: float, total_credit_transactions_amount_90d: float, p50_eod_balance_30d: float, p50_eod_balance_60d: float, p50_eod_balance_90d: float, p50_eod_balance_31d_to_60d: float, p50_eod_balance_61d_to_90d: float, p90_eod_balance_31d_to_60d: float, p90_eod_balance_61d_to_90d: float, p10_eod_balance_31d_to_60d: float, p10_eod_balance_61d_to_90d: float, transactions_last_updated: string, is_account_closed: bool, is_account_frozen_or_restricted: bool, distinct_ip_addresses_count_3d: int, distinct_ip_addresses_count_7d: int, distinct_ip_addresses_count_30d: int, distinct_ip_addresses_count_90d: int, distinct_user_agents_count_3d: int, distinct_user_agents_count_7d: int, distinct_user_agents_count_30d: int, distinct_user_agents_count_90d: int, distinct_ssl_tls_connection_sessions_count_3d: int, distinct_ssl_tls_connection_sessions_count_7d: int, distinct_ssl_tls_connection_sessions_count_30d: int, distinct_ssl_tls_connection_sessions_count_90d: int, days_since_account_opening: int, balance_to_transaction_amount_ratio: float>, risk_profile: record<key: string, outcome: string>, ruleset: record<ruleset_key: string, result: string, triggered_rule_details: record<internal_note: string, custom_action_key: string>, outcome: string>, warnings: table<warning_type: string, warning_code: string, warning_message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signal/evaluate")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, account_id: $account_id, client_transaction_id: $client_transaction_id, amount: $amount, user_present: $user_present, client_user_id: $client_user_id, is_recurring: $is_recurring, default_payment_method: $default_payment_method, user: $user, device: $device, risk_profile_key: $risk_profile_key, ruleset_key: $ruleset_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Schedule a planned ACH transaction
#
# POST /signal/schedule
# Docs: none
# operationId: signalSchedule
export def "signal-schedule signalSchedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
  account_id: string # The Plaid `account_id` of the account that is the funding source for the proposed transaction. The `account_id` is returned in the `/accounts/get` endpoint as well as the [`onSuccess`](https://plaid.com/docs/link/ios/#link-ios-onsuccess-linkSuccess-metadata-accounts-id) callback metadata.  This will return an [`INVALID_ACCOUNT_ID`](https://plaid.com/docs/errors/invalid-input/#invalid_account_id) error if the account has been removed at the bank or if the `account_id` is no longer valid.
  client_transaction_id: string # The unique ID that you would like to use to refer to this transaction. For your convenience mapping your internal data, you could use your internal ID/identifier for this transaction. The max length for this field is 36 characters.
  amount: float # The transaction amount, in USD (e.g. `102.05`) (format: double)
  --default-payment-method: string@default-payment-method-completer # The payment method specified in the `default_payment_method` field directly impacts the timing recommendations provided by the API for submitting the debit entry to your processor or ODFI. If unspecified, defaults to `STANDARD_ACH`.  `SAME_DAY_ACH`: Same Day ACH (as defined by Nacha). The API assumes the settlement will occur on the same business day if the `/signal/schedule` request is submitted by 6:00 PM UTC. Note: The actual cutoff time can vary depending on your payment processor or ODFI. Nacha has established three processing windows for Same Day ACH (UTC): 2:30 PM, 6:45 PM, and 8:45 PM.  `STANDARD_ACH`: Standard ACH (as defined by Nacha), typically settled one to three business days after submission.  `MULTIPLE_PAYMENT_METHODS`: Indicates that there is no default debit rail or multiple payment methods are available, and the transaction could use any of them based on customer policy or availability.
]: any -> record<optimal_date: string, recommendations: table<date: string, recommendation: string, rank: int>, warnings: table<warning_type: string, warning_code: string, warning_message: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signal/schedule")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token, account_id: $account_id, client_transaction_id: $client_transaction_id, amount: $amount, default_payment_method: $default_payment_method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  client_transaction_id: string # Must be the same as the `client_transaction_id` supplied when calling `/signal/evaluate`
  --initiated: string@bool-completer # `true` if the ACH transaction was initiated, `false` otherwise.  This field must be returned as a boolean. If formatted incorrectly, this will result in an [`INVALID_FIELD`](https://plaid.com/docs/errors/invalid-request/#invalid_field) error.
  --days-funds-on-hold: int # The actual number of days (hold time) since the ACH debit transaction that you wait before making funds available to your customers. The holding time could affect the ACH return rate.  For example, use 0 if you make funds available to your customers instantly or the same day following the debit transaction, or 1 if you make funds available the next day following the debit initialization. (nullable)
  --decision-outcome: string@decision-outcome-completer # The payment decision from the risk assessment.  `APPROVE`: approve the transaction without requiring further actions from your customers. For example, use this field if you are placing a standard hold for all the approved transactions before making funds available to your customers. You should also use this field if you decide to accelerate the fund availability for your customers.  `REVIEW`: the transaction requires manual review  `REJECT`: reject the transaction  `TAKE_OTHER_RISK_MEASURES`: for example, placing a longer hold on funds than those approved transactions or introducing customer frictions such as step-up verification/authentication  `NOT_EVALUATED`: if only logging the results without using them  (nullable)
  --payment-method: string@payment-method-completer # The payment method to complete the transaction after the risk assessment. It may be different from the default payment method.  `SAME_DAY_ACH`: Same Day ACH by Nacha. The debit transaction is processed and settled on the same day.  `STANDARD_ACH`: Standard ACH by Nacha.  `MULTIPLE_PAYMENT_METHODS`: if there is no default debit rail or there are multiple payment methods.  (nullable)
  --amount-instantly-available: float # The amount (in USD) made available to your customers instantly following the debit transaction. It could be a partial amount of the requested transaction (example: 102.05). (nullable, format: double)
  --submitted-at: string # The date the ACH debit was submitted to the bank for processing (in ISO 8601 format: `YYYY-MM-DDTHH:mm:ssZ`). This field should correspond to the attempt initiated after the `/signal/schedule` call. (format: date-time)
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signal/decision/report")
  let body = {client_id: $client_id, secret: $secret, client_transaction_id: $client_transaction_id, initiated: $initiated, days_funds_on_hold: $days_funds_on_hold, decision_outcome: $decision_outcome, payment_method: $payment_method, amount_instantly_available: $amount_instantly_available, submitted_at: $submitted_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  client_transaction_id: string # Must be the same as the `client_transaction_id` supplied when calling `/signal/evaluate` or `/accounts/balance/get`.
  return_code: string # Must be a valid ACH return code (e.g. "R01")  If formatted incorrectly, this will result in an [`INVALID_FIELD`](https://plaid.com/docs/errors/invalid-request/#invalid_field) error.
  --returned-at: string # Date and time when you receive the returns from your payment processors, in ISO 8601 format (`YYYY-MM-DDTHH:mm:ssZ`). (nullable, format: date-time)
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signal/return/report")
  let body = {client_id: $client_id, secret: $secret, client_transaction_id: $client_transaction_id, return_code: $return_code, returned_at: $returned_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Opt-in an Item to Signal Transaction Scores
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  access_token: string # The access token associated with the Item for which data is being requested.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/signal/prepare")
  let body = {client_id: $client_id, secret: $secret, access_token: $access_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  iso_currency_code: string@iso-currency-code-completer # An ISO-4217 currency code, used with e-wallets and transactions.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wallet/create")
  let body = {client_id: $client_id, secret: $secret, iso_currency_code: $iso_currency_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  wallet_id: string # The ID of the e-wallet
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wallet/get")
  let body = {client_id: $client_id, secret: $secret, wallet_id: $wallet_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --iso-currency-code: string@iso-currency-code-completer # An ISO-4217 currency code, used with e-wallets and transactions.
  --cursor: string # A base64 value representing the latest e-wallet that has already been requested. Set this to `next_cursor` received from the previous `/wallet/list` request. If provided, the response will only contain e-wallets created before that e-wallet. If omitted, the response will contain e-wallets starting from the most recent, and in descending order.
  --count: int # The number of e-wallets to fetch (default: 10)
]: any -> record<wallets: table<wallet_id: string, balance: record, numbers: record, recipient_id: string, status: string>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wallet/list")
  let body = {client_id: $client_id, secret: $secret, iso_currency_code: $iso_currency_code, cursor: $cursor, count: $count} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Execute a transaction using an e-wallet
#
# POST /wallet/transaction/execute
# Docs: /api/products/virtual-accounts/#wallettransactionexecute
# operationId: walletTransactionExecute
# --counterparty shape: {name: string, numbers: record, address?: record, date_of_birth?: string}
# --amount shape: {iso_currency_code: "GBP"|"EUR", value: float}
# --originating_fund_source shape: {full_name: string, address: record, account_number: string, bic: string}
export def "wallet-transaction-execute walletTransactionExecute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  idempotency_key: string # A random key provided by the client, per unique wallet transaction. Maximum of 128 characters.  The API supports idempotency for safely retrying requests without accidentally performing the same operation twice. If a request to execute a wallet transaction fails due to a network connection error, then after a minimum delay of one minute, you can retry the request with the same idempotency key to guarantee that only a single wallet transaction is created. If the request was successfully processed, it will prevent any transaction that uses the same idempotency key, and was received within 24 hours of the first request, from being processed.
  wallet_id: string # The ID of the e-wallet to debit from
  counterparty: record # An object representing the e-wallet transaction's counterparty — shape: {name: string, numbers: record, address?: record, date_of_birth?: string}
  amount: record # The amount and currency of a transaction — shape: {iso_currency_code: "GBP"|"EUR", value: float}
  reference: string # A reference for the transaction. This must be an alphanumeric string with 6 to 18 characters and must not contain any special characters or spaces. Ensure that the `reference` field is unique for each transaction.
  --originating-fund-source: record # The original source of the funds. This field is required by local regulation for certain businesses (e.g. money remittance) to send payouts to recipients in the EU and UK. (nullable) — shape: {full_name: string, address: record, account_number: string, bic: string}
]: any -> record<transaction_id: string, status: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wallet/transaction/execute")
  let body = {client_id: $client_id, secret: $secret, idempotency_key: $idempotency_key, wallet_id: $wallet_id, counterparty: $counterparty, amount: $amount, reference: $reference, originating_fund_source: $originating_fund_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  transaction_id: string # The ID of the transaction to fetch
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wallet/transaction/get")
  let body = {client_id: $client_id, secret: $secret, transaction_id: $transaction_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List e-wallet transactions
#
# POST /wallet/transaction/list
# Docs: /api/products/virtual-accounts/#wallettransactionlist
# operationId: walletTransactionList
# --options shape: {start_time?: string, end_time?: string}
export def "wallet-transaction-list walletTransactionList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  wallet_id: string # The ID of the e-wallet to fetch transactions from
  --cursor: string # A value representing the latest transaction to be included in the response. Set this from `next_cursor` received in the previous `/wallet/transaction/list` request. If provided, the response will only contain that transaction and transactions created before it. If omitted, the response will contain transactions starting from the most recent, and in descending order by the `created_at` time.
  --count: int # The number of transactions to fetch (default: 10)
  --options: record # Additional wallet transaction options (nullable) — shape: {start_time?: string, end_time?: string}
]: any -> record<transactions: table<transaction_id: string, wallet_id: string, reference: string, type: string, scheme: string, amount: record, counterparty: record, status: string, created_at: string, last_status_update: string, payee_verification_status: string, payment_id: string, failure_reason: string, error: record, related_transactions: list>, next_cursor: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wallet/transaction/list")
  let body = {client_id: $client_id, secret: $secret, wallet_id: $wallet_id, cursor: $cursor, count: $count, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enhance locally-held transaction data
#
# POST /beta/transactions/v1/enhance
# operationId: transactionsEnhance
# --transactions item shape: {id: string, description: string, amount: float, iso_currency_code: string}
export def "beta-transactions-enhance transactionsEnhance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  account_type: string # The type of account for the requested transactions (`depository` or `credit`).
  transactions: list # An array of raw transactions to be enhanced. — item shape: {id: string, description: string, amount: float, iso_currency_code: string}
]: any -> record<enhanced_transactions: table<id: string, description: string, amount: float, iso_currency_code: string, enhancements: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beta/transactions/v1/enhance")
  let body = {client_id: $client_id, secret: $secret, account_type: $account_type, transactions: $transactions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create transaction category rule
#
# POST /beta/transactions/rules/v1/create
# operationId: transactionsRulesCreate
# --rule_details shape: {field: "TRANSACTION_ID"|"MERCHANT_NAME", type: "EXACT_MATCH"|"SUBSTRING_MATCH", query: string}
export def "beta-transactions-rules-create transactionsRulesCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  client_user_id: string # A unique ID representing the end user. This ID is used to associate rules with a specific user.
  pfc_primary_category: string # A personal finance primary category. See the [taxonomy csv file](https://plaid.com/documents/pfc-taxonomy-all.csv) for a full list of personal finance categories.
  pfc_detailed_category: string # A personal finance detailed category. See the [taxonomy csv file](https://plaid.com/documents/pfc-taxonomy-all.csv) for a full list of personal finance categories.
  rule_details: record # A representation of transactions rule details. — shape: {field: "TRANSACTION_ID"|"MERCHANT_NAME", type: "EXACT_MATCH"|"SUBSTRING_MATCH", query: string}
]: any -> record<rule: record<id: string, user_id: string, created_at: string, updated_at: string, pfc_primary_category: string, pfc_detailed_category: string, rule_details: record<field: string, type: string, query: string>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beta/transactions/rules/v1/create")
  let body = {client_id: $client_id, secret: $secret, client_user_id: $client_user_id, pfc_primary_category: $pfc_primary_category, pfc_detailed_category: $pfc_detailed_category, rule_details: $rule_details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  client_user_id: string # A unique ID representing the end user whose rules should be listed.
]: any -> record<rules: table<id: string, user_id: string, created_at: string, updated_at: string, pfc_primary_category: string, pfc_detailed_category: string, rule_details: record>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beta/transactions/rules/v1/list")
  let body = {client_id: $client_id, secret: $secret, client_user_id: $client_user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  client_user_id: string # A unique ID representing the end user the rule belongs to.
  rule_id: string # A rule's unique identifier
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beta/transactions/rules/v1/remove")
  let body = {client_id: $client_id, secret: $secret, client_user_id: $client_user_id, rule_id: $rule_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Obtain user insights based on transactions sent through /transactions/enrich
#
# POST /beta/transactions/user_insights/v1/get
# Docs: /api/products/enrich/#userinsightsget
# operationId: transactionsUserInsightsGet
export def "beta-transactions-user-insights-get transactionsUserInsightsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  client_user_id: string # A unique client-provided `client_user_id` to retrieve insights for.
]: any -> record<user_data_overview: record<transaction_count: int, oldest_transaction_date: string, newest_transaction_date: string, days_available: int, total_outflows: float, total_inflows: float>, counterparty_insights: record<financial_institution_insights: list<record>, merchant_insights: list<record>>, category_insights: record<primary_category_insights: list<record>, detailed_category_insights: list<record>>, recurring_transactions: record<inflow_streams: list<record>, outflow_streams: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beta/transactions/user_insights/v1/get")
  let body = {client_id: $client_id, secret: $secret, client_user_id: $client_user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get EWA Score Report
#
# POST /beta/ewa_report/v1/get
# Docs: /api/products/beta/#betaewareportv1get
# operationId: betaEwaReportV1Get
export def "beta-ewa-report-get betaEwaReportV1Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  access_token: string # The access token associated with the Item for which data is being requested.
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<request_id: string, ewa_report_id: string, generation_time: string, ewa_scores: table<lowest_amount: float, highest_amount: float, score: int>, ewa_attributes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beta/ewa_report/v1/get")
  let body = {access_token: $access_token, client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search for an Issue
#
# POST /issues/search
# Docs: /api/products/issues#issuessearch
# operationId: issuesSearch
export def "issues-search issuesSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  --item-id: string # A unique identifier for the Plaid Item.
  --link-session-id: string # A unique identifier for the Link session.
  --link-session-request-id: string # The `request_id` for the Link session that might have had an institution connection issue.
]: any -> record<issues: table<issue_id: string, institution_names: list, institution_ids: list, created_at: string, summary: string, detailed_description: string, status: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/issues/search")
  let body = {client_id: $client_id, secret: $secret, item_id: $item_id, link_session_id: $link_session_id, link_session_request_id: $link_session_request_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an Issue
#
# POST /issues/get
# Docs: /api/products/issues/#issuesget
# operationId: issuesGet
export def "issues-get issuesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  issue_id: string # The unique identifier of the issue to retrieve.
]: any -> record<issue: record<issue_id: string, institution_names: list<string>, institution_ids: list<string>, created_at: string, summary: string, detailed_description: string, status: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/issues/get")
  let body = {client_id: $client_id, secret: $secret, issue_id: $issue_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Subscribe to an Issue
#
# POST /issues/subscribe
# Docs: /api/products/issues/#issuessubscribe
# operationId: issuesSubscribe
export def "issues-subscribe issuesSubscribe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  issue_id: string # The unique identifier of the issue to subscribe to.
  webhook: string # The webhook URL where notifications should be sent when the issue status changes.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/issues/subscribe")
  let body = {client_id: $client_id, secret: $secret, issue_id: $issue_id, webhook: $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create payment profile
#
# POST /payment_profile/create
# DEPRECATED
# Docs: /api/products/transfer/#payment_profilecreate
# operationId: paymentProfileCreate
@deprecated
export def "payment-profile-create paymentProfileCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
]: any -> record<payment_profile_token: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_profile/create")
  let body = {client_id: $client_id, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get payment profile
#
# POST /payment_profile/get
# DEPRECATED
# Docs: /api/products/transfer/#payment_profileget
# operationId: paymentProfileGet
@deprecated
export def "payment-profile-get paymentProfileGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  payment_profile_token: string # A payment profile token associated with the Payment Profile data that is being requested.
]: any -> record<updated_at: string, created_at: string, deleted_at: string, status: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_profile/get")
  let body = {client_id: $client_id, secret: $secret, payment_profile_token: $payment_profile_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove payment profile
#
# POST /payment_profile/remove
# DEPRECATED
# Docs: /api/products/transfer/#payment_profileremove
# operationId: paymentProfileRemove
@deprecated
export def "payment-profile-remove paymentProfileRemove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  payment_profile_token: string # A payment profile token associated with the Payment Profile data that is being requested.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment_profile/remove")
  let body = {client_id: $client_id, secret: $secret, payment_profile_token: $payment_profile_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a new end customer for a Plaid reseller.
#
# POST /partner/customer/create
# Docs: /api/partner/#partnercustomercreate
# operationId: partnerCustomerCreate
# --technical_contact shape: {given_name?: string, family_name?: string, email?: string}
# --billing_contact shape: {given_name?: string, family_name?: string, email?: string}
# --customer_support_info shape: {email?: string, phone_number?: string, contact_url?: string, link_update_url?: string}
# --address shape: {city?: string, street?: string, region?: string, postal_code?: string, country_code?: string}
# --assets_under_management shape: {amount: float, iso_currency_code: string}
export def "partner-customer-create partnerCustomerCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  company_name: string # The company name of the end customer being created. This will be used to display the end customer in the Plaid Dashboard. It will not be shown to end users.
  --is-diligence-attested: string@bool-completer # Denotes whether or not the partner has completed attestation of diligence for the end customer to be created.
  --products: list # The products to be enabled for the end customer. If empty or `null`, this field will default to the products enabled for the reseller at the time this endpoint is called.
  --create-link-customization: string@bool-completer # If `true`, the end customer's default Link customization will be set to match the partner's. You can always change the end customer's Link customization in the Plaid Dashboard. See the [Link Customization docs](https://plaid.com/docs/link/customization/) for more information. If you require the ability to programmatically create end customers using multiple different Link customization profiles, contact your Plaid account manager for assistance.  Important: Data Transparency Messaging (DTM) use cases will not be copied to the end customer's Link customization unless the **Publish changes** button is clicked after the use cases are applied. Link will not work in Production unless the end customer's DTM use cases are configured. For more details, see [Data Transparency Messaging](https://plaid.com/docs/link/data-transparency-messaging-migration-guide/).
  --logo: string # Base64-encoded representation of the end customer's logo. Must be a PNG of size 1024x1024 under 4MB. The logo will be shared with financial institutions and shown to the end user during Link flows. A logo is required if `create_link_customization` is `true`. If `create_link_customization` is `false` and the logo is omitted, the partner's logo will be used if one exists, otherwise a stock logo will be used.
  legal_entity_name: string # The end customer's legal name. This will be shared with financial institutions as part of the OAuth registration process. It will not be shown to end users.
  website: string # The end customer's website.
  application_name: string # The name of the end customer's application. This will be shown to end users when they go through the Plaid Link flow. The application name must be unique and cannot match the name of another application already registered with Plaid.
  --technical-contact: record # The technical contact for the end customer. Defaults to partner's technical contact if omitted. — shape: {given_name?: string, family_name?: string, email?: string}
  --billing-contact: record # The billing contact for the end customer. Defaults to partner's billing contact if omitted. — shape: {given_name?: string, family_name?: string, email?: string}
  --customer-support-info: record # This information is public. Users of your app will see this information when managing connections between your app and their bank accounts in Plaid Portal. Defaults to partner's customer support info if omitted. This field is mandatory for partners whose Plaid accounts were created after November 26, 2024 and will be mandatory for all partners by the 1033 compliance deadline. — shape: {email?: string, phone_number?: string, contact_url?: string, link_update_url?: string}
  address: record # The end customer's address. — shape: {city?: string, street?: string, region?: string, postal_code?: string, country_code?: string}
  --is-bank-addendum-completed: string@bool-completer # Denotes whether the partner has forwarded the Plaid bank addendum to the end customer.
  --assets-under-management: record # Assets under management for the given end customer. Required for end customers with monthly service commitments. — shape: {amount: float, iso_currency_code: string}
  --redirect-uris: list # A list of URIs indicating the destination(s) where a user can be forwarded after completing the Link flow; used to support OAuth authentication flows when launching Link in the browser or another app. URIs should not contain any query parameters. When used in Production, URIs must use https. To modify redirect URIs for an end customer after creating them, go to the end customer's [API page](https://dashboard.plaid.com/team/api) in the Dashboard.
  --registration-number: string # The unique identifier assigned to a financial institution by regulatory authorities, if applicable. For banks, this is the FDIC Certificate Number. For credit unions, this is the Credit Union Charter Number.
]: any -> record<end_customer: record, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/partner/customer/create")
  let body = {client_id: $client_id, secret: $secret, company_name: $company_name, is_diligence_attested: $is_diligence_attested, products: $products, create_link_customization: $create_link_customization, logo: $logo, legal_entity_name: $legal_entity_name, website: $website, application_name: $application_name, technical_contact: $technical_contact, billing_contact: $billing_contact, customer_support_info: $customer_support_info, address: $address, is_bank_addendum_completed: $is_bank_addendum_completed, assets_under_management: $assets_under_management, redirect_uris: $redirect_uris, registration_number: $registration_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  end_customer_client_id: string
]: any -> record<end_customer: record<client_id: string, company_name: string, status: string>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/partner/customer/get")
  let body = {client_id: $client_id, secret: $secret, end_customer_client_id: $end_customer_client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  end_customer_client_id: string
]: any -> record<production_secret: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/partner/customer/enable")
  let body = {client_id: $client_id, secret: $secret, end_customer_client_id: $end_customer_client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  end_customer_client_id: string # The `client_id` of the end customer to be removed.
]: any -> record<request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/partner/customer/remove")
  let body = {client_id: $client_id, secret: $secret, end_customer_client_id: $end_customer_client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  end_customer_client_id: string
]: any -> record<flowdown_status: string, questionnaire_status: string, institutions: table<name: string, institution_id: string, environments: record, production_enablement_date: string, classic_disablement_date: string, errors: list>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/partner/customer/oauth_institutions/get")
  let body = {client_id: $client_id, secret: $secret, end_customer_client_id: $end_customer_client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a new end customer for a Plaid reseller.
#
# POST /beta/partner/customer/v1/create
# Docs: /api/partner/#partnercustomercreate
# operationId: betaPartnerCustomerV1Create
# --technical_contact shape: {given_name?: string, family_name?: string, email?: string}
# --billing_contact shape: {given_name?: string, family_name?: string, email?: string}
# --customer_support_info shape: {email?: string, phone_number?: string, contact_url?: string, link_update_url?: string}
# --address shape: {city?: string, street?: string, region?: string, postal_code?: string, country_code?: string}
# --bank_addendum_acceptance shape: {customer_accepted?: bool, customer_ip_address?: string, customer_agreement_timestamp?: string}
# --questionnaires shape: {cra?: record}
export def "beta-partner-customer-create betaPartnerCustomerV1Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  company_name: string # The company name of the end customer being created. This will be used to display the end customer in the Plaid Dashboard. It will not be shown to end users.
  --is-diligence-attested: string@bool-completer # Denotes whether or not the partner has completed attestation of diligence for the end customer to be created.
  --products: list # The products to be enabled for the end customer. If empty or `null`, this field will default to the products enabled for the reseller at the time this endpoint is called.
  --create-link-customization: string@bool-completer # If `true`, the end customer's default Link customization will be set to match the partner's. You can always change the end customer's Link customization in the Plaid Dashboard. See the [Link Customization docs](https://plaid.com/docs/link/customization/) for more information. If you require the ability to programmatically create end customers using multiple different Link customization profiles, contact your Plaid account manager for assistance.  Important: Data Transparency Messaging (DTM) use cases will not be copied to the end customer's Link customization unless the **Publish changes** button is clicked after the use cases are applied. Link will not work in Production unless the end customer's DTM use cases are configured. For more details, see [Data Transparency Messaging](https://plaid.com/docs/link/data-transparency-messaging-migration-guide/).
  --logo: string # Base64-encoded representation of the end customer's logo. Must be a PNG of size 1024x1024 under 4MB. The logo will be shared with financial institutions and shown to the end user during Link flows. A logo is required if `create_link_customization` is `true`. If `create_link_customization` is `false` and the logo is omitted, the partner's logo will be used if one exists, otherwise a stock logo will be used.
  --legal-entity-name: string # The end customer's legal name. This will be shared with financial institutions as part of the OAuth registration process. It will not be shown to end users.
  website: string # The end customer's website.
  application_name: string # The name of the end customer's application. This will be shown to end users when they go through the Plaid Link flow. The application name must be unique and cannot match the name of another application already registered with Plaid.
  --technical-contact: record # The technical contact for the end customer. Defaults to partner's technical contact if omitted. — shape: {given_name?: string, family_name?: string, email?: string}
  --billing-contact: record # The billing contact for the end customer. Defaults to partner's billing contact if omitted. — shape: {given_name?: string, family_name?: string, email?: string}
  customer_support_info: record # This information is public. Users of your app will see this information when managing connections between your app and their bank accounts in Plaid Portal. Defaults to partner's customer support info if omitted. This field is mandatory for partners whose Plaid accounts were created after November 26, 2024 and will be mandatory for all partners by the 1033 compliance deadline. — shape: {email?: string, phone_number?: string, contact_url?: string, link_update_url?: string}
  address: record # The end customer's address. — shape: {city?: string, street?: string, region?: string, postal_code?: string, country_code?: string}
  --redirect-uris: list # A list of URIs indicating the destination(s) where a user can be forwarded after completing the Link flow; used to support OAuth authentication flows when launching Link in the browser or another app. URIs should not contain any query parameters. When used in Production, URIs must use https. To modify redirect URIs for an end customer after creating them, go to the end customer's [API page](https://dashboard.plaid.com/team/api) in the Dashboard.
  --bank-addendum-acceptance: record # The bank addendum acceptance for the end customer. — shape: {customer_accepted?: bool, customer_ip_address?: string, customer_agreement_timestamp?: string}
  --questionnaires: record # The questionnaires for the end customer. — shape: {cra?: record}
]: any -> record<end_customer: record, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beta/partner/customer/v1/create")
  let body = {client_id: $client_id, secret: $secret, company_name: $company_name, is_diligence_attested: $is_diligence_attested, products: $products, create_link_customization: $create_link_customization, logo: $logo, legal_entity_name: $legal_entity_name, website: $website, application_name: $application_name, technical_contact: $technical_contact, billing_contact: $billing_contact, customer_support_info: $customer_support_info, address: $address, redirect_uris: $redirect_uris, bank_addendum_acceptance: $bank_addendum_acceptance, questionnaires: $questionnaires} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the details of a Plaid reseller's end customer.
#
# POST /beta/partner/customer/v1/get
# Docs: /api/partner/#partnercustomerget
# operationId: betaPartnerCustomerV1Get
export def "beta-partner-customer-get betaPartnerCustomerV1Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  end_customer_client_id: string
]: any -> record<end_customer: record<client_id: string, company_name: string, status: string, product_statuses: record, requirements_due: list<string>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beta/partner/customer/v1/get")
  let body = {client_id: $client_id, secret: $secret, end_customer_client_id: $end_customer_client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates an existing end customer.
#
# POST /beta/partner/customer/v1/update
# Docs: /api/partner/#partnercustomercreate
# operationId: betaPartnerCustomerV1Update
# --bank_addendum_acceptance shape: {customer_accepted?: bool, customer_ip_address?: string, customer_agreement_timestamp?: string}
# --questionnaires shape: {cra?: record}
export def "beta-partner-customer-update betaPartnerCustomerV1Update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  end_customer_client_id: string
  --legal-entity-name: string
  --redirect-uris: list
  --bank-addendum-acceptance: record # The bank addendum acceptance for the end customer. — shape: {customer_accepted?: bool, customer_ip_address?: string, customer_agreement_timestamp?: string}
  --questionnaires: record # The questionnaires for the end customer. — shape: {cra?: record}
]: any -> record<end_customer: record<client_id: string, company_name: string, status: string, product_statuses: record, requirements_due: list<string>>, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beta/partner/customer/v1/update")
  let body = {client_id: $client_id, secret: $secret, end_customer_client_id: $end_customer_client_id, legal_entity_name: $legal_entity_name, redirect_uris: $redirect_uris, bank_addendum_acceptance: $bank_addendum_acceptance, questionnaires: $questionnaires} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enables a Plaid reseller's end customer in the Production environment.
#
# POST /beta/partner/customer/v1/enable
# Docs: /api/partner/#partnercustomerenable
# operationId: betaPartnerCustomerV1Enable
export def "beta-partner-customer-enable betaPartnerCustomerV1Enable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  end_customer_client_id: string
  --products: list
]: any -> record<end_customer_client_id: string, status: string, product_statuses: record, production_secret: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/beta/partner/customer/v1/enable")
  let body = {client_id: $client_id, secret: $secret, end_customer_client_id: $end_customer_client_id, products: $products} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Hosted Link session
#
# POST /link_delivery/create
# Docs: /assets/waitlist/hosted-link/
# operationId: linkDeliveryCreate
# --options shape: {recipient?: record}
export def "link-delivery-create linkDeliveryCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  link_token: string # A `link_token` from a previous invocation of `/link/token/create`.
  --options: record # Optional metadata related to the Hosted Link session — shape: {recipient?: record}
]: any -> record<link_delivery_url: string, link_delivery_session_id: string, request_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/link_delivery/create")
  let body = {client_id: $client_id, secret: $secret, link_token: $link_token, options: $options} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Hosted Link session
#
# POST /link_delivery/get
# Docs: /assets/waitlist/hosted-link/
# operationId: linkDeliveryGet
export def "link-delivery-get linkDeliveryGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-id: string # Your Plaid API `client_id`. The `client_id` is required and may be provided either in the `PLAID-CLIENT-ID` header or as part of a request body.
  --secret: string # Your Plaid API `secret`. The `secret` is required and may be provided either in the `PLAID-SECRET` header or as part of a request body.
  link_delivery_session_id: string # The ID for the Hosted Link session from a previous invocation of `/link_delivery/create`.
]: any -> record<status: string, created_at: string, completed_at: string, request_id: string, access_tokens: list<string>, item_ids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/link_delivery/get")
  let body = {client_id: $client_id, secret: $secret, link_delivery_session_id: $link_delivery_session_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Webhook receiver for fdx notifications
#
# POST /fdx/notifications
# Docs: /api/fdx/notifications/#post
# operationId: fdxNotifications
# --publisher shape: {name: string, type: "DATA_ACCESS_PLATFORM"|"DATA_PROVIDER"|"DATA_RECIPIENT"|"INDIVIDUAL"|"MERCHANT"|"VENDOR", homeUri?: string, logoUri?: string, registry?: "FDX"|"GLEIF"|"ICANN"|"PRIVATE", registeredEntityName?: string, registeredEntityId?: string}
# --subscriber shape: {name: string, type: "DATA_ACCESS_PLATFORM"|"DATA_PROVIDER"|"DATA_RECIPIENT"|"INDIVIDUAL"|"MERCHANT"|"VENDOR", homeUri?: string, logoUri?: string, registry?: "FDX"|"GLEIF"|"ICANN"|"PRIVATE", registeredEntityName?: string, registeredEntityId?: string}
# --notificationPayload shape: {id?: string, idType?: "ACCOUNT"|"CUSTOMER"|"PARTY"|"MAINTENANCE"|"CONSENT", event?: record}
# --url shape: {href: string, action?: "GET"|"POST"|"PATCH"|"DELETE"|"PUT", rel?: string, types?: list}
export def "fdx-notifications fdxNotifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  notificationId: string # Id of notification
  type: string@type-completer-4 # Type of Notification
  --subtype: string # An optional initiator-defined event subtype code or description if the event type needs to be further categorized or described.
  sentOn: string # ISO 8601 date-time in format 'YYYY-MM-DDThh:mm:ss.nnn[Z|[+|-]hh:mm]' according to [IETF RFC3339](https://xml2rfc.tools.ietf.org/public/rfc/html/rfc3339.html#anchor14) (format: date-time, e.g. 2021-07-15T14:46:41.375Z)
  category: string@category-completer # Category of Notification
  --severity: string@severity-completer # Severity level of notification
  --priority: string@priority-completer # Priority of notification
  --publisher: record # FDX Participant - an entity or person that is a part of a FDX API transaction — shape: {name: string, type: "DATA_ACCESS_PLATFORM"|"DATA_PROVIDER"|"DATA_RECIPIENT"|"INDIVIDUAL"|"MERCHANT"|"VENDOR", homeUri?: string, logoUri?: string, registry?: "FDX"|"GLEIF"|"ICANN"|"PRIVATE", registeredEntityName?: string, registeredEntityId?: string}
  --subscriber: record # FDX Participant - an entity or person that is a part of a FDX API transaction — shape: {name: string, type: "DATA_ACCESS_PLATFORM"|"DATA_PROVIDER"|"DATA_RECIPIENT"|"INDIVIDUAL"|"MERCHANT"|"VENDOR", homeUri?: string, logoUri?: string, registry?: "FDX"|"GLEIF"|"ICANN"|"PRIVATE", registeredEntityName?: string, registeredEntityId?: string}
  notificationPayload: record # Custom key-value pairs payload for a notification — shape: {id?: string, idType?: "ACCOUNT"|"CUSTOMER"|"PARTY"|"MAINTENANCE"|"CONSENT", event?: record}
  --body-url: record # REST application constraint (Hypermedia As The Engine Of Application State) — shape: {href: string, action?: "GET"|"POST"|"PATCH"|"DELETE"|"PUT", rel?: string, types?: list}
]: any -> record<error_type: string, error_code: string, error_code_reason: string, error_message: string, display_message: string, request_id: string, causes: list<any>, status: int, documentation_url: string, suggested_action: string, required_account_subtypes: list<string>, provided_account_subtypes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fdx/notifications")
  let body = {notificationId: $notificationId, type: $type, subtype: $subtype, sentOn: $sentOn, category: $category, severity: $severity, priority: $priority, publisher: $publisher, subscriber: $subscriber, notificationPayload: $notificationPayload, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Recipients
#
# GET /fdx/recipients
# operationId: getRecipients
export def "fdx-recipients get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<recipients: table<recipient_id: string, client_name: string, logo_uri: string, third_party_legal_name: string, category: string, joined_date: string, connection_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fdx/recipients")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get FDX Consent Grant
#
# GET /fdx/consents/{consentId}
# operationId: fdxConsentGet
export def "fdx-consents fdxConsentGet" [
  consentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, status: string, createdTime: string, updatedTime: string, expirationTime: string, parties: table<name: string, type: string, homeUri: string, logoUri: string, registry: string, registeredEntityName: string, registeredEntityId: string>, resources: table<resourceType: string, resourceId: string, dataClusters: list>> {
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fdx/consents/($consentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Recipient
#
# GET /fdx/recipient/{recipientId}
# operationId: getRecipient
export def "fdx-recipient get" [
  recipientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --OAUTH-STATE-ID: string # The value that is passed into the OAuth URI 'state' query parameter.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "plaid-client-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/fdx/recipient/($recipientId)")
  let extra_headers = {"OAUTH-STATE-ID": $OAUTH_STATE_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
