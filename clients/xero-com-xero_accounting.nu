# Auto-generated client for Xero Accounting API v2.9.4
# Source: https://api.apis.guru/v2/specs/xero.com/xero_accounting/2.9.4/openapi.json
# Auth: --token flag or $env.XERO_ACCOUNTING_API_TOKEN

const BASE_URL = "https://api.xero.com/api.xro/2.0"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o XERO_ACCOUNTING_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://api.xero.com/api.xro/2.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def bank-account-type-completer [] { ["" "BANK" "CREDITCARD" "NONE" "PAYPAL"] }
def currency-code-completer [] { ["" "AED" "AFN" "ALL" "AMD" "ANG" "AOA" "ARS" "AUD" "AWG" "AZN" "BAM" "BBD" "BDT" "BGN" "BHD" "BIF" "BMD" "BND" "BOB" "BRL" "BSD" "BTN" "BWP" "BYN" "BYR" "BZD" "CAD" "CDF" "CHF" "CLP" "CNY" "COP" "CRC" "CUC" "CUP" "CVE" "CZK" "DJF" "DKK" "DOP" "DZD" "EGP" "ERN" "ETB" "EUR" "FJD" "FKP" "GBP" "GEL" "GGP" "GHS" "GIP" "GMD" "GNF" "GTQ" "GYD" "HKD" "HNL" "HRK" "HTG" "HUF" "IDR" "ILS" "IMP" "INR" "IQD" "IRR" "ISK" "JEP" "JMD" "JOD" "JPY" "KES" "KGS" "KHR" "KMF" "KPW" "KRW" "KWD" "KYD" "KZT" "LAK" "LBP" "LKR" "LRD" "LSL" "LTL" "LYD" "MAD" "MDL" "MGA" "MKD" "MMK" "MNT" "MOP" "MRU" "MUR" "MVR" "MWK" "MXN" "MYR" "MZN" "NAD" "NGN" "NIO" "NOK" "NPR" "NZD" "OMR" "PAB" "PEN" "PGK" "PHP" "PKR" "PLN" "PYG" "QAR" "RON" "RSD" "RUB" "RWF" "SAR" "SBD" "SCR" "SDG" "SEK" "SGD" "SHP" "SLL" "SOS" "SPL" "SRD" "STN" "SVC" "SYP" "SZL" "THB" "TJS" "TMT" "TND" "TOP" "TRY" "TTD" "TVD" "TWD" "TZS" "UAH" "UGX" "USD" "UYU" "UZS" "VEF" "VND" "VUV" "WST" "XAF" "XCD" "XDR" "XOF" "XPF" "YER" "ZAR" "ZMK" "ZMW" "ZWD"] }
def status-completer [] { ["ACTIVE" "ARCHIVED" "DELETED"] }
def type-completer [] { ["BANK" "CURRENT" "CURRLIAB" "DEPRECIATN" "DIRECTCOSTS" "EQUITY" "EXPENSE" "FIXED" "INVENTORY" "LIABILITY" "NONCURRENT" "OTHERINCOME" "OVERHEADS" "PAYG" "PAYGLIABILITY" "PREPAYMENT" "REVENUE" "SALES" "SUPERANNUATIONEXPENSE" "SUPERANNUATIONLIABILITY" "TERMLIAB" "WAGESEXPENSE"] }
def code-completer [] { ["" "AED" "AFN" "ALL" "AMD" "ANG" "AOA" "ARS" "AUD" "AWG" "AZN" "BAM" "BBD" "BDT" "BGN" "BHD" "BIF" "BMD" "BND" "BOB" "BRL" "BSD" "BTN" "BWP" "BYN" "BYR" "BZD" "CAD" "CDF" "CHF" "CLP" "CNY" "COP" "CRC" "CUC" "CUP" "CVE" "CZK" "DJF" "DKK" "DOP" "DZD" "EGP" "ERN" "ETB" "EUR" "FJD" "FKP" "GBP" "GEL" "GGP" "GHS" "GIP" "GMD" "GNF" "GTQ" "GYD" "HKD" "HNL" "HRK" "HTG" "HUF" "IDR" "ILS" "IMP" "INR" "IQD" "IRR" "ISK" "JEP" "JMD" "JOD" "JPY" "KES" "KGS" "KHR" "KMF" "KPW" "KRW" "KWD" "KYD" "KZT" "LAK" "LBP" "LKR" "LRD" "LSL" "LTL" "LYD" "MAD" "MDL" "MGA" "MKD" "MMK" "MNT" "MOP" "MRU" "MUR" "MVR" "MWK" "MXN" "MYR" "MZN" "NAD" "NGN" "NIO" "NOK" "NPR" "NZD" "OMR" "PAB" "PEN" "PGK" "PHP" "PKR" "PLN" "PYG" "QAR" "RON" "RSD" "RUB" "RWF" "SAR" "SBD" "SCR" "SDG" "SEK" "SGD" "SHP" "SLL" "SOS" "SPL" "SRD" "STN" "SVC" "SYP" "SZL" "THB" "TJS" "TMT" "TND" "TOP" "TRY" "TTD" "TVD" "TWD" "TZS" "UAH" "UGX" "USD" "UYU" "UZS" "VEF" "VND" "VUV" "WST" "XAF" "XCD" "XDR" "XOF" "XPF" "YER" "ZAR" "ZMK" "ZMW" "ZWD"] }
def source-transaction-type-code-completer [] { ["ACCPAY" "SPEND"] }
def status-completer-1 [] { ["APPROVED" "BILLED" "DRAFT" "ONDRAFT" "VOIDED"] }
def type-completer-1 [] { ["BILLABLEEXPENSE"] }
def status-completer-2 [] { ["AUTHORISED" "DELETED"] }
def status-completer-3 [] { ["AUTHORISED" "BILLED" "DELETED" "DRAFT" "SUBMITTED"] }
def timeframe-completer [] { ["MONTH" "QUARTER" "YEAR"] }

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

# Retrieves the full chart of accounts
#
# GET /Accounts
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
  --qp-where: string # Filter by an any element (e.g. Status==&quot;ACTIVE&quot; AND Type==&quot;BANK&quot;)
  --order: string # Order by an any element (e.g. Name ASC)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Accounts: table<AccountID: string, AddToWatchlist: bool, BankAccountNumber: string, BankAccountType: string, Class: string, Code: string, CurrencyCode: string, Description: string, EnablePaymentsToAccount: bool, HasAttachments: bool, Name: string, ReportingCode: string, ReportingCodeName: string, ShowInExpenseClaims: bool, Status: string, SystemAccount: string, TaxType: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a new chart of accounts
#
# PUT /Accounts
# operationId: createAccount
# --ValidationErrors item shape: {Message?: string}
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
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --account-id: string # The Xero identifier for an account – specified as a string following the endpoint name e.g. /297c2dc5-cc47-4afd-8ec8-74990b8761e9 (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --add-to-watchlist: oneof<nothing, bool> # Boolean – describes whether the account is shown in the watchlist widget on the dashboard
  --bank-account-number: string # For bank accounts only (Account Type BANK)
  --bank-account-type: string@bank-account-type-completer # For bank accounts only. See Bank Account types
  --code: string # Customer defined alpha numeric account code e.g 200 or SALES (max length = 10) (e.g. 4400)
  --currency-code: string@currency-code-completer # 3 letter alpha code for the currency – see list of currency codes
  --description: string # Description of the Account. Valid for all types of accounts except bank accounts (max length = 4000)
  --enable-payments-to-account: oneof<nothing, bool> # Boolean – describes whether account can have payments applied to it
  --name: string # Name of account (max length = 150) (e.g. Food Sales)
  --reporting-code: string # Shown if set
  --show-in-expense-claims: oneof<nothing, bool> # Boolean – describes whether account code is available for use with expense claims
  --status: string@status-completer # Accounts with a status of ACTIVE can be updated to ARCHIVED. See Account Status Codes
  --tax-type: string # The tax type from TaxRates
  --type: string@type-completer # See Account Types
  --validation-errors: list # Displays array of validation error messages from the API — item shape: {Message?: string}
]: any -> record<Accounts: table<AccountID: string, AddToWatchlist: bool, BankAccountNumber: string, BankAccountType: string, Class: string, Code: string, CurrencyCode: string, Description: string, EnablePaymentsToAccount: bool, HasAttachments: bool, Name: string, ReportingCode: string, ReportingCodeName: string, ShowInExpenseClaims: bool, Status: string, SystemAccount: string, TaxType: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Accounts")
  let req_body = {"AccountID": $account_id, "AddToWatchlist": $add_to_watchlist, "BankAccountNumber": $bank_account_number, "BankAccountType": $bank_account_type, "Code": $code, "CurrencyCode": $currency_code, "Description": $description, "EnablePaymentsToAccount": $enable_payments_to_account, "Name": $name, "ReportingCode": $reporting_code, "ShowInExpenseClaims": $show_in_expense_claims, "Status": $status, "TaxType": $tax_type, "Type": $type, "ValidationErrors": $validation_errors} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a chart of accounts
#
# DELETE /Accounts/{AccountID}
# operationId: deleteAccount
export def "accounts delete" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Accounts: table<AccountID: string, AddToWatchlist: bool, BankAccountNumber: string, BankAccountType: string, Class: string, Code: string, CurrencyCode: string, Description: string, EnablePaymentsToAccount: bool, HasAttachments: bool, Name: string, ReportingCode: string, ReportingCodeName: string, ShowInExpenseClaims: bool, Status: string, SystemAccount: string, TaxType: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/Accounts/{account_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a single chart of accounts by using a unique account Id
#
# GET /Accounts/{AccountID}
# operationId: getAccount
export def "accounts get" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Accounts: table<AccountID: string, AddToWatchlist: bool, BankAccountNumber: string, BankAccountType: string, Class: string, Code: string, CurrencyCode: string, Description: string, EnablePaymentsToAccount: bool, HasAttachments: bool, Name: string, ReportingCode: string, ReportingCodeName: string, ShowInExpenseClaims: bool, Status: string, SystemAccount: string, TaxType: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/Accounts/{account_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a chart of accounts
#
# POST /Accounts/{AccountID}
# operationId: updateAccount
# --Accounts item shape: {AccountID?: string, AddToWatchlist?: bool, BankAccountNumber?: string, BankAccountType?: "BANK"|"CREDITCARD"|"PAYPAL"|"NONE"|"", Code?: string, ... (10 more fields)}
export def "accounts update" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --accounts: list # item shape: {AccountID?: string, AddToWatchlist?: bool, BankAccountNumber?: string, BankAccountType?: "BANK"|"CREDITCARD"|"PAYPAL"|"NONE"|"", Code?: string, ... (10 more fields)}
]: any -> record<Accounts: table<AccountID: string, AddToWatchlist: bool, BankAccountNumber: string, BankAccountType: string, Class: string, Code: string, CurrencyCode: string, Description: string, EnablePaymentsToAccount: bool, HasAttachments: bool, Name: string, ReportingCode: string, ReportingCodeName: string, ShowInExpenseClaims: bool, Status: string, SystemAccount: string, TaxType: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/Accounts/{account_id}"))
  let req_body = {"Accounts": $accounts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves attachments for a specific accounts by using a unique account Id
#
# GET /Accounts/{AccountID}/Attachments
# operationId: getAccountAttachments
export def "accounts-attachments list" [
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/Accounts/{account_id}/Attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific attachment from a specific account using a unique attachment Id
#
# GET /Accounts/{AccountID}/Attachments/{AttachmentID}
# operationId: getAccountAttachmentById
export def "accounts-attachments get" [
  account_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/Accounts/{account_id}/Attachments/{attachment_id}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves an attachment for a specific account by filename
#
# GET /Accounts/{AccountID}/Attachments/{FileName}
# operationId: getAccountAttachmentByFileName
export def "accounts-attachments get-by-file-name" [
  account_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), file_name: (encode-path-segment $file_name)} | format pattern "/Accounts/{account_id}/Attachments/{file_name}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates attachment on a specific account by filename
#
# POST /Accounts/{AccountID}/Attachments/{FileName}
# operationId: updateAccountAttachmentByFileName
export def "accounts-attachments update-by-file-name" [
  account_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), file_name: (encode-path-segment $file_name)} | format pattern "/Accounts/{account_id}/Attachments/{file_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# Creates an attachment on a specific account
#
# PUT /Accounts/{AccountID}/Attachments/{FileName}
# operationId: createAccountAttachmentByFileName
export def "accounts-attachments create-by-file-name" [
  account_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id), file_name: (encode-path-segment $file_name)} | format pattern "/Accounts/{account_id}/Attachments/{file_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# Retrieves any spent or received money transactions
#
# GET /BankTransactions
# operationId: getBankTransactions
export def "bank-transactions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="AUTHORISED")
  --order: string # Order by an any element (e.g. Type ASC)
  --page: int # Up to 100 bank transactions will be returned in a single API call with line items details (e.g. 1)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<BankTransactions: table<BankAccount: record, BankTransactionID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, IsReconciled: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, PrepaymentID: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/BankTransactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates or creates one or more spent or received money transaction
#
# POST /BankTransactions
# operationId: updateOrCreateBankTransactions
# --BankTransactions item shape: {BankAccount: record, BankTransactionID?: string, Contact?: record, ... (15 more fields)}
export def "bank-transactions update-or-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --bank-transactions: list # item shape: {BankAccount: record, BankTransactionID?: string, Contact?: record, ... (15 more fields)}
]: any -> record<BankTransactions: table<BankAccount: record, BankTransactionID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, IsReconciled: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, PrepaymentID: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/BankTransactions" $qp)
  let req_body = {"BankTransactions": $bank_transactions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates one or more spent or received money transaction
#
# PUT /BankTransactions
# operationId: createBankTransactions
# --BankTransactions item shape: {BankAccount: record, BankTransactionID?: string, Contact?: record, ... (15 more fields)}
export def "bank-transactions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --bank-transactions: list # item shape: {BankAccount: record, BankTransactionID?: string, Contact?: record, ... (15 more fields)}
]: any -> record<BankTransactions: table<BankAccount: record, BankTransactionID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, IsReconciled: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, PrepaymentID: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/BankTransactions" $qp)
  let req_body = {"BankTransactions": $bank_transactions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves a single spent or received money transaction by using a unique bank transaction Id
#
# GET /BankTransactions/{BankTransactionID}
# operationId: getBankTransaction
export def "bank-transactions get" [
  bank_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
]: nothing -> record<BankTransactions: table<BankAccount: record, BankTransactionID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, IsReconciled: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, PrepaymentID: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bank_transaction_id: (encode-path-segment $bank_transaction_id)} | format pattern "/BankTransactions/{bank_transaction_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a single spent or received money transaction
#
# POST /BankTransactions/{BankTransactionID}
# operationId: updateBankTransaction
# --BankTransactions item shape: {BankAccount: record, BankTransactionID?: string, Contact?: record, ... (15 more fields)}
export def "bank-transactions update" [
  bank_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --bank-transactions: list # item shape: {BankAccount: record, BankTransactionID?: string, Contact?: record, ... (15 more fields)}
]: any -> record<BankTransactions: table<BankAccount: record, BankTransactionID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, IsReconciled: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, PrepaymentID: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({bank_transaction_id: (encode-path-segment $bank_transaction_id)} | format pattern "/BankTransactions/{bank_transaction_id}") $qp)
  let req_body = {"BankTransactions": $bank_transactions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves any attachments from a specific bank transactions
#
# GET /BankTransactions/{BankTransactionID}/Attachments
# operationId: getBankTransactionAttachments
export def "bank-transactions-attachments list" [
  bank_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bank_transaction_id: (encode-path-segment $bank_transaction_id)} | format pattern "/BankTransactions/{bank_transaction_id}/Attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves specific attachments from a specific BankTransaction using a unique attachment Id
#
# GET /BankTransactions/{BankTransactionID}/Attachments/{AttachmentID}
# operationId: getBankTransactionAttachmentById
export def "bank-transactions-attachments get" [
  bank_transaction_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bank_transaction_id: (encode-path-segment $bank_transaction_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/BankTransactions/{bank_transaction_id}/Attachments/{attachment_id}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific attachment from a specific bank transaction by filename
#
# GET /BankTransactions/{BankTransactionID}/Attachments/{FileName}
# operationId: getBankTransactionAttachmentByFileName
export def "bank-transactions-attachments get-by-file-name" [
  bank_transaction_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bank_transaction_id: (encode-path-segment $bank_transaction_id), file_name: (encode-path-segment $file_name)} | format pattern "/BankTransactions/{bank_transaction_id}/Attachments/{file_name}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a specific attachment from a specific bank transaction by filename
#
# POST /BankTransactions/{BankTransactionID}/Attachments/{FileName}
# operationId: updateBankTransactionAttachmentByFileName
export def "bank-transactions-attachments update-by-file-name" [
  bank_transaction_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bank_transaction_id: (encode-path-segment $bank_transaction_id), file_name: (encode-path-segment $file_name)} | format pattern "/BankTransactions/{bank_transaction_id}/Attachments/{file_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# Creates an attachment for a specific bank transaction by filename
#
# PUT /BankTransactions/{BankTransactionID}/Attachments/{FileName}
# operationId: createBankTransactionAttachmentByFileName
export def "bank-transactions-attachments create-by-file-name" [
  bank_transaction_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bank_transaction_id: (encode-path-segment $bank_transaction_id), file_name: (encode-path-segment $file_name)} | format pattern "/BankTransactions/{bank_transaction_id}/Attachments/{file_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# Retrieves history from a specific bank transaction using a unique bank transaction Id
#
# GET /BankTransactions/{BankTransactionID}/History
# operationId: getBankTransactionsHistory
export def "bank-transactions-history get" [
  bank_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bank_transaction_id: (encode-path-segment $bank_transaction_id)} | format pattern "/BankTransactions/{bank_transaction_id}/History"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a history record for a specific bank transactions
#
# PUT /BankTransactions/{BankTransactionID}/History
# operationId: createBankTransactionHistoryRecord
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "bank-transactions-history create-record" [
  bank_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bank_transaction_id: (encode-path-segment $bank_transaction_id)} | format pattern "/BankTransactions/{bank_transaction_id}/History"))
  let req_body = {"HistoryRecords": $history_records} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves all bank transfers
#
# GET /BankTransfers
# operationId: getBankTransfers
export def "bank-transfers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. HasAttachments==true)
  --order: string # Order by an any element (e.g. Amount ASC)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<BankTransfers: table<Amount: float, BankTransferID: string, CreatedDateUTC: string, CurrencyRate: float, Date: string, FromBankAccount: record, FromBankTransactionID: string, HasAttachments: bool, ToBankAccount: record, ToBankTransactionID: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/BankTransfers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a bank transfer
#
# PUT /BankTransfers
# operationId: createBankTransfer
# --BankTransfers item shape: {Amount: float, Date?: string, FromBankAccount: record, ToBankAccount: record, ValidationErrors?: list}
export def "bank-transfers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --bank-transfers: list # item shape: {Amount: float, Date?: string, FromBankAccount: record, ToBankAccount: record, ValidationErrors?: list}
]: any -> record<BankTransfers: table<Amount: float, BankTransferID: string, CreatedDateUTC: string, CurrencyRate: float, Date: string, FromBankAccount: record, FromBankTransactionID: string, HasAttachments: bool, ToBankAccount: record, ToBankTransactionID: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/BankTransfers")
  let req_body = {"BankTransfers": $bank_transfers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves specific bank transfers by using a unique bank transfer Id
#
# GET /BankTransfers/{BankTransferID}
# operationId: getBankTransfer
export def "bank-transfers get" [
  bank_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<BankTransfers: table<Amount: float, BankTransferID: string, CreatedDateUTC: string, CurrencyRate: float, Date: string, FromBankAccount: record, FromBankTransactionID: string, HasAttachments: bool, ToBankAccount: record, ToBankTransactionID: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bank_transfer_id: (encode-path-segment $bank_transfer_id)} | format pattern "/BankTransfers/{bank_transfer_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves attachments from a specific bank transfer
#
# GET /BankTransfers/{BankTransferID}/Attachments
# operationId: getBankTransferAttachments
export def "bank-transfers-attachments list" [
  bank_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bank_transfer_id: (encode-path-segment $bank_transfer_id)} | format pattern "/BankTransfers/{bank_transfer_id}/Attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific attachment from a specific bank transfer using a unique attachment ID
#
# GET /BankTransfers/{BankTransferID}/Attachments/{AttachmentID}
# operationId: getBankTransferAttachmentById
export def "bank-transfers-attachments get" [
  bank_transfer_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bank_transfer_id: (encode-path-segment $bank_transfer_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/BankTransfers/{bank_transfer_id}/Attachments/{attachment_id}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific attachment on a specific bank transfer by file name
#
# GET /BankTransfers/{BankTransferID}/Attachments/{FileName}
# operationId: getBankTransferAttachmentByFileName
export def "bank-transfers-attachments get-by-file-name" [
  bank_transfer_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bank_transfer_id: (encode-path-segment $bank_transfer_id), file_name: (encode-path-segment $file_name)} | format pattern "/BankTransfers/{bank_transfer_id}/Attachments/{file_name}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# POST /BankTransfers/{BankTransferID}/Attachments/{FileName}
#
# operationId: updateBankTransferAttachmentByFileName
export def "bank-transfers-attachments update-by-file-name" [
  bank_transfer_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bank_transfer_id: (encode-path-segment $bank_transfer_id), file_name: (encode-path-segment $file_name)} | format pattern "/BankTransfers/{bank_transfer_id}/Attachments/{file_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# PUT /BankTransfers/{BankTransferID}/Attachments/{FileName}
#
# operationId: createBankTransferAttachmentByFileName
export def "bank-transfers-attachments create-by-file-name" [
  bank_transfer_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bank_transfer_id: (encode-path-segment $bank_transfer_id), file_name: (encode-path-segment $file_name)} | format pattern "/BankTransfers/{bank_transfer_id}/Attachments/{file_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# Retrieves history from a specific bank transfer using a unique bank transfer Id
#
# GET /BankTransfers/{BankTransferID}/History
# operationId: getBankTransferHistory
export def "bank-transfers-history get" [
  bank_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bank_transfer_id: (encode-path-segment $bank_transfer_id)} | format pattern "/BankTransfers/{bank_transfer_id}/History"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a history record for a specific bank transfer
#
# PUT /BankTransfers/{BankTransferID}/History
# operationId: createBankTransferHistoryRecord
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "bank-transfers-history create-record" [
  bank_transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({bank_transfer_id: (encode-path-segment $bank_transfer_id)} | format pattern "/BankTransfers/{bank_transfer_id}/History"))
  let req_body = {"HistoryRecords": $history_records} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves either one or many batch payments for invoices
#
# GET /BatchPayments
# operationId: getBatchPayments
export def "batch-payments get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="AUTHORISED")
  --order: string # Order by an any element (e.g. Date ASC)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<BatchPayments: table<Account: record, Amount: float, BatchPaymentID: string, Code: string, Date: string, DateString: string, Details: string, IsReconciled: string, Narrative: string, Particulars: string, Payments: list, Reference: string, Status: string, TotalAmount: string, Type: string, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/BatchPayments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates one or many batch payments for invoices
#
# PUT /BatchPayments
# operationId: createBatchPayment
# --BatchPayments item shape: {Account?: record, Amount?: float, Code?: string, Date?: string, DateString?: string, Details?: string, Narrative?: string, Particulars?: string, Payments?: list, Reference?: string}
export def "batch-payments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --batch-payments: list # item shape: {Account?: record, Amount?: float, Code?: string, Date?: string, DateString?: string, Details?: string, Narrative?: string, Particulars?: string, Payments?: list, Reference?: string}
]: any -> record<BatchPayments: table<Account: record, Amount: float, BatchPaymentID: string, Code: string, Date: string, DateString: string, Details: string, IsReconciled: string, Narrative: string, Particulars: string, Payments: list, Reference: string, Status: string, TotalAmount: string, Type: string, UpdatedDateUTC: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/BatchPayments" $qp)
  let req_body = {"BatchPayments": $batch_payments} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves history from a specific batch payment
#
# GET /BatchPayments/{BatchPaymentID}/History
# operationId: getBatchPaymentHistory
export def "batch-payments-history get" [
  batch_payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({batch_payment_id: (encode-path-segment $batch_payment_id)} | format pattern "/BatchPayments/{batch_payment_id}/History"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a history record for a specific batch payment
#
# PUT /BatchPayments/{BatchPaymentID}/History
# operationId: createBatchPaymentHistoryRecord
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "batch-payments-history create-record" [
  batch_payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({batch_payment_id: (encode-path-segment $batch_payment_id)} | format pattern "/BatchPayments/{batch_payment_id}/History"))
  let req_body = {"HistoryRecords": $history_records} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves all the branding themes
#
# GET /BrandingThemes
# operationId: getBrandingThemes
export def "branding-themes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<BrandingThemes: table<BrandingThemeID: string, CreatedDateUTC: string, LogoUrl: string, Name: string, SortOrder: int, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/BrandingThemes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific branding theme using a unique branding theme Id
#
# GET /BrandingThemes/{BrandingThemeID}
# operationId: getBrandingTheme
export def "branding-themes get" [
  branding_theme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<BrandingThemes: table<BrandingThemeID: string, CreatedDateUTC: string, LogoUrl: string, Name: string, SortOrder: int, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({branding_theme_id: (encode-path-segment $branding_theme_id)} | format pattern "/BrandingThemes/{branding_theme_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the payment services for a specific branding theme
#
# GET /BrandingThemes/{BrandingThemeID}/PaymentServices
# operationId: getBrandingThemePaymentServices
export def "branding-themes-payment-services get" [
  branding_theme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<PaymentServices: table<PayNowText: string, PaymentServiceID: string, PaymentServiceName: string, PaymentServiceType: string, PaymentServiceUrl: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({branding_theme_id: (encode-path-segment $branding_theme_id)} | format pattern "/BrandingThemes/{branding_theme_id}/PaymentServices"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a new custom payment service for a specific branding theme
#
# POST /BrandingThemes/{BrandingThemeID}/PaymentServices
# operationId: createBrandingThemePaymentServices
# --ValidationErrors item shape: {Message?: string}
export def "branding-themes-payment-services create" [
  branding_theme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --pay-now-text: string # The text displayed on the Pay Now button in Xero Online Invoicing. If this is not set it will default to Pay by credit card
  --payment-service-id: string # Xero identifier (format: uuid)
  --payment-service-name: string # Name of payment service
  --payment-service-type: string # This will always be CUSTOM for payment services created via the API.
  --payment-service-url: string # The custom payment URL
  --validation-errors: list # Displays array of validation error messages from the API — item shape: {Message?: string}
]: any -> record<PaymentServices: table<PayNowText: string, PaymentServiceID: string, PaymentServiceName: string, PaymentServiceType: string, PaymentServiceUrl: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({branding_theme_id: (encode-path-segment $branding_theme_id)} | format pattern "/BrandingThemes/{branding_theme_id}/PaymentServices"))
  let req_body = {"PayNowText": $pay_now_text, "PaymentServiceID": $payment_service_id, "PaymentServiceName": $payment_service_name, "PaymentServiceType": $payment_service_type, "PaymentServiceUrl": $payment_service_url, "ValidationErrors": $validation_errors} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves the contact Id and name of all the contacts in a contact group
#
# GET /ContactGroups
# operationId: getContactGroups
export def "contact-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="ACTIVE")
  --order: string # Order by an any element (e.g. Name ASC)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<ContactGroups: table<ContactGroupID: string, Contacts: list, Name: string, Status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ContactGroups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a contact group
#
# PUT /ContactGroups
# operationId: createContactGroup
# --ContactGroups item shape: {ContactGroupID?: string, Contacts?: list, Name?: string, Status?: "ACTIVE"|"DELETED"}
export def "contact-groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contact-groups: list # item shape: {ContactGroupID?: string, Contacts?: list, Name?: string, Status?: "ACTIVE"|"DELETED"}
]: any -> record<ContactGroups: table<ContactGroupID: string, Contacts: list, Name: string, Status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ContactGroups")
  let req_body = {"ContactGroups": $contact_groups} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves a specific contact group by using a unique contact group Id
#
# GET /ContactGroups/{ContactGroupID}
# operationId: getContactGroup
export def "contact-groups get" [
  contact_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<ContactGroups: table<ContactGroupID: string, Contacts: list, Name: string, Status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_group_id: (encode-path-segment $contact_group_id)} | format pattern "/ContactGroups/{contact_group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a specific contact group
#
# POST /ContactGroups/{ContactGroupID}
# operationId: updateContactGroup
# --ContactGroups item shape: {ContactGroupID?: string, Contacts?: list, Name?: string, Status?: "ACTIVE"|"DELETED"}
export def "contact-groups update" [
  contact_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contact-groups: list # item shape: {ContactGroupID?: string, Contacts?: list, Name?: string, Status?: "ACTIVE"|"DELETED"}
]: any -> record<ContactGroups: table<ContactGroupID: string, Contacts: list, Name: string, Status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_group_id: (encode-path-segment $contact_group_id)} | format pattern "/ContactGroups/{contact_group_id}"))
  let req_body = {"ContactGroups": $contact_groups} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes all contacts from a specific contact group
#
# DELETE /ContactGroups/{ContactGroupID}/Contacts
# operationId: deleteContactGroupContacts
export def "contact-groups-contacts delete-by-ContactGroupID" [
  contact_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_group_id: (encode-path-segment $contact_group_id)} | format pattern "/ContactGroups/{contact_group_id}/Contacts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates contacts to a specific contact group
#
# PUT /ContactGroups/{ContactGroupID}/Contacts
# operationId: createContactGroupContacts
# --Contacts item shape: {AccountNumber?: string, AccountsPayableTaxType?: string, AccountsReceivableTaxType?: string, Addresses?: list, Attachments?: list, Balances?: record, BankAccountDetails?: string, BatchPayments?: any, BrandingTheme?: record, ContactGroups?: list, ContactID?: string, ContactNumber?: string, ContactPersons?: list, ContactStatus?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST", ... (22 more fields)}
export def "contact-groups-contacts create" [
  contact_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contacts: list # item shape: {AccountNumber?: string, AccountsPayableTaxType?: string, AccountsReceivableTaxType?: string, Addresses?: list, Attachments?: list, Balances?: record, BankAccountDetails?: string, BatchPayments?: any, BrandingTheme?: record, ContactGroups?: list, ContactID?: string, ContactNumber?: string, ContactPersons?: list, ContactStatus?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST", ... (22 more fields)}
]: any -> record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_group_id: (encode-path-segment $contact_group_id)} | format pattern "/ContactGroups/{contact_group_id}/Contacts"))
  let req_body = {"Contacts": $contacts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a specific contact from a contact group using a unique contact Id
#
# DELETE /ContactGroups/{ContactGroupID}/Contacts/{ContactID}
# operationId: deleteContactGroupContact
export def "contact-groups-contacts delete-by-ContactGroupID-ContactID" [
  contact_group_id: string
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_group_id: (encode-path-segment $contact_group_id), contact_id: (encode-path-segment $contact_id)} | format pattern "/ContactGroups/{contact_group_id}/Contacts/{contact_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves all contacts in a Xero organisation
#
# GET /Contacts
# operationId: getContacts
export def "contacts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. ContactStatus==&quot;ACTIVE&quot;)
  --order: string # Order by an any element (e.g. Name ASC)
  --i-ds: list<string> # Filter by a comma separated list of ContactIDs. Allows you to retrieve a specific set of contacts in a single call. (e.g. &quot;00000000-0000-0000-0000-000000000000&quot;)
  --page: int # e.g. page=1 - Up to 100 contacts will be returned in a single API call. (e.g. 1)
  --include-archived: oneof<nothing, bool> # e.g. includeArchived=true - Contacts with a status of ARCHIVED will be included in the response
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "IDs" $i_ds "csv") (serialize-qp "page" $page "scalar") (serialize-qp "includeArchived" $include_archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates or creates one or more contacts in a Xero organisation
#
# POST /Contacts
# operationId: updateOrCreateContacts
# --Contacts item shape: {AccountNumber?: string, AccountsPayableTaxType?: string, AccountsReceivableTaxType?: string, Addresses?: list, Attachments?: list, Balances?: record, BankAccountDetails?: string, BatchPayments?: any, BrandingTheme?: record, ContactGroups?: list, ContactID?: string, ContactNumber?: string, ContactPersons?: list, ContactStatus?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST", ... (22 more fields)}
export def "contacts update-or-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --contacts: list # item shape: {AccountNumber?: string, AccountsPayableTaxType?: string, AccountsReceivableTaxType?: string, Addresses?: list, Attachments?: list, Balances?: record, BankAccountDetails?: string, BatchPayments?: any, BrandingTheme?: record, ContactGroups?: list, ContactID?: string, ContactNumber?: string, ContactPersons?: list, ContactStatus?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST", ... (22 more fields)}
]: any -> record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Contacts" $qp)
  let req_body = {"Contacts": $contacts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates multiple contacts (bulk) in a Xero organisation
#
# PUT /Contacts
# operationId: createContacts
# --Contacts item shape: {AccountNumber?: string, AccountsPayableTaxType?: string, AccountsReceivableTaxType?: string, Addresses?: list, Attachments?: list, Balances?: record, BankAccountDetails?: string, BatchPayments?: any, BrandingTheme?: record, ContactGroups?: list, ContactID?: string, ContactNumber?: string, ContactPersons?: list, ContactStatus?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST", ... (22 more fields)}
export def "contacts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --contacts: list # item shape: {AccountNumber?: string, AccountsPayableTaxType?: string, AccountsReceivableTaxType?: string, Addresses?: list, Attachments?: list, Balances?: record, BankAccountDetails?: string, BatchPayments?: any, BrandingTheme?: record, ContactGroups?: list, ContactID?: string, ContactNumber?: string, ContactPersons?: list, ContactStatus?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST", ... (22 more fields)}
]: any -> record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Contacts" $qp)
  let req_body = {"Contacts": $contacts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves a specific contacts in a Xero organisation using a unique contact Id
#
# GET /Contacts/{ContactID}
# operationId: getContact
export def "contacts get" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id)} | format pattern "/Contacts/{contact_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a specific contact in a Xero organisation
#
# POST /Contacts/{ContactID}
# operationId: updateContact
# --Contacts item shape: {AccountNumber?: string, AccountsPayableTaxType?: string, AccountsReceivableTaxType?: string, Addresses?: list, Attachments?: list, Balances?: record, BankAccountDetails?: string, BatchPayments?: any, BrandingTheme?: record, ContactGroups?: list, ContactID?: string, ContactNumber?: string, ContactPersons?: list, ContactStatus?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST", ... (22 more fields)}
export def "contacts update" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contacts: list # item shape: {AccountNumber?: string, AccountsPayableTaxType?: string, AccountsReceivableTaxType?: string, Addresses?: list, Attachments?: list, Balances?: record, BankAccountDetails?: string, BatchPayments?: any, BrandingTheme?: record, ContactGroups?: list, ContactID?: string, ContactNumber?: string, ContactPersons?: list, ContactStatus?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST", ... (22 more fields)}
]: any -> record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id)} | format pattern "/Contacts/{contact_id}"))
  let req_body = {"Contacts": $contacts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves attachments for a specific contact in a Xero organisation
#
# GET /Contacts/{ContactID}/Attachments
# operationId: getContactAttachments
export def "contacts-attachments list" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id)} | format pattern "/Contacts/{contact_id}/Attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific attachment from a specific contact using a unique attachment Id
#
# GET /Contacts/{ContactID}/Attachments/{AttachmentID}
# operationId: getContactAttachmentById
export def "contacts-attachments get" [
  contact_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/Contacts/{contact_id}/Attachments/{attachment_id}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific attachment from a specific contact by file name
#
# GET /Contacts/{ContactID}/Attachments/{FileName}
# operationId: getContactAttachmentByFileName
export def "contacts-attachments get-by-file-name" [
  contact_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id), file_name: (encode-path-segment $file_name)} | format pattern "/Contacts/{contact_id}/Attachments/{file_name}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# POST /Contacts/{ContactID}/Attachments/{FileName}
#
# operationId: updateContactAttachmentByFileName
export def "contacts-attachments update-by-file-name" [
  contact_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id), file_name: (encode-path-segment $file_name)} | format pattern "/Contacts/{contact_id}/Attachments/{file_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# PUT /Contacts/{ContactID}/Attachments/{FileName}
#
# operationId: createContactAttachmentByFileName
export def "contacts-attachments create-by-file-name" [
  contact_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id), file_name: (encode-path-segment $file_name)} | format pattern "/Contacts/{contact_id}/Attachments/{file_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# Retrieves CIS settings for a specific contact in a Xero organisation
#
# GET /Contacts/{ContactID}/CISSettings
# operationId: getContactCISSettings
export def "contacts-cis-settings get" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<CISSettings: table<CISEnabled: bool, Rate: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id)} | format pattern "/Contacts/{contact_id}/CISSettings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves history records for a specific contact
#
# GET /Contacts/{ContactID}/History
# operationId: getContactHistory
export def "contacts-history get" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id)} | format pattern "/Contacts/{contact_id}/History"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a new history record for a specific contact
#
# PUT /Contacts/{ContactID}/History
# operationId: createContactHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "contacts-history create" [
  contact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_id: (encode-path-segment $contact_id)} | format pattern "/Contacts/{contact_id}/History"))
  let req_body = {"HistoryRecords": $history_records} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves a specific contact by contact number in a Xero organisation
#
# GET /Contacts/{ContactNumber}
# operationId: getContactByContactNumber
export def "contacts get-by-number" [
  contact_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({contact_number: (encode-path-segment $contact_number)} | format pattern "/Contacts/{contact_number}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves any credit notes
#
# GET /CreditNotes
# operationId: getCreditNotes
export def "credit-notes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="DRAFT")
  --order: string # Order by an any element (e.g. CreditNoteNumber ASC)
  --page: int # e.g. page=1 – Up to 100 credit notes will be returned in a single API call with line items shown for each credit note (e.g. 1)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<CreditNotes: table<Allocations: list, AppliedAmount: float, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNoteID: string, CreditNoteNumber: string, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, LineAmountTypes: string, LineItems: list, Payments: list, Reference: string, RemainingCredit: float, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/CreditNotes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates or creates one or more credit notes
#
# POST /CreditNotes
# operationId: updateOrCreateCreditNotes
# --CreditNotes item shape: {Allocations?: list, AppliedAmount?: float, BrandingThemeID?: string, Contact?: record, CreditNoteID?: string, CreditNoteNumber?: string, ... (20 more fields)}
export def "credit-notes update-or-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --credit-notes: list # item shape: {Allocations?: list, AppliedAmount?: float, BrandingThemeID?: string, Contact?: record, CreditNoteID?: string, CreditNoteNumber?: string, ... (20 more fields)}
]: any -> record<CreditNotes: table<Allocations: list, AppliedAmount: float, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNoteID: string, CreditNoteNumber: string, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, LineAmountTypes: string, LineItems: list, Payments: list, Reference: string, RemainingCredit: float, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/CreditNotes" $qp)
  let req_body = {"CreditNotes": $credit_notes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates a new credit note
#
# PUT /CreditNotes
# operationId: createCreditNotes
# --CreditNotes item shape: {Allocations?: list, AppliedAmount?: float, BrandingThemeID?: string, Contact?: record, CreditNoteID?: string, CreditNoteNumber?: string, ... (20 more fields)}
export def "credit-notes create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --credit-notes: list # item shape: {Allocations?: list, AppliedAmount?: float, BrandingThemeID?: string, Contact?: record, CreditNoteID?: string, CreditNoteNumber?: string, ... (20 more fields)}
]: any -> record<CreditNotes: table<Allocations: list, AppliedAmount: float, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNoteID: string, CreditNoteNumber: string, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, LineAmountTypes: string, LineItems: list, Payments: list, Reference: string, RemainingCredit: float, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/CreditNotes" $qp)
  let req_body = {"CreditNotes": $credit_notes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves a specific credit note using a unique credit note Id
#
# GET /CreditNotes/{CreditNoteID}
# operationId: getCreditNote
export def "credit-notes get" [
  credit_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
]: nothing -> record<CreditNotes: table<Allocations: list, AppliedAmount: float, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNoteID: string, CreditNoteNumber: string, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, LineAmountTypes: string, LineItems: list, Payments: list, Reference: string, RemainingCredit: float, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({credit_note_id: (encode-path-segment $credit_note_id)} | format pattern "/CreditNotes/{credit_note_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a specific credit note
#
# POST /CreditNotes/{CreditNoteID}
# operationId: updateCreditNote
# --CreditNotes item shape: {Allocations?: list, AppliedAmount?: float, BrandingThemeID?: string, Contact?: record, CreditNoteID?: string, CreditNoteNumber?: string, ... (20 more fields)}
export def "credit-notes update" [
  credit_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --credit-notes: list # item shape: {Allocations?: list, AppliedAmount?: float, BrandingThemeID?: string, Contact?: record, CreditNoteID?: string, CreditNoteNumber?: string, ... (20 more fields)}
]: any -> record<CreditNotes: table<Allocations: list, AppliedAmount: float, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNoteID: string, CreditNoteNumber: string, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, LineAmountTypes: string, LineItems: list, Payments: list, Reference: string, RemainingCredit: float, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({credit_note_id: (encode-path-segment $credit_note_id)} | format pattern "/CreditNotes/{credit_note_id}") $qp)
  let req_body = {"CreditNotes": $credit_notes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates allocation for a specific credit note
#
# PUT /CreditNotes/{CreditNoteID}/Allocations
# operationId: createCreditNoteAllocation
# --Allocations item shape: {Amount: float, CreditNote?: record, Date: string, Invoice: record, Overpayment?: record, Prepayment?: record, StatusAttributeString?: string, ValidationErrors?: list}
export def "credit-notes-allocations create" [
  credit_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --allocations: list # item shape: {Amount: float, CreditNote?: record, Date: string, Invoice: record, Overpayment?: record, Prepayment?: record, StatusAttributeString?: string, ValidationErrors?: list}
]: any -> record<Allocations: table<Amount: float, CreditNote: record, Date: string, Invoice: record, Overpayment: record, Prepayment: record, StatusAttributeString: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({credit_note_id: (encode-path-segment $credit_note_id)} | format pattern "/CreditNotes/{credit_note_id}/Allocations") $qp)
  let req_body = {"Allocations": $allocations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves attachments for a specific credit notes
#
# GET /CreditNotes/{CreditNoteID}/Attachments
# operationId: getCreditNoteAttachments
export def "credit-notes-attachments list" [
  credit_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({credit_note_id: (encode-path-segment $credit_note_id)} | format pattern "/CreditNotes/{credit_note_id}/Attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific attachment from a specific credit note using a unique attachment Id
#
# GET /CreditNotes/{CreditNoteID}/Attachments/{AttachmentID}
# operationId: getCreditNoteAttachmentById
export def "credit-notes-attachments get" [
  credit_note_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({credit_note_id: (encode-path-segment $credit_note_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/CreditNotes/{credit_note_id}/Attachments/{attachment_id}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific attachment on a specific credit note by file name
#
# GET /CreditNotes/{CreditNoteID}/Attachments/{FileName}
# operationId: getCreditNoteAttachmentByFileName
export def "credit-notes-attachments get-by-file-name" [
  credit_note_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({credit_note_id: (encode-path-segment $credit_note_id), file_name: (encode-path-segment $file_name)} | format pattern "/CreditNotes/{credit_note_id}/Attachments/{file_name}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates attachments on a specific credit note by file name
#
# POST /CreditNotes/{CreditNoteID}/Attachments/{FileName}
# operationId: updateCreditNoteAttachmentByFileName
export def "credit-notes-attachments update-by-file-name" [
  credit_note_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({credit_note_id: (encode-path-segment $credit_note_id), file_name: (encode-path-segment $file_name)} | format pattern "/CreditNotes/{credit_note_id}/Attachments/{file_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# Creates an attachment for a specific credit note
#
# PUT /CreditNotes/{CreditNoteID}/Attachments/{FileName}
# operationId: createCreditNoteAttachmentByFileName
export def "credit-notes-attachments create-by-file-name" [
  credit_note_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-online: oneof<nothing, bool> # Allows an attachment to be seen by the end customer within their online invoice (default: false, e.g. true)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "IncludeOnline" $include_online "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({credit_note_id: (encode-path-segment $credit_note_id), file_name: (encode-path-segment $file_name)} | format pattern "/CreditNotes/{credit_note_id}/Attachments/{file_name}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# Retrieves history records of a specific credit note
#
# GET /CreditNotes/{CreditNoteID}/History
# operationId: getCreditNoteHistory
export def "credit-notes-history get" [
  credit_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({credit_note_id: (encode-path-segment $credit_note_id)} | format pattern "/CreditNotes/{credit_note_id}/History"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves history records of a specific credit note
#
# PUT /CreditNotes/{CreditNoteID}/History
# operationId: createCreditNoteHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "credit-notes-history create" [
  credit_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({credit_note_id: (encode-path-segment $credit_note_id)} | format pattern "/CreditNotes/{credit_note_id}/History"))
  let req_body = {"HistoryRecords": $history_records} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves credit notes as PDF files
#
# GET /CreditNotes/{CreditNoteID}/pdf
# operationId: getCreditNoteAsPdf
export def "credit-notes-pdf get" [
  credit_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({credit_note_id: (encode-path-segment $credit_note_id)} | format pattern "/CreditNotes/{credit_note_id}/pdf"))
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves currencies for your Xero organisation
#
# GET /Currencies
# operationId: getCurrencies
export def "currencies get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Code=="USD")
  --order: string # Order by an any element (e.g. Code ASC)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Currencies: table<Code: string, Description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Currencies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a new currency for a Xero organisation
#
# PUT /Currencies
# operationId: createCurrency
export def "currencies create-currency" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --code: string@code-completer # 3 letter alpha code for the currency – see list of currency codes
  --description: string # Name of Currency
]: any -> record<Currencies: table<Code: string, Description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Currencies")
  let req_body = {"Code": $code, "Description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves employees used in Xero payrun
#
# GET /Employees
# operationId: getEmployees
export def "employees list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="ACTIVE")
  --order: string # Order by an any element (e.g. LastName ASC)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Employees: table<EmployeeID: string, ExternalLink: record, FirstName: string, LastName: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Employees" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a single new employees used in Xero payrun
#
# POST /Employees
# operationId: updateOrCreateEmployees
# --Employees item shape: {EmployeeID?: string, ExternalLink?: record, FirstName?: string, LastName?: string, Status?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST"|"DELETED", StatusAttributeString?: string, ValidationErrors?: list}
export def "employees update-or-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --employees: list # item shape: {EmployeeID?: string, ExternalLink?: record, FirstName?: string, LastName?: string, Status?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST"|"DELETED", StatusAttributeString?: string, ValidationErrors?: list}
]: any -> record<Employees: table<EmployeeID: string, ExternalLink: record, FirstName: string, LastName: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Employees" $qp)
  let req_body = {"Employees": $employees} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates new employees used in Xero payrun
#
# PUT /Employees
# operationId: createEmployees
# --Employees item shape: {EmployeeID?: string, ExternalLink?: record, FirstName?: string, LastName?: string, Status?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST"|"DELETED", StatusAttributeString?: string, ValidationErrors?: list}
export def "employees create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --employees: list # item shape: {EmployeeID?: string, ExternalLink?: record, FirstName?: string, LastName?: string, Status?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST"|"DELETED", StatusAttributeString?: string, ValidationErrors?: list}
]: any -> record<Employees: table<EmployeeID: string, ExternalLink: record, FirstName: string, LastName: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Employees" $qp)
  let req_body = {"Employees": $employees} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves a specific employee used in Xero payrun using a unique employee Id
#
# GET /Employees/{EmployeeID}
# operationId: getEmployee
export def "employees get" [
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Employees: table<EmployeeID: string, ExternalLink: record, FirstName: string, LastName: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employee_id: (encode-path-segment $employee_id)} | format pattern "/Employees/{employee_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves expense claims
#
# GET /ExpenseClaims
# operationId: getExpenseClaims
export def "expense-claims list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="SUBMITTED")
  --order: string # Order by an any element (e.g. Status ASC)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<ExpenseClaims: table<AmountDue: float, AmountPaid: float, ExpenseClaimID: string, PaymentDueDate: string, Payments: list, ReceiptID: string, Receipts: list, ReportingDate: string, Status: string, Total: float, UpdatedDateUTC: string, User: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ExpenseClaims" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates expense claims
#
# PUT /ExpenseClaims
# operationId: createExpenseClaims
# --ExpenseClaims item shape: {ExpenseClaimID?: string, Payments?: list, ReceiptID?: string, Receipts?: list, Status?: "SUBMITTED"|"AUTHORISED"|"PAID"|"VOIDED"|"DELETED", User?: record}
export def "expense-claims create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --expense-claims: list # item shape: {ExpenseClaimID?: string, Payments?: list, ReceiptID?: string, Receipts?: list, Status?: "SUBMITTED"|"AUTHORISED"|"PAID"|"VOIDED"|"DELETED", User?: record}
]: any -> record<ExpenseClaims: table<AmountDue: float, AmountPaid: float, ExpenseClaimID: string, PaymentDueDate: string, Payments: list, ReceiptID: string, Receipts: list, ReportingDate: string, Status: string, Total: float, UpdatedDateUTC: string, User: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ExpenseClaims")
  let req_body = {"ExpenseClaims": $expense_claims} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves a specific expense claim using a unique expense claim Id
#
# GET /ExpenseClaims/{ExpenseClaimID}
# operationId: getExpenseClaim
export def "expense-claims get" [
  expense_claim_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<ExpenseClaims: table<AmountDue: float, AmountPaid: float, ExpenseClaimID: string, PaymentDueDate: string, Payments: list, ReceiptID: string, Receipts: list, ReportingDate: string, Status: string, Total: float, UpdatedDateUTC: string, User: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({expense_claim_id: (encode-path-segment $expense_claim_id)} | format pattern "/ExpenseClaims/{expense_claim_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a specific expense claims
#
# POST /ExpenseClaims/{ExpenseClaimID}
# operationId: updateExpenseClaim
# --ExpenseClaims item shape: {ExpenseClaimID?: string, Payments?: list, ReceiptID?: string, Receipts?: list, Status?: "SUBMITTED"|"AUTHORISED"|"PAID"|"VOIDED"|"DELETED", User?: record}
export def "expense-claims update" [
  expense_claim_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --expense-claims: list # item shape: {ExpenseClaimID?: string, Payments?: list, ReceiptID?: string, Receipts?: list, Status?: "SUBMITTED"|"AUTHORISED"|"PAID"|"VOIDED"|"DELETED", User?: record}
]: any -> record<ExpenseClaims: table<AmountDue: float, AmountPaid: float, ExpenseClaimID: string, PaymentDueDate: string, Payments: list, ReceiptID: string, Receipts: list, ReportingDate: string, Status: string, Total: float, UpdatedDateUTC: string, User: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({expense_claim_id: (encode-path-segment $expense_claim_id)} | format pattern "/ExpenseClaims/{expense_claim_id}"))
  let req_body = {"ExpenseClaims": $expense_claims} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves history records of a specific expense claim
#
# GET /ExpenseClaims/{ExpenseClaimID}/History
# operationId: getExpenseClaimHistory
export def "expense-claims-history get" [
  expense_claim_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({expense_claim_id: (encode-path-segment $expense_claim_id)} | format pattern "/ExpenseClaims/{expense_claim_id}/History"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a history record for a specific expense claim
#
# PUT /ExpenseClaims/{ExpenseClaimID}/History
# operationId: createExpenseClaimHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "expense-claims-history create" [
  expense_claim_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({expense_claim_id: (encode-path-segment $expense_claim_id)} | format pattern "/ExpenseClaims/{expense_claim_id}/History"))
  let req_body = {"HistoryRecords": $history_records} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves invoice reminder settings
#
# GET /InvoiceReminders/Settings
# operationId: getInvoiceReminders
export def "invoice-reminders-settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<InvoiceReminders: table<Enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/InvoiceReminders/Settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves sales invoices or purchase bills
#
# GET /Invoices
# operationId: getInvoices
export def "invoices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="DRAFT")
  --order: string # Order by an any element (e.g. InvoiceNumber ASC)
  --i-ds: list<string> # Filter by a comma-separated list of InvoicesIDs. (e.g. &quot;00000000-0000-0000-0000-000000000000&quot;)
  --invoice-numbers: list<string> # Filter by a comma-separated list of InvoiceNumbers. (e.g. &quot;INV-001&quot;, &quot;INV-002&quot;)
  --contact-i-ds: list<string> # Filter by a comma-separated list of ContactIDs. (e.g. &quot;00000000-0000-0000-0000-000000000000&quot;)
  --statuses: list<string> # Filter by a comma-separated list Statuses. For faster response times we recommend using these explicit parameters instead of passing OR conditions into the Where filter. (e.g. &quot;DRAFT&quot;, &quot;SUBMITTED&quot;)
  --page: int # e.g. page=1 – Up to 100 invoices will be returned in a single API call with line items shown for each invoice (e.g. 1)
  --include-archived: oneof<nothing, bool> # e.g. includeArchived=true - Contacts with a status of ARCHIVED will be included in the response
  --created-by-my-app: oneof<nothing, bool> # When set to true you'll only retrieve Invoices created by your app (e.g. false)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Invoices: table<AmountCredited: float, AmountDue: float, AmountPaid: float, Attachments: list, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNotes: list, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, ExpectedPaymentDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, InvoiceID: string, InvoiceNumber: string, IsDiscounted: bool, LineAmountTypes: string, LineItems: list, Overpayments: list, Payments: list, PlannedPaymentDate: string, Prepayments: list, Reference: string, RepeatingInvoiceID: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalDiscount: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "IDs" $i_ds "csv") (serialize-qp "InvoiceNumbers" $invoice_numbers "csv") (serialize-qp "ContactIDs" $contact_i_ds "csv") (serialize-qp "Statuses" $statuses "csv") (serialize-qp "page" $page "scalar") (serialize-qp "includeArchived" $include_archived "scalar") (serialize-qp "createdByMyApp" $created_by_my_app "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Invoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates or creates one or more sales invoices or purchase bills
#
# POST /Invoices
# operationId: updateOrCreateInvoices
# --Invoices item shape: {Attachments?: list, BrandingThemeID?: string, Contact?: record, ... (20 more fields)}
export def "invoices update-or-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --invoices: list # item shape: {Attachments?: list, BrandingThemeID?: string, Contact?: record, ... (20 more fields)}
]: any -> record<Invoices: table<AmountCredited: float, AmountDue: float, AmountPaid: float, Attachments: list, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNotes: list, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, ExpectedPaymentDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, InvoiceID: string, InvoiceNumber: string, IsDiscounted: bool, LineAmountTypes: string, LineItems: list, Overpayments: list, Payments: list, PlannedPaymentDate: string, Prepayments: list, Reference: string, RepeatingInvoiceID: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalDiscount: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Invoices" $qp)
  let req_body = {"Invoices": $invoices} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates one or more sales invoices or purchase bills
#
# PUT /Invoices
# operationId: createInvoices
# --Invoices item shape: {Attachments?: list, BrandingThemeID?: string, Contact?: record, ... (20 more fields)}
export def "invoices create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --invoices: list # item shape: {Attachments?: list, BrandingThemeID?: string, Contact?: record, ... (20 more fields)}
]: any -> record<Invoices: table<AmountCredited: float, AmountDue: float, AmountPaid: float, Attachments: list, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNotes: list, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, ExpectedPaymentDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, InvoiceID: string, InvoiceNumber: string, IsDiscounted: bool, LineAmountTypes: string, LineItems: list, Overpayments: list, Payments: list, PlannedPaymentDate: string, Prepayments: list, Reference: string, RepeatingInvoiceID: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalDiscount: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Invoices" $qp)
  let req_body = {"Invoices": $invoices} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves a specific sales invoice or purchase bill using a unique invoice Id
#
# GET /Invoices/{InvoiceID}
# operationId: getInvoice
export def "invoices get" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
]: nothing -> record<Invoices: table<AmountCredited: float, AmountDue: float, AmountPaid: float, Attachments: list, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNotes: list, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, ExpectedPaymentDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, InvoiceID: string, InvoiceNumber: string, IsDiscounted: bool, LineAmountTypes: string, LineItems: list, Overpayments: list, Payments: list, PlannedPaymentDate: string, Prepayments: list, Reference: string, RepeatingInvoiceID: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalDiscount: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/Invoices/{invoice_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a specific sales invoices or purchase bills
#
# POST /Invoices/{InvoiceID}
# operationId: updateInvoice
# --Invoices item shape: {Attachments?: list, BrandingThemeID?: string, Contact?: record, ... (20 more fields)}
export def "invoices update" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --invoices: list # item shape: {Attachments?: list, BrandingThemeID?: string, Contact?: record, ... (20 more fields)}
]: any -> record<Invoices: table<AmountCredited: float, AmountDue: float, AmountPaid: float, Attachments: list, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNotes: list, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, ExpectedPaymentDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, InvoiceID: string, InvoiceNumber: string, IsDiscounted: bool, LineAmountTypes: string, LineItems: list, Overpayments: list, Payments: list, PlannedPaymentDate: string, Prepayments: list, Reference: string, RepeatingInvoiceID: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalDiscount: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/Invoices/{invoice_id}") $qp)
  let req_body = {"Invoices": $invoices} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves attachments for a specific invoice or purchase bill
#
# GET /Invoices/{InvoiceID}/Attachments
# operationId: getInvoiceAttachments
export def "invoices-attachments list" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/Invoices/{invoice_id}/Attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific attachment from a specific invoices or purchase bills by using a unique attachment Id
#
# GET /Invoices/{InvoiceID}/Attachments/{AttachmentID}
# operationId: getInvoiceAttachmentById
export def "invoices-attachments get" [
  invoice_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/Invoices/{invoice_id}/Attachments/{attachment_id}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves an attachment from a specific invoice or purchase bill by filename
#
# GET /Invoices/{InvoiceID}/Attachments/{FileName}
# operationId: getInvoiceAttachmentByFileName
export def "invoices-attachments get-by-file-name" [
  invoice_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id), file_name: (encode-path-segment $file_name)} | format pattern "/Invoices/{invoice_id}/Attachments/{file_name}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates an attachment from a specific invoices or purchase bill by filename
#
# POST /Invoices/{InvoiceID}/Attachments/{FileName}
# operationId: updateInvoiceAttachmentByFileName
export def "invoices-attachments update-by-file-name" [
  invoice_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id), file_name: (encode-path-segment $file_name)} | format pattern "/Invoices/{invoice_id}/Attachments/{file_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# Creates an attachment for a specific invoice or purchase bill by filename
#
# PUT /Invoices/{InvoiceID}/Attachments/{FileName}
# operationId: createInvoiceAttachmentByFileName
export def "invoices-attachments create-by-file-name" [
  invoice_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-online: oneof<nothing, bool> # Allows an attachment to be seen by the end customer within their online invoice (default: false, e.g. true)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "IncludeOnline" $include_online "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id), file_name: (encode-path-segment $file_name)} | format pattern "/Invoices/{invoice_id}/Attachments/{file_name}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# Sends a copy of a specific invoice to related contact via email
#
# POST /Invoices/{InvoiceID}/Email
# operationId: emailInvoice
export def "invoices-email create" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --status: string # Need at least one field to create an empty JSON payload
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/Invoices/{invoice_id}/Email"))
  let req_body = {"Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves history records for a specific invoice
#
# GET /Invoices/{InvoiceID}/History
# operationId: getInvoiceHistory
export def "invoices-history get" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/Invoices/{invoice_id}/History"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a history record for a specific invoice
#
# PUT /Invoices/{InvoiceID}/History
# operationId: createInvoiceHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "invoices-history create" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/Invoices/{invoice_id}/History"))
  let req_body = {"HistoryRecords": $history_records} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves a URL to an online invoice
#
# GET /Invoices/{InvoiceID}/OnlineInvoice
# operationId: getOnlineInvoice
export def "invoices-online-invoice get" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<OnlineInvoices: table<OnlineInvoiceUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/Invoices/{invoice_id}/OnlineInvoice"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves invoices or purchase bills as PDF files
#
# GET /Invoices/{InvoiceID}/pdf
# operationId: getInvoiceAsPdf
export def "invoices-pdf get" [
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/Invoices/{invoice_id}/pdf"))
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves items
#
# GET /Items
# operationId: getItems
export def "items list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. IsSold==true)
  --order: string # Order by an any element (e.g. Code ASC)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Items: table<Code: string, Description: string, InventoryAssetAccountCode: string, IsPurchased: bool, IsSold: bool, IsTrackedAsInventory: bool, ItemID: string, Name: string, PurchaseDescription: string, PurchaseDetails: record, QuantityOnHand: float, SalesDetails: record, StatusAttributeString: string, TotalCostPool: float, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates or creates one or more items
#
# POST /Items
# operationId: updateOrCreateItems
# --Items item shape: {Code: string, Description?: string, InventoryAssetAccountCode?: string, IsPurchased?: bool, IsSold?: bool, IsTrackedAsInventory?: bool, ItemID?: string, Name?: string, PurchaseDescription?: string, PurchaseDetails?: record, QuantityOnHand?: float, SalesDetails?: record, StatusAttributeString?: string, TotalCostPool?: float, ValidationErrors?: list}
export def "items update-or-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --items: list # item shape: {Code: string, Description?: string, InventoryAssetAccountCode?: string, IsPurchased?: bool, IsSold?: bool, IsTrackedAsInventory?: bool, ItemID?: string, Name?: string, PurchaseDescription?: string, PurchaseDetails?: record, QuantityOnHand?: float, SalesDetails?: record, StatusAttributeString?: string, TotalCostPool?: float, ValidationErrors?: list}
]: any -> record<Items: table<Code: string, Description: string, InventoryAssetAccountCode: string, IsPurchased: bool, IsSold: bool, IsTrackedAsInventory: bool, ItemID: string, Name: string, PurchaseDescription: string, PurchaseDetails: record, QuantityOnHand: float, SalesDetails: record, StatusAttributeString: string, TotalCostPool: float, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Items" $qp)
  let req_body = {"Items": $items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates one or more items
#
# PUT /Items
# operationId: createItems
# --Items item shape: {Code: string, Description?: string, InventoryAssetAccountCode?: string, IsPurchased?: bool, IsSold?: bool, IsTrackedAsInventory?: bool, ItemID?: string, Name?: string, PurchaseDescription?: string, PurchaseDetails?: record, QuantityOnHand?: float, SalesDetails?: record, StatusAttributeString?: string, TotalCostPool?: float, ValidationErrors?: list}
export def "items create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --items: list # item shape: {Code: string, Description?: string, InventoryAssetAccountCode?: string, IsPurchased?: bool, IsSold?: bool, IsTrackedAsInventory?: bool, ItemID?: string, Name?: string, PurchaseDescription?: string, PurchaseDetails?: record, QuantityOnHand?: float, SalesDetails?: record, StatusAttributeString?: string, TotalCostPool?: float, ValidationErrors?: list}
]: any -> record<Items: table<Code: string, Description: string, InventoryAssetAccountCode: string, IsPurchased: bool, IsSold: bool, IsTrackedAsInventory: bool, ItemID: string, Name: string, PurchaseDescription: string, PurchaseDetails: record, QuantityOnHand: float, SalesDetails: record, StatusAttributeString: string, TotalCostPool: float, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Items" $qp)
  let req_body = {"Items": $items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a specific item
#
# DELETE /Items/{ItemID}
# operationId: deleteItem
export def "items delete" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/Items/{item_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific item using a unique item Id
#
# GET /Items/{ItemID}
# operationId: getItem
export def "items get" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
]: nothing -> record<Items: table<Code: string, Description: string, InventoryAssetAccountCode: string, IsPurchased: bool, IsSold: bool, IsTrackedAsInventory: bool, ItemID: string, Name: string, PurchaseDescription: string, PurchaseDetails: record, QuantityOnHand: float, SalesDetails: record, StatusAttributeString: string, TotalCostPool: float, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/Items/{item_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a specific item
#
# POST /Items/{ItemID}
# operationId: updateItem
# --Items item shape: {Code: string, Description?: string, InventoryAssetAccountCode?: string, IsPurchased?: bool, IsSold?: bool, IsTrackedAsInventory?: bool, ItemID?: string, Name?: string, PurchaseDescription?: string, PurchaseDetails?: record, QuantityOnHand?: float, SalesDetails?: record, StatusAttributeString?: string, TotalCostPool?: float, ValidationErrors?: list}
export def "items update" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --items: list # item shape: {Code: string, Description?: string, InventoryAssetAccountCode?: string, IsPurchased?: bool, IsSold?: bool, IsTrackedAsInventory?: bool, ItemID?: string, Name?: string, PurchaseDescription?: string, PurchaseDetails?: record, QuantityOnHand?: float, SalesDetails?: record, StatusAttributeString?: string, TotalCostPool?: float, ValidationErrors?: list}
]: any -> record<Items: table<Code: string, Description: string, InventoryAssetAccountCode: string, IsPurchased: bool, IsSold: bool, IsTrackedAsInventory: bool, ItemID: string, Name: string, PurchaseDescription: string, PurchaseDetails: record, QuantityOnHand: float, SalesDetails: record, StatusAttributeString: string, TotalCostPool: float, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/Items/{item_id}") $qp)
  let req_body = {"Items": $items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves history for a specific item
#
# GET /Items/{ItemID}/History
# operationId: getItemHistory
export def "items-history get" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/Items/{item_id}/History"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a history record for a specific item
#
# PUT /Items/{ItemID}/History
# operationId: createItemHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "items-history create" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/Items/{item_id}/History"))
  let req_body = {"HistoryRecords": $history_records} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves journals
#
# GET /Journals
# operationId: getJournals
export def "journals list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Offset by a specified journal number. e.g. journals with a JournalNumber greater than the offset will be returned (e.g. 10)
  --payments-only: oneof<nothing, bool> # Filter to retrieve journals on a cash basis. Journals are returned on an accrual basis by default.
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Journals: table<CreatedDateUTC: string, JournalDate: string, JournalID: string, JournalLines: list, JournalNumber: int, Reference: string, SourceID: string, SourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "paymentsOnly" $payments_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Journals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific journal using a unique journal Id.
#
# GET /Journals/{JournalID}
# operationId: getJournal
export def "journals get" [
  journal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Journals: table<CreatedDateUTC: string, JournalDate: string, JournalID: string, JournalLines: list, JournalNumber: int, Reference: string, SourceID: string, SourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({journal_id: (encode-path-segment $journal_id)} | format pattern "/Journals/{journal_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves linked transactions (billable expenses)
#
# GET /LinkedTransactions
# operationId: getLinkedTransactions
export def "linked-transactions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Up to 100 linked transactions will be returned in a single API call. Use the page parameter to specify the page to be returned e.g. page=1. (e.g. 1)
  --linked-transaction-id: string # The Xero identifier for an Linked Transaction (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --source-transaction-id: string # Filter by the SourceTransactionID. Get the linked transactions created from a particular ACCPAY invoice (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --contact-id: string # Filter by the ContactID. Get all the linked transactions that have been assigned to a particular customer. (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --status: string # Filter by the combination of ContactID and Status. Get the linked transactions associated to a customer and with a status (e.g. APPROVED)
  --target-transaction-id: string # Filter by the TargetTransactionID. Get all the linked transactions allocated to a particular ACCREC invoice (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<LinkedTransactions: table<ContactID: string, LinkedTransactionID: string, SourceLineItemID: string, SourceTransactionID: string, SourceTransactionTypeCode: string, Status: string, TargetLineItemID: string, TargetTransactionID: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "LinkedTransactionID" $linked_transaction_id "scalar") (serialize-qp "SourceTransactionID" $source_transaction_id "scalar") (serialize-qp "ContactID" $contact_id "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "TargetTransactionID" $target_transaction_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/LinkedTransactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates linked transactions (billable expenses)
#
# PUT /LinkedTransactions
# operationId: createLinkedTransaction
# --ValidationErrors item shape: {Message?: string}
export def "linked-transactions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contact-id: string # Filter by the combination of ContactID and Status. Get all the linked transactions that have been assigned to a particular customer and have a particular status e.g. GET /LinkedTransactions?ContactID=4bb34b03-3378-4bb2-a0ed-6345abf3224e&Status=APPROVED. (format: uuid)
  --linked-transaction-id: string # The Xero identifier for an Linked Transaction e.g./LinkedTransactions/297c2dc5-cc47-4afd-8ec8-74990b8761e9 (format: uuid)
  --source-line-item-id: string # The line item identifier from the source transaction. (format: uuid)
  --source-transaction-id: string # Filter by the SourceTransactionID. Get all the linked transactions created from a particular ACCPAY invoice (format: uuid)
  --source-transaction-type-code: string@source-transaction-type-code-completer # The Type of the source tranasction. This will be ACCPAY if the linked transaction was created from an invoice and SPEND if it was created from a bank transaction.
  --status: string@status-completer-1 # Filter by the combination of ContactID and Status. Get all the linked transactions that have been assigned to a particular customer and have a particular status e.g. GET /LinkedTransactions?ContactID=4bb34b03-3378-4bb2-a0ed-6345abf3224e&Status=APPROVED.
  --target-line-item-id: string # The line item identifier from the target transaction. It is possible to link multiple billable expenses to the same TargetLineItemID. (format: uuid)
  --target-transaction-id: string # Filter by the TargetTransactionID. Get all the linked transactions allocated to a particular ACCREC invoice (format: uuid)
  --type: string@type-completer-1 # This will always be BILLABLEEXPENSE. More types may be added in future.
  --validation-errors: list # Displays array of validation error messages from the API — item shape: {Message?: string}
]: any -> record<LinkedTransactions: table<ContactID: string, LinkedTransactionID: string, SourceLineItemID: string, SourceTransactionID: string, SourceTransactionTypeCode: string, Status: string, TargetLineItemID: string, TargetTransactionID: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/LinkedTransactions")
  let req_body = {"ContactID": $contact_id, "LinkedTransactionID": $linked_transaction_id, "SourceLineItemID": $source_line_item_id, "SourceTransactionID": $source_transaction_id, "SourceTransactionTypeCode": $source_transaction_type_code, "Status": $status, "TargetLineItemID": $target_line_item_id, "TargetTransactionID": $target_transaction_id, "Type": $type, "ValidationErrors": $validation_errors} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a specific linked transactions (billable expenses)
#
# DELETE /LinkedTransactions/{LinkedTransactionID}
# operationId: deleteLinkedTransaction
export def "linked-transactions delete" [
  linked_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linked_transaction_id: (encode-path-segment $linked_transaction_id)} | format pattern "/LinkedTransactions/{linked_transaction_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific linked transaction (billable expenses) using a unique linked transaction Id
#
# GET /LinkedTransactions/{LinkedTransactionID}
# operationId: getLinkedTransaction
export def "linked-transactions get" [
  linked_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<LinkedTransactions: table<ContactID: string, LinkedTransactionID: string, SourceLineItemID: string, SourceTransactionID: string, SourceTransactionTypeCode: string, Status: string, TargetLineItemID: string, TargetTransactionID: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linked_transaction_id: (encode-path-segment $linked_transaction_id)} | format pattern "/LinkedTransactions/{linked_transaction_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a specific linked transactions (billable expenses)
#
# POST /LinkedTransactions/{LinkedTransactionID}
# operationId: updateLinkedTransaction
# --LinkedTransactions item shape: {ContactID?: string, LinkedTransactionID?: string, SourceLineItemID?: string, SourceTransactionID?: string, SourceTransactionTypeCode?: "ACCPAY"|"SPEND", Status?: "APPROVED"|"DRAFT"|"ONDRAFT"|"BILLED"|"VOIDED", TargetLineItemID?: string, TargetTransactionID?: string, Type?: "BILLABLEEXPENSE", ValidationErrors?: list}
export def "linked-transactions update" [
  linked_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --linked-transactions: list # item shape: {ContactID?: string, LinkedTransactionID?: string, SourceLineItemID?: string, SourceTransactionID?: string, SourceTransactionTypeCode?: "ACCPAY"|"SPEND", Status?: "APPROVED"|"DRAFT"|"ONDRAFT"|"BILLED"|"VOIDED", TargetLineItemID?: string, TargetTransactionID?: string, Type?: "BILLABLEEXPENSE", ValidationErrors?: list}
]: any -> record<LinkedTransactions: table<ContactID: string, LinkedTransactionID: string, SourceLineItemID: string, SourceTransactionID: string, SourceTransactionTypeCode: string, Status: string, TargetLineItemID: string, TargetTransactionID: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({linked_transaction_id: (encode-path-segment $linked_transaction_id)} | format pattern "/LinkedTransactions/{linked_transaction_id}"))
  let req_body = {"LinkedTransactions": $linked_transactions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves manual journals
#
# GET /ManualJournals
# operationId: getManualJournals
export def "manual-journals list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="DRAFT")
  --order: string # Order by an any element (e.g. Date ASC)
  --page: int # e.g. page=1 – Up to 100 manual journals will be returned in a single API call with line items shown for each overpayment (e.g. 1)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<ManualJournals: table<Attachments: list, Date: string, HasAttachments: bool, JournalLines: list, LineAmountTypes: string, ManualJournalID: string, Narration: string, ShowOnCashBasisReports: bool, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ManualJournals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates or creates a single manual journal
#
# POST /ManualJournals
# operationId: updateOrCreateManualJournals
# --ManualJournals item shape: {Attachments?: list, Date?: string, JournalLines?: list, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", ManualJournalID?: string, Narration: string, ShowOnCashBasisReports?: bool, Status?: "DRAFT"|"POSTED"|"DELETED"|"VOIDED"|"ARCHIVED", StatusAttributeString?: string, Url?: string, ValidationErrors?: list, Warnings?: list}
export def "manual-journals update-or-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --manual-journals: list # item shape: {Attachments?: list, Date?: string, JournalLines?: list, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", ManualJournalID?: string, Narration: string, ShowOnCashBasisReports?: bool, Status?: "DRAFT"|"POSTED"|"DELETED"|"VOIDED"|"ARCHIVED", StatusAttributeString?: string, Url?: string, ValidationErrors?: list, Warnings?: list}
]: any -> record<ManualJournals: table<Attachments: list, Date: string, HasAttachments: bool, JournalLines: list, LineAmountTypes: string, ManualJournalID: string, Narration: string, ShowOnCashBasisReports: bool, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ManualJournals" $qp)
  let req_body = {"ManualJournals": $manual_journals} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates one or more manual journals
#
# PUT /ManualJournals
# operationId: createManualJournals
# --ManualJournals item shape: {Attachments?: list, Date?: string, JournalLines?: list, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", ManualJournalID?: string, Narration: string, ShowOnCashBasisReports?: bool, Status?: "DRAFT"|"POSTED"|"DELETED"|"VOIDED"|"ARCHIVED", StatusAttributeString?: string, Url?: string, ValidationErrors?: list, Warnings?: list}
export def "manual-journals create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --manual-journals: list # item shape: {Attachments?: list, Date?: string, JournalLines?: list, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", ManualJournalID?: string, Narration: string, ShowOnCashBasisReports?: bool, Status?: "DRAFT"|"POSTED"|"DELETED"|"VOIDED"|"ARCHIVED", StatusAttributeString?: string, Url?: string, ValidationErrors?: list, Warnings?: list}
]: any -> record<ManualJournals: table<Attachments: list, Date: string, HasAttachments: bool, JournalLines: list, LineAmountTypes: string, ManualJournalID: string, Narration: string, ShowOnCashBasisReports: bool, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ManualJournals" $qp)
  let req_body = {"ManualJournals": $manual_journals} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves a specific manual journal
#
# GET /ManualJournals/{ManualJournalID}
# operationId: getManualJournal
export def "manual-journals get" [
  manual_journal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<ManualJournals: table<Attachments: list, Date: string, HasAttachments: bool, JournalLines: list, LineAmountTypes: string, ManualJournalID: string, Narration: string, ShowOnCashBasisReports: bool, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({manual_journal_id: (encode-path-segment $manual_journal_id)} | format pattern "/ManualJournals/{manual_journal_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a specific manual journal
#
# POST /ManualJournals/{ManualJournalID}
# operationId: updateManualJournal
# --ManualJournals item shape: {Attachments?: list, Date?: string, JournalLines?: list, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", ManualJournalID?: string, Narration: string, ShowOnCashBasisReports?: bool, Status?: "DRAFT"|"POSTED"|"DELETED"|"VOIDED"|"ARCHIVED", StatusAttributeString?: string, Url?: string, ValidationErrors?: list, Warnings?: list}
export def "manual-journals update" [
  manual_journal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --manual-journals: list # item shape: {Attachments?: list, Date?: string, JournalLines?: list, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", ManualJournalID?: string, Narration: string, ShowOnCashBasisReports?: bool, Status?: "DRAFT"|"POSTED"|"DELETED"|"VOIDED"|"ARCHIVED", StatusAttributeString?: string, Url?: string, ValidationErrors?: list, Warnings?: list}
]: any -> record<ManualJournals: table<Attachments: list, Date: string, HasAttachments: bool, JournalLines: list, LineAmountTypes: string, ManualJournalID: string, Narration: string, ShowOnCashBasisReports: bool, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({manual_journal_id: (encode-path-segment $manual_journal_id)} | format pattern "/ManualJournals/{manual_journal_id}"))
  let req_body = {"ManualJournals": $manual_journals} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves attachment for a specific manual journal
#
# GET /ManualJournals/{ManualJournalID}/Attachments
# operationId: getManualJournalAttachments
export def "manual-journals-attachments list" [
  manual_journal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({manual_journal_id: (encode-path-segment $manual_journal_id)} | format pattern "/ManualJournals/{manual_journal_id}/Attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Allows you to retrieve a specific attachment from a specific manual journal using a unique attachment Id
#
# GET /ManualJournals/{ManualJournalID}/Attachments/{AttachmentID}
# operationId: getManualJournalAttachmentById
export def "manual-journals-attachments get" [
  manual_journal_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({manual_journal_id: (encode-path-segment $manual_journal_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/ManualJournals/{manual_journal_id}/Attachments/{attachment_id}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific attachment from a specific manual journal by file name
#
# GET /ManualJournals/{ManualJournalID}/Attachments/{FileName}
# operationId: getManualJournalAttachmentByFileName
export def "manual-journals-attachments get-by-file-name" [
  manual_journal_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({manual_journal_id: (encode-path-segment $manual_journal_id), file_name: (encode-path-segment $file_name)} | format pattern "/ManualJournals/{manual_journal_id}/Attachments/{file_name}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a specific attachment from a specific manual journal by file name
#
# POST /ManualJournals/{ManualJournalID}/Attachments/{FileName}
# operationId: updateManualJournalAttachmentByFileName
export def "manual-journals-attachments update-by-file-name" [
  manual_journal_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({manual_journal_id: (encode-path-segment $manual_journal_id), file_name: (encode-path-segment $file_name)} | format pattern "/ManualJournals/{manual_journal_id}/Attachments/{file_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# Creates a specific attachment for a specific manual journal by file name
#
# PUT /ManualJournals/{ManualJournalID}/Attachments/{FileName}
# operationId: createManualJournalAttachmentByFileName
export def "manual-journals-attachments create-by-file-name" [
  manual_journal_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({manual_journal_id: (encode-path-segment $manual_journal_id), file_name: (encode-path-segment $file_name)} | format pattern "/ManualJournals/{manual_journal_id}/Attachments/{file_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# Retrieves history for a specific manual journal
#
# GET /ManualJournals/{ManualJournalID}/History
# operationId: getManualJournalsHistory
export def "manual-journals-history get" [
  manual_journal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({manual_journal_id: (encode-path-segment $manual_journal_id)} | format pattern "/ManualJournals/{manual_journal_id}/History"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a history record for a specific manual journal
#
# PUT /ManualJournals/{ManualJournalID}/History
# operationId: createManualJournalHistoryRecord
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "manual-journals-history create-record" [
  manual_journal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({manual_journal_id: (encode-path-segment $manual_journal_id)} | format pattern "/ManualJournals/{manual_journal_id}/History"))
  let req_body = {"HistoryRecords": $history_records} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves Xero organisation details
#
# GET /Organisation
# operationId: getOrganisations
export def "organisation get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Organisations: table<APIKey: string, Addresses: list, BaseCurrency: string, Class: string, CountryCode: string, CreatedDateUTC: string, DefaultPurchasesTax: string, DefaultSalesTax: string, Edition: string, EmployerIdentificationNumber: string, EndOfYearLockDate: string, ExternalLinks: list, FinancialYearEndDay: int, FinancialYearEndMonth: int, IsDemoCompany: bool, LegalName: string, LineOfBusiness: string, Name: string, OrganisationEntityType: string, OrganisationID: string, OrganisationStatus: string, OrganisationType: string, PaymentTerms: record, PaysTax: bool, PeriodLockDate: string, Phones: list, RegistrationNumber: string, SalesTaxBasis: string, SalesTaxPeriod: string, ShortCode: string, TaxNumber: string, Timezone: string, Version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Organisation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a list of the key actions your app has permission to perform in the connected Xero organisation.
#
# GET /Organisation/Actions
# operationId: getOrganisationActions
export def "organisation-actions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Actions: table<Name: string, Status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Organisation/Actions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves the CIS settings for the Xero organistaion.
#
# GET /Organisation/{OrganisationID}/CISSettings
# operationId: getOrganisationCISSettings
export def "organisation-cis-settings get" [
  organisation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<CISSettings: table<CISContractorEnabled: bool, CISSubContractorEnabled: bool, Rate: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({organisation_id: (encode-path-segment $organisation_id)} | format pattern "/Organisation/{organisation_id}/CISSettings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves overpayments
#
# GET /Overpayments
# operationId: getOverpayments
export def "overpayments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="AUTHORISED")
  --order: string # Order by an any element (e.g. Status ASC)
  --page: int # e.g. page=1 – Up to 100 overpayments will be returned in a single API call with line items shown for each overpayment (e.g. 1)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Overpayments: table<Allocations: list, AppliedAmount: float, Attachments: list, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, Payments: list, RemainingCredit: float, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Overpayments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific overpayment using a unique overpayment Id
#
# GET /Overpayments/{OverpaymentID}
# operationId: getOverpayment
export def "overpayments get" [
  overpayment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Overpayments: table<Allocations: list, AppliedAmount: float, Attachments: list, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, Payments: list, RemainingCredit: float, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({overpayment_id: (encode-path-segment $overpayment_id)} | format pattern "/Overpayments/{overpayment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a single allocation for a specific overpayment
#
# PUT /Overpayments/{OverpaymentID}/Allocations
# operationId: createOverpaymentAllocations
# --Allocations item shape: {Amount: float, CreditNote?: record, Date: string, Invoice: record, Overpayment?: record, Prepayment?: record, StatusAttributeString?: string, ValidationErrors?: list}
export def "overpayments-allocations create" [
  overpayment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --allocations: list # item shape: {Amount: float, CreditNote?: record, Date: string, Invoice: record, Overpayment?: record, Prepayment?: record, StatusAttributeString?: string, ValidationErrors?: list}
]: any -> record<Allocations: table<Amount: float, CreditNote: record, Date: string, Invoice: record, Overpayment: record, Prepayment: record, StatusAttributeString: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({overpayment_id: (encode-path-segment $overpayment_id)} | format pattern "/Overpayments/{overpayment_id}/Allocations") $qp)
  let req_body = {"Allocations": $allocations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves history records of a specific overpayment
#
# GET /Overpayments/{OverpaymentID}/History
# operationId: getOverpaymentHistory
export def "overpayments-history get" [
  overpayment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({overpayment_id: (encode-path-segment $overpayment_id)} | format pattern "/Overpayments/{overpayment_id}/History"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a history record for a specific overpayment
#
# PUT /Overpayments/{OverpaymentID}/History
# operationId: createOverpaymentHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "overpayments-history create" [
  overpayment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({overpayment_id: (encode-path-segment $overpayment_id)} | format pattern "/Overpayments/{overpayment_id}/History"))
  let req_body = {"HistoryRecords": $history_records} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves payment services
#
# GET /PaymentServices
# operationId: getPaymentServices
export def "payment-services get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<PaymentServices: table<PayNowText: string, PaymentServiceID: string, PaymentServiceName: string, PaymentServiceType: string, PaymentServiceUrl: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/PaymentServices")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a payment service
#
# PUT /PaymentServices
# operationId: createPaymentService
# --PaymentServices item shape: {PayNowText?: string, PaymentServiceID?: string, PaymentServiceName?: string, PaymentServiceType?: string, PaymentServiceUrl?: string, ValidationErrors?: list}
export def "payment-services create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --payment-services: list # item shape: {PayNowText?: string, PaymentServiceID?: string, PaymentServiceName?: string, PaymentServiceType?: string, PaymentServiceUrl?: string, ValidationErrors?: list}
]: any -> record<PaymentServices: table<PayNowText: string, PaymentServiceID: string, PaymentServiceName: string, PaymentServiceType: string, PaymentServiceUrl: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/PaymentServices")
  let req_body = {"PaymentServices": $payment_services} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves payments for invoices and credit notes
#
# GET /Payments
# operationId: getPayments
export def "payments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="AUTHORISED")
  --order: string # Order by an any element (e.g. Amount ASC)
  --page: int # Up to 100 payments will be returned in a single API call (e.g. 1)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Payments: table<Account: record, Amount: float, BankAccountNumber: string, BatchPaymentID: string, Code: string, CreditNote: record, CreditNoteNumber: string, CurrencyRate: float, Date: string, Details: string, HasAccount: bool, HasValidationErrors: bool, Invoice: record, InvoiceNumber: string, IsReconciled: bool, Overpayment: record, Particulars: string, PaymentID: string, PaymentType: string, Prepayment: record, Reference: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a single payment for invoice or credit notes
#
# POST /Payments
# operationId: createPayment
# --Account shape: {AccountID?: string, AddToWatchlist?: bool, BankAccountNumber?: string, BankAccountType?: "BANK"|"CREDITCARD"|"PAYPAL"|"NONE"|"", Code?: string, ... (10 more fields)}
# --CreditNote shape: {Allocations?: list, AppliedAmount?: float, BrandingThemeID?: string, Contact?: record, CreditNoteID?: string, CreditNoteNumber?: string, ... (20 more fields)}
# --Invoice shape: {Attachments?: list, BrandingThemeID?: string, Contact?: record, ... (20 more fields)}
# --Overpayment shape: {Allocations?: list, AppliedAmount?: float, Attachments?: list, Contact?: record, ... (13 more fields)}
# --Prepayment shape: {Allocations?: list, AppliedAmount?: float, Attachments?: list, Contact?: record, ... (12 more fields)}
# --ValidationErrors item shape: {Message?: string}
export def "payments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --account: record # shape: {AccountID?: string, AddToWatchlist?: bool, BankAccountNumber?: string, BankAccountType?: "BANK"|"CREDITCARD"|"PAYPAL"|"NONE"|"", Code?: string, ... (10 more fields)}
  --amount: float # The amount of the payment. Must be less than or equal to the outstanding amount owing on the invoice e.g. 200.00 (format: double)
  --bank-account-number: string # The suppliers bank account number the payment is being made to
  --batch-payment-id: string # Present if the payment was created as part of a batch. (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --code: string # Code of account you are using to make the payment e.g. 001 (note- not all accounts have a code value)
  --credit-note: record # shape: {Allocations?: list, AppliedAmount?: float, BrandingThemeID?: string, Contact?: record, CreditNoteID?: string, CreditNoteNumber?: string, ... (20 more fields)}
  --credit-note-number: string # Number of invoice or credit note you are applying payment to e.g. INV-4003
  --currency-rate: float # Exchange rate when payment is received. Only used for non base currency invoices and credit notes e.g. 0.7500 (format: double)
  --date: string # Date the payment is being made (YYYY-MM-DD) e.g. 2009-09-06
  --details: string # The information to appear on the supplier's bank account
  --has-account: oneof<nothing, bool> # A boolean to indicate if a contact has an validation errors (default: false, e.g. false)
  --has-validation-errors: oneof<nothing, bool> # A boolean to indicate if a contact has an validation errors (default: false, e.g. false)
  --invoice: record # shape: {Attachments?: list, BrandingThemeID?: string, Contact?: record, ... (20 more fields)}
  --invoice-number: string # Number of invoice or credit note you are applying payment to e.g.INV-4003
  --is-reconciled: oneof<nothing, bool> # An optional parameter for the payment. A boolean indicating whether you would like the payment to be created as reconciled when using PUT, or whether a payment has been reconciled when using GET
  --overpayment: record # shape: {Allocations?: list, AppliedAmount?: float, Attachments?: list, Contact?: record, ... (13 more fields)}
  --particulars: string # The suppliers bank account number the payment is being made to
  --payment-id: string # The Xero identifier for an Payment e.g. 297c2dc5-cc47-4afd-8ec8-74990b8761e9 (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --prepayment: record # shape: {Allocations?: list, AppliedAmount?: float, Attachments?: list, Contact?: record, ... (12 more fields)}
  --reference: string # An optional description for the payment e.g. Direct Debit
  --status: string@status-completer-2 # The status of the payment.
  --status-attribute-string: string # A string to indicate if a invoice status
  --validation-errors: list # Displays array of validation error messages from the API — item shape: {Message?: string}
]: any -> record<Payments: table<Account: record, Amount: float, BankAccountNumber: string, BatchPaymentID: string, Code: string, CreditNote: record, CreditNoteNumber: string, CurrencyRate: float, Date: string, Details: string, HasAccount: bool, HasValidationErrors: bool, Invoice: record, InvoiceNumber: string, IsReconciled: bool, Overpayment: record, Particulars: string, PaymentID: string, PaymentType: string, Prepayment: record, Reference: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Payments")
  let req_body = {"Account": $account, "Amount": $amount, "BankAccountNumber": $bank_account_number, "BatchPaymentID": $batch_payment_id, "Code": $code, "CreditNote": $credit_note, "CreditNoteNumber": $credit_note_number, "CurrencyRate": $currency_rate, "Date": $date, "Details": $details, "HasAccount": $has_account, "HasValidationErrors": $has_validation_errors, "Invoice": $invoice, "InvoiceNumber": $invoice_number, "IsReconciled": $is_reconciled, "Overpayment": $overpayment, "Particulars": $particulars, "PaymentID": $payment_id, "Prepayment": $prepayment, "Reference": $reference, "Status": $status, "StatusAttributeString": $status_attribute_string, "ValidationErrors": $validation_errors} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates multiple payments for invoices or credit notes
#
# PUT /Payments
# operationId: createPayments
# --Payments item shape: {Account?: record, Amount?: float, BankAccountNumber?: string, BatchPaymentID?: string, Code?: string, CreditNote?: record, CreditNoteNumber?: string, CurrencyRate?: float, Date?: string, Details?: string, HasAccount?: bool, HasValidationErrors?: bool, Invoice?: record, InvoiceNumber?: string, IsReconciled?: bool, Overpayment?: record, Particulars?: string, PaymentID?: string, Prepayment?: record, Reference?: string, Status?: "AUTHORISED"|"DELETED", StatusAttributeString?: string, ... (1 more fields)}
export def "payments create-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --payments: list # item shape: {Account?: record, Amount?: float, BankAccountNumber?: string, BatchPaymentID?: string, Code?: string, CreditNote?: record, CreditNoteNumber?: string, CurrencyRate?: float, Date?: string, Details?: string, HasAccount?: bool, HasValidationErrors?: bool, Invoice?: record, InvoiceNumber?: string, IsReconciled?: bool, Overpayment?: record, Particulars?: string, PaymentID?: string, Prepayment?: record, Reference?: string, Status?: "AUTHORISED"|"DELETED", StatusAttributeString?: string, ... (1 more fields)}
]: any -> record<Payments: table<Account: record, Amount: float, BankAccountNumber: string, BatchPaymentID: string, Code: string, CreditNote: record, CreditNoteNumber: string, CurrencyRate: float, Date: string, Details: string, HasAccount: bool, HasValidationErrors: bool, Invoice: record, InvoiceNumber: string, IsReconciled: bool, Overpayment: record, Particulars: string, PaymentID: string, PaymentType: string, Prepayment: record, Reference: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Payments" $qp)
  let req_body = {"Payments": $payments} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves a specific payment for invoices and credit notes using a unique payment Id
#
# GET /Payments/{PaymentID}
# operationId: getPayment
export def "payments get" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Payments: table<Account: record, Amount: float, BankAccountNumber: string, BatchPaymentID: string, Code: string, CreditNote: record, CreditNoteNumber: string, CurrencyRate: float, Date: string, Details: string, HasAccount: bool, HasValidationErrors: bool, Invoice: record, InvoiceNumber: string, IsReconciled: bool, Overpayment: record, Particulars: string, PaymentID: string, PaymentType: string, Prepayment: record, Reference: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id)} | format pattern "/Payments/{payment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a specific payment for invoices and credit notes
#
# POST /Payments/{PaymentID}
# operationId: deletePayment
export def "payments delete" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  status: string # The status of the payment. (default: DELETED)
]: any -> record<Payments: table<Account: record, Amount: float, BankAccountNumber: string, BatchPaymentID: string, Code: string, CreditNote: record, CreditNoteNumber: string, CurrencyRate: float, Date: string, Details: string, HasAccount: bool, HasValidationErrors: bool, Invoice: record, InvoiceNumber: string, IsReconciled: bool, Overpayment: record, Particulars: string, PaymentID: string, PaymentType: string, Prepayment: record, Reference: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id)} | format pattern "/Payments/{payment_id}"))
  let req_body = {"Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves history records of a specific payment
#
# GET /Payments/{PaymentID}/History
# operationId: getPaymentHistory
export def "payments-history get" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id)} | format pattern "/Payments/{payment_id}/History"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a history record for a specific payment
#
# PUT /Payments/{PaymentID}/History
# operationId: createPaymentHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "payments-history create" [
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id)} | format pattern "/Payments/{payment_id}/History"))
  let req_body = {"HistoryRecords": $history_records} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves prepayments
#
# GET /Prepayments
# operationId: getPrepayments
export def "prepayments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="AUTHORISED")
  --order: string # Order by an any element (e.g. Reference ASC)
  --page: int # e.g. page=1 – Up to 100 prepayments will be returned in a single API call with line items shown for each overpayment (e.g. 1)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Prepayments: table<Allocations: list, AppliedAmount: float, Attachments: list, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PrepaymentID: string, Reference: string, RemainingCredit: float, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Prepayments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Allows you to retrieve a specified prepayments
#
# GET /Prepayments/{PrepaymentID}
# operationId: getPrepayment
export def "prepayments get" [
  prepayment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Prepayments: table<Allocations: list, AppliedAmount: float, Attachments: list, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PrepaymentID: string, Reference: string, RemainingCredit: float, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({prepayment_id: (encode-path-segment $prepayment_id)} | format pattern "/Prepayments/{prepayment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Allows you to create an Allocation for prepayments
#
# PUT /Prepayments/{PrepaymentID}/Allocations
# operationId: createPrepaymentAllocations
# --Allocations item shape: {Amount: float, CreditNote?: record, Date: string, Invoice: record, Overpayment?: record, Prepayment?: record, StatusAttributeString?: string, ValidationErrors?: list}
export def "prepayments-allocations create" [
  prepayment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --allocations: list # item shape: {Amount: float, CreditNote?: record, Date: string, Invoice: record, Overpayment?: record, Prepayment?: record, StatusAttributeString?: string, ValidationErrors?: list}
]: any -> record<Allocations: table<Amount: float, CreditNote: record, Date: string, Invoice: record, Overpayment: record, Prepayment: record, StatusAttributeString: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({prepayment_id: (encode-path-segment $prepayment_id)} | format pattern "/Prepayments/{prepayment_id}/Allocations") $qp)
  let req_body = {"Allocations": $allocations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves history record for a specific prepayment
#
# GET /Prepayments/{PrepaymentID}/History
# operationId: getPrepaymentHistory
export def "prepayments-history get" [
  prepayment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({prepayment_id: (encode-path-segment $prepayment_id)} | format pattern "/Prepayments/{prepayment_id}/History"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a history record for a specific prepayment
#
# PUT /Prepayments/{PrepaymentID}/History
# operationId: createPrepaymentHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "prepayments-history create" [
  prepayment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({prepayment_id: (encode-path-segment $prepayment_id)} | format pattern "/Prepayments/{prepayment_id}/History"))
  let req_body = {"HistoryRecords": $history_records} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves purchase orders
#
# GET /PurchaseOrders
# operationId: getPurchaseOrders
export def "purchase-orders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-3 # Filter by purchase order status (e.g. SUBMITTED)
  --date-from: string # Filter by purchase order date (e.g. GET https://.../PurchaseOrders?DateFrom=2015-12-01&DateTo=2015-12-31 (e.g. 2019-12-01)
  --date-to: string # Filter by purchase order date (e.g. GET https://.../PurchaseOrders?DateFrom=2015-12-01&DateTo=2015-12-31 (e.g. 2019-12-31)
  --order: string # Order by an any element (e.g. PurchaseOrderNumber ASC)
  --page: int # To specify a page, append the page parameter to the URL e.g. ?page=1. If there are 100 records in the response you will need to check if there is any more data by fetching the next page e.g ?page=2 and continuing this process until no more results are returned. (e.g. 1)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Status" $status "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/PurchaseOrders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates or creates one or more purchase orders
#
# POST /PurchaseOrders
# operationId: updateOrCreatePurchaseOrders
# --PurchaseOrders item shape: {Attachments?: list, AttentionTo?: string, BrandingThemeID?: string, Contact?: record, ... (18 more fields)}
export def "purchase-orders update-or-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --purchase-orders: list # item shape: {Attachments?: list, AttentionTo?: string, BrandingThemeID?: string, Contact?: record, ... (18 more fields)}
]: any -> record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/PurchaseOrders" $qp)
  let req_body = {"PurchaseOrders": $purchase_orders} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates one or more purchase orders
#
# PUT /PurchaseOrders
# operationId: createPurchaseOrders
# --PurchaseOrders item shape: {Attachments?: list, AttentionTo?: string, BrandingThemeID?: string, Contact?: record, ... (18 more fields)}
export def "purchase-orders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --purchase-orders: list # item shape: {Attachments?: list, AttentionTo?: string, BrandingThemeID?: string, Contact?: record, ... (18 more fields)}
]: any -> record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/PurchaseOrders" $qp)
  let req_body = {"PurchaseOrders": $purchase_orders} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves a specific purchase order using a unique purchase order Id
#
# GET /PurchaseOrders/{PurchaseOrderID}
# operationId: getPurchaseOrder
export def "purchase-orders get" [
  purchase_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({purchase_order_id: (encode-path-segment $purchase_order_id)} | format pattern "/PurchaseOrders/{purchase_order_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a specific purchase order
#
# POST /PurchaseOrders/{PurchaseOrderID}
# operationId: updatePurchaseOrder
# --PurchaseOrders item shape: {Attachments?: list, AttentionTo?: string, BrandingThemeID?: string, Contact?: record, ... (18 more fields)}
export def "purchase-orders update" [
  purchase_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --purchase-orders: list # item shape: {Attachments?: list, AttentionTo?: string, BrandingThemeID?: string, Contact?: record, ... (18 more fields)}
]: any -> record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({purchase_order_id: (encode-path-segment $purchase_order_id)} | format pattern "/PurchaseOrders/{purchase_order_id}"))
  let req_body = {"PurchaseOrders": $purchase_orders} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves attachments for a specific purchase order
#
# GET /PurchaseOrders/{PurchaseOrderID}/Attachments
# operationId: getPurchaseOrderAttachments
export def "purchase-orders-attachments list" [
  purchase_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({purchase_order_id: (encode-path-segment $purchase_order_id)} | format pattern "/PurchaseOrders/{purchase_order_id}/Attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves specific attachment for a specific purchase order using a unique attachment Id
#
# GET /PurchaseOrders/{PurchaseOrderID}/Attachments/{AttachmentID}
# operationId: getPurchaseOrderAttachmentById
export def "purchase-orders-attachments get" [
  purchase_order_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({purchase_order_id: (encode-path-segment $purchase_order_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/PurchaseOrders/{purchase_order_id}/Attachments/{attachment_id}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific attachment for a specific purchase order by filename
#
# GET /PurchaseOrders/{PurchaseOrderID}/Attachments/{FileName}
# operationId: getPurchaseOrder≠AttachmentByFileName
export def "purchase-orders-attachments get-order≠attachment-by-file-name" [
  purchase_order_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({purchase_order_id: (encode-path-segment $purchase_order_id), file_name: (encode-path-segment $file_name)} | format pattern "/PurchaseOrders/{purchase_order_id}/Attachments/{file_name}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a specific attachment for a specific purchase order by filename
#
# POST /PurchaseOrders/{PurchaseOrderID}/Attachments/{FileName}
# operationId: updatePurchaseOrderAttachmentByFileName
export def "purchase-orders-attachments update-by-file-name" [
  purchase_order_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({purchase_order_id: (encode-path-segment $purchase_order_id), file_name: (encode-path-segment $file_name)} | format pattern "/PurchaseOrders/{purchase_order_id}/Attachments/{file_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# Creates attachment for a specific purchase order
#
# PUT /PurchaseOrders/{PurchaseOrderID}/Attachments/{FileName}
# operationId: createPurchaseOrderAttachmentByFileName
export def "purchase-orders-attachments create-by-file-name" [
  purchase_order_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({purchase_order_id: (encode-path-segment $purchase_order_id), file_name: (encode-path-segment $file_name)} | format pattern "/PurchaseOrders/{purchase_order_id}/Attachments/{file_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# Retrieves history for a specific purchase order
#
# GET /PurchaseOrders/{PurchaseOrderID}/History
# operationId: getPurchaseOrderHistory
export def "purchase-orders-history get" [
  purchase_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({purchase_order_id: (encode-path-segment $purchase_order_id)} | format pattern "/PurchaseOrders/{purchase_order_id}/History"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a history record for a specific purchase orders
#
# PUT /PurchaseOrders/{PurchaseOrderID}/History
# operationId: createPurchaseOrderHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "purchase-orders-history create" [
  purchase_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({purchase_order_id: (encode-path-segment $purchase_order_id)} | format pattern "/PurchaseOrders/{purchase_order_id}/History"))
  let req_body = {"HistoryRecords": $history_records} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves specific purchase order as PDF files using a unique purchase order Id
#
# GET /PurchaseOrders/{PurchaseOrderID}/pdf
# operationId: getPurchaseOrderAsPdf
export def "purchase-orders-pdf get" [
  purchase_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({purchase_order_id: (encode-path-segment $purchase_order_id)} | format pattern "/PurchaseOrders/{purchase_order_id}/pdf"))
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific purchase order using purchase order number
#
# GET /PurchaseOrders/{PurchaseOrderNumber}
# operationId: getPurchaseOrderByNumber
export def "purchase-orders get-by-number" [
  purchase_order_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({purchase_order_number: (encode-path-segment $purchase_order_number)} | format pattern "/PurchaseOrders/{purchase_order_number}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves sales quotes
#
# GET /Quotes
# operationId: getQuotes
export def "quotes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # Filter for quotes after a particular date (format: date)
  --date-to: string # Filter for quotes before a particular date (format: date)
  --expiry-date-from: string # Filter for quotes expiring after a particular date (format: date)
  --expiry-date-to: string # Filter for quotes before a particular date (format: date)
  --contact-id: string # Filter for quotes belonging to a particular contact (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --status: string # Filter for quotes of a particular Status (e.g. DRAFT)
  --page: int # e.g. page=1 – Up to 100 Quotes will be returned in a single API call with line items shown for each quote (e.g. 1)
  --order: string # Order by an any element (e.g. Status ASC)
  --quote-number: string # Filter by quote number (e.g. GET https://.../Quotes?QuoteNumber=QU-0001) (e.g. QU-0001)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Quotes: table<BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DateString: string, ExpiryDate: string, ExpiryDateString: string, LineAmountTypes: string, LineItems: list, QuoteID: string, QuoteNumber: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Summary: string, Terms: string, Title: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "ExpiryDateFrom" $expiry_date_from "scalar") (serialize-qp "ExpiryDateTo" $expiry_date_to "scalar") (serialize-qp "ContactID" $contact_id "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "QuoteNumber" $quote_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Quotes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates or creates one or more quotes
#
# POST /Quotes
# operationId: updateOrCreateQuotes
# --Quotes item shape: {BrandingThemeID?: string, Contact?: record, ... (17 more fields)}
export def "quotes update-or-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --quotes: list # item shape: {BrandingThemeID?: string, Contact?: record, ... (17 more fields)}
]: any -> record<Quotes: table<BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DateString: string, ExpiryDate: string, ExpiryDateString: string, LineAmountTypes: string, LineItems: list, QuoteID: string, QuoteNumber: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Summary: string, Terms: string, Title: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Quotes" $qp)
  let req_body = {"Quotes": $quotes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create one or more quotes
#
# PUT /Quotes
# operationId: createQuotes
# --Quotes item shape: {BrandingThemeID?: string, Contact?: record, ... (17 more fields)}
export def "quotes create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarize-errors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --quotes: list # item shape: {BrandingThemeID?: string, Contact?: record, ... (17 more fields)}
]: any -> record<Quotes: table<BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DateString: string, ExpiryDate: string, ExpiryDateString: string, LineAmountTypes: string, LineItems: list, QuoteID: string, QuoteNumber: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Summary: string, Terms: string, Title: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarize_errors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Quotes" $qp)
  let req_body = {"Quotes": $quotes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves a specific quote using a unique quote Id
#
# GET /Quotes/{QuoteID}
# operationId: getQuote
export def "quotes get" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Quotes: table<BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DateString: string, ExpiryDate: string, ExpiryDateString: string, LineAmountTypes: string, LineItems: list, QuoteID: string, QuoteNumber: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Summary: string, Terms: string, Title: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/Quotes/{quote_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a specific quote
#
# POST /Quotes/{QuoteID}
# operationId: updateQuote
# --Quotes item shape: {BrandingThemeID?: string, Contact?: record, ... (17 more fields)}
export def "quotes update" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --quotes: list # item shape: {BrandingThemeID?: string, Contact?: record, ... (17 more fields)}
]: any -> record<Quotes: table<BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DateString: string, ExpiryDate: string, ExpiryDateString: string, LineAmountTypes: string, LineItems: list, QuoteID: string, QuoteNumber: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Summary: string, Terms: string, Title: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/Quotes/{quote_id}"))
  let req_body = {"Quotes": $quotes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves attachments for a specific quote
#
# GET /Quotes/{QuoteID}/Attachments
# operationId: getQuoteAttachments
export def "quotes-attachments list" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/Quotes/{quote_id}/Attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific attachment from a specific quote using a unique attachment Id
#
# GET /Quotes/{QuoteID}/Attachments/{AttachmentID}
# operationId: getQuoteAttachmentById
export def "quotes-attachments get" [
  quote_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/Quotes/{quote_id}/Attachments/{attachment_id}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific attachment from a specific quote by filename
#
# GET /Quotes/{QuoteID}/Attachments/{FileName}
# operationId: getQuoteAttachmentByFileName
export def "quotes-attachments get-by-file-name" [
  quote_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), file_name: (encode-path-segment $file_name)} | format pattern "/Quotes/{quote_id}/Attachments/{file_name}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a specific attachment from a specific quote by filename
#
# POST /Quotes/{QuoteID}/Attachments/{FileName}
# operationId: updateQuoteAttachmentByFileName
export def "quotes-attachments update-by-file-name" [
  quote_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), file_name: (encode-path-segment $file_name)} | format pattern "/Quotes/{quote_id}/Attachments/{file_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# Creates attachment for a specific quote
#
# PUT /Quotes/{QuoteID}/Attachments/{FileName}
# operationId: createQuoteAttachmentByFileName
export def "quotes-attachments create-by-file-name" [
  quote_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), file_name: (encode-path-segment $file_name)} | format pattern "/Quotes/{quote_id}/Attachments/{file_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# Retrieves history records of a specific quote
#
# GET /Quotes/{QuoteID}/History
# operationId: getQuoteHistory
export def "quotes-history get" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/Quotes/{quote_id}/History"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a history record for a specific quote
#
# PUT /Quotes/{QuoteID}/History
# operationId: createQuoteHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "quotes-history create" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/Quotes/{quote_id}/History"))
  let req_body = {"HistoryRecords": $history_records} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves a specific quote as a PDF file using a unique quote Id
#
# GET /Quotes/{QuoteID}/pdf
# operationId: getQuoteAsPdf
export def "quotes-pdf get" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/Quotes/{quote_id}/pdf"))
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves draft expense claim receipts for any user
#
# GET /Receipts
# operationId: getReceipts
export def "receipts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="DRAFT")
  --order: string # Order by an any element (e.g. ReceiptNumber ASC)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Receipts: table<Attachments: list, Contact: record, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, ReceiptID: string, ReceiptNumber: string, Reference: string, Status: string, SubTotal: float, Total: float, TotalTax: float, UpdatedDateUTC: string, Url: string, User: record, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Receipts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates draft expense claim receipts for any user
#
# PUT /Receipts
# operationId: createReceipt
# --Receipts item shape: {Attachments?: list, Contact?: record, Date?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, ReceiptID?: string, Reference?: string, Status?: "DRAFT"|"SUBMITTED"|"AUTHORISED"|"DECLINED"|"VOIDED", SubTotal?: float, Total?: float, TotalTax?: float, User?: record, ValidationErrors?: list, Warnings?: list}
export def "receipts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --receipts: list # item shape: {Attachments?: list, Contact?: record, Date?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, ReceiptID?: string, Reference?: string, Status?: "DRAFT"|"SUBMITTED"|"AUTHORISED"|"DECLINED"|"VOIDED", SubTotal?: float, Total?: float, TotalTax?: float, User?: record, ValidationErrors?: list, Warnings?: list}
]: any -> record<Receipts: table<Attachments: list, Contact: record, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, ReceiptID: string, ReceiptNumber: string, Reference: string, Status: string, SubTotal: float, Total: float, TotalTax: float, UpdatedDateUTC: string, Url: string, User: record, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Receipts" $qp)
  let req_body = {"Receipts": $receipts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves a specific draft expense claim receipt by using a unique receipt Id
#
# GET /Receipts/{ReceiptID}
# operationId: getReceipt
export def "receipts get" [
  receipt_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
]: nothing -> record<Receipts: table<Attachments: list, Contact: record, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, ReceiptID: string, ReceiptNumber: string, Reference: string, Status: string, SubTotal: float, Total: float, TotalTax: float, UpdatedDateUTC: string, Url: string, User: record, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({receipt_id: (encode-path-segment $receipt_id)} | format pattern "/Receipts/{receipt_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a specific draft expense claim receipts
#
# POST /Receipts/{ReceiptID}
# operationId: updateReceipt
# --Receipts item shape: {Attachments?: list, Contact?: record, Date?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, ReceiptID?: string, Reference?: string, Status?: "DRAFT"|"SUBMITTED"|"AUTHORISED"|"DECLINED"|"VOIDED", SubTotal?: float, Total?: float, TotalTax?: float, User?: record, ValidationErrors?: list, Warnings?: list}
export def "receipts update" [
  receipt_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --receipts: list # item shape: {Attachments?: list, Contact?: record, Date?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, ReceiptID?: string, Reference?: string, Status?: "DRAFT"|"SUBMITTED"|"AUTHORISED"|"DECLINED"|"VOIDED", SubTotal?: float, Total?: float, TotalTax?: float, User?: record, ValidationErrors?: list, Warnings?: list}
]: any -> record<Receipts: table<Attachments: list, Contact: record, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, ReceiptID: string, ReceiptNumber: string, Reference: string, Status: string, SubTotal: float, Total: float, TotalTax: float, UpdatedDateUTC: string, Url: string, User: record, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({receipt_id: (encode-path-segment $receipt_id)} | format pattern "/Receipts/{receipt_id}") $qp)
  let req_body = {"Receipts": $receipts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves attachments for a specific expense claim receipt
#
# GET /Receipts/{ReceiptID}/Attachments
# operationId: getReceiptAttachments
export def "receipts-attachments list" [
  receipt_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({receipt_id: (encode-path-segment $receipt_id)} | format pattern "/Receipts/{receipt_id}/Attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific attachments from a specific expense claim receipts by using a unique attachment Id
#
# GET /Receipts/{ReceiptID}/Attachments/{AttachmentID}
# operationId: getReceiptAttachmentById
export def "receipts-attachments get" [
  receipt_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({receipt_id: (encode-path-segment $receipt_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/Receipts/{receipt_id}/Attachments/{attachment_id}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific attachment from a specific expense claim receipts by file name
#
# GET /Receipts/{ReceiptID}/Attachments/{FileName}
# operationId: getReceiptAttachmentByFileName
export def "receipts-attachments get-by-file-name" [
  receipt_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({receipt_id: (encode-path-segment $receipt_id), file_name: (encode-path-segment $file_name)} | format pattern "/Receipts/{receipt_id}/Attachments/{file_name}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a specific attachment on a specific expense claim receipts by file name
#
# POST /Receipts/{ReceiptID}/Attachments/{FileName}
# operationId: updateReceiptAttachmentByFileName
export def "receipts-attachments update-by-file-name" [
  receipt_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({receipt_id: (encode-path-segment $receipt_id), file_name: (encode-path-segment $file_name)} | format pattern "/Receipts/{receipt_id}/Attachments/{file_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# Creates an attachment on a specific expense claim receipts by file name
#
# PUT /Receipts/{ReceiptID}/Attachments/{FileName}
# operationId: createReceiptAttachmentByFileName
export def "receipts-attachments create-by-file-name" [
  receipt_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({receipt_id: (encode-path-segment $receipt_id), file_name: (encode-path-segment $file_name)} | format pattern "/Receipts/{receipt_id}/Attachments/{file_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# Retrieves a history record for a specific receipt
#
# GET /Receipts/{ReceiptID}/History
# operationId: getReceiptHistory
export def "receipts-history get" [
  receipt_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({receipt_id: (encode-path-segment $receipt_id)} | format pattern "/Receipts/{receipt_id}/History"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a history record for a specific receipt
#
# PUT /Receipts/{ReceiptID}/History
# operationId: createReceiptHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "receipts-history create" [
  receipt_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({receipt_id: (encode-path-segment $receipt_id)} | format pattern "/Receipts/{receipt_id}/History"))
  let req_body = {"HistoryRecords": $history_records} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves repeating invoices
#
# GET /RepeatingInvoices
# operationId: getRepeatingInvoices
export def "repeating-invoices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="DRAFT")
  --order: string # Order by an any element (e.g. Total ASC)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<RepeatingInvoices: table<Attachments: list, BrandingThemeID: string, Contact: record, CurrencyCode: string, HasAttachments: bool, ID: string, LineAmountTypes: string, LineItems: list, Reference: string, RepeatingInvoiceID: string, Schedule: record, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/RepeatingInvoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific repeating invoice by using a unique repeating invoice Id
#
# GET /RepeatingInvoices/{RepeatingInvoiceID}
# operationId: getRepeatingInvoice
export def "repeating-invoices get" [
  repeating_invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<RepeatingInvoices: table<Attachments: list, BrandingThemeID: string, Contact: record, CurrencyCode: string, HasAttachments: bool, ID: string, LineAmountTypes: string, LineItems: list, Reference: string, RepeatingInvoiceID: string, Schedule: record, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({repeating_invoice_id: (encode-path-segment $repeating_invoice_id)} | format pattern "/RepeatingInvoices/{repeating_invoice_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves attachments from a specific repeating invoice
#
# GET /RepeatingInvoices/{RepeatingInvoiceID}/Attachments
# operationId: getRepeatingInvoiceAttachments
export def "repeating-invoices-attachments list" [
  repeating_invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({repeating_invoice_id: (encode-path-segment $repeating_invoice_id)} | format pattern "/RepeatingInvoices/{repeating_invoice_id}/Attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific attachment from a specific repeating invoice
#
# GET /RepeatingInvoices/{RepeatingInvoiceID}/Attachments/{AttachmentID}
# operationId: getRepeatingInvoiceAttachmentById
export def "repeating-invoices-attachments get" [
  repeating_invoice_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({repeating_invoice_id: (encode-path-segment $repeating_invoice_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/RepeatingInvoices/{repeating_invoice_id}/Attachments/{attachment_id}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific attachment from a specific repeating invoices by file name
#
# GET /RepeatingInvoices/{RepeatingInvoiceID}/Attachments/{FileName}
# operationId: getRepeatingInvoiceAttachmentByFileName
export def "repeating-invoices-attachments get-by-file-name" [
  repeating_invoice_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --content-type: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({repeating_invoice_id: (encode-path-segment $repeating_invoice_id), file_name: (encode-path-segment $file_name)} | format pattern "/RepeatingInvoices/{repeating_invoice_id}/Attachments/{file_name}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a specific attachment from a specific repeating invoices by file name
#
# POST /RepeatingInvoices/{RepeatingInvoiceID}/Attachments/{FileName}
# operationId: updateRepeatingInvoiceAttachmentByFileName
export def "repeating-invoices-attachments update-by-file-name" [
  repeating_invoice_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({repeating_invoice_id: (encode-path-segment $repeating_invoice_id), file_name: (encode-path-segment $file_name)} | format pattern "/RepeatingInvoices/{repeating_invoice_id}/Attachments/{file_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# Creates an attachment from a specific repeating invoices by file name
#
# PUT /RepeatingInvoices/{RepeatingInvoiceID}/Attachments/{FileName}
# operationId: createRepeatingInvoiceAttachmentByFileName
export def "repeating-invoices-attachments create-by-file-name" [
  repeating_invoice_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: string
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({repeating_invoice_id: (encode-path-segment $repeating_invoice_id), file_name: (encode-path-segment $file_name)} | format pattern "/RepeatingInvoices/{repeating_invoice_id}/Attachments/{file_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body
}

# Retrieves history record for a specific repeating invoice
#
# GET /RepeatingInvoices/{RepeatingInvoiceID}/History
# operationId: getRepeatingInvoiceHistory
export def "repeating-invoices-history get" [
  repeating_invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({repeating_invoice_id: (encode-path-segment $repeating_invoice_id)} | format pattern "/RepeatingInvoices/{repeating_invoice_id}/History"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a history record for a specific repeating invoice
#
# PUT /RepeatingInvoices/{RepeatingInvoiceID}/History
# operationId: createRepeatingInvoiceHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "repeating-invoices-history create" [
  repeating_invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --history-records: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({repeating_invoice_id: (encode-path-segment $repeating_invoice_id)} | format pattern "/RepeatingInvoices/{repeating_invoice_id}/History"))
  let req_body = {"HistoryRecords": $history_records} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves report for BAS (only valid for AU orgs)
#
# GET /Reports
# operationId: getReportBASorGSTList
export def "reports get-ba-sor-gst-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Reports")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves report for aged payables by contact
#
# GET /Reports/AgedPayablesByContact
# operationId: getReportAgedPayablesByContact
export def "reports-aged-payables-by-contact get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-id: string # Unique identifier for a Contact (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --date: string # The date of the Aged Payables By Contact report (format: date)
  --from-date: string # The from date of the Aged Payables By Contact report (format: date)
  --to-date: string # The to date of the Aged Payables By Contact report (format: date)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contactId" $contact_id "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Reports/AgedPayablesByContact" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves report for aged receivables by contact
#
# GET /Reports/AgedReceivablesByContact
# operationId: getReportAgedReceivablesByContact
export def "reports-aged-receivables-by-contact get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-id: string # Unique identifier for a Contact (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --date: string # The date of the Aged Receivables By Contact report (format: date)
  --from-date: string # The from date of the Aged Receivables By Contact report (format: date)
  --to-date: string # The to date of the Aged Receivables By Contact report (format: date)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contactId" $contact_id "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Reports/AgedReceivablesByContact" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves report for balancesheet
#
# GET /Reports/BalanceSheet
# operationId: getReportBalanceSheet
export def "reports-balance-sheet get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # The date of the Balance Sheet report (format: date, e.g. 2019-11-01)
  --periods: int # The number of periods for the Balance Sheet report (e.g. 3)
  --timeframe: string@timeframe-completer # The period size to compare to (MONTH, QUARTER, YEAR) (e.g. MONTH)
  --tracking-option-id1: string # The tracking option 1 for the Balance Sheet report (e.g. 00000000-0000-0000-0000-000000000000)
  --tracking-option-id2: string # The tracking option 2 for the Balance Sheet report (e.g. 00000000-0000-0000-0000-000000000000)
  --standard-layout: oneof<nothing, bool> # The standard layout boolean for the Balance Sheet report (e.g. true)
  --payments-only: oneof<nothing, bool> # return a cash basis for the Balance Sheet report (e.g. false)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "periods" $periods "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "trackingOptionID1" $tracking_option_id1 "scalar") (serialize-qp "trackingOptionID2" $tracking_option_id2 "scalar") (serialize-qp "standardLayout" $standard_layout "scalar") (serialize-qp "paymentsOnly" $payments_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Reports/BalanceSheet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves report for bank summary
#
# GET /Reports/BankSummary
# operationId: getReportBankSummary
export def "reports-bank-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # The from date for the Bank Summary report e.g. 2018-03-31 (format: date, e.g. 2019-11-01)
  --to-date: string # The to date for the Bank Summary report e.g. 2018-03-31 (format: date, e.g. 2019-11-30)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Reports/BankSummary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves report for budget summary
#
# GET /Reports/BudgetSummary
# operationId: getReportBudgetSummary
export def "reports-budget-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # The date for the Bank Summary report e.g. 2018-03-31 (format: date, e.g. 2019-03-31)
  --period: int # The number of periods to compare (integer between 1 and 12) (e.g. 2)
  --timeframe: int # The period size to compare to (1=month, 3=quarter, 12=year) (e.g. 3)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "period" $period "scalar") (serialize-qp "timeframe" $timeframe "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Reports/BudgetSummary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves report for executive summary
#
# GET /Reports/ExecutiveSummary
# operationId: getReportExecutiveSummary
export def "reports-executive-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # The date for the Bank Summary report e.g. 2018-03-31 (format: date, e.g. 2019-03-31)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Reports/ExecutiveSummary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves report for profit and loss
#
# GET /Reports/ProfitAndLoss
# operationId: getReportProfitAndLoss
export def "reports-profit-and-loss get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # The from date for the ProfitAndLoss report e.g. 2018-03-31 (format: date, e.g. 2019-03-01)
  --to-date: string # The to date for the ProfitAndLoss report e.g. 2018-03-31 (format: date, e.g. 2019-03-31)
  --periods: int # The number of periods to compare (integer between 1 and 12) (e.g. 3)
  --timeframe: string@timeframe-completer # The period size to compare to (MONTH, QUARTER, YEAR) (e.g. MONTH)
  --tracking-category-id: string # The trackingCategory 1 for the ProfitAndLoss report (e.g. 00000000-0000-0000-0000-000000000000)
  --tracking-category-id2: string # The trackingCategory 2 for the ProfitAndLoss report (e.g. 00000000-0000-0000-0000-000000000000)
  --tracking-option-id: string # The tracking option 1 for the ProfitAndLoss report (e.g. 00000000-0000-0000-0000-000000000000)
  --tracking-option-id2: string # The tracking option 2 for the ProfitAndLoss report (e.g. 00000000-0000-0000-0000-000000000000)
  --standard-layout: oneof<nothing, bool> # Return the standard layout for the ProfitAndLoss report (e.g. true)
  --payments-only: oneof<nothing, bool> # Return cash only basis for the ProfitAndLoss report (e.g. false)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "periods" $periods "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "trackingCategoryID" $tracking_category_id "scalar") (serialize-qp "trackingCategoryID2" $tracking_category_id2 "scalar") (serialize-qp "trackingOptionID" $tracking_option_id "scalar") (serialize-qp "trackingOptionID2" $tracking_option_id2 "scalar") (serialize-qp "standardLayout" $standard_layout "scalar") (serialize-qp "paymentsOnly" $payments_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Reports/ProfitAndLoss" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieve reports for 1099
#
# GET /Reports/TenNinetyNine
# operationId: getReportTenNinetyNine
export def "reports-ten-ninety-nine get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-year: string # The year of the 1099 report (e.g. 2019)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Reports: table<Contacts: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportType: string, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportYear" $report_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Reports/TenNinetyNine" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves report for trial balance
#
# GET /Reports/TrialBalance
# operationId: getReportTrialBalance
export def "reports-trial-balance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # The date for the Trial Balance report e.g. 2018-03-31 (format: date, e.g. 2019-10-31)
  --payments-only: oneof<nothing, bool> # Return cash only basis for the Trial Balance report (e.g. true)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "paymentsOnly" $payments_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Reports/TrialBalance" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific report for BAS using a unique report Id (only valid for AU orgs)
#
# GET /Reports/{ReportID}
# operationId: getReportBASorGST
export def "reports get-ba-sor-gst" [
  report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id)} | format pattern "/Reports/{report_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Sets the chart of accounts, the conversion date and conversion balances
#
# POST /Setup
# operationId: postSetup
# --Accounts item shape: {AccountID?: string, AddToWatchlist?: bool, BankAccountNumber?: string, BankAccountType?: "BANK"|"CREDITCARD"|"PAYPAL"|"NONE"|"", Code?: string, ... (10 more fields)}
# --ConversionBalances item shape: {AccountCode?: string, Balance?: float, BalanceDetails?: list}
# --ConversionDate shape: {Month?: int, Year?: int}
export def "setup create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --accounts: list # item shape: {AccountID?: string, AddToWatchlist?: bool, BankAccountNumber?: string, BankAccountType?: "BANK"|"CREDITCARD"|"PAYPAL"|"NONE"|"", Code?: string, ... (10 more fields)}
  --conversion-balances: list # Balance supplied for each account that has a value as at the conversion date. — item shape: {AccountCode?: string, Balance?: float, BalanceDetails?: list}
  --conversion-date: record # The date when the organisation starts using Xero — shape: {Month?: int, Year?: int}
]: any -> record<ImportSummary: record<Accounts: record<Deleted: float, Errored: float, Locked: float, New: float, NewOrUpdated: float, Present: bool, System: float, Total: float, Updated: float>, Organisation: record<Present: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Setup")
  let req_body = {"Accounts": $accounts, "ConversionBalances": $conversion_balances, "ConversionDate": $conversion_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves tax rates
#
# GET /TaxRates
# operationId: getTaxRates
export def "tax-rates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="ACTIVE")
  --order: string # Order by an any element (e.g. Name ASC)
  --tax-type: string # Filter by tax type (e.g. INPUT)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<TaxRates: table<CanApplyToAssets: bool, CanApplyToEquity: bool, CanApplyToExpenses: bool, CanApplyToLiabilities: bool, CanApplyToRevenue: bool, DisplayTaxRate: float, EffectiveRate: float, Name: string, ReportTaxType: string, Status: string, TaxComponents: list, TaxType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "TaxType" $tax_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/TaxRates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates tax rates
#
# POST /TaxRates
# operationId: updateTaxRate
# --TaxRates item shape: {Name?: string, ... (4 more fields)}
export def "tax-rates update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --tax-rates: list # item shape: {Name?: string, ... (4 more fields)}
]: any -> record<TaxRates: table<CanApplyToAssets: bool, CanApplyToEquity: bool, CanApplyToExpenses: bool, CanApplyToLiabilities: bool, CanApplyToRevenue: bool, DisplayTaxRate: float, EffectiveRate: float, Name: string, ReportTaxType: string, Status: string, TaxComponents: list, TaxType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/TaxRates")
  let req_body = {"TaxRates": $tax_rates} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates one or more tax rates
#
# PUT /TaxRates
# operationId: createTaxRates
# --TaxRates item shape: {Name?: string, ... (4 more fields)}
export def "tax-rates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --tax-rates: list # item shape: {Name?: string, ... (4 more fields)}
]: any -> record<TaxRates: table<CanApplyToAssets: bool, CanApplyToEquity: bool, CanApplyToExpenses: bool, CanApplyToLiabilities: bool, CanApplyToRevenue: bool, DisplayTaxRate: float, EffectiveRate: float, Name: string, ReportTaxType: string, Status: string, TaxComponents: list, TaxType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/TaxRates")
  let req_body = {"TaxRates": $tax_rates} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves tracking categories and options
#
# GET /TrackingCategories
# operationId: getTrackingCategories
export def "tracking-categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="ACTIVE")
  --order: string # Order by an any element (e.g. Name ASC)
  --include-archived: oneof<nothing, bool> # e.g. includeArchived=true - Categories and options with a status of ARCHIVED will be included in the response
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<TrackingCategories: table<Name: string, Option: string, Options: list, Status: string, TrackingCategoryID: string, TrackingOptionID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "includeArchived" $include_archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/TrackingCategories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create tracking categories
#
# PUT /TrackingCategories
# operationId: createTrackingCategory
# --Options item shape: {Name?: string, Status?: "ACTIVE"|"ARCHIVED"|"DELETED", TrackingCategoryID?: string, TrackingOptionID?: string}
export def "tracking-categories create-category" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --name: string # The name of the tracking category e.g. Department, Region (max length = 100)
  --option: string # The option name of the tracking option e.g. East, West (max length = 100)
  --options: list # See Tracking Options — item shape: {Name?: string, Status?: "ACTIVE"|"ARCHIVED"|"DELETED", TrackingCategoryID?: string, TrackingOptionID?: string}
  --status: string@status-completer # The status of a tracking category
  --tracking-category-id: string # The Xero identifier for a tracking category e.g. 297c2dc5-cc47-4afd-8ec8-74990b8761e9 (format: uuid)
  --tracking-option-id: string # The Xero identifier for a tracking option e.g. dc54c220-0140-495a-b925-3246adc0075f (format: uuid)
]: any -> record<TrackingCategories: table<Name: string, Option: string, Options: list, Status: string, TrackingCategoryID: string, TrackingOptionID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/TrackingCategories")
  let req_body = {"Name": $name, "Option": $option, "Options": $options, "Status": $status, "TrackingCategoryID": $tracking_category_id, "TrackingOptionID": $tracking_option_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a specific tracking category
#
# DELETE /TrackingCategories/{TrackingCategoryID}
# operationId: deleteTrackingCategory
export def "tracking-categories delete-category" [
  tracking_category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<TrackingCategories: table<Name: string, Option: string, Options: list, Status: string, TrackingCategoryID: string, TrackingOptionID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tracking_category_id: (encode-path-segment $tracking_category_id)} | format pattern "/TrackingCategories/{tracking_category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves specific tracking categories and options using a unique tracking category Id
#
# GET /TrackingCategories/{TrackingCategoryID}
# operationId: getTrackingCategory
export def "tracking-categories get-category" [
  tracking_category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<TrackingCategories: table<Name: string, Option: string, Options: list, Status: string, TrackingCategoryID: string, TrackingOptionID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tracking_category_id: (encode-path-segment $tracking_category_id)} | format pattern "/TrackingCategories/{tracking_category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a specific tracking category
#
# POST /TrackingCategories/{TrackingCategoryID}
# operationId: updateTrackingCategory
# --Options item shape: {Name?: string, Status?: "ACTIVE"|"ARCHIVED"|"DELETED", TrackingCategoryID?: string, TrackingOptionID?: string}
export def "tracking-categories update-category" [
  tracking_category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --name: string # The name of the tracking category e.g. Department, Region (max length = 100)
  --option: string # The option name of the tracking option e.g. East, West (max length = 100)
  --options: list # See Tracking Options — item shape: {Name?: string, Status?: "ACTIVE"|"ARCHIVED"|"DELETED", TrackingCategoryID?: string, TrackingOptionID?: string}
  --status: string@status-completer # The status of a tracking category
  --body-tracking-category-id: string # The Xero identifier for a tracking category e.g. 297c2dc5-cc47-4afd-8ec8-74990b8761e9 (format: uuid)
  --tracking-option-id: string # The Xero identifier for a tracking option e.g. dc54c220-0140-495a-b925-3246adc0075f (format: uuid)
]: any -> record<TrackingCategories: table<Name: string, Option: string, Options: list, Status: string, TrackingCategoryID: string, TrackingOptionID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tracking_category_id: (encode-path-segment $tracking_category_id)} | format pattern "/TrackingCategories/{tracking_category_id}"))
  let req_body = {"Name": $name, "Option": $option, "Options": $options, "Status": $status, "TrackingCategoryID": $body_tracking_category_id, "TrackingOptionID": $tracking_option_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Creates options for a specific tracking category
#
# PUT /TrackingCategories/{TrackingCategoryID}/Options
# operationId: createTrackingOptions
export def "tracking-categories-options create" [
  tracking_category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --name: string # The name of the tracking option e.g. Marketing, East (max length = 100)
  --status: string@status-completer # The status of a tracking option
  --body-tracking-category-id: string # Filter by a tracking category e.g. 297c2dc5-cc47-4afd-8ec8-74990b8761e9 (format: uuid)
  --tracking-option-id: string # The Xero identifier for a tracking option e.g. ae777a87-5ef3-4fa0-a4f0-d10e1f13073a (format: uuid)
]: any -> record<Options: table<Name: string, Status: string, TrackingCategoryID: string, TrackingOptionID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tracking_category_id: (encode-path-segment $tracking_category_id)} | format pattern "/TrackingCategories/{tracking_category_id}/Options"))
  let req_body = {"Name": $name, "Status": $status, "TrackingCategoryID": $body_tracking_category_id, "TrackingOptionID": $tracking_option_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a specific option for a specific tracking category
#
# DELETE /TrackingCategories/{TrackingCategoryID}/Options/{TrackingOptionID}
# operationId: deleteTrackingOptions
export def "tracking-categories-options delete" [
  tracking_category_id: string
  tracking_option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Options: table<Name: string, Status: string, TrackingCategoryID: string, TrackingOptionID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tracking_category_id: (encode-path-segment $tracking_category_id), tracking_option_id: (encode-path-segment $tracking_option_id)} | format pattern "/TrackingCategories/{tracking_category_id}/Options/{tracking_option_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a specific option for a specific tracking category
#
# POST /TrackingCategories/{TrackingCategoryID}/Options/{TrackingOptionID}
# operationId: updateTrackingOptions
export def "tracking-categories-options update" [
  tracking_category_id: string
  tracking_option_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --name: string # The name of the tracking option e.g. Marketing, East (max length = 100)
  --status: string@status-completer # The status of a tracking option
  --body-tracking-category-id: string # Filter by a tracking category e.g. 297c2dc5-cc47-4afd-8ec8-74990b8761e9 (format: uuid)
  --body-tracking-option-id: string # The Xero identifier for a tracking option e.g. ae777a87-5ef3-4fa0-a4f0-d10e1f13073a (format: uuid)
]: any -> record<Options: table<Name: string, Status: string, TrackingCategoryID: string, TrackingOptionID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tracking_category_id: (encode-path-segment $tracking_category_id), tracking_option_id: (encode-path-segment $tracking_option_id)} | format pattern "/TrackingCategories/{tracking_category_id}/Options/{tracking_option_id}"))
  let req_body = {"Name": $name, "Status": $status, "TrackingCategoryID": $body_tracking_category_id, "TrackingOptionID": $body_tracking_option_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Retrieves users
#
# GET /Users
# operationId: getUsers
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. IsSubscriber==true)
  --order: string # Order by an any element (e.g. LastName ASC)
  --if-modified-since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Users: table<EmailAddress: string, FirstName: string, IsSubscriber: bool, LastName: string, OrganisationRole: string, UpdatedDateUTC: string, UserID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Modified-Since": $if_modified_since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieves a specific user
#
# GET /Users/{UserID}
# operationId: getUser
export def "users get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Users: table<EmailAddress: string, FirstName: string, IsSubscriber: bool, LastName: string, OrganisationRole: string, UpdatedDateUTC: string, UserID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/Users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
