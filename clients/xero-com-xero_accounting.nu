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

def base-url-completer [] { ["https://api.xero.com/api.xro/2.0"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def BankAccountType-completer [] { ["" "BANK" "CREDITCARD" "NONE" "PAYPAL"] }
def CurrencyCode-completer [] { ["" "AED" "AFN" "ALL" "AMD" "ANG" "AOA" "ARS" "AUD" "AWG" "AZN" "BAM" "BBD" "BDT" "BGN" "BHD" "BIF" "BMD" "BND" "BOB" "BRL" "BSD" "BTN" "BWP" "BYN" "BYR" "BZD" "CAD" "CDF" "CHF" "CLP" "CNY" "COP" "CRC" "CUC" "CUP" "CVE" "CZK" "DJF" "DKK" "DOP" "DZD" "EGP" "ERN" "ETB" "EUR" "FJD" "FKP" "GBP" "GEL" "GGP" "GHS" "GIP" "GMD" "GNF" "GTQ" "GYD" "HKD" "HNL" "HRK" "HTG" "HUF" "IDR" "ILS" "IMP" "INR" "IQD" "IRR" "ISK" "JEP" "JMD" "JOD" "JPY" "KES" "KGS" "KHR" "KMF" "KPW" "KRW" "KWD" "KYD" "KZT" "LAK" "LBP" "LKR" "LRD" "LSL" "LTL" "LYD" "MAD" "MDL" "MGA" "MKD" "MMK" "MNT" "MOP" "MRU" "MUR" "MVR" "MWK" "MXN" "MYR" "MZN" "NAD" "NGN" "NIO" "NOK" "NPR" "NZD" "OMR" "PAB" "PEN" "PGK" "PHP" "PKR" "PLN" "PYG" "QAR" "RON" "RSD" "RUB" "RWF" "SAR" "SBD" "SCR" "SDG" "SEK" "SGD" "SHP" "SLL" "SOS" "SPL" "SRD" "STN" "SVC" "SYP" "SZL" "THB" "TJS" "TMT" "TND" "TOP" "TRY" "TTD" "TVD" "TWD" "TZS" "UAH" "UGX" "USD" "UYU" "UZS" "VEF" "VND" "VUV" "WST" "XAF" "XCD" "XDR" "XOF" "XPF" "YER" "ZAR" "ZMK" "ZMW" "ZWD"] }
def Status-completer [] { ["ACTIVE" "ARCHIVED" "DELETED"] }
def Type-completer [] { ["BANK" "CURRENT" "CURRLIAB" "DEPRECIATN" "DIRECTCOSTS" "EQUITY" "EXPENSE" "FIXED" "INVENTORY" "LIABILITY" "NONCURRENT" "OTHERINCOME" "OVERHEADS" "PAYG" "PAYGLIABILITY" "PREPAYMENT" "REVENUE" "SALES" "SUPERANNUATIONEXPENSE" "SUPERANNUATIONLIABILITY" "TERMLIAB" "WAGESEXPENSE"] }
def Code-completer [] { ["" "AED" "AFN" "ALL" "AMD" "ANG" "AOA" "ARS" "AUD" "AWG" "AZN" "BAM" "BBD" "BDT" "BGN" "BHD" "BIF" "BMD" "BND" "BOB" "BRL" "BSD" "BTN" "BWP" "BYN" "BYR" "BZD" "CAD" "CDF" "CHF" "CLP" "CNY" "COP" "CRC" "CUC" "CUP" "CVE" "CZK" "DJF" "DKK" "DOP" "DZD" "EGP" "ERN" "ETB" "EUR" "FJD" "FKP" "GBP" "GEL" "GGP" "GHS" "GIP" "GMD" "GNF" "GTQ" "GYD" "HKD" "HNL" "HRK" "HTG" "HUF" "IDR" "ILS" "IMP" "INR" "IQD" "IRR" "ISK" "JEP" "JMD" "JOD" "JPY" "KES" "KGS" "KHR" "KMF" "KPW" "KRW" "KWD" "KYD" "KZT" "LAK" "LBP" "LKR" "LRD" "LSL" "LTL" "LYD" "MAD" "MDL" "MGA" "MKD" "MMK" "MNT" "MOP" "MRU" "MUR" "MVR" "MWK" "MXN" "MYR" "MZN" "NAD" "NGN" "NIO" "NOK" "NPR" "NZD" "OMR" "PAB" "PEN" "PGK" "PHP" "PKR" "PLN" "PYG" "QAR" "RON" "RSD" "RUB" "RWF" "SAR" "SBD" "SCR" "SDG" "SEK" "SGD" "SHP" "SLL" "SOS" "SPL" "SRD" "STN" "SVC" "SYP" "SZL" "THB" "TJS" "TMT" "TND" "TOP" "TRY" "TTD" "TVD" "TWD" "TZS" "UAH" "UGX" "USD" "UYU" "UZS" "VEF" "VND" "VUV" "WST" "XAF" "XCD" "XDR" "XOF" "XPF" "YER" "ZAR" "ZMK" "ZMW" "ZWD"] }
def SourceTransactionTypeCode-completer [] { ["ACCPAY" "SPEND"] }
def Status-completer-1 [] { ["APPROVED" "BILLED" "DRAFT" "ONDRAFT" "VOIDED"] }
def Type-completer-1 [] { ["BILLABLEEXPENSE"] }
def Status-completer-2 [] { ["AUTHORISED" "DELETED"] }
def Status-completer-3 [] { ["AUTHORISED" "BILLED" "DELETED" "DRAFT" "SUBMITTED"] }
def timeframe-completer [] { ["MONTH" "QUARTER" "YEAR"] }

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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status==&quot;ACTIVE&quot; AND Type==&quot;BANK&quot;)
  --order: string # Order by an any element (e.g. Name ASC)
  --If-Modified-Since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Accounts: table<AccountID: string, AddToWatchlist: bool, BankAccountNumber: string, BankAccountType: string, Class: string, Code: string, CurrencyCode: string, Description: string, EnablePaymentsToAccount: bool, HasAttachments: bool, Name: string, ReportingCode: string, ReportingCodeName: string, ShowInExpenseClaims: bool, Status: string, SystemAccount: string, TaxType: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Accounts" $qp)
  let extra_headers = {"If-Modified-Since": $If_Modified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new chart of accounts
#
# PUT /Accounts
# operationId: createAccount
# --ValidationErrors item shape: {Message?: string}
export def "accounts createAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --AccountID: string # The Xero identifier for an account – specified as a string following  the endpoint name   e.g. /297c2dc5-cc47-4afd-8ec8-74990b8761e9 (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --AddToWatchlist: oneof<nothing, bool> # Boolean – describes whether the account is shown in the watchlist widget on the dashboard
  --BankAccountNumber: string # For bank accounts only (Account Type BANK)
  --BankAccountType: string@BankAccountType-completer # For bank accounts only. See Bank Account types
  --Code: string # Customer defined alpha numeric account code e.g 200 or SALES (max length = 10) (e.g. 4400)
  --CurrencyCode: string@CurrencyCode-completer # 3 letter alpha code for the currency – see list of currency codes
  --Description: string # Description of the Account. Valid for all types of accounts except bank accounts (max length = 4000)
  --EnablePaymentsToAccount: oneof<nothing, bool> # Boolean – describes whether account can have payments applied to it
  --Name: string # Name of account (max length = 150) (e.g. Food Sales)
  --ReportingCode: string # Shown if set
  --ShowInExpenseClaims: oneof<nothing, bool> # Boolean – describes whether account code is available for use with expense claims
  --Status: string@Status-completer # Accounts with a status of ACTIVE can be updated to ARCHIVED. See Account Status Codes
  --TaxType: string # The tax type from TaxRates
  --Type: string@Type-completer # See Account Types
  --ValidationErrors: list # Displays array of validation error messages from the API — item shape: {Message?: string}
]: any -> record<Accounts: table<AccountID: string, AddToWatchlist: bool, BankAccountNumber: string, BankAccountType: string, Class: string, Code: string, CurrencyCode: string, Description: string, EnablePaymentsToAccount: bool, HasAttachments: bool, Name: string, ReportingCode: string, ReportingCodeName: string, ShowInExpenseClaims: bool, Status: string, SystemAccount: string, TaxType: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Accounts")
  let body = {AccountID: $AccountID, AddToWatchlist: $AddToWatchlist, BankAccountNumber: $BankAccountNumber, BankAccountType: $BankAccountType, Code: $Code, CurrencyCode: $CurrencyCode, Description: $Description, EnablePaymentsToAccount: $EnablePaymentsToAccount, Name: $Name, ReportingCode: $ReportingCode, ShowInExpenseClaims: $ShowInExpenseClaims, Status: $Status, TaxType: $TaxType, Type: $Type, ValidationErrors: $ValidationErrors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a chart of accounts
#
# DELETE /Accounts/{AccountID}
# operationId: deleteAccount
export def "accounts delete" [
  AccountID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Accounts: table<AccountID: string, AddToWatchlist: bool, BankAccountNumber: string, BankAccountType: string, Class: string, Code: string, CurrencyCode: string, Description: string, EnablePaymentsToAccount: bool, HasAttachments: bool, Name: string, ReportingCode: string, ReportingCodeName: string, ShowInExpenseClaims: bool, Status: string, SystemAccount: string, TaxType: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Accounts/($AccountID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a single chart of accounts by using a unique account Id
#
# GET /Accounts/{AccountID}
# operationId: getAccount
export def "accounts get" [
  AccountID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Accounts: table<AccountID: string, AddToWatchlist: bool, BankAccountNumber: string, BankAccountType: string, Class: string, Code: string, CurrencyCode: string, Description: string, EnablePaymentsToAccount: bool, HasAttachments: bool, Name: string, ReportingCode: string, ReportingCodeName: string, ShowInExpenseClaims: bool, Status: string, SystemAccount: string, TaxType: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Accounts/($AccountID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a chart of accounts
#
# POST /Accounts/{AccountID}
# operationId: updateAccount
# --Accounts item shape: {AccountID?: string, AddToWatchlist?: bool, BankAccountNumber?: string, BankAccountType?: "BANK"|"CREDITCARD"|"PAYPAL"|"NONE"|"", Code?: string, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", Description?: string, EnablePaymentsToAccount?: bool, Name?: string, ReportingCode?: string, ShowInExpenseClaims?: bool, Status?: "ACTIVE"|"ARCHIVED"|"DELETED", TaxType?: string, Type?: "BANK"|"CURRENT"|"CURRLIAB"|"DEPRECIATN"|"DIRECTCOSTS"|"EQUITY"|"EXPENSE"|"FIXED"|"INVENTORY"|"LIABILITY"|"NONCURRENT"|"OTHERINCOME"|"OVERHEADS"|"PREPAYMENT"|"REVENUE"|"SALES"|"TERMLIAB"|"PAYGLIABILITY"|"PAYG"|"SUPERANNUATIONEXPENSE"|"SUPERANNUATIONLIABILITY"|"WAGESEXPENSE", ValidationErrors?: list}
export def "accounts updateAccount" [
  AccountID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --Accounts: list # item shape: {AccountID?: string, AddToWatchlist?: bool, BankAccountNumber?: string, BankAccountType?: "BANK"|"CREDITCARD"|"PAYPAL"|"NONE"|"", Code?: string, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", Description?: string, EnablePaymentsToAccount?: bool, Name?: string, ReportingCode?: string, ShowInExpenseClaims?: bool, Status?: "ACTIVE"|"ARCHIVED"|"DELETED", TaxType?: string, Type?: "BANK"|"CURRENT"|"CURRLIAB"|"DEPRECIATN"|"DIRECTCOSTS"|"EQUITY"|"EXPENSE"|"FIXED"|"INVENTORY"|"LIABILITY"|"NONCURRENT"|"OTHERINCOME"|"OVERHEADS"|"PREPAYMENT"|"REVENUE"|"SALES"|"TERMLIAB"|"PAYGLIABILITY"|"PAYG"|"SUPERANNUATIONEXPENSE"|"SUPERANNUATIONLIABILITY"|"WAGESEXPENSE", ValidationErrors?: list}
]: any -> record<Accounts: table<AccountID: string, AddToWatchlist: bool, BankAccountNumber: string, BankAccountType: string, Class: string, Code: string, CurrencyCode: string, Description: string, EnablePaymentsToAccount: bool, HasAttachments: bool, Name: string, ReportingCode: string, ReportingCodeName: string, ShowInExpenseClaims: bool, Status: string, SystemAccount: string, TaxType: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Accounts/($AccountID)")
  let body = {Accounts: $Accounts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves attachments for a specific accounts by using a unique account Id
#
# GET /Accounts/{AccountID}/Attachments
# operationId: getAccountAttachments
export def "accounts-attachments get-by-AccountID" [
  AccountID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Accounts/($AccountID)/Attachments")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific attachment from a specific account using a unique attachment Id
#
# GET /Accounts/{AccountID}/Attachments/{AttachmentID}
# operationId: getAccountAttachmentById
export def "accounts-attachments get-by-AccountID-AttachmentID" [
  AccountID: string
  AttachmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Accounts/($AccountID)/Attachments/($AttachmentID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves an attachment for a specific account by filename
#
# GET /Accounts/{AccountID}/Attachments/{FileName}
# operationId: getAccountAttachmentByFileName
export def "accounts-attachments get-by-AccountID-FileName" [
  AccountID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Accounts/($AccountID)/Attachments/($FileName)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates attachment on a specific account by filename
#
# POST /Accounts/{AccountID}/Attachments/{FileName}
# operationId: updateAccountAttachmentByFileName
export def "accounts-attachments updateAccountAttachmentByFileName" [
  AccountID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Accounts/($AccountID)/Attachments/($FileName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Creates an attachment on a specific account
#
# PUT /Accounts/{AccountID}/Attachments/{FileName}
# operationId: createAccountAttachmentByFileName
export def "accounts-attachments createAccountAttachmentByFileName" [
  AccountID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Accounts/($AccountID)/Attachments/($FileName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="AUTHORISED")
  --order: string # Order by an any element (e.g. Type ASC)
  --page: int # Up to 100 bank transactions will be returned in a single API call with line items details (e.g. 1)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --If-Modified-Since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<BankTransactions: table<BankAccount: record, BankTransactionID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, IsReconciled: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, PrepaymentID: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/BankTransactions" $qp)
  let extra_headers = {"If-Modified-Since": $If_Modified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates or creates one or more spent or received money transaction
#
# POST /BankTransactions
# operationId: updateOrCreateBankTransactions
# --BankTransactions item shape: {BankAccount: record, BankTransactionID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, IsReconciled?: bool, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems: list, Reference?: string, Status?: "AUTHORISED"|"DELETED"|"VOIDED", StatusAttributeString?: string, SubTotal?: float, Total?: float, TotalTax?: float, Type: "RECEIVE"|"RECEIVE-OVERPAYMENT"|"RECEIVE-PREPAYMENT"|"SPEND"|"SPEND-OVERPAYMENT"|"SPEND-PREPAYMENT"|"RECEIVE-TRANSFER"|"SPEND-TRANSFER", Url?: string, ValidationErrors?: list}
export def "bank-transactions updateOrCreateBankTransactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --BankTransactions: list # item shape: {BankAccount: record, BankTransactionID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, IsReconciled?: bool, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems: list, Reference?: string, Status?: "AUTHORISED"|"DELETED"|"VOIDED", StatusAttributeString?: string, SubTotal?: float, Total?: float, TotalTax?: float, Type: "RECEIVE"|"RECEIVE-OVERPAYMENT"|"RECEIVE-PREPAYMENT"|"SPEND"|"SPEND-OVERPAYMENT"|"SPEND-PREPAYMENT"|"RECEIVE-TRANSFER"|"SPEND-TRANSFER", Url?: string, ValidationErrors?: list}
]: any -> record<BankTransactions: table<BankAccount: record, BankTransactionID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, IsReconciled: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, PrepaymentID: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/BankTransactions" $qp)
  let body = {BankTransactions: $BankTransactions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates one or more spent or received money transaction
#
# PUT /BankTransactions
# operationId: createBankTransactions
# --BankTransactions item shape: {BankAccount: record, BankTransactionID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, IsReconciled?: bool, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems: list, Reference?: string, Status?: "AUTHORISED"|"DELETED"|"VOIDED", StatusAttributeString?: string, SubTotal?: float, Total?: float, TotalTax?: float, Type: "RECEIVE"|"RECEIVE-OVERPAYMENT"|"RECEIVE-PREPAYMENT"|"SPEND"|"SPEND-OVERPAYMENT"|"SPEND-PREPAYMENT"|"RECEIVE-TRANSFER"|"SPEND-TRANSFER", Url?: string, ValidationErrors?: list}
export def "bank-transactions createBankTransactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --BankTransactions: list # item shape: {BankAccount: record, BankTransactionID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, IsReconciled?: bool, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems: list, Reference?: string, Status?: "AUTHORISED"|"DELETED"|"VOIDED", StatusAttributeString?: string, SubTotal?: float, Total?: float, TotalTax?: float, Type: "RECEIVE"|"RECEIVE-OVERPAYMENT"|"RECEIVE-PREPAYMENT"|"SPEND"|"SPEND-OVERPAYMENT"|"SPEND-PREPAYMENT"|"RECEIVE-TRANSFER"|"SPEND-TRANSFER", Url?: string, ValidationErrors?: list}
]: any -> record<BankTransactions: table<BankAccount: record, BankTransactionID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, IsReconciled: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, PrepaymentID: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/BankTransactions" $qp)
  let body = {BankTransactions: $BankTransactions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a single spent or received money transaction by using a unique bank transaction Id
#
# GET /BankTransactions/{BankTransactionID}
# operationId: getBankTransaction
export def "bank-transactions get" [
  BankTransactionID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
]: nothing -> record<BankTransactions: table<BankAccount: record, BankTransactionID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, IsReconciled: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, PrepaymentID: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/BankTransactions/($BankTransactionID)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a single spent or received money transaction
#
# POST /BankTransactions/{BankTransactionID}
# operationId: updateBankTransaction
# --BankTransactions item shape: {BankAccount: record, BankTransactionID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, IsReconciled?: bool, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems: list, Reference?: string, Status?: "AUTHORISED"|"DELETED"|"VOIDED", StatusAttributeString?: string, SubTotal?: float, Total?: float, TotalTax?: float, Type: "RECEIVE"|"RECEIVE-OVERPAYMENT"|"RECEIVE-PREPAYMENT"|"SPEND"|"SPEND-OVERPAYMENT"|"SPEND-PREPAYMENT"|"RECEIVE-TRANSFER"|"SPEND-TRANSFER", Url?: string, ValidationErrors?: list}
export def "bank-transactions updateBankTransaction" [
  BankTransactionID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --BankTransactions: list # item shape: {BankAccount: record, BankTransactionID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, IsReconciled?: bool, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems: list, Reference?: string, Status?: "AUTHORISED"|"DELETED"|"VOIDED", StatusAttributeString?: string, SubTotal?: float, Total?: float, TotalTax?: float, Type: "RECEIVE"|"RECEIVE-OVERPAYMENT"|"RECEIVE-PREPAYMENT"|"SPEND"|"SPEND-OVERPAYMENT"|"SPEND-PREPAYMENT"|"RECEIVE-TRANSFER"|"SPEND-TRANSFER", Url?: string, ValidationErrors?: list}
]: any -> record<BankTransactions: table<BankAccount: record, BankTransactionID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, IsReconciled: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, PrepaymentID: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/BankTransactions/($BankTransactionID)" $qp)
  let body = {BankTransactions: $BankTransactions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves any attachments from a specific bank transactions
#
# GET /BankTransactions/{BankTransactionID}/Attachments
# operationId: getBankTransactionAttachments
export def "bank-transactions-attachments get-by-BankTransactionID" [
  BankTransactionID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/BankTransactions/($BankTransactionID)/Attachments")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves specific attachments from a specific BankTransaction using a unique attachment Id
#
# GET /BankTransactions/{BankTransactionID}/Attachments/{AttachmentID}
# operationId: getBankTransactionAttachmentById
export def "bank-transactions-attachments get-by-BankTransactionID-AttachmentID" [
  BankTransactionID: string
  AttachmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/BankTransactions/($BankTransactionID)/Attachments/($AttachmentID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific attachment from a specific bank transaction by filename
#
# GET /BankTransactions/{BankTransactionID}/Attachments/{FileName}
# operationId: getBankTransactionAttachmentByFileName
export def "bank-transactions-attachments get-by-BankTransactionID-FileName" [
  BankTransactionID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/BankTransactions/($BankTransactionID)/Attachments/($FileName)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific attachment from a specific bank transaction by filename
#
# POST /BankTransactions/{BankTransactionID}/Attachments/{FileName}
# operationId: updateBankTransactionAttachmentByFileName
export def "bank-transactions-attachments updateBankTransactionAttachmentByFileName" [
  BankTransactionID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/BankTransactions/($BankTransactionID)/Attachments/($FileName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Creates an attachment for a specific bank transaction by filename
#
# PUT /BankTransactions/{BankTransactionID}/Attachments/{FileName}
# operationId: createBankTransactionAttachmentByFileName
export def "bank-transactions-attachments createBankTransactionAttachmentByFileName" [
  BankTransactionID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/BankTransactions/($BankTransactionID)/Attachments/($FileName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Retrieves history from a specific bank transaction using a unique bank transaction Id
#
# GET /BankTransactions/{BankTransactionID}/History
# operationId: getBankTransactionsHistory
export def "bank-transactions-history get" [
  BankTransactionID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/BankTransactions/($BankTransactionID)/History")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a history record for a specific bank transactions
#
# PUT /BankTransactions/{BankTransactionID}/History
# operationId: createBankTransactionHistoryRecord
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "bank-transactions-history createBankTransactionHistoryRecord" [
  BankTransactionID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --HistoryRecords: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/BankTransactions/($BankTransactionID)/History")
  let body = {HistoryRecords: $HistoryRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. HasAttachments==true)
  --order: string # Order by an any element (e.g. Amount ASC)
  --If-Modified-Since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<BankTransfers: table<Amount: float, BankTransferID: string, CreatedDateUTC: string, CurrencyRate: float, Date: string, FromBankAccount: record, FromBankTransactionID: string, HasAttachments: bool, ToBankAccount: record, ToBankTransactionID: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/BankTransfers" $qp)
  let extra_headers = {"If-Modified-Since": $If_Modified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a bank transfer
#
# PUT /BankTransfers
# operationId: createBankTransfer
# --BankTransfers item shape: {Amount: float, Date?: string, FromBankAccount: record, ToBankAccount: record, ValidationErrors?: list}
export def "bank-transfers createBankTransfer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --BankTransfers: list # item shape: {Amount: float, Date?: string, FromBankAccount: record, ToBankAccount: record, ValidationErrors?: list}
]: any -> record<BankTransfers: table<Amount: float, BankTransferID: string, CreatedDateUTC: string, CurrencyRate: float, Date: string, FromBankAccount: record, FromBankTransactionID: string, HasAttachments: bool, ToBankAccount: record, ToBankTransactionID: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/BankTransfers")
  let body = {BankTransfers: $BankTransfers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves specific bank transfers by using a unique bank transfer Id
#
# GET /BankTransfers/{BankTransferID}
# operationId: getBankTransfer
export def "bank-transfers get" [
  BankTransferID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<BankTransfers: table<Amount: float, BankTransferID: string, CreatedDateUTC: string, CurrencyRate: float, Date: string, FromBankAccount: record, FromBankTransactionID: string, HasAttachments: bool, ToBankAccount: record, ToBankTransactionID: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/BankTransfers/($BankTransferID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves attachments from a specific bank transfer
#
# GET /BankTransfers/{BankTransferID}/Attachments
# operationId: getBankTransferAttachments
export def "bank-transfers-attachments get-by-BankTransferID" [
  BankTransferID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/BankTransfers/($BankTransferID)/Attachments")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific attachment from a specific bank transfer using a unique attachment ID
#
# GET /BankTransfers/{BankTransferID}/Attachments/{AttachmentID}
# operationId: getBankTransferAttachmentById
export def "bank-transfers-attachments get-by-BankTransferID-AttachmentID" [
  BankTransferID: string
  AttachmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/BankTransfers/($BankTransferID)/Attachments/($AttachmentID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific attachment on a specific bank transfer by file name
#
# GET /BankTransfers/{BankTransferID}/Attachments/{FileName}
# operationId: getBankTransferAttachmentByFileName
export def "bank-transfers-attachments get-by-BankTransferID-FileName" [
  BankTransferID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/BankTransfers/($BankTransferID)/Attachments/($FileName)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /BankTransfers/{BankTransferID}/Attachments/{FileName}
#
# operationId: updateBankTransferAttachmentByFileName
export def "bank-transfers-attachments updateBankTransferAttachmentByFileName" [
  BankTransferID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/BankTransfers/($BankTransferID)/Attachments/($FileName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# PUT /BankTransfers/{BankTransferID}/Attachments/{FileName}
#
# operationId: createBankTransferAttachmentByFileName
export def "bank-transfers-attachments createBankTransferAttachmentByFileName" [
  BankTransferID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/BankTransfers/($BankTransferID)/Attachments/($FileName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Retrieves history from a specific bank transfer using a unique bank transfer Id
#
# GET /BankTransfers/{BankTransferID}/History
# operationId: getBankTransferHistory
export def "bank-transfers-history get" [
  BankTransferID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/BankTransfers/($BankTransferID)/History")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a history record for a specific bank transfer
#
# PUT /BankTransfers/{BankTransferID}/History
# operationId: createBankTransferHistoryRecord
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "bank-transfers-history createBankTransferHistoryRecord" [
  BankTransferID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --HistoryRecords: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/BankTransfers/($BankTransferID)/History")
  let body = {HistoryRecords: $HistoryRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="AUTHORISED")
  --order: string # Order by an any element (e.g. Date ASC)
  --If-Modified-Since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<BatchPayments: table<Account: record, Amount: float, BatchPaymentID: string, Code: string, Date: string, DateString: string, Details: string, IsReconciled: string, Narrative: string, Particulars: string, Payments: list, Reference: string, Status: string, TotalAmount: string, Type: string, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/BatchPayments" $qp)
  let extra_headers = {"If-Modified-Since": $If_Modified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates one or many batch payments for invoices
#
# PUT /BatchPayments
# operationId: createBatchPayment
# --BatchPayments item shape: {Account?: record, Amount?: float, Code?: string, Date?: string, DateString?: string, Details?: string, Narrative?: string, Particulars?: string, Payments?: list, Reference?: string}
export def "batch-payments createBatchPayment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --BatchPayments: list # item shape: {Account?: record, Amount?: float, Code?: string, Date?: string, DateString?: string, Details?: string, Narrative?: string, Particulars?: string, Payments?: list, Reference?: string}
]: any -> record<BatchPayments: table<Account: record, Amount: float, BatchPaymentID: string, Code: string, Date: string, DateString: string, Details: string, IsReconciled: string, Narrative: string, Particulars: string, Payments: list, Reference: string, Status: string, TotalAmount: string, Type: string, UpdatedDateUTC: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/BatchPayments" $qp)
  let body = {BatchPayments: $BatchPayments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves history from a specific batch payment
#
# GET /BatchPayments/{BatchPaymentID}/History
# operationId: getBatchPaymentHistory
export def "batch-payments-history get" [
  BatchPaymentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/BatchPayments/($BatchPaymentID)/History")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a history record for a specific batch payment
#
# PUT /BatchPayments/{BatchPaymentID}/History
# operationId: createBatchPaymentHistoryRecord
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "batch-payments-history createBatchPaymentHistoryRecord" [
  BatchPaymentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --HistoryRecords: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> record<HistoryRecords: table<Changes: string, DateUTC: string, Details: string, User: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/BatchPayments/($BatchPaymentID)/History")
  let body = {HistoryRecords: $HistoryRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<BrandingThemes: table<BrandingThemeID: string, CreatedDateUTC: string, LogoUrl: string, Name: string, SortOrder: int, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/BrandingThemes")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific branding theme using a unique branding theme Id
#
# GET /BrandingThemes/{BrandingThemeID}
# operationId: getBrandingTheme
export def "branding-themes get" [
  BrandingThemeID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<BrandingThemes: table<BrandingThemeID: string, CreatedDateUTC: string, LogoUrl: string, Name: string, SortOrder: int, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/BrandingThemes/($BrandingThemeID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the payment services for a specific branding theme
#
# GET /BrandingThemes/{BrandingThemeID}/PaymentServices
# operationId: getBrandingThemePaymentServices
export def "branding-themes-payment-services get" [
  BrandingThemeID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<PaymentServices: table<PayNowText: string, PaymentServiceID: string, PaymentServiceName: string, PaymentServiceType: string, PaymentServiceUrl: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/BrandingThemes/($BrandingThemeID)/PaymentServices")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new custom payment service for a specific branding theme
#
# POST /BrandingThemes/{BrandingThemeID}/PaymentServices
# operationId: createBrandingThemePaymentServices
# --ValidationErrors item shape: {Message?: string}
export def "branding-themes-payment-services createBrandingThemePaymentServices" [
  BrandingThemeID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --PayNowText: string # The text displayed on the Pay Now button in Xero Online Invoicing. If this is not set it will default to Pay by credit card
  --PaymentServiceID: string # Xero identifier (format: uuid)
  --PaymentServiceName: string # Name of payment service
  --PaymentServiceType: string # This will always be CUSTOM for payment services created via the API.
  --PaymentServiceUrl: string # The custom payment URL
  --ValidationErrors: list # Displays array of validation error messages from the API — item shape: {Message?: string}
]: any -> record<PaymentServices: table<PayNowText: string, PaymentServiceID: string, PaymentServiceName: string, PaymentServiceType: string, PaymentServiceUrl: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/BrandingThemes/($BrandingThemeID)/PaymentServices")
  let body = {PayNowText: $PayNowText, PaymentServiceID: $PaymentServiceID, PaymentServiceName: $PaymentServiceName, PaymentServiceType: $PaymentServiceType, PaymentServiceUrl: $PaymentServiceUrl, ValidationErrors: $ValidationErrors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="ACTIVE")
  --order: string # Order by an any element (e.g. Name ASC)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<ContactGroups: table<ContactGroupID: string, Contacts: list, Name: string, Status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ContactGroups" $qp)
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a contact group
#
# PUT /ContactGroups
# operationId: createContactGroup
# --ContactGroups item shape: {ContactGroupID?: string, Contacts?: list, Name?: string, Status?: "ACTIVE"|"DELETED"}
export def "contact-groups createContactGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --ContactGroups: list # item shape: {ContactGroupID?: string, Contacts?: list, Name?: string, Status?: "ACTIVE"|"DELETED"}
]: any -> record<ContactGroups: table<ContactGroupID: string, Contacts: list, Name: string, Status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ContactGroups")
  let body = {ContactGroups: $ContactGroups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a specific contact group by using a unique contact group Id
#
# GET /ContactGroups/{ContactGroupID}
# operationId: getContactGroup
export def "contact-groups get" [
  ContactGroupID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<ContactGroups: table<ContactGroupID: string, Contacts: list, Name: string, Status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ContactGroups/($ContactGroupID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific contact group
#
# POST /ContactGroups/{ContactGroupID}
# operationId: updateContactGroup
# --ContactGroups item shape: {ContactGroupID?: string, Contacts?: list, Name?: string, Status?: "ACTIVE"|"DELETED"}
export def "contact-groups updateContactGroup" [
  ContactGroupID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --ContactGroups: list # item shape: {ContactGroupID?: string, Contacts?: list, Name?: string, Status?: "ACTIVE"|"DELETED"}
]: any -> record<ContactGroups: table<ContactGroupID: string, Contacts: list, Name: string, Status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ContactGroups/($ContactGroupID)")
  let body = {ContactGroups: $ContactGroups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes all contacts from a specific contact group
#
# DELETE /ContactGroups/{ContactGroupID}/Contacts
# operationId: deleteContactGroupContacts
export def "contact-groups-contacts delete-by-ContactGroupID" [
  ContactGroupID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ContactGroups/($ContactGroupID)/Contacts")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates contacts to a specific contact group
#
# PUT /ContactGroups/{ContactGroupID}/Contacts
# operationId: createContactGroupContacts
# --Contacts item shape: {AccountNumber?: string, AccountsPayableTaxType?: string, AccountsReceivableTaxType?: string, Addresses?: list, Attachments?: list, Balances?: record, BankAccountDetails?: string, BatchPayments?: any, BrandingTheme?: record, ContactGroups?: list, ContactID?: string, ContactNumber?: string, ContactPersons?: list, ContactStatus?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST", DefaultCurrency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", EmailAddress?: string, FirstName?: string, HasAttachments?: bool, HasValidationErrors?: bool, IsCustomer?: bool, IsSupplier?: bool, LastName?: string, Name?: string, PaymentTerms?: record, Phones?: list, PurchasesDefaultAccountCode?: string, PurchasesTrackingCategories?: list, SalesDefaultAccountCode?: string, SalesTrackingCategories?: list, SkypeUserName?: string, StatusAttributeString?: string, TaxNumber?: string, TrackingCategoryName?: string, TrackingCategoryOption?: string, ValidationErrors?: list, XeroNetworkKey?: string}
export def "contact-groups-contacts createContactGroupContacts" [
  ContactGroupID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --Contacts: list # item shape: {AccountNumber?: string, AccountsPayableTaxType?: string, AccountsReceivableTaxType?: string, Addresses?: list, Attachments?: list, Balances?: record, BankAccountDetails?: string, BatchPayments?: any, BrandingTheme?: record, ContactGroups?: list, ContactID?: string, ContactNumber?: string, ContactPersons?: list, ContactStatus?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST", DefaultCurrency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", EmailAddress?: string, FirstName?: string, HasAttachments?: bool, HasValidationErrors?: bool, IsCustomer?: bool, IsSupplier?: bool, LastName?: string, Name?: string, PaymentTerms?: record, Phones?: list, PurchasesDefaultAccountCode?: string, PurchasesTrackingCategories?: list, SalesDefaultAccountCode?: string, SalesTrackingCategories?: list, SkypeUserName?: string, StatusAttributeString?: string, TaxNumber?: string, TrackingCategoryName?: string, TrackingCategoryOption?: string, ValidationErrors?: list, XeroNetworkKey?: string}
]: any -> record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ContactGroups/($ContactGroupID)/Contacts")
  let body = {Contacts: $Contacts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a specific contact from a contact group using a unique contact Id
#
# DELETE /ContactGroups/{ContactGroupID}/Contacts/{ContactID}
# operationId: deleteContactGroupContact
export def "contact-groups-contacts delete-by-ContactGroupID-ContactID" [
  ContactGroupID: string
  ContactID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ContactGroups/($ContactGroupID)/Contacts/($ContactID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves all contacts in a Xero organisation
#
# GET /Contacts
# operationId: getContacts
export def "contacts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. ContactStatus==&quot;ACTIVE&quot;)
  --order: string # Order by an any element (e.g. Name ASC)
  --IDs: list # Filter by a comma separated list of ContactIDs. Allows you to retrieve a specific set of contacts in a single call. (e.g. &quot;00000000-0000-0000-0000-000000000000&quot;)
  --page: int # e.g. page=1 - Up to 100 contacts will be returned in a single API call. (e.g. 1)
  --includeArchived: oneof<nothing, bool> # e.g. includeArchived=true - Contacts with a status of ARCHIVED will be included in the response
  --If-Modified-Since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "IDs" $IDs "csv") (serialize-qp "page" $page "scalar") (serialize-qp "includeArchived" $includeArchived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Contacts" $qp)
  let extra_headers = {"If-Modified-Since": $If_Modified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates or creates one or more contacts in a Xero organisation
#
# POST /Contacts
# operationId: updateOrCreateContacts
# --Contacts item shape: {AccountNumber?: string, AccountsPayableTaxType?: string, AccountsReceivableTaxType?: string, Addresses?: list, Attachments?: list, Balances?: record, BankAccountDetails?: string, BatchPayments?: any, BrandingTheme?: record, ContactGroups?: list, ContactID?: string, ContactNumber?: string, ContactPersons?: list, ContactStatus?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST", DefaultCurrency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", EmailAddress?: string, FirstName?: string, HasAttachments?: bool, HasValidationErrors?: bool, IsCustomer?: bool, IsSupplier?: bool, LastName?: string, Name?: string, PaymentTerms?: record, Phones?: list, PurchasesDefaultAccountCode?: string, PurchasesTrackingCategories?: list, SalesDefaultAccountCode?: string, SalesTrackingCategories?: list, SkypeUserName?: string, StatusAttributeString?: string, TaxNumber?: string, TrackingCategoryName?: string, TrackingCategoryOption?: string, ValidationErrors?: list, XeroNetworkKey?: string}
export def "contacts updateOrCreateContacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --Contacts: list # item shape: {AccountNumber?: string, AccountsPayableTaxType?: string, AccountsReceivableTaxType?: string, Addresses?: list, Attachments?: list, Balances?: record, BankAccountDetails?: string, BatchPayments?: any, BrandingTheme?: record, ContactGroups?: list, ContactID?: string, ContactNumber?: string, ContactPersons?: list, ContactStatus?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST", DefaultCurrency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", EmailAddress?: string, FirstName?: string, HasAttachments?: bool, HasValidationErrors?: bool, IsCustomer?: bool, IsSupplier?: bool, LastName?: string, Name?: string, PaymentTerms?: record, Phones?: list, PurchasesDefaultAccountCode?: string, PurchasesTrackingCategories?: list, SalesDefaultAccountCode?: string, SalesTrackingCategories?: list, SkypeUserName?: string, StatusAttributeString?: string, TaxNumber?: string, TrackingCategoryName?: string, TrackingCategoryOption?: string, ValidationErrors?: list, XeroNetworkKey?: string}
]: any -> record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Contacts" $qp)
  let body = {Contacts: $Contacts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates multiple contacts (bulk) in a Xero organisation
#
# PUT /Contacts
# operationId: createContacts
# --Contacts item shape: {AccountNumber?: string, AccountsPayableTaxType?: string, AccountsReceivableTaxType?: string, Addresses?: list, Attachments?: list, Balances?: record, BankAccountDetails?: string, BatchPayments?: any, BrandingTheme?: record, ContactGroups?: list, ContactID?: string, ContactNumber?: string, ContactPersons?: list, ContactStatus?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST", DefaultCurrency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", EmailAddress?: string, FirstName?: string, HasAttachments?: bool, HasValidationErrors?: bool, IsCustomer?: bool, IsSupplier?: bool, LastName?: string, Name?: string, PaymentTerms?: record, Phones?: list, PurchasesDefaultAccountCode?: string, PurchasesTrackingCategories?: list, SalesDefaultAccountCode?: string, SalesTrackingCategories?: list, SkypeUserName?: string, StatusAttributeString?: string, TaxNumber?: string, TrackingCategoryName?: string, TrackingCategoryOption?: string, ValidationErrors?: list, XeroNetworkKey?: string}
export def "contacts createContacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --Contacts: list # item shape: {AccountNumber?: string, AccountsPayableTaxType?: string, AccountsReceivableTaxType?: string, Addresses?: list, Attachments?: list, Balances?: record, BankAccountDetails?: string, BatchPayments?: any, BrandingTheme?: record, ContactGroups?: list, ContactID?: string, ContactNumber?: string, ContactPersons?: list, ContactStatus?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST", DefaultCurrency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", EmailAddress?: string, FirstName?: string, HasAttachments?: bool, HasValidationErrors?: bool, IsCustomer?: bool, IsSupplier?: bool, LastName?: string, Name?: string, PaymentTerms?: record, Phones?: list, PurchasesDefaultAccountCode?: string, PurchasesTrackingCategories?: list, SalesDefaultAccountCode?: string, SalesTrackingCategories?: list, SkypeUserName?: string, StatusAttributeString?: string, TaxNumber?: string, TrackingCategoryName?: string, TrackingCategoryOption?: string, ValidationErrors?: list, XeroNetworkKey?: string}
]: any -> record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Contacts" $qp)
  let body = {Contacts: $Contacts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a specific contacts in a Xero organisation using a unique contact Id
#
# GET /Contacts/{ContactID}
# operationId: getContact
export def "contacts get-by-ContactID" [
  ContactID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Contacts/($ContactID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific contact in a Xero organisation
#
# POST /Contacts/{ContactID}
# operationId: updateContact
# --Contacts item shape: {AccountNumber?: string, AccountsPayableTaxType?: string, AccountsReceivableTaxType?: string, Addresses?: list, Attachments?: list, Balances?: record, BankAccountDetails?: string, BatchPayments?: any, BrandingTheme?: record, ContactGroups?: list, ContactID?: string, ContactNumber?: string, ContactPersons?: list, ContactStatus?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST", DefaultCurrency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", EmailAddress?: string, FirstName?: string, HasAttachments?: bool, HasValidationErrors?: bool, IsCustomer?: bool, IsSupplier?: bool, LastName?: string, Name?: string, PaymentTerms?: record, Phones?: list, PurchasesDefaultAccountCode?: string, PurchasesTrackingCategories?: list, SalesDefaultAccountCode?: string, SalesTrackingCategories?: list, SkypeUserName?: string, StatusAttributeString?: string, TaxNumber?: string, TrackingCategoryName?: string, TrackingCategoryOption?: string, ValidationErrors?: list, XeroNetworkKey?: string}
export def "contacts updateContact" [
  ContactID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --Contacts: list # item shape: {AccountNumber?: string, AccountsPayableTaxType?: string, AccountsReceivableTaxType?: string, Addresses?: list, Attachments?: list, Balances?: record, BankAccountDetails?: string, BatchPayments?: any, BrandingTheme?: record, ContactGroups?: list, ContactID?: string, ContactNumber?: string, ContactPersons?: list, ContactStatus?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST", DefaultCurrency?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", EmailAddress?: string, FirstName?: string, HasAttachments?: bool, HasValidationErrors?: bool, IsCustomer?: bool, IsSupplier?: bool, LastName?: string, Name?: string, PaymentTerms?: record, Phones?: list, PurchasesDefaultAccountCode?: string, PurchasesTrackingCategories?: list, SalesDefaultAccountCode?: string, SalesTrackingCategories?: list, SkypeUserName?: string, StatusAttributeString?: string, TaxNumber?: string, TrackingCategoryName?: string, TrackingCategoryOption?: string, ValidationErrors?: list, XeroNetworkKey?: string}
]: any -> record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Contacts/($ContactID)")
  let body = {Contacts: $Contacts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves attachments for a specific contact in a Xero organisation
#
# GET /Contacts/{ContactID}/Attachments
# operationId: getContactAttachments
export def "contacts-attachments get-by-ContactID" [
  ContactID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Contacts/($ContactID)/Attachments")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific attachment from a specific contact using a unique attachment Id
#
# GET /Contacts/{ContactID}/Attachments/{AttachmentID}
# operationId: getContactAttachmentById
export def "contacts-attachments get-by-ContactID-AttachmentID" [
  ContactID: string
  AttachmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Contacts/($ContactID)/Attachments/($AttachmentID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific attachment from a specific contact by file name
#
# GET /Contacts/{ContactID}/Attachments/{FileName}
# operationId: getContactAttachmentByFileName
export def "contacts-attachments get-by-ContactID-FileName" [
  ContactID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Contacts/($ContactID)/Attachments/($FileName)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /Contacts/{ContactID}/Attachments/{FileName}
#
# operationId: updateContactAttachmentByFileName
export def "contacts-attachments updateContactAttachmentByFileName" [
  ContactID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Contacts/($ContactID)/Attachments/($FileName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# PUT /Contacts/{ContactID}/Attachments/{FileName}
#
# operationId: createContactAttachmentByFileName
export def "contacts-attachments createContactAttachmentByFileName" [
  ContactID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Contacts/($ContactID)/Attachments/($FileName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Retrieves CIS settings for a specific contact in a Xero organisation
#
# GET /Contacts/{ContactID}/CISSettings
# operationId: getContactCISSettings
export def "contacts-cis-settings get" [
  ContactID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<CISSettings: table<CISEnabled: bool, Rate: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Contacts/($ContactID)/CISSettings")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves history records for a specific contact
#
# GET /Contacts/{ContactID}/History
# operationId: getContactHistory
export def "contacts-history get" [
  ContactID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Contacts/($ContactID)/History")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new history record for a specific contact
#
# PUT /Contacts/{ContactID}/History
# operationId: createContactHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "contacts-history createContactHistory" [
  ContactID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --HistoryRecords: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Contacts/($ContactID)/History")
  let body = {HistoryRecords: $HistoryRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a specific contact by contact number in a Xero organisation
#
# GET /Contacts/{ContactNumber}
# operationId: getContactByContactNumber
export def "contacts get-by-ContactNumber" [
  ContactNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Contacts: table<AccountNumber: string, AccountsPayableTaxType: string, AccountsReceivableTaxType: string, Addresses: list, Attachments: list, Balances: record, BankAccountDetails: string, BatchPayments: record, BrandingTheme: record, ContactGroups: list, ContactID: string, ContactNumber: string, ContactPersons: list, ContactStatus: string, DefaultCurrency: string, Discount: float, EmailAddress: string, FirstName: string, HasAttachments: bool, HasValidationErrors: bool, IsCustomer: bool, IsSupplier: bool, LastName: string, Name: string, PaymentTerms: record, Phones: list, PurchasesDefaultAccountCode: string, PurchasesTrackingCategories: list, SalesDefaultAccountCode: string, SalesTrackingCategories: list, SkypeUserName: string, StatusAttributeString: string, TaxNumber: string, TrackingCategoryName: string, TrackingCategoryOption: string, UpdatedDateUTC: string, ValidationErrors: list, Website: string, XeroNetworkKey: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Contacts/($ContactNumber)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="DRAFT")
  --order: string # Order by an any element (e.g. CreditNoteNumber ASC)
  --page: int # e.g. page=1 – Up to 100 credit notes will be returned in a single API call with line items shown for each credit note (e.g. 1)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --If-Modified-Since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<CreditNotes: table<Allocations: list, AppliedAmount: float, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNoteID: string, CreditNoteNumber: string, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, LineAmountTypes: string, LineItems: list, Payments: list, Reference: string, RemainingCredit: float, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/CreditNotes" $qp)
  let extra_headers = {"If-Modified-Since": $If_Modified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates or creates one or more credit notes
#
# POST /CreditNotes
# operationId: updateOrCreateCreditNotes
# --CreditNotes item shape: {Allocations?: list, AppliedAmount?: float, BrandingThemeID?: string, Contact?: record, CreditNoteID?: string, CreditNoteNumber?: string, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DueDate?: string, FullyPaidOnDate?: string, HasAttachments?: bool, HasErrors?: bool, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, Payments?: list, Reference?: string, RemainingCredit?: float, Status?: "DRAFT"|"SUBMITTED"|"DELETED"|"AUTHORISED"|"PAID"|"VOIDED", StatusAttributeString?: string, SubTotal?: float, Total?: float, TotalTax?: float, Type?: "ACCPAYCREDIT"|"ACCRECCREDIT", ValidationErrors?: list, Warnings?: list}
export def "credit-notes updateOrCreateCreditNotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --CreditNotes: list # item shape: {Allocations?: list, AppliedAmount?: float, BrandingThemeID?: string, Contact?: record, CreditNoteID?: string, CreditNoteNumber?: string, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DueDate?: string, FullyPaidOnDate?: string, HasAttachments?: bool, HasErrors?: bool, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, Payments?: list, Reference?: string, RemainingCredit?: float, Status?: "DRAFT"|"SUBMITTED"|"DELETED"|"AUTHORISED"|"PAID"|"VOIDED", StatusAttributeString?: string, SubTotal?: float, Total?: float, TotalTax?: float, Type?: "ACCPAYCREDIT"|"ACCRECCREDIT", ValidationErrors?: list, Warnings?: list}
]: any -> record<CreditNotes: table<Allocations: list, AppliedAmount: float, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNoteID: string, CreditNoteNumber: string, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, LineAmountTypes: string, LineItems: list, Payments: list, Reference: string, RemainingCredit: float, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/CreditNotes" $qp)
  let body = {CreditNotes: $CreditNotes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new credit note
#
# PUT /CreditNotes
# operationId: createCreditNotes
# --CreditNotes item shape: {Allocations?: list, AppliedAmount?: float, BrandingThemeID?: string, Contact?: record, CreditNoteID?: string, CreditNoteNumber?: string, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DueDate?: string, FullyPaidOnDate?: string, HasAttachments?: bool, HasErrors?: bool, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, Payments?: list, Reference?: string, RemainingCredit?: float, Status?: "DRAFT"|"SUBMITTED"|"DELETED"|"AUTHORISED"|"PAID"|"VOIDED", StatusAttributeString?: string, SubTotal?: float, Total?: float, TotalTax?: float, Type?: "ACCPAYCREDIT"|"ACCRECCREDIT", ValidationErrors?: list, Warnings?: list}
export def "credit-notes createCreditNotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --CreditNotes: list # item shape: {Allocations?: list, AppliedAmount?: float, BrandingThemeID?: string, Contact?: record, CreditNoteID?: string, CreditNoteNumber?: string, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DueDate?: string, FullyPaidOnDate?: string, HasAttachments?: bool, HasErrors?: bool, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, Payments?: list, Reference?: string, RemainingCredit?: float, Status?: "DRAFT"|"SUBMITTED"|"DELETED"|"AUTHORISED"|"PAID"|"VOIDED", StatusAttributeString?: string, SubTotal?: float, Total?: float, TotalTax?: float, Type?: "ACCPAYCREDIT"|"ACCRECCREDIT", ValidationErrors?: list, Warnings?: list}
]: any -> record<CreditNotes: table<Allocations: list, AppliedAmount: float, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNoteID: string, CreditNoteNumber: string, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, LineAmountTypes: string, LineItems: list, Payments: list, Reference: string, RemainingCredit: float, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/CreditNotes" $qp)
  let body = {CreditNotes: $CreditNotes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a specific credit note using a unique credit note Id
#
# GET /CreditNotes/{CreditNoteID}
# operationId: getCreditNote
export def "credit-notes get" [
  CreditNoteID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
]: nothing -> record<CreditNotes: table<Allocations: list, AppliedAmount: float, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNoteID: string, CreditNoteNumber: string, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, LineAmountTypes: string, LineItems: list, Payments: list, Reference: string, RemainingCredit: float, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/CreditNotes/($CreditNoteID)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific credit note
#
# POST /CreditNotes/{CreditNoteID}
# operationId: updateCreditNote
# --CreditNotes item shape: {Allocations?: list, AppliedAmount?: float, BrandingThemeID?: string, Contact?: record, CreditNoteID?: string, CreditNoteNumber?: string, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DueDate?: string, FullyPaidOnDate?: string, HasAttachments?: bool, HasErrors?: bool, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, Payments?: list, Reference?: string, RemainingCredit?: float, Status?: "DRAFT"|"SUBMITTED"|"DELETED"|"AUTHORISED"|"PAID"|"VOIDED", StatusAttributeString?: string, SubTotal?: float, Total?: float, TotalTax?: float, Type?: "ACCPAYCREDIT"|"ACCRECCREDIT", ValidationErrors?: list, Warnings?: list}
export def "credit-notes updateCreditNote" [
  CreditNoteID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --CreditNotes: list # item shape: {Allocations?: list, AppliedAmount?: float, BrandingThemeID?: string, Contact?: record, CreditNoteID?: string, CreditNoteNumber?: string, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DueDate?: string, FullyPaidOnDate?: string, HasAttachments?: bool, HasErrors?: bool, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, Payments?: list, Reference?: string, RemainingCredit?: float, Status?: "DRAFT"|"SUBMITTED"|"DELETED"|"AUTHORISED"|"PAID"|"VOIDED", StatusAttributeString?: string, SubTotal?: float, Total?: float, TotalTax?: float, Type?: "ACCPAYCREDIT"|"ACCRECCREDIT", ValidationErrors?: list, Warnings?: list}
]: any -> record<CreditNotes: table<Allocations: list, AppliedAmount: float, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNoteID: string, CreditNoteNumber: string, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, LineAmountTypes: string, LineItems: list, Payments: list, Reference: string, RemainingCredit: float, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/CreditNotes/($CreditNoteID)" $qp)
  let body = {CreditNotes: $CreditNotes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates allocation for a specific credit note
#
# PUT /CreditNotes/{CreditNoteID}/Allocations
# operationId: createCreditNoteAllocation
# --Allocations item shape: {Amount: float, CreditNote?: record, Date: string, Invoice: record, Overpayment?: record, Prepayment?: record, StatusAttributeString?: string, ValidationErrors?: list}
export def "credit-notes-allocations createCreditNoteAllocation" [
  CreditNoteID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --Allocations: list # item shape: {Amount: float, CreditNote?: record, Date: string, Invoice: record, Overpayment?: record, Prepayment?: record, StatusAttributeString?: string, ValidationErrors?: list}
]: any -> record<Allocations: table<Amount: float, CreditNote: record, Date: string, Invoice: record, Overpayment: record, Prepayment: record, StatusAttributeString: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/CreditNotes/($CreditNoteID)/Allocations" $qp)
  let body = {Allocations: $Allocations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves attachments for a specific credit notes
#
# GET /CreditNotes/{CreditNoteID}/Attachments
# operationId: getCreditNoteAttachments
export def "credit-notes-attachments get-by-CreditNoteID" [
  CreditNoteID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/CreditNotes/($CreditNoteID)/Attachments")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific attachment from a specific credit note using a unique attachment Id
#
# GET /CreditNotes/{CreditNoteID}/Attachments/{AttachmentID}
# operationId: getCreditNoteAttachmentById
export def "credit-notes-attachments get-by-CreditNoteID-AttachmentID" [
  CreditNoteID: string
  AttachmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/CreditNotes/($CreditNoteID)/Attachments/($AttachmentID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific attachment on a specific credit note by file name
#
# GET /CreditNotes/{CreditNoteID}/Attachments/{FileName}
# operationId: getCreditNoteAttachmentByFileName
export def "credit-notes-attachments get-by-CreditNoteID-FileName" [
  CreditNoteID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/CreditNotes/($CreditNoteID)/Attachments/($FileName)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates attachments on a specific credit note by file name
#
# POST /CreditNotes/{CreditNoteID}/Attachments/{FileName}
# operationId: updateCreditNoteAttachmentByFileName
export def "credit-notes-attachments updateCreditNoteAttachmentByFileName" [
  CreditNoteID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/CreditNotes/($CreditNoteID)/Attachments/($FileName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Creates an attachment for a specific credit note
#
# PUT /CreditNotes/{CreditNoteID}/Attachments/{FileName}
# operationId: createCreditNoteAttachmentByFileName
export def "credit-notes-attachments createCreditNoteAttachmentByFileName" [
  CreditNoteID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --IncludeOnline: oneof<nothing, bool> # Allows an attachment to be seen by the end customer within their online invoice (default: false, e.g. true)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "IncludeOnline" $IncludeOnline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/CreditNotes/($CreditNoteID)/Attachments/($FileName)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Retrieves history records of a specific credit note
#
# GET /CreditNotes/{CreditNoteID}/History
# operationId: getCreditNoteHistory
export def "credit-notes-history get" [
  CreditNoteID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/CreditNotes/($CreditNoteID)/History")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves history records of a specific credit note
#
# PUT /CreditNotes/{CreditNoteID}/History
# operationId: createCreditNoteHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "credit-notes-history createCreditNoteHistory" [
  CreditNoteID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --HistoryRecords: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/CreditNotes/($CreditNoteID)/History")
  let body = {HistoryRecords: $HistoryRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves credit notes as PDF files
#
# GET /CreditNotes/{CreditNoteID}/pdf
# operationId: getCreditNoteAsPdf
export def "credit-notes-pdf get" [
  CreditNoteID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/CreditNotes/($CreditNoteID)/pdf")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Code=="USD")
  --order: string # Order by an any element (e.g. Code ASC)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Currencies: table<Code: string, Description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Currencies" $qp)
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new currency for a Xero organisation
#
# PUT /Currencies
# operationId: createCurrency
export def "currencies createCurrency" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --Code: string@Code-completer # 3 letter alpha code for the currency – see list of currency codes
  --Description: string # Name of Currency
]: any -> record<Currencies: table<Code: string, Description: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Currencies")
  let body = {Code: $Code, Description: $Description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="ACTIVE")
  --order: string # Order by an any element (e.g. LastName ASC)
  --If-Modified-Since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Employees: table<EmployeeID: string, ExternalLink: record, FirstName: string, LastName: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Employees" $qp)
  let extra_headers = {"If-Modified-Since": $If_Modified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a single new employees used in Xero payrun
#
# POST /Employees
# operationId: updateOrCreateEmployees
# --Employees item shape: {EmployeeID?: string, ExternalLink?: record, FirstName?: string, LastName?: string, Status?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST"|"DELETED", StatusAttributeString?: string, ValidationErrors?: list}
export def "employees updateOrCreateEmployees" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --Employees: list # item shape: {EmployeeID?: string, ExternalLink?: record, FirstName?: string, LastName?: string, Status?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST"|"DELETED", StatusAttributeString?: string, ValidationErrors?: list}
]: any -> record<Employees: table<EmployeeID: string, ExternalLink: record, FirstName: string, LastName: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Employees" $qp)
  let body = {Employees: $Employees} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates new employees used in Xero payrun
#
# PUT /Employees
# operationId: createEmployees
# --Employees item shape: {EmployeeID?: string, ExternalLink?: record, FirstName?: string, LastName?: string, Status?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST"|"DELETED", StatusAttributeString?: string, ValidationErrors?: list}
export def "employees createEmployees" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --Employees: list # item shape: {EmployeeID?: string, ExternalLink?: record, FirstName?: string, LastName?: string, Status?: "ACTIVE"|"ARCHIVED"|"GDPRREQUEST"|"DELETED", StatusAttributeString?: string, ValidationErrors?: list}
]: any -> record<Employees: table<EmployeeID: string, ExternalLink: record, FirstName: string, LastName: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Employees" $qp)
  let body = {Employees: $Employees} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a specific employee used in Xero payrun using a unique employee Id
#
# GET /Employees/{EmployeeID}
# operationId: getEmployee
export def "employees get" [
  EmployeeID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Employees: table<EmployeeID: string, ExternalLink: record, FirstName: string, LastName: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employees/($EmployeeID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="SUBMITTED")
  --order: string # Order by an any element (e.g. Status ASC)
  --If-Modified-Since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<ExpenseClaims: table<AmountDue: float, AmountPaid: float, ExpenseClaimID: string, PaymentDueDate: string, Payments: list, ReceiptID: string, Receipts: list, ReportingDate: string, Status: string, Total: float, UpdatedDateUTC: string, User: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ExpenseClaims" $qp)
  let extra_headers = {"If-Modified-Since": $If_Modified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates expense claims
#
# PUT /ExpenseClaims
# operationId: createExpenseClaims
# --ExpenseClaims item shape: {ExpenseClaimID?: string, Payments?: list, ReceiptID?: string, Receipts?: list, Status?: "SUBMITTED"|"AUTHORISED"|"PAID"|"VOIDED"|"DELETED", User?: record}
export def "expense-claims createExpenseClaims" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --ExpenseClaims: list # item shape: {ExpenseClaimID?: string, Payments?: list, ReceiptID?: string, Receipts?: list, Status?: "SUBMITTED"|"AUTHORISED"|"PAID"|"VOIDED"|"DELETED", User?: record}
]: any -> record<ExpenseClaims: table<AmountDue: float, AmountPaid: float, ExpenseClaimID: string, PaymentDueDate: string, Payments: list, ReceiptID: string, Receipts: list, ReportingDate: string, Status: string, Total: float, UpdatedDateUTC: string, User: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ExpenseClaims")
  let body = {ExpenseClaims: $ExpenseClaims} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a specific expense claim using a unique expense claim Id
#
# GET /ExpenseClaims/{ExpenseClaimID}
# operationId: getExpenseClaim
export def "expense-claims get" [
  ExpenseClaimID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<ExpenseClaims: table<AmountDue: float, AmountPaid: float, ExpenseClaimID: string, PaymentDueDate: string, Payments: list, ReceiptID: string, Receipts: list, ReportingDate: string, Status: string, Total: float, UpdatedDateUTC: string, User: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ExpenseClaims/($ExpenseClaimID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific expense claims
#
# POST /ExpenseClaims/{ExpenseClaimID}
# operationId: updateExpenseClaim
# --ExpenseClaims item shape: {ExpenseClaimID?: string, Payments?: list, ReceiptID?: string, Receipts?: list, Status?: "SUBMITTED"|"AUTHORISED"|"PAID"|"VOIDED"|"DELETED", User?: record}
export def "expense-claims updateExpenseClaim" [
  ExpenseClaimID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --ExpenseClaims: list # item shape: {ExpenseClaimID?: string, Payments?: list, ReceiptID?: string, Receipts?: list, Status?: "SUBMITTED"|"AUTHORISED"|"PAID"|"VOIDED"|"DELETED", User?: record}
]: any -> record<ExpenseClaims: table<AmountDue: float, AmountPaid: float, ExpenseClaimID: string, PaymentDueDate: string, Payments: list, ReceiptID: string, Receipts: list, ReportingDate: string, Status: string, Total: float, UpdatedDateUTC: string, User: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ExpenseClaims/($ExpenseClaimID)")
  let body = {ExpenseClaims: $ExpenseClaims} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves history records of a specific expense claim
#
# GET /ExpenseClaims/{ExpenseClaimID}/History
# operationId: getExpenseClaimHistory
export def "expense-claims-history get" [
  ExpenseClaimID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ExpenseClaims/($ExpenseClaimID)/History")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a history record for a specific expense claim
#
# PUT /ExpenseClaims/{ExpenseClaimID}/History
# operationId: createExpenseClaimHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "expense-claims-history createExpenseClaimHistory" [
  ExpenseClaimID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --HistoryRecords: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ExpenseClaims/($ExpenseClaimID)/History")
  let body = {HistoryRecords: $HistoryRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<InvoiceReminders: table<Enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/InvoiceReminders/Settings")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="DRAFT")
  --order: string # Order by an any element (e.g. InvoiceNumber ASC)
  --IDs: list # Filter by a comma-separated list of InvoicesIDs. (e.g. &quot;00000000-0000-0000-0000-000000000000&quot;)
  --InvoiceNumbers: list # Filter by a comma-separated list of InvoiceNumbers. (e.g. &quot;INV-001&quot;, &quot;INV-002&quot;)
  --ContactIDs: list # Filter by a comma-separated list of ContactIDs. (e.g. &quot;00000000-0000-0000-0000-000000000000&quot;)
  --Statuses: list # Filter by a comma-separated list Statuses. For faster response times we recommend using these explicit parameters instead of passing OR conditions into the Where filter. (e.g. &quot;DRAFT&quot;, &quot;SUBMITTED&quot;)
  --page: int # e.g. page=1 – Up to 100 invoices will be returned in a single API call with line items shown for each invoice (e.g. 1)
  --includeArchived: oneof<nothing, bool> # e.g. includeArchived=true - Contacts with a status of ARCHIVED will be included in the response
  --createdByMyApp: oneof<nothing, bool> # When set to true you'll only retrieve Invoices created by your app (e.g. false)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --If-Modified-Since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Invoices: table<AmountCredited: float, AmountDue: float, AmountPaid: float, Attachments: list, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNotes: list, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, ExpectedPaymentDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, InvoiceID: string, InvoiceNumber: string, IsDiscounted: bool, LineAmountTypes: string, LineItems: list, Overpayments: list, Payments: list, PlannedPaymentDate: string, Prepayments: list, Reference: string, RepeatingInvoiceID: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalDiscount: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "IDs" $IDs "csv") (serialize-qp "InvoiceNumbers" $InvoiceNumbers "csv") (serialize-qp "ContactIDs" $ContactIDs "csv") (serialize-qp "Statuses" $Statuses "csv") (serialize-qp "page" $page "scalar") (serialize-qp "includeArchived" $includeArchived "scalar") (serialize-qp "createdByMyApp" $createdByMyApp "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Invoices" $qp)
  let extra_headers = {"If-Modified-Since": $If_Modified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates or creates one or more sales invoices or purchase bills
#
# POST /Invoices
# operationId: updateOrCreateInvoices
# --Invoices item shape: {Attachments?: list, BrandingThemeID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DueDate?: string, ExpectedPaymentDate?: string, HasErrors?: bool, InvoiceID?: string, InvoiceNumber?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, PlannedPaymentDate?: string, Reference?: string, RepeatingInvoiceID?: string, SentToContact?: bool, Status?: "DRAFT"|"SUBMITTED"|"DELETED"|"AUTHORISED"|"PAID"|"VOIDED", StatusAttributeString?: string, Type?: "ACCPAY"|"ACCPAYCREDIT"|"APOVERPAYMENT"|"APPREPAYMENT"|"ACCREC"|"ACCRECCREDIT"|"AROVERPAYMENT"|"ARPREPAYMENT", Url?: string, ValidationErrors?: list, Warnings?: list}
export def "invoices updateOrCreateInvoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --Invoices: list # item shape: {Attachments?: list, BrandingThemeID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DueDate?: string, ExpectedPaymentDate?: string, HasErrors?: bool, InvoiceID?: string, InvoiceNumber?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, PlannedPaymentDate?: string, Reference?: string, RepeatingInvoiceID?: string, SentToContact?: bool, Status?: "DRAFT"|"SUBMITTED"|"DELETED"|"AUTHORISED"|"PAID"|"VOIDED", StatusAttributeString?: string, Type?: "ACCPAY"|"ACCPAYCREDIT"|"APOVERPAYMENT"|"APPREPAYMENT"|"ACCREC"|"ACCRECCREDIT"|"AROVERPAYMENT"|"ARPREPAYMENT", Url?: string, ValidationErrors?: list, Warnings?: list}
]: any -> record<Invoices: table<AmountCredited: float, AmountDue: float, AmountPaid: float, Attachments: list, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNotes: list, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, ExpectedPaymentDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, InvoiceID: string, InvoiceNumber: string, IsDiscounted: bool, LineAmountTypes: string, LineItems: list, Overpayments: list, Payments: list, PlannedPaymentDate: string, Prepayments: list, Reference: string, RepeatingInvoiceID: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalDiscount: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Invoices" $qp)
  let body = {Invoices: $Invoices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates one or more sales invoices or purchase bills
#
# PUT /Invoices
# operationId: createInvoices
# --Invoices item shape: {Attachments?: list, BrandingThemeID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DueDate?: string, ExpectedPaymentDate?: string, HasErrors?: bool, InvoiceID?: string, InvoiceNumber?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, PlannedPaymentDate?: string, Reference?: string, RepeatingInvoiceID?: string, SentToContact?: bool, Status?: "DRAFT"|"SUBMITTED"|"DELETED"|"AUTHORISED"|"PAID"|"VOIDED", StatusAttributeString?: string, Type?: "ACCPAY"|"ACCPAYCREDIT"|"APOVERPAYMENT"|"APPREPAYMENT"|"ACCREC"|"ACCRECCREDIT"|"AROVERPAYMENT"|"ARPREPAYMENT", Url?: string, ValidationErrors?: list, Warnings?: list}
export def "invoices createInvoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --Invoices: list # item shape: {Attachments?: list, BrandingThemeID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DueDate?: string, ExpectedPaymentDate?: string, HasErrors?: bool, InvoiceID?: string, InvoiceNumber?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, PlannedPaymentDate?: string, Reference?: string, RepeatingInvoiceID?: string, SentToContact?: bool, Status?: "DRAFT"|"SUBMITTED"|"DELETED"|"AUTHORISED"|"PAID"|"VOIDED", StatusAttributeString?: string, Type?: "ACCPAY"|"ACCPAYCREDIT"|"APOVERPAYMENT"|"APPREPAYMENT"|"ACCREC"|"ACCRECCREDIT"|"AROVERPAYMENT"|"ARPREPAYMENT", Url?: string, ValidationErrors?: list, Warnings?: list}
]: any -> record<Invoices: table<AmountCredited: float, AmountDue: float, AmountPaid: float, Attachments: list, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNotes: list, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, ExpectedPaymentDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, InvoiceID: string, InvoiceNumber: string, IsDiscounted: bool, LineAmountTypes: string, LineItems: list, Overpayments: list, Payments: list, PlannedPaymentDate: string, Prepayments: list, Reference: string, RepeatingInvoiceID: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalDiscount: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Invoices" $qp)
  let body = {Invoices: $Invoices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a specific sales invoice or purchase bill using a unique invoice Id
#
# GET /Invoices/{InvoiceID}
# operationId: getInvoice
export def "invoices get" [
  InvoiceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
]: nothing -> record<Invoices: table<AmountCredited: float, AmountDue: float, AmountPaid: float, Attachments: list, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNotes: list, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, ExpectedPaymentDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, InvoiceID: string, InvoiceNumber: string, IsDiscounted: bool, LineAmountTypes: string, LineItems: list, Overpayments: list, Payments: list, PlannedPaymentDate: string, Prepayments: list, Reference: string, RepeatingInvoiceID: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalDiscount: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Invoices/($InvoiceID)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific sales invoices or purchase bills
#
# POST /Invoices/{InvoiceID}
# operationId: updateInvoice
# --Invoices item shape: {Attachments?: list, BrandingThemeID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DueDate?: string, ExpectedPaymentDate?: string, HasErrors?: bool, InvoiceID?: string, InvoiceNumber?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, PlannedPaymentDate?: string, Reference?: string, RepeatingInvoiceID?: string, SentToContact?: bool, Status?: "DRAFT"|"SUBMITTED"|"DELETED"|"AUTHORISED"|"PAID"|"VOIDED", StatusAttributeString?: string, Type?: "ACCPAY"|"ACCPAYCREDIT"|"APOVERPAYMENT"|"APPREPAYMENT"|"ACCREC"|"ACCRECCREDIT"|"AROVERPAYMENT"|"ARPREPAYMENT", Url?: string, ValidationErrors?: list, Warnings?: list}
export def "invoices updateInvoice" [
  InvoiceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --Invoices: list # item shape: {Attachments?: list, BrandingThemeID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DueDate?: string, ExpectedPaymentDate?: string, HasErrors?: bool, InvoiceID?: string, InvoiceNumber?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, PlannedPaymentDate?: string, Reference?: string, RepeatingInvoiceID?: string, SentToContact?: bool, Status?: "DRAFT"|"SUBMITTED"|"DELETED"|"AUTHORISED"|"PAID"|"VOIDED", StatusAttributeString?: string, Type?: "ACCPAY"|"ACCPAYCREDIT"|"APOVERPAYMENT"|"APPREPAYMENT"|"ACCREC"|"ACCRECCREDIT"|"AROVERPAYMENT"|"ARPREPAYMENT", Url?: string, ValidationErrors?: list, Warnings?: list}
]: any -> record<Invoices: table<AmountCredited: float, AmountDue: float, AmountPaid: float, Attachments: list, BrandingThemeID: string, CISDeduction: float, CISRate: float, Contact: record, CreditNotes: list, CurrencyCode: string, CurrencyRate: float, Date: string, DueDate: string, ExpectedPaymentDate: string, FullyPaidOnDate: string, HasAttachments: bool, HasErrors: bool, InvoiceID: string, InvoiceNumber: string, IsDiscounted: bool, LineAmountTypes: string, LineItems: list, Overpayments: list, Payments: list, PlannedPaymentDate: string, Prepayments: list, Reference: string, RepeatingInvoiceID: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Total: float, TotalDiscount: float, TotalTax: float, Type: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Invoices/($InvoiceID)" $qp)
  let body = {Invoices: $Invoices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves attachments for a specific invoice or purchase bill
#
# GET /Invoices/{InvoiceID}/Attachments
# operationId: getInvoiceAttachments
export def "invoices-attachments get-by-InvoiceID" [
  InvoiceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Invoices/($InvoiceID)/Attachments")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific attachment from a specific invoices or purchase bills by using a unique attachment Id
#
# GET /Invoices/{InvoiceID}/Attachments/{AttachmentID}
# operationId: getInvoiceAttachmentById
export def "invoices-attachments get-by-InvoiceID-AttachmentID" [
  InvoiceID: string
  AttachmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Invoices/($InvoiceID)/Attachments/($AttachmentID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves an attachment from a specific invoice or purchase bill by filename
#
# GET /Invoices/{InvoiceID}/Attachments/{FileName}
# operationId: getInvoiceAttachmentByFileName
export def "invoices-attachments get-by-InvoiceID-FileName" [
  InvoiceID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Invoices/($InvoiceID)/Attachments/($FileName)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an attachment from a specific invoices or purchase bill by filename
#
# POST /Invoices/{InvoiceID}/Attachments/{FileName}
# operationId: updateInvoiceAttachmentByFileName
export def "invoices-attachments updateInvoiceAttachmentByFileName" [
  InvoiceID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Invoices/($InvoiceID)/Attachments/($FileName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Creates an attachment for a specific invoice or purchase bill by filename
#
# PUT /Invoices/{InvoiceID}/Attachments/{FileName}
# operationId: createInvoiceAttachmentByFileName
export def "invoices-attachments createInvoiceAttachmentByFileName" [
  InvoiceID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --IncludeOnline: oneof<nothing, bool> # Allows an attachment to be seen by the end customer within their online invoice (default: false, e.g. true)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "IncludeOnline" $IncludeOnline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Invoices/($InvoiceID)/Attachments/($FileName)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Sends a copy of a specific invoice to related contact via email
#
# POST /Invoices/{InvoiceID}/Email
# operationId: emailInvoice
export def "invoices-email emailInvoice" [
  InvoiceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --Status: string # Need at least one field to create an empty JSON payload
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Invoices/($InvoiceID)/Email")
  let body = {Status: $Status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves history records for a specific invoice
#
# GET /Invoices/{InvoiceID}/History
# operationId: getInvoiceHistory
export def "invoices-history get" [
  InvoiceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Invoices/($InvoiceID)/History")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a history record for a specific invoice
#
# PUT /Invoices/{InvoiceID}/History
# operationId: createInvoiceHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "invoices-history createInvoiceHistory" [
  InvoiceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --HistoryRecords: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Invoices/($InvoiceID)/History")
  let body = {HistoryRecords: $HistoryRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a URL to an online invoice
#
# GET /Invoices/{InvoiceID}/OnlineInvoice
# operationId: getOnlineInvoice
export def "invoices-online-invoice get" [
  InvoiceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<OnlineInvoices: table<OnlineInvoiceUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Invoices/($InvoiceID)/OnlineInvoice")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves invoices or purchase bills as PDF files
#
# GET /Invoices/{InvoiceID}/pdf
# operationId: getInvoiceAsPdf
export def "invoices-pdf get" [
  InvoiceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Invoices/($InvoiceID)/pdf")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. IsSold==true)
  --order: string # Order by an any element (e.g. Code ASC)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --If-Modified-Since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Items: table<Code: string, Description: string, InventoryAssetAccountCode: string, IsPurchased: bool, IsSold: bool, IsTrackedAsInventory: bool, ItemID: string, Name: string, PurchaseDescription: string, PurchaseDetails: record, QuantityOnHand: float, SalesDetails: record, StatusAttributeString: string, TotalCostPool: float, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Items" $qp)
  let extra_headers = {"If-Modified-Since": $If_Modified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates or creates one or more items
#
# POST /Items
# operationId: updateOrCreateItems
# --Items item shape: {Code: string, Description?: string, InventoryAssetAccountCode?: string, IsPurchased?: bool, IsSold?: bool, IsTrackedAsInventory?: bool, ItemID?: string, Name?: string, PurchaseDescription?: string, PurchaseDetails?: record, QuantityOnHand?: float, SalesDetails?: record, StatusAttributeString?: string, TotalCostPool?: float, ValidationErrors?: list}
export def "items updateOrCreateItems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --Items: list # item shape: {Code: string, Description?: string, InventoryAssetAccountCode?: string, IsPurchased?: bool, IsSold?: bool, IsTrackedAsInventory?: bool, ItemID?: string, Name?: string, PurchaseDescription?: string, PurchaseDetails?: record, QuantityOnHand?: float, SalesDetails?: record, StatusAttributeString?: string, TotalCostPool?: float, ValidationErrors?: list}
]: any -> record<Items: table<Code: string, Description: string, InventoryAssetAccountCode: string, IsPurchased: bool, IsSold: bool, IsTrackedAsInventory: bool, ItemID: string, Name: string, PurchaseDescription: string, PurchaseDetails: record, QuantityOnHand: float, SalesDetails: record, StatusAttributeString: string, TotalCostPool: float, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Items" $qp)
  let body = {Items: $Items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates one or more items
#
# PUT /Items
# operationId: createItems
# --Items item shape: {Code: string, Description?: string, InventoryAssetAccountCode?: string, IsPurchased?: bool, IsSold?: bool, IsTrackedAsInventory?: bool, ItemID?: string, Name?: string, PurchaseDescription?: string, PurchaseDetails?: record, QuantityOnHand?: float, SalesDetails?: record, StatusAttributeString?: string, TotalCostPool?: float, ValidationErrors?: list}
export def "items createItems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --Items: list # item shape: {Code: string, Description?: string, InventoryAssetAccountCode?: string, IsPurchased?: bool, IsSold?: bool, IsTrackedAsInventory?: bool, ItemID?: string, Name?: string, PurchaseDescription?: string, PurchaseDetails?: record, QuantityOnHand?: float, SalesDetails?: record, StatusAttributeString?: string, TotalCostPool?: float, ValidationErrors?: list}
]: any -> record<Items: table<Code: string, Description: string, InventoryAssetAccountCode: string, IsPurchased: bool, IsSold: bool, IsTrackedAsInventory: bool, ItemID: string, Name: string, PurchaseDescription: string, PurchaseDetails: record, QuantityOnHand: float, SalesDetails: record, StatusAttributeString: string, TotalCostPool: float, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Items" $qp)
  let body = {Items: $Items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a specific item
#
# DELETE /Items/{ItemID}
# operationId: deleteItem
export def "items delete" [
  ItemID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Items/($ItemID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific item using a unique item Id
#
# GET /Items/{ItemID}
# operationId: getItem
export def "items get" [
  ItemID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
]: nothing -> record<Items: table<Code: string, Description: string, InventoryAssetAccountCode: string, IsPurchased: bool, IsSold: bool, IsTrackedAsInventory: bool, ItemID: string, Name: string, PurchaseDescription: string, PurchaseDetails: record, QuantityOnHand: float, SalesDetails: record, StatusAttributeString: string, TotalCostPool: float, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Items/($ItemID)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific item
#
# POST /Items/{ItemID}
# operationId: updateItem
# --Items item shape: {Code: string, Description?: string, InventoryAssetAccountCode?: string, IsPurchased?: bool, IsSold?: bool, IsTrackedAsInventory?: bool, ItemID?: string, Name?: string, PurchaseDescription?: string, PurchaseDetails?: record, QuantityOnHand?: float, SalesDetails?: record, StatusAttributeString?: string, TotalCostPool?: float, ValidationErrors?: list}
export def "items updateItem" [
  ItemID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --Items: list # item shape: {Code: string, Description?: string, InventoryAssetAccountCode?: string, IsPurchased?: bool, IsSold?: bool, IsTrackedAsInventory?: bool, ItemID?: string, Name?: string, PurchaseDescription?: string, PurchaseDetails?: record, QuantityOnHand?: float, SalesDetails?: record, StatusAttributeString?: string, TotalCostPool?: float, ValidationErrors?: list}
]: any -> record<Items: table<Code: string, Description: string, InventoryAssetAccountCode: string, IsPurchased: bool, IsSold: bool, IsTrackedAsInventory: bool, ItemID: string, Name: string, PurchaseDescription: string, PurchaseDetails: record, QuantityOnHand: float, SalesDetails: record, StatusAttributeString: string, TotalCostPool: float, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Items/($ItemID)" $qp)
  let body = {Items: $Items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves history for a specific item
#
# GET /Items/{ItemID}/History
# operationId: getItemHistory
export def "items-history get" [
  ItemID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Items/($ItemID)/History")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a history record for a specific item
#
# PUT /Items/{ItemID}/History
# operationId: createItemHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "items-history createItemHistory" [
  ItemID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --HistoryRecords: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Items/($ItemID)/History")
  let body = {HistoryRecords: $HistoryRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Offset by a specified journal number. e.g. journals with a JournalNumber greater than the offset will be returned (e.g. 10)
  --paymentsOnly: oneof<nothing, bool> # Filter to retrieve journals on a cash basis. Journals are returned on an accrual basis by default.
  --If-Modified-Since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Journals: table<CreatedDateUTC: string, JournalDate: string, JournalID: string, JournalLines: list, JournalNumber: int, Reference: string, SourceID: string, SourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "paymentsOnly" $paymentsOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Journals" $qp)
  let extra_headers = {"If-Modified-Since": $If_Modified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific journal using a unique journal Id.
#
# GET /Journals/{JournalID}
# operationId: getJournal
export def "journals get" [
  JournalID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Journals: table<CreatedDateUTC: string, JournalDate: string, JournalID: string, JournalLines: list, JournalNumber: int, Reference: string, SourceID: string, SourceType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Journals/($JournalID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Up to 100 linked transactions will be returned in a single API call. Use the page parameter to specify the page to be returned e.g. page=1. (e.g. 1)
  --LinkedTransactionID: string # The Xero identifier for an Linked Transaction (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --SourceTransactionID: string # Filter by the SourceTransactionID. Get the linked transactions created from a particular ACCPAY invoice (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --ContactID: string # Filter by the ContactID. Get all the linked transactions that have been assigned to a particular customer. (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --Status: string # Filter by the combination of ContactID and Status. Get  the linked transactions associated to a  customer and with a status (e.g. APPROVED)
  --TargetTransactionID: string # Filter by the TargetTransactionID. Get all the linked transactions allocated to a particular ACCREC invoice (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<LinkedTransactions: table<ContactID: string, LinkedTransactionID: string, SourceLineItemID: string, SourceTransactionID: string, SourceTransactionTypeCode: string, Status: string, TargetLineItemID: string, TargetTransactionID: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "LinkedTransactionID" $LinkedTransactionID "scalar") (serialize-qp "SourceTransactionID" $SourceTransactionID "scalar") (serialize-qp "ContactID" $ContactID "scalar") (serialize-qp "Status" $Status "scalar") (serialize-qp "TargetTransactionID" $TargetTransactionID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/LinkedTransactions" $qp)
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates linked transactions (billable expenses)
#
# PUT /LinkedTransactions
# operationId: createLinkedTransaction
# --ValidationErrors item shape: {Message?: string}
export def "linked-transactions createLinkedTransaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --ContactID: string # Filter by the combination of ContactID and Status. Get all the linked transactions that have been assigned to a particular customer and have a particular status e.g. GET /LinkedTransactions?ContactID=4bb34b03-3378-4bb2-a0ed-6345abf3224e&Status=APPROVED. (format: uuid)
  --LinkedTransactionID: string # The Xero identifier for an Linked Transaction e.g./LinkedTransactions/297c2dc5-cc47-4afd-8ec8-74990b8761e9 (format: uuid)
  --SourceLineItemID: string # The line item identifier from the source transaction. (format: uuid)
  --SourceTransactionID: string # Filter by the SourceTransactionID. Get all the linked transactions created from a particular ACCPAY invoice (format: uuid)
  --SourceTransactionTypeCode: string@SourceTransactionTypeCode-completer # The Type of the source tranasction. This will be ACCPAY if the linked transaction was created from an invoice and SPEND if it was created from a bank transaction.
  --Status: string@Status-completer-1 # Filter by the combination of ContactID and Status. Get all the linked transactions that have been assigned to a particular customer and have a particular status e.g. GET /LinkedTransactions?ContactID=4bb34b03-3378-4bb2-a0ed-6345abf3224e&Status=APPROVED.
  --TargetLineItemID: string # The line item identifier from the target transaction. It is possible  to link multiple billable expenses to the same TargetLineItemID. (format: uuid)
  --TargetTransactionID: string # Filter by the TargetTransactionID. Get all the linked transactions  allocated to a particular ACCREC invoice (format: uuid)
  --Type: string@Type-completer-1 # This will always be BILLABLEEXPENSE. More types may be added in future.
  --ValidationErrors: list # Displays array of validation error messages from the API — item shape: {Message?: string}
]: any -> record<LinkedTransactions: table<ContactID: string, LinkedTransactionID: string, SourceLineItemID: string, SourceTransactionID: string, SourceTransactionTypeCode: string, Status: string, TargetLineItemID: string, TargetTransactionID: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/LinkedTransactions")
  let body = {ContactID: $ContactID, LinkedTransactionID: $LinkedTransactionID, SourceLineItemID: $SourceLineItemID, SourceTransactionID: $SourceTransactionID, SourceTransactionTypeCode: $SourceTransactionTypeCode, Status: $Status, TargetLineItemID: $TargetLineItemID, TargetTransactionID: $TargetTransactionID, Type: $Type, ValidationErrors: $ValidationErrors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a specific linked transactions (billable expenses)
#
# DELETE /LinkedTransactions/{LinkedTransactionID}
# operationId: deleteLinkedTransaction
export def "linked-transactions delete" [
  LinkedTransactionID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/LinkedTransactions/($LinkedTransactionID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific linked transaction (billable expenses) using a unique linked transaction Id
#
# GET /LinkedTransactions/{LinkedTransactionID}
# operationId: getLinkedTransaction
export def "linked-transactions get" [
  LinkedTransactionID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<LinkedTransactions: table<ContactID: string, LinkedTransactionID: string, SourceLineItemID: string, SourceTransactionID: string, SourceTransactionTypeCode: string, Status: string, TargetLineItemID: string, TargetTransactionID: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/LinkedTransactions/($LinkedTransactionID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific linked transactions (billable expenses)
#
# POST /LinkedTransactions/{LinkedTransactionID}
# operationId: updateLinkedTransaction
# --LinkedTransactions item shape: {ContactID?: string, LinkedTransactionID?: string, SourceLineItemID?: string, SourceTransactionID?: string, SourceTransactionTypeCode?: "ACCPAY"|"SPEND", Status?: "APPROVED"|"DRAFT"|"ONDRAFT"|"BILLED"|"VOIDED", TargetLineItemID?: string, TargetTransactionID?: string, Type?: "BILLABLEEXPENSE", ValidationErrors?: list}
export def "linked-transactions updateLinkedTransaction" [
  LinkedTransactionID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --LinkedTransactions: list # item shape: {ContactID?: string, LinkedTransactionID?: string, SourceLineItemID?: string, SourceTransactionID?: string, SourceTransactionTypeCode?: "ACCPAY"|"SPEND", Status?: "APPROVED"|"DRAFT"|"ONDRAFT"|"BILLED"|"VOIDED", TargetLineItemID?: string, TargetTransactionID?: string, Type?: "BILLABLEEXPENSE", ValidationErrors?: list}
]: any -> record<LinkedTransactions: table<ContactID: string, LinkedTransactionID: string, SourceLineItemID: string, SourceTransactionID: string, SourceTransactionTypeCode: string, Status: string, TargetLineItemID: string, TargetTransactionID: string, Type: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/LinkedTransactions/($LinkedTransactionID)")
  let body = {LinkedTransactions: $LinkedTransactions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="DRAFT")
  --order: string # Order by an any element (e.g. Date ASC)
  --page: int # e.g. page=1 – Up to 100 manual journals will be returned in a single API call with line items shown for each overpayment (e.g. 1)
  --If-Modified-Since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<ManualJournals: table<Attachments: list, Date: string, HasAttachments: bool, JournalLines: list, LineAmountTypes: string, ManualJournalID: string, Narration: string, ShowOnCashBasisReports: bool, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ManualJournals" $qp)
  let extra_headers = {"If-Modified-Since": $If_Modified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates or creates a single manual journal
#
# POST /ManualJournals
# operationId: updateOrCreateManualJournals
# --ManualJournals item shape: {Attachments?: list, Date?: string, JournalLines?: list, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", ManualJournalID?: string, Narration: string, ShowOnCashBasisReports?: bool, Status?: "DRAFT"|"POSTED"|"DELETED"|"VOIDED"|"ARCHIVED", StatusAttributeString?: string, Url?: string, ValidationErrors?: list, Warnings?: list}
export def "manual-journals updateOrCreateManualJournals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --ManualJournals: list # item shape: {Attachments?: list, Date?: string, JournalLines?: list, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", ManualJournalID?: string, Narration: string, ShowOnCashBasisReports?: bool, Status?: "DRAFT"|"POSTED"|"DELETED"|"VOIDED"|"ARCHIVED", StatusAttributeString?: string, Url?: string, ValidationErrors?: list, Warnings?: list}
]: any -> record<ManualJournals: table<Attachments: list, Date: string, HasAttachments: bool, JournalLines: list, LineAmountTypes: string, ManualJournalID: string, Narration: string, ShowOnCashBasisReports: bool, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ManualJournals" $qp)
  let body = {ManualJournals: $ManualJournals} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates one or more manual journals
#
# PUT /ManualJournals
# operationId: createManualJournals
# --ManualJournals item shape: {Attachments?: list, Date?: string, JournalLines?: list, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", ManualJournalID?: string, Narration: string, ShowOnCashBasisReports?: bool, Status?: "DRAFT"|"POSTED"|"DELETED"|"VOIDED"|"ARCHIVED", StatusAttributeString?: string, Url?: string, ValidationErrors?: list, Warnings?: list}
export def "manual-journals createManualJournals" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --ManualJournals: list # item shape: {Attachments?: list, Date?: string, JournalLines?: list, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", ManualJournalID?: string, Narration: string, ShowOnCashBasisReports?: bool, Status?: "DRAFT"|"POSTED"|"DELETED"|"VOIDED"|"ARCHIVED", StatusAttributeString?: string, Url?: string, ValidationErrors?: list, Warnings?: list}
]: any -> record<ManualJournals: table<Attachments: list, Date: string, HasAttachments: bool, JournalLines: list, LineAmountTypes: string, ManualJournalID: string, Narration: string, ShowOnCashBasisReports: bool, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ManualJournals" $qp)
  let body = {ManualJournals: $ManualJournals} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a specific manual journal
#
# GET /ManualJournals/{ManualJournalID}
# operationId: getManualJournal
export def "manual-journals get" [
  ManualJournalID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<ManualJournals: table<Attachments: list, Date: string, HasAttachments: bool, JournalLines: list, LineAmountTypes: string, ManualJournalID: string, Narration: string, ShowOnCashBasisReports: bool, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ManualJournals/($ManualJournalID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific manual journal
#
# POST /ManualJournals/{ManualJournalID}
# operationId: updateManualJournal
# --ManualJournals item shape: {Attachments?: list, Date?: string, JournalLines?: list, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", ManualJournalID?: string, Narration: string, ShowOnCashBasisReports?: bool, Status?: "DRAFT"|"POSTED"|"DELETED"|"VOIDED"|"ARCHIVED", StatusAttributeString?: string, Url?: string, ValidationErrors?: list, Warnings?: list}
export def "manual-journals updateManualJournal" [
  ManualJournalID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --ManualJournals: list # item shape: {Attachments?: list, Date?: string, JournalLines?: list, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", ManualJournalID?: string, Narration: string, ShowOnCashBasisReports?: bool, Status?: "DRAFT"|"POSTED"|"DELETED"|"VOIDED"|"ARCHIVED", StatusAttributeString?: string, Url?: string, ValidationErrors?: list, Warnings?: list}
]: any -> record<ManualJournals: table<Attachments: list, Date: string, HasAttachments: bool, JournalLines: list, LineAmountTypes: string, ManualJournalID: string, Narration: string, ShowOnCashBasisReports: bool, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, Url: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ManualJournals/($ManualJournalID)")
  let body = {ManualJournals: $ManualJournals} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves attachment for a specific manual journal
#
# GET /ManualJournals/{ManualJournalID}/Attachments
# operationId: getManualJournalAttachments
export def "manual-journals-attachments get-by-ManualJournalID" [
  ManualJournalID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ManualJournals/($ManualJournalID)/Attachments")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows you to retrieve a specific attachment from a specific manual journal using a unique attachment Id
#
# GET /ManualJournals/{ManualJournalID}/Attachments/{AttachmentID}
# operationId: getManualJournalAttachmentById
export def "manual-journals-attachments get-by-ManualJournalID-AttachmentID" [
  ManualJournalID: string
  AttachmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ManualJournals/($ManualJournalID)/Attachments/($AttachmentID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific attachment from a specific manual journal by file name
#
# GET /ManualJournals/{ManualJournalID}/Attachments/{FileName}
# operationId: getManualJournalAttachmentByFileName
export def "manual-journals-attachments get-by-ManualJournalID-FileName" [
  ManualJournalID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ManualJournals/($ManualJournalID)/Attachments/($FileName)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific attachment from a specific manual journal by file name
#
# POST /ManualJournals/{ManualJournalID}/Attachments/{FileName}
# operationId: updateManualJournalAttachmentByFileName
export def "manual-journals-attachments updateManualJournalAttachmentByFileName" [
  ManualJournalID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ManualJournals/($ManualJournalID)/Attachments/($FileName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Creates a specific attachment for a specific manual journal by file name
#
# PUT /ManualJournals/{ManualJournalID}/Attachments/{FileName}
# operationId: createManualJournalAttachmentByFileName
export def "manual-journals-attachments createManualJournalAttachmentByFileName" [
  ManualJournalID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ManualJournals/($ManualJournalID)/Attachments/($FileName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Retrieves history for a specific manual journal
#
# GET /ManualJournals/{ManualJournalID}/History
# operationId: getManualJournalsHistory
export def "manual-journals-history get" [
  ManualJournalID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ManualJournals/($ManualJournalID)/History")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a history record for a specific manual journal
#
# PUT /ManualJournals/{ManualJournalID}/History
# operationId: createManualJournalHistoryRecord
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "manual-journals-history createManualJournalHistoryRecord" [
  ManualJournalID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --HistoryRecords: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ManualJournals/($ManualJournalID)/History")
  let body = {HistoryRecords: $HistoryRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Organisations: table<APIKey: string, Addresses: list, BaseCurrency: string, Class: string, CountryCode: string, CreatedDateUTC: string, DefaultPurchasesTax: string, DefaultSalesTax: string, Edition: string, EmployerIdentificationNumber: string, EndOfYearLockDate: string, ExternalLinks: list, FinancialYearEndDay: int, FinancialYearEndMonth: int, IsDemoCompany: bool, LegalName: string, LineOfBusiness: string, Name: string, OrganisationEntityType: string, OrganisationID: string, OrganisationStatus: string, OrganisationType: string, PaymentTerms: record, PaysTax: bool, PeriodLockDate: string, Phones: list, RegistrationNumber: string, SalesTaxBasis: string, SalesTaxPeriod: string, ShortCode: string, TaxNumber: string, Timezone: string, Version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Organisation")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Actions: table<Name: string, Status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Organisation/Actions")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the CIS settings for the Xero organistaion.
#
# GET /Organisation/{OrganisationID}/CISSettings
# operationId: getOrganisationCISSettings
export def "organisation-cis-settings get" [
  OrganisationID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<CISSettings: table<CISContractorEnabled: bool, CISSubContractorEnabled: bool, Rate: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Organisation/($OrganisationID)/CISSettings")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="AUTHORISED")
  --order: string # Order by an any element (e.g. Status ASC)
  --page: int # e.g. page=1 – Up to 100 overpayments will be returned in a single API call with line items shown for each overpayment (e.g. 1)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --If-Modified-Since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Overpayments: table<Allocations: list, AppliedAmount: float, Attachments: list, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, Payments: list, RemainingCredit: float, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Overpayments" $qp)
  let extra_headers = {"If-Modified-Since": $If_Modified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific overpayment using a unique overpayment Id
#
# GET /Overpayments/{OverpaymentID}
# operationId: getOverpayment
export def "overpayments get" [
  OverpaymentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Overpayments: table<Allocations: list, AppliedAmount: float, Attachments: list, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, OverpaymentID: string, Payments: list, RemainingCredit: float, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Overpayments/($OverpaymentID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a single allocation for a specific overpayment
#
# PUT /Overpayments/{OverpaymentID}/Allocations
# operationId: createOverpaymentAllocations
# --Allocations item shape: {Amount: float, CreditNote?: record, Date: string, Invoice: record, Overpayment?: record, Prepayment?: record, StatusAttributeString?: string, ValidationErrors?: list}
export def "overpayments-allocations createOverpaymentAllocations" [
  OverpaymentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --Allocations: list # item shape: {Amount: float, CreditNote?: record, Date: string, Invoice: record, Overpayment?: record, Prepayment?: record, StatusAttributeString?: string, ValidationErrors?: list}
]: any -> record<Allocations: table<Amount: float, CreditNote: record, Date: string, Invoice: record, Overpayment: record, Prepayment: record, StatusAttributeString: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Overpayments/($OverpaymentID)/Allocations" $qp)
  let body = {Allocations: $Allocations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves history records of a specific overpayment
#
# GET /Overpayments/{OverpaymentID}/History
# operationId: getOverpaymentHistory
export def "overpayments-history get" [
  OverpaymentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Overpayments/($OverpaymentID)/History")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a history record for a specific overpayment
#
# PUT /Overpayments/{OverpaymentID}/History
# operationId: createOverpaymentHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "overpayments-history createOverpaymentHistory" [
  OverpaymentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --HistoryRecords: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Overpayments/($OverpaymentID)/History")
  let body = {HistoryRecords: $HistoryRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<PaymentServices: table<PayNowText: string, PaymentServiceID: string, PaymentServiceName: string, PaymentServiceType: string, PaymentServiceUrl: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/PaymentServices")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a payment service
#
# PUT /PaymentServices
# operationId: createPaymentService
# --PaymentServices item shape: {PayNowText?: string, PaymentServiceID?: string, PaymentServiceName?: string, PaymentServiceType?: string, PaymentServiceUrl?: string, ValidationErrors?: list}
export def "payment-services createPaymentService" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --PaymentServices: list # item shape: {PayNowText?: string, PaymentServiceID?: string, PaymentServiceName?: string, PaymentServiceType?: string, PaymentServiceUrl?: string, ValidationErrors?: list}
]: any -> record<PaymentServices: table<PayNowText: string, PaymentServiceID: string, PaymentServiceName: string, PaymentServiceType: string, PaymentServiceUrl: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/PaymentServices")
  let body = {PaymentServices: $PaymentServices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="AUTHORISED")
  --order: string # Order by an any element (e.g. Amount ASC)
  --page: int # Up to 100 payments will be returned in a single API call (e.g. 1)
  --If-Modified-Since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Payments: table<Account: record, Amount: float, BankAccountNumber: string, BatchPaymentID: string, Code: string, CreditNote: record, CreditNoteNumber: string, CurrencyRate: float, Date: string, Details: string, HasAccount: bool, HasValidationErrors: bool, Invoice: record, InvoiceNumber: string, IsReconciled: bool, Overpayment: record, Particulars: string, PaymentID: string, PaymentType: string, Prepayment: record, Reference: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Payments" $qp)
  let extra_headers = {"If-Modified-Since": $If_Modified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a single payment for invoice or credit notes
#
# POST /Payments
# operationId: createPayment
# --Account shape: {AccountID?: string, AddToWatchlist?: bool, BankAccountNumber?: string, BankAccountType?: "BANK"|"CREDITCARD"|"PAYPAL"|"NONE"|"", Code?: string, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", Description?: string, EnablePaymentsToAccount?: bool, Name?: string, ReportingCode?: string, ShowInExpenseClaims?: bool, Status?: "ACTIVE"|"ARCHIVED"|"DELETED", TaxType?: string, Type?: "BANK"|"CURRENT"|"CURRLIAB"|"DEPRECIATN"|"DIRECTCOSTS"|"EQUITY"|"EXPENSE"|"FIXED"|"INVENTORY"|"LIABILITY"|"NONCURRENT"|"OTHERINCOME"|"OVERHEADS"|"PREPAYMENT"|"REVENUE"|"SALES"|"TERMLIAB"|"PAYGLIABILITY"|"PAYG"|"SUPERANNUATIONEXPENSE"|"SUPERANNUATIONLIABILITY"|"WAGESEXPENSE", ValidationErrors?: list}
# --CreditNote shape: {Allocations?: list, AppliedAmount?: float, BrandingThemeID?: string, Contact?: record, CreditNoteID?: string, CreditNoteNumber?: string, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DueDate?: string, FullyPaidOnDate?: string, HasAttachments?: bool, HasErrors?: bool, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, Payments?: list, Reference?: string, RemainingCredit?: float, Status?: "DRAFT"|"SUBMITTED"|"DELETED"|"AUTHORISED"|"PAID"|"VOIDED", StatusAttributeString?: string, SubTotal?: float, Total?: float, TotalTax?: float, Type?: "ACCPAYCREDIT"|"ACCRECCREDIT", ValidationErrors?: list, Warnings?: list}
# --Invoice shape: {Attachments?: list, BrandingThemeID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DueDate?: string, ExpectedPaymentDate?: string, HasErrors?: bool, InvoiceID?: string, InvoiceNumber?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, PlannedPaymentDate?: string, Reference?: string, RepeatingInvoiceID?: string, SentToContact?: bool, Status?: "DRAFT"|"SUBMITTED"|"DELETED"|"AUTHORISED"|"PAID"|"VOIDED", StatusAttributeString?: string, Type?: "ACCPAY"|"ACCPAYCREDIT"|"APOVERPAYMENT"|"APPREPAYMENT"|"ACCREC"|"ACCRECCREDIT"|"AROVERPAYMENT"|"ARPREPAYMENT", Url?: string, ValidationErrors?: list, Warnings?: list}
# --Overpayment shape: {Allocations?: list, AppliedAmount?: float, Attachments?: list, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, OverpaymentID?: string, Payments?: list, RemainingCredit?: float, Status?: "AUTHORISED"|"PAID"|"VOIDED", SubTotal?: float, Total?: float, TotalTax?: float, Type?: "RECEIVE-OVERPAYMENT"|"SPEND-OVERPAYMENT"|"AROVERPAYMENT"}
# --Prepayment shape: {Allocations?: list, AppliedAmount?: float, Attachments?: list, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, PrepaymentID?: string, RemainingCredit?: float, Status?: "AUTHORISED"|"PAID"|"VOIDED", SubTotal?: float, Total?: float, TotalTax?: float, Type?: "RECEIVE-PREPAYMENT"|"SPEND-PREPAYMENT"|"ARPREPAYMENT"|"APPREPAYMENT"}
# --ValidationErrors item shape: {Message?: string}
export def "payments createPayment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --Account: record # shape: {AccountID?: string, AddToWatchlist?: bool, BankAccountNumber?: string, BankAccountType?: "BANK"|"CREDITCARD"|"PAYPAL"|"NONE"|"", Code?: string, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", Description?: string, EnablePaymentsToAccount?: bool, Name?: string, ReportingCode?: string, ShowInExpenseClaims?: bool, Status?: "ACTIVE"|"ARCHIVED"|"DELETED", TaxType?: string, Type?: "BANK"|"CURRENT"|"CURRLIAB"|"DEPRECIATN"|"DIRECTCOSTS"|"EQUITY"|"EXPENSE"|"FIXED"|"INVENTORY"|"LIABILITY"|"NONCURRENT"|"OTHERINCOME"|"OVERHEADS"|"PREPAYMENT"|"REVENUE"|"SALES"|"TERMLIAB"|"PAYGLIABILITY"|"PAYG"|"SUPERANNUATIONEXPENSE"|"SUPERANNUATIONLIABILITY"|"WAGESEXPENSE", ValidationErrors?: list}
  --Amount: float # The amount of the payment. Must be less than or equal to the outstanding amount owing on the invoice e.g. 200.00 (format: double)
  --BankAccountNumber: string # The suppliers bank account number the payment is being made to
  --BatchPaymentID: string # Present if the payment was created as part of a batch. (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --Code: string # Code of account you are using to make the payment e.g. 001 (note- not all accounts have a code value)
  --CreditNote: record # shape: {Allocations?: list, AppliedAmount?: float, BrandingThemeID?: string, Contact?: record, CreditNoteID?: string, CreditNoteNumber?: string, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DueDate?: string, FullyPaidOnDate?: string, HasAttachments?: bool, HasErrors?: bool, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, Payments?: list, Reference?: string, RemainingCredit?: float, Status?: "DRAFT"|"SUBMITTED"|"DELETED"|"AUTHORISED"|"PAID"|"VOIDED", StatusAttributeString?: string, SubTotal?: float, Total?: float, TotalTax?: float, Type?: "ACCPAYCREDIT"|"ACCRECCREDIT", ValidationErrors?: list, Warnings?: list}
  --CreditNoteNumber: string # Number of invoice or credit note you are applying payment to e.g. INV-4003
  --CurrencyRate: float # Exchange rate when payment is received. Only used for non base currency invoices and credit notes e.g. 0.7500 (format: double)
  --Date: string # Date the payment is being made (YYYY-MM-DD) e.g. 2009-09-06
  --Details: string # The information to appear on the supplier's bank account
  --HasAccount: oneof<nothing, bool> # A boolean to indicate if a contact has an validation errors (default: false, e.g. false)
  --HasValidationErrors: oneof<nothing, bool> # A boolean to indicate if a contact has an validation errors (default: false, e.g. false)
  --Invoice: record # shape: {Attachments?: list, BrandingThemeID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DueDate?: string, ExpectedPaymentDate?: string, HasErrors?: bool, InvoiceID?: string, InvoiceNumber?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, PlannedPaymentDate?: string, Reference?: string, RepeatingInvoiceID?: string, SentToContact?: bool, Status?: "DRAFT"|"SUBMITTED"|"DELETED"|"AUTHORISED"|"PAID"|"VOIDED", StatusAttributeString?: string, Type?: "ACCPAY"|"ACCPAYCREDIT"|"APOVERPAYMENT"|"APPREPAYMENT"|"ACCREC"|"ACCRECCREDIT"|"AROVERPAYMENT"|"ARPREPAYMENT", Url?: string, ValidationErrors?: list, Warnings?: list}
  --InvoiceNumber: string # Number of invoice or credit note you are applying payment to e.g.INV-4003
  --IsReconciled: oneof<nothing, bool> # An optional parameter for the payment. A boolean indicating whether you would like the payment to be created as reconciled when using PUT, or whether a payment has been reconciled when using GET
  --Overpayment: record # shape: {Allocations?: list, AppliedAmount?: float, Attachments?: list, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, OverpaymentID?: string, Payments?: list, RemainingCredit?: float, Status?: "AUTHORISED"|"PAID"|"VOIDED", SubTotal?: float, Total?: float, TotalTax?: float, Type?: "RECEIVE-OVERPAYMENT"|"SPEND-OVERPAYMENT"|"AROVERPAYMENT"}
  --Particulars: string # The suppliers bank account number the payment is being made to
  --PaymentID: string # The Xero identifier for an Payment e.g. 297c2dc5-cc47-4afd-8ec8-74990b8761e9 (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --Prepayment: record # shape: {Allocations?: list, AppliedAmount?: float, Attachments?: list, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, PrepaymentID?: string, RemainingCredit?: float, Status?: "AUTHORISED"|"PAID"|"VOIDED", SubTotal?: float, Total?: float, TotalTax?: float, Type?: "RECEIVE-PREPAYMENT"|"SPEND-PREPAYMENT"|"ARPREPAYMENT"|"APPREPAYMENT"}
  --Reference: string # An optional description for the payment e.g. Direct Debit
  --Status: string@Status-completer-2 # The status of the payment.
  --StatusAttributeString: string # A string to indicate if a invoice status
  --ValidationErrors: list # Displays array of validation error messages from the API — item shape: {Message?: string}
]: any -> record<Payments: table<Account: record, Amount: float, BankAccountNumber: string, BatchPaymentID: string, Code: string, CreditNote: record, CreditNoteNumber: string, CurrencyRate: float, Date: string, Details: string, HasAccount: bool, HasValidationErrors: bool, Invoice: record, InvoiceNumber: string, IsReconciled: bool, Overpayment: record, Particulars: string, PaymentID: string, PaymentType: string, Prepayment: record, Reference: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Payments")
  let body = {Account: $Account, Amount: $Amount, BankAccountNumber: $BankAccountNumber, BatchPaymentID: $BatchPaymentID, Code: $Code, CreditNote: $CreditNote, CreditNoteNumber: $CreditNoteNumber, CurrencyRate: $CurrencyRate, Date: $Date, Details: $Details, HasAccount: $HasAccount, HasValidationErrors: $HasValidationErrors, Invoice: $Invoice, InvoiceNumber: $InvoiceNumber, IsReconciled: $IsReconciled, Overpayment: $Overpayment, Particulars: $Particulars, PaymentID: $PaymentID, Prepayment: $Prepayment, Reference: $Reference, Status: $Status, StatusAttributeString: $StatusAttributeString, ValidationErrors: $ValidationErrors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates multiple payments for invoices or credit notes
#
# PUT /Payments
# operationId: createPayments
# --Payments item shape: {Account?: record, Amount?: float, BankAccountNumber?: string, BatchPaymentID?: string, Code?: string, CreditNote?: record, CreditNoteNumber?: string, CurrencyRate?: float, Date?: string, Details?: string, HasAccount?: bool, HasValidationErrors?: bool, Invoice?: record, InvoiceNumber?: string, IsReconciled?: bool, Overpayment?: record, Particulars?: string, PaymentID?: string, Prepayment?: record, Reference?: string, Status?: "AUTHORISED"|"DELETED", StatusAttributeString?: string, ValidationErrors?: list}
export def "payments createPayments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --Payments: list # item shape: {Account?: record, Amount?: float, BankAccountNumber?: string, BatchPaymentID?: string, Code?: string, CreditNote?: record, CreditNoteNumber?: string, CurrencyRate?: float, Date?: string, Details?: string, HasAccount?: bool, HasValidationErrors?: bool, Invoice?: record, InvoiceNumber?: string, IsReconciled?: bool, Overpayment?: record, Particulars?: string, PaymentID?: string, Prepayment?: record, Reference?: string, Status?: "AUTHORISED"|"DELETED", StatusAttributeString?: string, ValidationErrors?: list}
]: any -> record<Payments: table<Account: record, Amount: float, BankAccountNumber: string, BatchPaymentID: string, Code: string, CreditNote: record, CreditNoteNumber: string, CurrencyRate: float, Date: string, Details: string, HasAccount: bool, HasValidationErrors: bool, Invoice: record, InvoiceNumber: string, IsReconciled: bool, Overpayment: record, Particulars: string, PaymentID: string, PaymentType: string, Prepayment: record, Reference: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Payments" $qp)
  let body = {Payments: $Payments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a specific payment for invoices and credit notes using a unique payment Id
#
# GET /Payments/{PaymentID}
# operationId: getPayment
export def "payments get" [
  PaymentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Payments: table<Account: record, Amount: float, BankAccountNumber: string, BatchPaymentID: string, Code: string, CreditNote: record, CreditNoteNumber: string, CurrencyRate: float, Date: string, Details: string, HasAccount: bool, HasValidationErrors: bool, Invoice: record, InvoiceNumber: string, IsReconciled: bool, Overpayment: record, Particulars: string, PaymentID: string, PaymentType: string, Prepayment: record, Reference: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Payments/($PaymentID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific payment for invoices and credit notes
#
# POST /Payments/{PaymentID}
# operationId: deletePayment
export def "payments post" [
  PaymentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  Status: string # The status of the payment. (default: DELETED)
]: any -> record<Payments: table<Account: record, Amount: float, BankAccountNumber: string, BatchPaymentID: string, Code: string, CreditNote: record, CreditNoteNumber: string, CurrencyRate: float, Date: string, Details: string, HasAccount: bool, HasValidationErrors: bool, Invoice: record, InvoiceNumber: string, IsReconciled: bool, Overpayment: record, Particulars: string, PaymentID: string, PaymentType: string, Prepayment: record, Reference: string, Status: string, StatusAttributeString: string, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Payments/($PaymentID)")
  let body = {Status: $Status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves history records of a specific payment
#
# GET /Payments/{PaymentID}/History
# operationId: getPaymentHistory
export def "payments-history get" [
  PaymentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Payments/($PaymentID)/History")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a history record for a specific payment
#
# PUT /Payments/{PaymentID}/History
# operationId: createPaymentHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "payments-history createPaymentHistory" [
  PaymentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --HistoryRecords: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Payments/($PaymentID)/History")
  let body = {HistoryRecords: $HistoryRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="AUTHORISED")
  --order: string # Order by an any element (e.g. Reference ASC)
  --page: int # e.g. page=1 – Up to 100 prepayments will be returned in a single API call with line items shown for each overpayment (e.g. 1)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --If-Modified-Since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Prepayments: table<Allocations: list, AppliedAmount: float, Attachments: list, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PrepaymentID: string, Reference: string, RemainingCredit: float, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Prepayments" $qp)
  let extra_headers = {"If-Modified-Since": $If_Modified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows you to retrieve a specified prepayments
#
# GET /Prepayments/{PrepaymentID}
# operationId: getPrepayment
export def "prepayments get" [
  PrepaymentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Prepayments: table<Allocations: list, AppliedAmount: float, Attachments: list, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PrepaymentID: string, Reference: string, RemainingCredit: float, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Prepayments/($PrepaymentID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows you to create an Allocation for prepayments
#
# PUT /Prepayments/{PrepaymentID}/Allocations
# operationId: createPrepaymentAllocations
# --Allocations item shape: {Amount: float, CreditNote?: record, Date: string, Invoice: record, Overpayment?: record, Prepayment?: record, StatusAttributeString?: string, ValidationErrors?: list}
export def "prepayments-allocations createPrepaymentAllocations" [
  PrepaymentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --Allocations: list # item shape: {Amount: float, CreditNote?: record, Date: string, Invoice: record, Overpayment?: record, Prepayment?: record, StatusAttributeString?: string, ValidationErrors?: list}
]: any -> record<Allocations: table<Amount: float, CreditNote: record, Date: string, Invoice: record, Overpayment: record, Prepayment: record, StatusAttributeString: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Prepayments/($PrepaymentID)/Allocations" $qp)
  let body = {Allocations: $Allocations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves history record for a specific prepayment
#
# GET /Prepayments/{PrepaymentID}/History
# operationId: getPrepaymentHistory
export def "prepayments-history get" [
  PrepaymentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Prepayments/($PrepaymentID)/History")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a history record for a specific prepayment
#
# PUT /Prepayments/{PrepaymentID}/History
# operationId: createPrepaymentHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "prepayments-history createPrepaymentHistory" [
  PrepaymentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --HistoryRecords: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Prepayments/($PrepaymentID)/History")
  let body = {HistoryRecords: $HistoryRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves purchase orders
#
# GET /PurchaseOrders
# operationId: getPurchaseOrders
export def "purchase-orders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Status: string@Status-completer-3 # Filter by purchase order status (e.g. SUBMITTED)
  --DateFrom: string # Filter by purchase order date (e.g. GET https://.../PurchaseOrders?DateFrom=2015-12-01&DateTo=2015-12-31 (e.g. 2019-12-01)
  --DateTo: string # Filter by purchase order date (e.g. GET https://.../PurchaseOrders?DateFrom=2015-12-01&DateTo=2015-12-31 (e.g. 2019-12-31)
  --order: string # Order by an any element (e.g. PurchaseOrderNumber ASC)
  --page: int # To specify a page, append the page parameter to the URL e.g. ?page=1. If there are 100 records in the response you will need to check if there is any more data by fetching the next page e.g ?page=2 and continuing this process until no more results are returned. (e.g. 1)
  --If-Modified-Since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Status" $Status "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/PurchaseOrders" $qp)
  let extra_headers = {"If-Modified-Since": $If_Modified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates or creates one or more purchase orders
#
# POST /PurchaseOrders
# operationId: updateOrCreatePurchaseOrders
# --PurchaseOrders item shape: {Attachments?: list, AttentionTo?: string, BrandingThemeID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DeliveryAddress?: string, DeliveryDate?: string, DeliveryInstructions?: string, ExpectedArrivalDate?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, PurchaseOrderID?: string, PurchaseOrderNumber?: string, Reference?: string, SentToContact?: bool, Status?: "DRAFT"|"SUBMITTED"|"AUTHORISED"|"BILLED"|"DELETED", StatusAttributeString?: string, Telephone?: string, ValidationErrors?: list, Warnings?: list}
export def "purchase-orders updateOrCreatePurchaseOrders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --PurchaseOrders: list # item shape: {Attachments?: list, AttentionTo?: string, BrandingThemeID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DeliveryAddress?: string, DeliveryDate?: string, DeliveryInstructions?: string, ExpectedArrivalDate?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, PurchaseOrderID?: string, PurchaseOrderNumber?: string, Reference?: string, SentToContact?: bool, Status?: "DRAFT"|"SUBMITTED"|"AUTHORISED"|"BILLED"|"DELETED", StatusAttributeString?: string, Telephone?: string, ValidationErrors?: list, Warnings?: list}
]: any -> record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/PurchaseOrders" $qp)
  let body = {PurchaseOrders: $PurchaseOrders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates one or more purchase orders
#
# PUT /PurchaseOrders
# operationId: createPurchaseOrders
# --PurchaseOrders item shape: {Attachments?: list, AttentionTo?: string, BrandingThemeID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DeliveryAddress?: string, DeliveryDate?: string, DeliveryInstructions?: string, ExpectedArrivalDate?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, PurchaseOrderID?: string, PurchaseOrderNumber?: string, Reference?: string, SentToContact?: bool, Status?: "DRAFT"|"SUBMITTED"|"AUTHORISED"|"BILLED"|"DELETED", StatusAttributeString?: string, Telephone?: string, ValidationErrors?: list, Warnings?: list}
export def "purchase-orders createPurchaseOrders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --PurchaseOrders: list # item shape: {Attachments?: list, AttentionTo?: string, BrandingThemeID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DeliveryAddress?: string, DeliveryDate?: string, DeliveryInstructions?: string, ExpectedArrivalDate?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, PurchaseOrderID?: string, PurchaseOrderNumber?: string, Reference?: string, SentToContact?: bool, Status?: "DRAFT"|"SUBMITTED"|"AUTHORISED"|"BILLED"|"DELETED", StatusAttributeString?: string, Telephone?: string, ValidationErrors?: list, Warnings?: list}
]: any -> record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/PurchaseOrders" $qp)
  let body = {PurchaseOrders: $PurchaseOrders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a specific purchase order using a unique purchase order Id
#
# GET /PurchaseOrders/{PurchaseOrderID}
# operationId: getPurchaseOrder
export def "purchase-orders get-by-PurchaseOrderID" [
  PurchaseOrderID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/PurchaseOrders/($PurchaseOrderID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific purchase order
#
# POST /PurchaseOrders/{PurchaseOrderID}
# operationId: updatePurchaseOrder
# --PurchaseOrders item shape: {Attachments?: list, AttentionTo?: string, BrandingThemeID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DeliveryAddress?: string, DeliveryDate?: string, DeliveryInstructions?: string, ExpectedArrivalDate?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, PurchaseOrderID?: string, PurchaseOrderNumber?: string, Reference?: string, SentToContact?: bool, Status?: "DRAFT"|"SUBMITTED"|"AUTHORISED"|"BILLED"|"DELETED", StatusAttributeString?: string, Telephone?: string, ValidationErrors?: list, Warnings?: list}
export def "purchase-orders updatePurchaseOrder" [
  PurchaseOrderID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --PurchaseOrders: list # item shape: {Attachments?: list, AttentionTo?: string, BrandingThemeID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DeliveryAddress?: string, DeliveryDate?: string, DeliveryInstructions?: string, ExpectedArrivalDate?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, PurchaseOrderID?: string, PurchaseOrderNumber?: string, Reference?: string, SentToContact?: bool, Status?: "DRAFT"|"SUBMITTED"|"AUTHORISED"|"BILLED"|"DELETED", StatusAttributeString?: string, Telephone?: string, ValidationErrors?: list, Warnings?: list}
]: any -> record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/PurchaseOrders/($PurchaseOrderID)")
  let body = {PurchaseOrders: $PurchaseOrders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves attachments for a specific purchase order
#
# GET /PurchaseOrders/{PurchaseOrderID}/Attachments
# operationId: getPurchaseOrderAttachments
export def "purchase-orders-attachments get-by-PurchaseOrderID" [
  PurchaseOrderID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/PurchaseOrders/($PurchaseOrderID)/Attachments")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves specific attachment for a specific purchase order using a unique attachment Id
#
# GET /PurchaseOrders/{PurchaseOrderID}/Attachments/{AttachmentID}
# operationId: getPurchaseOrderAttachmentById
export def "purchase-orders-attachments get-by-PurchaseOrderID-AttachmentID" [
  PurchaseOrderID: string
  AttachmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/PurchaseOrders/($PurchaseOrderID)/Attachments/($AttachmentID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific attachment for a specific purchase order by filename
#
# GET /PurchaseOrders/{PurchaseOrderID}/Attachments/{FileName}
# operationId: getPurchaseOrder≠AttachmentByFileName
export def "purchase-orders-attachments get-by-PurchaseOrderID-FileName" [
  PurchaseOrderID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/PurchaseOrders/($PurchaseOrderID)/Attachments/($FileName)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific attachment for a specific purchase order by filename
#
# POST /PurchaseOrders/{PurchaseOrderID}/Attachments/{FileName}
# operationId: updatePurchaseOrderAttachmentByFileName
export def "purchase-orders-attachments updatePurchaseOrderAttachmentByFileName" [
  PurchaseOrderID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/PurchaseOrders/($PurchaseOrderID)/Attachments/($FileName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Creates attachment for a specific purchase order
#
# PUT /PurchaseOrders/{PurchaseOrderID}/Attachments/{FileName}
# operationId: createPurchaseOrderAttachmentByFileName
export def "purchase-orders-attachments createPurchaseOrderAttachmentByFileName" [
  PurchaseOrderID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/PurchaseOrders/($PurchaseOrderID)/Attachments/($FileName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Retrieves history for a specific purchase order
#
# GET /PurchaseOrders/{PurchaseOrderID}/History
# operationId: getPurchaseOrderHistory
export def "purchase-orders-history get" [
  PurchaseOrderID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/PurchaseOrders/($PurchaseOrderID)/History")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a history record for a specific purchase orders
#
# PUT /PurchaseOrders/{PurchaseOrderID}/History
# operationId: createPurchaseOrderHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "purchase-orders-history createPurchaseOrderHistory" [
  PurchaseOrderID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --HistoryRecords: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/PurchaseOrders/($PurchaseOrderID)/History")
  let body = {HistoryRecords: $HistoryRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves specific purchase order as PDF files using a unique purchase order Id
#
# GET /PurchaseOrders/{PurchaseOrderID}/pdf
# operationId: getPurchaseOrderAsPdf
export def "purchase-orders-pdf get" [
  PurchaseOrderID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/PurchaseOrders/($PurchaseOrderID)/pdf")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific purchase order using purchase order number
#
# GET /PurchaseOrders/{PurchaseOrderNumber}
# operationId: getPurchaseOrderByNumber
export def "purchase-orders get-by-PurchaseOrderNumber" [
  PurchaseOrderNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<PurchaseOrders: table<Attachments: list, AttentionTo: string, BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DeliveryAddress: string, DeliveryDate: string, DeliveryInstructions: string, ExpectedArrivalDate: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, PurchaseOrderID: string, PurchaseOrderNumber: string, Reference: string, SentToContact: bool, Status: string, StatusAttributeString: string, SubTotal: float, Telephone: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/PurchaseOrders/($PurchaseOrderNumber)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --DateFrom: string # Filter for quotes after a particular date (format: date)
  --DateTo: string # Filter for quotes before a particular date (format: date)
  --ExpiryDateFrom: string # Filter for quotes expiring after a particular date (format: date)
  --ExpiryDateTo: string # Filter for quotes before a particular date (format: date)
  --ContactID: string # Filter for quotes belonging to a particular contact (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --Status: string # Filter for quotes of a particular Status (e.g. DRAFT)
  --page: int # e.g. page=1 – Up to 100 Quotes will be returned in a single API call with line items shown for each quote (e.g. 1)
  --order: string # Order by an any element (e.g. Status ASC)
  --QuoteNumber: string # Filter by quote number (e.g. GET https://.../Quotes?QuoteNumber=QU-0001) (e.g. QU-0001)
  --If-Modified-Since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Quotes: table<BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DateString: string, ExpiryDate: string, ExpiryDateString: string, LineAmountTypes: string, LineItems: list, QuoteID: string, QuoteNumber: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Summary: string, Terms: string, Title: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "ExpiryDateFrom" $ExpiryDateFrom "scalar") (serialize-qp "ExpiryDateTo" $ExpiryDateTo "scalar") (serialize-qp "ContactID" $ContactID "scalar") (serialize-qp "Status" $Status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "QuoteNumber" $QuoteNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Quotes" $qp)
  let extra_headers = {"If-Modified-Since": $If_Modified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates or creates one or more quotes
#
# POST /Quotes
# operationId: updateOrCreateQuotes
# --Quotes item shape: {BrandingThemeID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DateString?: string, ExpiryDate?: string, ExpiryDateString?: string, LineAmountTypes?: "EXCLUSIVE"|"INCLUSIVE"|"NOTAX", LineItems?: list, QuoteID?: string, QuoteNumber?: string, Reference?: string, Status?: "DRAFT"|"SENT"|"DECLINED"|"ACCEPTED"|"INVOICED"|"DELETED", StatusAttributeString?: string, Summary?: string, Terms?: string, Title?: string, ValidationErrors?: list}
export def "quotes updateOrCreateQuotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --Quotes: list # item shape: {BrandingThemeID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DateString?: string, ExpiryDate?: string, ExpiryDateString?: string, LineAmountTypes?: "EXCLUSIVE"|"INCLUSIVE"|"NOTAX", LineItems?: list, QuoteID?: string, QuoteNumber?: string, Reference?: string, Status?: "DRAFT"|"SENT"|"DECLINED"|"ACCEPTED"|"INVOICED"|"DELETED", StatusAttributeString?: string, Summary?: string, Terms?: string, Title?: string, ValidationErrors?: list}
]: any -> record<Quotes: table<BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DateString: string, ExpiryDate: string, ExpiryDateString: string, LineAmountTypes: string, LineItems: list, QuoteID: string, QuoteNumber: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Summary: string, Terms: string, Title: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Quotes" $qp)
  let body = {Quotes: $Quotes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create one or more quotes
#
# PUT /Quotes
# operationId: createQuotes
# --Quotes item shape: {BrandingThemeID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DateString?: string, ExpiryDate?: string, ExpiryDateString?: string, LineAmountTypes?: "EXCLUSIVE"|"INCLUSIVE"|"NOTAX", LineItems?: list, QuoteID?: string, QuoteNumber?: string, Reference?: string, Status?: "DRAFT"|"SENT"|"DECLINED"|"ACCEPTED"|"INVOICED"|"DELETED", StatusAttributeString?: string, Summary?: string, Terms?: string, Title?: string, ValidationErrors?: list}
export def "quotes createQuotes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --summarizeErrors: oneof<nothing, bool> # If false return 200 OK and mix of successfully created objects and any with validation errors (default: false, e.g. true)
  --Quotes: list # item shape: {BrandingThemeID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DateString?: string, ExpiryDate?: string, ExpiryDateString?: string, LineAmountTypes?: "EXCLUSIVE"|"INCLUSIVE"|"NOTAX", LineItems?: list, QuoteID?: string, QuoteNumber?: string, Reference?: string, Status?: "DRAFT"|"SENT"|"DECLINED"|"ACCEPTED"|"INVOICED"|"DELETED", StatusAttributeString?: string, Summary?: string, Terms?: string, Title?: string, ValidationErrors?: list}
]: any -> record<Quotes: table<BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DateString: string, ExpiryDate: string, ExpiryDateString: string, LineAmountTypes: string, LineItems: list, QuoteID: string, QuoteNumber: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Summary: string, Terms: string, Title: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "summarizeErrors" $summarizeErrors "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Quotes" $qp)
  let body = {Quotes: $Quotes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a specific quote using a unique quote Id
#
# GET /Quotes/{QuoteID}
# operationId: getQuote
export def "quotes get" [
  QuoteID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Quotes: table<BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DateString: string, ExpiryDate: string, ExpiryDateString: string, LineAmountTypes: string, LineItems: list, QuoteID: string, QuoteNumber: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Summary: string, Terms: string, Title: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Quotes/($QuoteID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific quote
#
# POST /Quotes/{QuoteID}
# operationId: updateQuote
# --Quotes item shape: {BrandingThemeID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DateString?: string, ExpiryDate?: string, ExpiryDateString?: string, LineAmountTypes?: "EXCLUSIVE"|"INCLUSIVE"|"NOTAX", LineItems?: list, QuoteID?: string, QuoteNumber?: string, Reference?: string, Status?: "DRAFT"|"SENT"|"DECLINED"|"ACCEPTED"|"INVOICED"|"DELETED", StatusAttributeString?: string, Summary?: string, Terms?: string, Title?: string, ValidationErrors?: list}
export def "quotes updateQuote" [
  QuoteID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --Quotes: list # item shape: {BrandingThemeID?: string, Contact?: record, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", CurrencyRate?: float, Date?: string, DateString?: string, ExpiryDate?: string, ExpiryDateString?: string, LineAmountTypes?: "EXCLUSIVE"|"INCLUSIVE"|"NOTAX", LineItems?: list, QuoteID?: string, QuoteNumber?: string, Reference?: string, Status?: "DRAFT"|"SENT"|"DECLINED"|"ACCEPTED"|"INVOICED"|"DELETED", StatusAttributeString?: string, Summary?: string, Terms?: string, Title?: string, ValidationErrors?: list}
]: any -> record<Quotes: table<BrandingThemeID: string, Contact: record, CurrencyCode: string, CurrencyRate: float, Date: string, DateString: string, ExpiryDate: string, ExpiryDateString: string, LineAmountTypes: string, LineItems: list, QuoteID: string, QuoteNumber: string, Reference: string, Status: string, StatusAttributeString: string, SubTotal: float, Summary: string, Terms: string, Title: string, Total: float, TotalDiscount: float, TotalTax: float, UpdatedDateUTC: string, ValidationErrors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Quotes/($QuoteID)")
  let body = {Quotes: $Quotes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves attachments for a specific quote
#
# GET /Quotes/{QuoteID}/Attachments
# operationId: getQuoteAttachments
export def "quotes-attachments get-by-QuoteID" [
  QuoteID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Quotes/($QuoteID)/Attachments")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific attachment from a specific quote using a unique attachment Id
#
# GET /Quotes/{QuoteID}/Attachments/{AttachmentID}
# operationId: getQuoteAttachmentById
export def "quotes-attachments get-by-QuoteID-AttachmentID" [
  QuoteID: string
  AttachmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Quotes/($QuoteID)/Attachments/($AttachmentID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific attachment from a specific quote by filename
#
# GET /Quotes/{QuoteID}/Attachments/{FileName}
# operationId: getQuoteAttachmentByFileName
export def "quotes-attachments get-by-QuoteID-FileName" [
  QuoteID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Quotes/($QuoteID)/Attachments/($FileName)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific attachment from a specific quote by filename
#
# POST /Quotes/{QuoteID}/Attachments/{FileName}
# operationId: updateQuoteAttachmentByFileName
export def "quotes-attachments updateQuoteAttachmentByFileName" [
  QuoteID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Quotes/($QuoteID)/Attachments/($FileName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Creates attachment for a specific quote
#
# PUT /Quotes/{QuoteID}/Attachments/{FileName}
# operationId: createQuoteAttachmentByFileName
export def "quotes-attachments createQuoteAttachmentByFileName" [
  QuoteID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Quotes/($QuoteID)/Attachments/($FileName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Retrieves history records of a specific quote
#
# GET /Quotes/{QuoteID}/History
# operationId: getQuoteHistory
export def "quotes-history get" [
  QuoteID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Quotes/($QuoteID)/History")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a history record for a specific quote
#
# PUT /Quotes/{QuoteID}/History
# operationId: createQuoteHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "quotes-history createQuoteHistory" [
  QuoteID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --HistoryRecords: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Quotes/($QuoteID)/History")
  let body = {HistoryRecords: $HistoryRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a specific quote as a PDF file using a unique quote Id
#
# GET /Quotes/{QuoteID}/pdf
# operationId: getQuoteAsPdf
export def "quotes-pdf get" [
  QuoteID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Quotes/($QuoteID)/pdf")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="DRAFT")
  --order: string # Order by an any element (e.g. ReceiptNumber ASC)
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --If-Modified-Since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Receipts: table<Attachments: list, Contact: record, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, ReceiptID: string, ReceiptNumber: string, Reference: string, Status: string, SubTotal: float, Total: float, TotalTax: float, UpdatedDateUTC: string, Url: string, User: record, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Receipts" $qp)
  let extra_headers = {"If-Modified-Since": $If_Modified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates draft expense claim receipts for any user
#
# PUT /Receipts
# operationId: createReceipt
# --Receipts item shape: {Attachments?: list, Contact?: record, Date?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, ReceiptID?: string, Reference?: string, Status?: "DRAFT"|"SUBMITTED"|"AUTHORISED"|"DECLINED"|"VOIDED", SubTotal?: float, Total?: float, TotalTax?: float, User?: record, ValidationErrors?: list, Warnings?: list}
export def "receipts createReceipt" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --Receipts: list # item shape: {Attachments?: list, Contact?: record, Date?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, ReceiptID?: string, Reference?: string, Status?: "DRAFT"|"SUBMITTED"|"AUTHORISED"|"DECLINED"|"VOIDED", SubTotal?: float, Total?: float, TotalTax?: float, User?: record, ValidationErrors?: list, Warnings?: list}
]: any -> record<Receipts: table<Attachments: list, Contact: record, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, ReceiptID: string, ReceiptNumber: string, Reference: string, Status: string, SubTotal: float, Total: float, TotalTax: float, UpdatedDateUTC: string, Url: string, User: record, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Receipts" $qp)
  let body = {Receipts: $Receipts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves a specific draft expense claim receipt by using a unique receipt Id
#
# GET /Receipts/{ReceiptID}
# operationId: getReceipt
export def "receipts get" [
  ReceiptID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
]: nothing -> record<Receipts: table<Attachments: list, Contact: record, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, ReceiptID: string, ReceiptNumber: string, Reference: string, Status: string, SubTotal: float, Total: float, TotalTax: float, UpdatedDateUTC: string, Url: string, User: record, ValidationErrors: list, Warnings: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Receipts/($ReceiptID)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific draft expense claim receipts
#
# POST /Receipts/{ReceiptID}
# operationId: updateReceipt
# --Receipts item shape: {Attachments?: list, Contact?: record, Date?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, ReceiptID?: string, Reference?: string, Status?: "DRAFT"|"SUBMITTED"|"AUTHORISED"|"DECLINED"|"VOIDED", SubTotal?: float, Total?: float, TotalTax?: float, User?: record, ValidationErrors?: list, Warnings?: list}
export def "receipts updateReceipt" [
  ReceiptID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --unitdp: int # e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts (e.g. 4)
  --Receipts: list # item shape: {Attachments?: list, Contact?: record, Date?: string, LineAmountTypes?: "Exclusive"|"Inclusive"|"NoTax", LineItems?: list, ReceiptID?: string, Reference?: string, Status?: "DRAFT"|"SUBMITTED"|"AUTHORISED"|"DECLINED"|"VOIDED", SubTotal?: float, Total?: float, TotalTax?: float, User?: record, ValidationErrors?: list, Warnings?: list}
]: any -> record<Receipts: table<Attachments: list, Contact: record, Date: string, HasAttachments: bool, LineAmountTypes: string, LineItems: list, ReceiptID: string, ReceiptNumber: string, Reference: string, Status: string, SubTotal: float, Total: float, TotalTax: float, UpdatedDateUTC: string, Url: string, User: record, ValidationErrors: list, Warnings: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unitdp" $unitdp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Receipts/($ReceiptID)" $qp)
  let body = {Receipts: $Receipts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves attachments for a specific expense claim receipt
#
# GET /Receipts/{ReceiptID}/Attachments
# operationId: getReceiptAttachments
export def "receipts-attachments get-by-ReceiptID" [
  ReceiptID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Receipts/($ReceiptID)/Attachments")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific attachments from a specific expense claim receipts by using a unique attachment Id
#
# GET /Receipts/{ReceiptID}/Attachments/{AttachmentID}
# operationId: getReceiptAttachmentById
export def "receipts-attachments get-by-ReceiptID-AttachmentID" [
  ReceiptID: string
  AttachmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Receipts/($ReceiptID)/Attachments/($AttachmentID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific attachment from a specific expense claim receipts by file name
#
# GET /Receipts/{ReceiptID}/Attachments/{FileName}
# operationId: getReceiptAttachmentByFileName
export def "receipts-attachments get-by-ReceiptID-FileName" [
  ReceiptID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Receipts/($ReceiptID)/Attachments/($FileName)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific attachment on a specific expense claim receipts by file name
#
# POST /Receipts/{ReceiptID}/Attachments/{FileName}
# operationId: updateReceiptAttachmentByFileName
export def "receipts-attachments updateReceiptAttachmentByFileName" [
  ReceiptID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Receipts/($ReceiptID)/Attachments/($FileName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Creates an attachment on a specific expense claim receipts by file name
#
# PUT /Receipts/{ReceiptID}/Attachments/{FileName}
# operationId: createReceiptAttachmentByFileName
export def "receipts-attachments createReceiptAttachmentByFileName" [
  ReceiptID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Receipts/($ReceiptID)/Attachments/($FileName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Retrieves a history record for a specific receipt
#
# GET /Receipts/{ReceiptID}/History
# operationId: getReceiptHistory
export def "receipts-history get" [
  ReceiptID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Receipts/($ReceiptID)/History")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a history record for a specific receipt
#
# PUT /Receipts/{ReceiptID}/History
# operationId: createReceiptHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "receipts-history createReceiptHistory" [
  ReceiptID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --HistoryRecords: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Receipts/($ReceiptID)/History")
  let body = {HistoryRecords: $HistoryRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="DRAFT")
  --order: string # Order by an any element (e.g. Total ASC)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<RepeatingInvoices: table<Attachments: list, BrandingThemeID: string, Contact: record, CurrencyCode: string, HasAttachments: bool, ID: string, LineAmountTypes: string, LineItems: list, Reference: string, RepeatingInvoiceID: string, Schedule: record, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/RepeatingInvoices" $qp)
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific repeating invoice by using a unique repeating invoice Id
#
# GET /RepeatingInvoices/{RepeatingInvoiceID}
# operationId: getRepeatingInvoice
export def "repeating-invoices get" [
  RepeatingInvoiceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<RepeatingInvoices: table<Attachments: list, BrandingThemeID: string, Contact: record, CurrencyCode: string, HasAttachments: bool, ID: string, LineAmountTypes: string, LineItems: list, Reference: string, RepeatingInvoiceID: string, Schedule: record, Status: string, SubTotal: float, Total: float, TotalTax: float, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/RepeatingInvoices/($RepeatingInvoiceID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves attachments from a specific repeating invoice
#
# GET /RepeatingInvoices/{RepeatingInvoiceID}/Attachments
# operationId: getRepeatingInvoiceAttachments
export def "repeating-invoices-attachments get-by-RepeatingInvoiceID" [
  RepeatingInvoiceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/RepeatingInvoices/($RepeatingInvoiceID)/Attachments")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific attachment from a specific repeating invoice
#
# GET /RepeatingInvoices/{RepeatingInvoiceID}/Attachments/{AttachmentID}
# operationId: getRepeatingInvoiceAttachmentById
export def "repeating-invoices-attachments get-by-RepeatingInvoiceID-AttachmentID" [
  RepeatingInvoiceID: string
  AttachmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/RepeatingInvoices/($RepeatingInvoiceID)/Attachments/($AttachmentID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific attachment from a specific repeating invoices by file name
#
# GET /RepeatingInvoices/{RepeatingInvoiceID}/Attachments/{FileName}
# operationId: getRepeatingInvoiceAttachmentByFileName
export def "repeating-invoices-attachments get-by-RepeatingInvoiceID-FileName" [
  RepeatingInvoiceID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --contentType: string # The mime type of the attachment file you are retrieving i.e image/jpg, application/pdf (e.g. image/jpg)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/RepeatingInvoices/($RepeatingInvoiceID)/Attachments/($FileName)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id, "contentType": $contentType} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific attachment from a specific repeating invoices by file name
#
# POST /RepeatingInvoices/{RepeatingInvoiceID}/Attachments/{FileName}
# operationId: updateRepeatingInvoiceAttachmentByFileName
export def "repeating-invoices-attachments updateRepeatingInvoiceAttachmentByFileName" [
  RepeatingInvoiceID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/RepeatingInvoices/($RepeatingInvoiceID)/Attachments/($FileName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Creates an attachment from a specific repeating invoices by file name
#
# PUT /RepeatingInvoices/{RepeatingInvoiceID}/Attachments/{FileName}
# operationId: createRepeatingInvoiceAttachmentByFileName
export def "repeating-invoices-attachments createRepeatingInvoiceAttachmentByFileName" [
  RepeatingInvoiceID: string
  FileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --body: record
]: any -> record<Attachments: table<AttachmentID: string, ContentLength: int, FileName: string, IncludeOnline: bool, MimeType: string, Url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/RepeatingInvoices/($RepeatingInvoiceID)/Attachments/($FileName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/octet-stream" $body
}

# Retrieves history record for a specific repeating invoice
#
# GET /RepeatingInvoices/{RepeatingInvoiceID}/History
# operationId: getRepeatingInvoiceHistory
export def "repeating-invoices-history get" [
  RepeatingInvoiceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/RepeatingInvoices/($RepeatingInvoiceID)/History")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a  history record for a specific repeating invoice
#
# PUT /RepeatingInvoices/{RepeatingInvoiceID}/History
# operationId: createRepeatingInvoiceHistory
# --HistoryRecords item shape: {Changes?: string, Details?: string, User?: string}
export def "repeating-invoices-history createRepeatingInvoiceHistory" [
  RepeatingInvoiceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --HistoryRecords: list # item shape: {Changes?: string, Details?: string, User?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/RepeatingInvoices/($RepeatingInvoiceID)/History")
  let body = {HistoryRecords: $HistoryRecords} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves report for BAS (only valid for AU orgs)
#
# GET /Reports
# operationId: getReportBASorGSTList
export def "reports list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Reports")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --contactId: string # Unique identifier for a Contact (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --date: string # The date of the Aged Payables By Contact report (format: date)
  --fromDate: string # The from date of the Aged Payables By Contact report (format: date)
  --toDate: string # The to date of the Aged Payables By Contact report (format: date)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contactId" $contactId "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Reports/AgedPayablesByContact" $qp)
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --contactId: string # Unique identifier for a Contact (format: uuid, e.g. 00000000-0000-0000-0000-000000000000)
  --date: string # The date of the Aged Receivables By Contact report (format: date)
  --fromDate: string # The from date of the Aged Receivables By Contact report (format: date)
  --toDate: string # The to date of the Aged Receivables By Contact report (format: date)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contactId" $contactId "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Reports/AgedReceivablesByContact" $qp)
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # The date of the Balance Sheet report (format: date, e.g. 2019-11-01)
  --periods: int # The number of periods for the Balance Sheet report (e.g. 3)
  --timeframe: string@timeframe-completer # The period size to compare to (MONTH, QUARTER, YEAR) (e.g. MONTH)
  --trackingOptionID1: string # The tracking option 1 for the Balance Sheet report (e.g. 00000000-0000-0000-0000-000000000000)
  --trackingOptionID2: string # The tracking option 2 for the Balance Sheet report (e.g. 00000000-0000-0000-0000-000000000000)
  --standardLayout: oneof<nothing, bool> # The standard layout boolean for the Balance Sheet report (e.g. true)
  --paymentsOnly: oneof<nothing, bool> # return a cash basis for the Balance Sheet report (e.g. false)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "periods" $periods "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "trackingOptionID1" $trackingOptionID1 "scalar") (serialize-qp "trackingOptionID2" $trackingOptionID2 "scalar") (serialize-qp "standardLayout" $standardLayout "scalar") (serialize-qp "paymentsOnly" $paymentsOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Reports/BalanceSheet" $qp)
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --fromDate: string # The from date for the Bank Summary report e.g. 2018-03-31 (format: date, e.g. 2019-11-01)
  --toDate: string # The to date for the Bank Summary report e.g. 2018-03-31 (format: date, e.g. 2019-11-30)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Reports/BankSummary" $qp)
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # The date for the Bank Summary report e.g. 2018-03-31 (format: date, e.g. 2019-03-31)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Reports/ExecutiveSummary" $qp)
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --fromDate: string # The from date for the ProfitAndLoss report e.g. 2018-03-31 (format: date, e.g. 2019-03-01)
  --toDate: string # The to date for the ProfitAndLoss report e.g. 2018-03-31 (format: date, e.g. 2019-03-31)
  --periods: int # The number of periods to compare (integer between 1 and 12) (e.g. 3)
  --timeframe: string@timeframe-completer # The period size to compare to (MONTH, QUARTER, YEAR) (e.g. MONTH)
  --trackingCategoryID: string # The trackingCategory 1 for the ProfitAndLoss report (e.g. 00000000-0000-0000-0000-000000000000)
  --trackingCategoryID2: string # The trackingCategory 2 for the ProfitAndLoss report (e.g. 00000000-0000-0000-0000-000000000000)
  --trackingOptionID: string # The tracking option 1 for the ProfitAndLoss report (e.g. 00000000-0000-0000-0000-000000000000)
  --trackingOptionID2: string # The tracking option 2 for the ProfitAndLoss report (e.g. 00000000-0000-0000-0000-000000000000)
  --standardLayout: oneof<nothing, bool> # Return the standard layout for the ProfitAndLoss report (e.g. true)
  --paymentsOnly: oneof<nothing, bool> # Return cash only basis for the ProfitAndLoss report (e.g. false)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar") (serialize-qp "periods" $periods "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "trackingCategoryID" $trackingCategoryID "scalar") (serialize-qp "trackingCategoryID2" $trackingCategoryID2 "scalar") (serialize-qp "trackingOptionID" $trackingOptionID "scalar") (serialize-qp "trackingOptionID2" $trackingOptionID2 "scalar") (serialize-qp "standardLayout" $standardLayout "scalar") (serialize-qp "paymentsOnly" $paymentsOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Reports/ProfitAndLoss" $qp)
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportYear: string # The year of the 1099 report (e.g. 2019)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Reports: table<Contacts: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportType: string, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportYear" $reportYear "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Reports/TenNinetyNine" $qp)
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --date: string # The date for the Trial Balance report e.g. 2018-03-31 (format: date, e.g. 2019-10-31)
  --paymentsOnly: oneof<nothing, bool> # Return cash only basis for the Trial Balance report (e.g. true)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar") (serialize-qp "paymentsOnly" $paymentsOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Reports/TrialBalance" $qp)
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific report for BAS using a unique report Id (only valid for AU orgs)
#
# GET /Reports/{ReportID}
# operationId: getReportBASorGST
export def "reports get" [
  ReportID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Reports: table<Fields: list, ReportDate: string, ReportID: string, ReportName: string, ReportTitle: string, ReportTitles: list, ReportType: string, Rows: list, UpdatedDateUTC: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Reports/($ReportID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets the chart of accounts, the conversion date and conversion balances
#
# POST /Setup
# operationId: postSetup
# --Accounts item shape: {AccountID?: string, AddToWatchlist?: bool, BankAccountNumber?: string, BankAccountType?: "BANK"|"CREDITCARD"|"PAYPAL"|"NONE"|"", Code?: string, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", Description?: string, EnablePaymentsToAccount?: bool, Name?: string, ReportingCode?: string, ShowInExpenseClaims?: bool, Status?: "ACTIVE"|"ARCHIVED"|"DELETED", TaxType?: string, Type?: "BANK"|"CURRENT"|"CURRLIAB"|"DEPRECIATN"|"DIRECTCOSTS"|"EQUITY"|"EXPENSE"|"FIXED"|"INVENTORY"|"LIABILITY"|"NONCURRENT"|"OTHERINCOME"|"OVERHEADS"|"PREPAYMENT"|"REVENUE"|"SALES"|"TERMLIAB"|"PAYGLIABILITY"|"PAYG"|"SUPERANNUATIONEXPENSE"|"SUPERANNUATIONLIABILITY"|"WAGESEXPENSE", ValidationErrors?: list}
# --ConversionBalances item shape: {AccountCode?: string, Balance?: float, BalanceDetails?: list}
# --ConversionDate shape: {Month?: int, Year?: int}
export def "setup post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --Accounts: list # item shape: {AccountID?: string, AddToWatchlist?: bool, BankAccountNumber?: string, BankAccountType?: "BANK"|"CREDITCARD"|"PAYPAL"|"NONE"|"", Code?: string, CurrencyCode?: "AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BRL"|"BSD"|"BTN"|"BWP"|"BYN"|"BYR"|"BZD"|"CAD"|"CDF"|"CHF"|"CLP"|"CNY"|"COP"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GGP"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"IMP"|"INR"|"IQD"|"IRR"|"ISK"|"JEP"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRU"|"MUR"|"MVR"|"MWK"|"MXN"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SPL"|"SRD"|"STN"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRY"|"TTD"|"TVD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XCD"|"XDR"|"XOF"|"XPF"|"YER"|"ZAR"|"ZMW"|"ZMK"|"ZWD"|"", Description?: string, EnablePaymentsToAccount?: bool, Name?: string, ReportingCode?: string, ShowInExpenseClaims?: bool, Status?: "ACTIVE"|"ARCHIVED"|"DELETED", TaxType?: string, Type?: "BANK"|"CURRENT"|"CURRLIAB"|"DEPRECIATN"|"DIRECTCOSTS"|"EQUITY"|"EXPENSE"|"FIXED"|"INVENTORY"|"LIABILITY"|"NONCURRENT"|"OTHERINCOME"|"OVERHEADS"|"PREPAYMENT"|"REVENUE"|"SALES"|"TERMLIAB"|"PAYGLIABILITY"|"PAYG"|"SUPERANNUATIONEXPENSE"|"SUPERANNUATIONLIABILITY"|"WAGESEXPENSE", ValidationErrors?: list}
  --ConversionBalances: list # Balance supplied for each account that has a value as at the conversion date. — item shape: {AccountCode?: string, Balance?: float, BalanceDetails?: list}
  --ConversionDate: record # The date when the organisation starts using Xero — shape: {Month?: int, Year?: int}
]: any -> record<ImportSummary: record<Accounts: record<Deleted: float, Errored: float, Locked: float, New: float, NewOrUpdated: float, Present: bool, System: float, Total: float, Updated: float>, Organisation: record<Present: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Setup")
  let body = {Accounts: $Accounts, ConversionBalances: $ConversionBalances, ConversionDate: $ConversionDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="ACTIVE")
  --order: string # Order by an any element (e.g. Name ASC)
  --TaxType: string # Filter by tax type (e.g. INPUT)
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<TaxRates: table<CanApplyToAssets: bool, CanApplyToEquity: bool, CanApplyToExpenses: bool, CanApplyToLiabilities: bool, CanApplyToRevenue: bool, DisplayTaxRate: float, EffectiveRate: float, Name: string, ReportTaxType: string, Status: string, TaxComponents: list, TaxType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "TaxType" $TaxType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/TaxRates" $qp)
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates tax rates
#
# POST /TaxRates
# operationId: updateTaxRate
# --TaxRates item shape: {Name?: string, ReportTaxType?: "AVALARA"|"BASEXCLUDED"|"CAPITALSALESOUTPUT"|"CAPITALEXPENSESINPUT"|"ECOUTPUT"|"ECOUTPUTSERVICES"|"ECINPUT"|"ECACQUISITIONS"|"EXEMPTEXPENSES"|"EXEMPTINPUT"|"EXEMPTOUTPUT"|"GSTONIMPORTS"|"INPUT"|"INPUTTAXED"|"MOSSSALES"|"NONE"|"NONEOUTPUT"|"OUTPUT"|"PURCHASESINPUT"|"SALESOUTPUT"|"EXEMPTCAPITAL"|"EXEMPTEXPORT"|"CAPITALEXINPUT"|"GSTONCAPIMPORTS"|"GSTONCAPITALIMPORTS"|"REVERSECHARGES"|"PAYMENTS"|"INVOICE"|"CASH"|"ACCRUAL"|"FLATRATECASH"|"FLATRATEACCRUAL"|"ACCRUALS"|"TXCA"|"SRCAS"|"DSOUTPUT"|"BLINPUT2"|"EPINPUT"|"IMINPUT2"|"MEINPUT"|"IGDSINPUT2"|"ESN33OUTPUT"|"OPINPUT"|"OSOUTPUT"|"TXN33INPUT"|"TXESSINPUT"|"TXREINPUT"|"TXPETINPUT"|"NRINPUT"|"ES33OUTPUT"|"ZERORATEDINPUT"|"ZERORATEDOUTPUT"|"DRCHARGESUPPLY"|"DRCHARGE"|"CAPINPUT"|"CAPIMPORTS"|"IMINPUT"|"INPUT2"|"CIUINPUT"|"SRINPUT"|"OUTPUT2"|"SROUTPUT"|"CAPOUTPUT"|"SROUTPUT2"|"CIUOUTPUT"|"ZROUTPUT"|"ZREXPORT"|"ACC28PLUS"|"ACCUPTO28"|"OTHEROUTPUT"|"SHOUTPUT"|"ZRINPUT"|"BADDEBT"|"OTHERINPUT", Status?: "ACTIVE"|"DELETED"|"ARCHIVED"|"PENDING", TaxComponents?: list, TaxType?: string}
export def "tax-rates updateTaxRate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --TaxRates: list # item shape: {Name?: string, ReportTaxType?: "AVALARA"|"BASEXCLUDED"|"CAPITALSALESOUTPUT"|"CAPITALEXPENSESINPUT"|"ECOUTPUT"|"ECOUTPUTSERVICES"|"ECINPUT"|"ECACQUISITIONS"|"EXEMPTEXPENSES"|"EXEMPTINPUT"|"EXEMPTOUTPUT"|"GSTONIMPORTS"|"INPUT"|"INPUTTAXED"|"MOSSSALES"|"NONE"|"NONEOUTPUT"|"OUTPUT"|"PURCHASESINPUT"|"SALESOUTPUT"|"EXEMPTCAPITAL"|"EXEMPTEXPORT"|"CAPITALEXINPUT"|"GSTONCAPIMPORTS"|"GSTONCAPITALIMPORTS"|"REVERSECHARGES"|"PAYMENTS"|"INVOICE"|"CASH"|"ACCRUAL"|"FLATRATECASH"|"FLATRATEACCRUAL"|"ACCRUALS"|"TXCA"|"SRCAS"|"DSOUTPUT"|"BLINPUT2"|"EPINPUT"|"IMINPUT2"|"MEINPUT"|"IGDSINPUT2"|"ESN33OUTPUT"|"OPINPUT"|"OSOUTPUT"|"TXN33INPUT"|"TXESSINPUT"|"TXREINPUT"|"TXPETINPUT"|"NRINPUT"|"ES33OUTPUT"|"ZERORATEDINPUT"|"ZERORATEDOUTPUT"|"DRCHARGESUPPLY"|"DRCHARGE"|"CAPINPUT"|"CAPIMPORTS"|"IMINPUT"|"INPUT2"|"CIUINPUT"|"SRINPUT"|"OUTPUT2"|"SROUTPUT"|"CAPOUTPUT"|"SROUTPUT2"|"CIUOUTPUT"|"ZROUTPUT"|"ZREXPORT"|"ACC28PLUS"|"ACCUPTO28"|"OTHEROUTPUT"|"SHOUTPUT"|"ZRINPUT"|"BADDEBT"|"OTHERINPUT", Status?: "ACTIVE"|"DELETED"|"ARCHIVED"|"PENDING", TaxComponents?: list, TaxType?: string}
]: any -> record<TaxRates: table<CanApplyToAssets: bool, CanApplyToEquity: bool, CanApplyToExpenses: bool, CanApplyToLiabilities: bool, CanApplyToRevenue: bool, DisplayTaxRate: float, EffectiveRate: float, Name: string, ReportTaxType: string, Status: string, TaxComponents: list, TaxType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/TaxRates")
  let body = {TaxRates: $TaxRates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates one or more tax rates
#
# PUT /TaxRates
# operationId: createTaxRates
# --TaxRates item shape: {Name?: string, ReportTaxType?: "AVALARA"|"BASEXCLUDED"|"CAPITALSALESOUTPUT"|"CAPITALEXPENSESINPUT"|"ECOUTPUT"|"ECOUTPUTSERVICES"|"ECINPUT"|"ECACQUISITIONS"|"EXEMPTEXPENSES"|"EXEMPTINPUT"|"EXEMPTOUTPUT"|"GSTONIMPORTS"|"INPUT"|"INPUTTAXED"|"MOSSSALES"|"NONE"|"NONEOUTPUT"|"OUTPUT"|"PURCHASESINPUT"|"SALESOUTPUT"|"EXEMPTCAPITAL"|"EXEMPTEXPORT"|"CAPITALEXINPUT"|"GSTONCAPIMPORTS"|"GSTONCAPITALIMPORTS"|"REVERSECHARGES"|"PAYMENTS"|"INVOICE"|"CASH"|"ACCRUAL"|"FLATRATECASH"|"FLATRATEACCRUAL"|"ACCRUALS"|"TXCA"|"SRCAS"|"DSOUTPUT"|"BLINPUT2"|"EPINPUT"|"IMINPUT2"|"MEINPUT"|"IGDSINPUT2"|"ESN33OUTPUT"|"OPINPUT"|"OSOUTPUT"|"TXN33INPUT"|"TXESSINPUT"|"TXREINPUT"|"TXPETINPUT"|"NRINPUT"|"ES33OUTPUT"|"ZERORATEDINPUT"|"ZERORATEDOUTPUT"|"DRCHARGESUPPLY"|"DRCHARGE"|"CAPINPUT"|"CAPIMPORTS"|"IMINPUT"|"INPUT2"|"CIUINPUT"|"SRINPUT"|"OUTPUT2"|"SROUTPUT"|"CAPOUTPUT"|"SROUTPUT2"|"CIUOUTPUT"|"ZROUTPUT"|"ZREXPORT"|"ACC28PLUS"|"ACCUPTO28"|"OTHEROUTPUT"|"SHOUTPUT"|"ZRINPUT"|"BADDEBT"|"OTHERINPUT", Status?: "ACTIVE"|"DELETED"|"ARCHIVED"|"PENDING", TaxComponents?: list, TaxType?: string}
export def "tax-rates createTaxRates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --TaxRates: list # item shape: {Name?: string, ReportTaxType?: "AVALARA"|"BASEXCLUDED"|"CAPITALSALESOUTPUT"|"CAPITALEXPENSESINPUT"|"ECOUTPUT"|"ECOUTPUTSERVICES"|"ECINPUT"|"ECACQUISITIONS"|"EXEMPTEXPENSES"|"EXEMPTINPUT"|"EXEMPTOUTPUT"|"GSTONIMPORTS"|"INPUT"|"INPUTTAXED"|"MOSSSALES"|"NONE"|"NONEOUTPUT"|"OUTPUT"|"PURCHASESINPUT"|"SALESOUTPUT"|"EXEMPTCAPITAL"|"EXEMPTEXPORT"|"CAPITALEXINPUT"|"GSTONCAPIMPORTS"|"GSTONCAPITALIMPORTS"|"REVERSECHARGES"|"PAYMENTS"|"INVOICE"|"CASH"|"ACCRUAL"|"FLATRATECASH"|"FLATRATEACCRUAL"|"ACCRUALS"|"TXCA"|"SRCAS"|"DSOUTPUT"|"BLINPUT2"|"EPINPUT"|"IMINPUT2"|"MEINPUT"|"IGDSINPUT2"|"ESN33OUTPUT"|"OPINPUT"|"OSOUTPUT"|"TXN33INPUT"|"TXESSINPUT"|"TXREINPUT"|"TXPETINPUT"|"NRINPUT"|"ES33OUTPUT"|"ZERORATEDINPUT"|"ZERORATEDOUTPUT"|"DRCHARGESUPPLY"|"DRCHARGE"|"CAPINPUT"|"CAPIMPORTS"|"IMINPUT"|"INPUT2"|"CIUINPUT"|"SRINPUT"|"OUTPUT2"|"SROUTPUT"|"CAPOUTPUT"|"SROUTPUT2"|"CIUOUTPUT"|"ZROUTPUT"|"ZREXPORT"|"ACC28PLUS"|"ACCUPTO28"|"OTHEROUTPUT"|"SHOUTPUT"|"ZRINPUT"|"BADDEBT"|"OTHERINPUT", Status?: "ACTIVE"|"DELETED"|"ARCHIVED"|"PENDING", TaxComponents?: list, TaxType?: string}
]: any -> record<TaxRates: table<CanApplyToAssets: bool, CanApplyToEquity: bool, CanApplyToExpenses: bool, CanApplyToLiabilities: bool, CanApplyToRevenue: bool, DisplayTaxRate: float, EffectiveRate: float, Name: string, ReportTaxType: string, Status: string, TaxComponents: list, TaxType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/TaxRates")
  let body = {TaxRates: $TaxRates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves tracking categories and options
#
# GET /TrackingCategories
# operationId: getTrackingCategories
export def "tracking-categories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. Status=="ACTIVE")
  --order: string # Order by an any element (e.g. Name ASC)
  --includeArchived: oneof<nothing, bool> # e.g. includeArchived=true - Categories and options with a status of ARCHIVED will be included in the response
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<TrackingCategories: table<Name: string, Option: string, Options: list, Status: string, TrackingCategoryID: string, TrackingOptionID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "includeArchived" $includeArchived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/TrackingCategories" $qp)
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create tracking categories
#
# PUT /TrackingCategories
# operationId: createTrackingCategory
# --Options item shape: {Name?: string, Status?: "ACTIVE"|"ARCHIVED"|"DELETED", TrackingCategoryID?: string, TrackingOptionID?: string}
export def "tracking-categories createTrackingCategory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --Name: string # The name of the tracking category e.g. Department, Region (max length = 100)
  --Option: string # The option name of the tracking option e.g. East, West (max length = 100)
  --Options: list # See Tracking Options — item shape: {Name?: string, Status?: "ACTIVE"|"ARCHIVED"|"DELETED", TrackingCategoryID?: string, TrackingOptionID?: string}
  --Status: string@Status-completer # The status of a tracking category
  --TrackingCategoryID: string # The Xero identifier for a tracking category e.g. 297c2dc5-cc47-4afd-8ec8-74990b8761e9 (format: uuid)
  --TrackingOptionID: string # The Xero identifier for a tracking option e.g. dc54c220-0140-495a-b925-3246adc0075f (format: uuid)
]: any -> record<TrackingCategories: table<Name: string, Option: string, Options: list, Status: string, TrackingCategoryID: string, TrackingOptionID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/TrackingCategories")
  let body = {Name: $Name, Option: $Option, Options: $Options, Status: $Status, TrackingCategoryID: $TrackingCategoryID, TrackingOptionID: $TrackingOptionID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a specific tracking category
#
# DELETE /TrackingCategories/{TrackingCategoryID}
# operationId: deleteTrackingCategory
export def "tracking-categories delete" [
  TrackingCategoryID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<TrackingCategories: table<Name: string, Option: string, Options: list, Status: string, TrackingCategoryID: string, TrackingOptionID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/TrackingCategories/($TrackingCategoryID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves specific tracking categories and options using a unique tracking category Id
#
# GET /TrackingCategories/{TrackingCategoryID}
# operationId: getTrackingCategory
export def "tracking-categories get" [
  TrackingCategoryID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<TrackingCategories: table<Name: string, Option: string, Options: list, Status: string, TrackingCategoryID: string, TrackingOptionID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/TrackingCategories/($TrackingCategoryID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific tracking category
#
# POST /TrackingCategories/{TrackingCategoryID}
# operationId: updateTrackingCategory
# --Options item shape: {Name?: string, Status?: "ACTIVE"|"ARCHIVED"|"DELETED", TrackingCategoryID?: string, TrackingOptionID?: string}
export def "tracking-categories updateTrackingCategory" [
  TrackingCategoryID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --Name: string # The name of the tracking category e.g. Department, Region (max length = 100)
  --Option: string # The option name of the tracking option e.g. East, West (max length = 100)
  --Options: list # See Tracking Options — item shape: {Name?: string, Status?: "ACTIVE"|"ARCHIVED"|"DELETED", TrackingCategoryID?: string, TrackingOptionID?: string}
  --Status: string@Status-completer # The status of a tracking category
  --body-TrackingCategoryID: string # The Xero identifier for a tracking category e.g. 297c2dc5-cc47-4afd-8ec8-74990b8761e9 (format: uuid)
  --TrackingOptionID: string # The Xero identifier for a tracking option e.g. dc54c220-0140-495a-b925-3246adc0075f (format: uuid)
]: any -> record<TrackingCategories: table<Name: string, Option: string, Options: list, Status: string, TrackingCategoryID: string, TrackingOptionID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/TrackingCategories/($TrackingCategoryID)")
  let body = {Name: $Name, Option: $Option, Options: $Options, Status: $Status, TrackingCategoryID: $body_TrackingCategoryID, TrackingOptionID: $TrackingOptionID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates options for a specific tracking category
#
# PUT /TrackingCategories/{TrackingCategoryID}/Options
# operationId: createTrackingOptions
export def "tracking-categories-options createTrackingOptions" [
  TrackingCategoryID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --Name: string # The name of the tracking option e.g. Marketing, East (max length = 100)
  --Status: string@Status-completer # The status of a tracking option
  --body-TrackingCategoryID: string # Filter by a tracking category e.g. 297c2dc5-cc47-4afd-8ec8-74990b8761e9 (format: uuid)
  --TrackingOptionID: string # The Xero identifier for a tracking option e.g. ae777a87-5ef3-4fa0-a4f0-d10e1f13073a (format: uuid)
]: any -> record<Options: table<Name: string, Status: string, TrackingCategoryID: string, TrackingOptionID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/TrackingCategories/($TrackingCategoryID)/Options")
  let body = {Name: $Name, Status: $Status, TrackingCategoryID: $body_TrackingCategoryID, TrackingOptionID: $TrackingOptionID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a specific option for a specific tracking category
#
# DELETE /TrackingCategories/{TrackingCategoryID}/Options/{TrackingOptionID}
# operationId: deleteTrackingOptions
export def "tracking-categories-options delete" [
  TrackingCategoryID: string
  TrackingOptionID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Options: table<Name: string, Status: string, TrackingCategoryID: string, TrackingOptionID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/TrackingCategories/($TrackingCategoryID)/Options/($TrackingOptionID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a specific option for a specific tracking category
#
# POST /TrackingCategories/{TrackingCategoryID}/Options/{TrackingOptionID}
# operationId: updateTrackingOptions
export def "tracking-categories-options updateTrackingOptions" [
  TrackingCategoryID: string
  TrackingOptionID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
  --Name: string # The name of the tracking option e.g. Marketing, East (max length = 100)
  --Status: string@Status-completer # The status of a tracking option
  --body-TrackingCategoryID: string # Filter by a tracking category e.g. 297c2dc5-cc47-4afd-8ec8-74990b8761e9 (format: uuid)
  --body-TrackingOptionID: string # The Xero identifier for a tracking option e.g. ae777a87-5ef3-4fa0-a4f0-d10e1f13073a (format: uuid)
]: any -> record<Options: table<Name: string, Status: string, TrackingCategoryID: string, TrackingOptionID: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/TrackingCategories/($TrackingCategoryID)/Options/($TrackingOptionID)")
  let body = {Name: $Name, Status: $Status, TrackingCategoryID: $body_TrackingCategoryID, TrackingOptionID: $body_TrackingOptionID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-where: string # Filter by an any element (e.g. IsSubscriber==true)
  --order: string # Order by an any element (e.g. LastName ASC)
  --If-Modified-Since: string # Only records created or modified since this timestamp will be returned (e.g. 2020-02-06T12:17:43.202-08:00)
]: nothing -> record<Users: table<EmailAddress: string, FirstName: string, IsSubscriber: bool, LastName: string, OrganisationRole: string, UpdatedDateUTC: string, UserID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "where" $qp_where "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Users" $qp)
  let extra_headers = {"If-Modified-Since": $If_Modified_Since} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a specific user
#
# GET /Users/{UserID}
# operationId: getUser
export def "users get" [
  UserID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xero-tenant-id: string # Xero identifier for Tenant (e.g. YOUR_XERO_TENANT_ID)
]: nothing -> record<Users: table<EmailAddress: string, FirstName: string, IsSubscriber: bool, LastName: string, OrganisationRole: string, UpdatedDateUTC: string, UserID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Users/($UserID)")
  let extra_headers = {"xero-tenant-id": $xero_tenant_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
