# Auto-generated client for Assess API v1.0
# Source: https://api.apis.guru/v2/specs/codat.io/assess/1.0/openapi.json
# Auth: --token flag or $env.ASSESS_API_TOKEN

const BASE_URL = "https://api.codat.io"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ASSESS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.codat.io"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def reportType-completer [] { ["audit" "enhancedFinancials"] }
def periodUnit-completer [] { ["Day" "Month" "Week" "Year"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "companies-reports-enhanced-balance-sheet-accounts get-accounts-for-enhanced-balance-sheet" } } | get name | first)
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

# Enhanced Balance Sheet Accounts
#
# GET /companies/{companyId}/reports/enhancedBalanceSheet/accounts
# operationId: get-accounts-for-enhanced-balance-sheet
export def "companies-reports-enhanced-balance-sheet-accounts get-accounts-for-enhanced-balance-sheet" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportDate: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --numberOfPeriods: int # The number of periods to return.  There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
]: nothing -> record<reportInfo: any, reportItems: table<accountCategory: any, accountId: string, accountName: string, balance: float, date: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportDate" $reportDate "scalar") (serialize-qp "numberOfPeriods" $numberOfPeriods "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/reports/enhancedBalanceSheet/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get enhanced cash flow report
#
# GET /companies/{companyId}/reports/enhancedCashFlow/transactions
# operationId: get-enhanced-cash-flow-transactions
export def "companies-reports-enhanced-cash-flow-transactions get-enhanced-cash-flow-transactions" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1, e.g. 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100, e.g. 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
]: nothing -> record<dataSources: list<any>, reportInfo: any, reportItems: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/reports/enhancedCashFlow/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enhanced Invoices Report
#
# GET /companies/{companyId}/reports/enhancedInvoices
# operationId: get-enhanced-invoices-report
export def "companies-reports-enhanced-invoices get-enhanced-invoices-report" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1, e.g. 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100, e.g. 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
]: nothing -> record<reportInfo: any, reportItems: table<invoices: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/reports/enhancedInvoices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enhanced Profit and Loss Accounts
#
# GET /companies/{companyId}/reports/enhancedProfitAndLoss/accounts
# operationId: get-accounts-for-enhanced-profit-and-loss
export def "companies-reports-enhanced-profit-and-loss-accounts get-accounts-for-enhanced-profit-and-loss" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportDate: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --numberOfPeriods: int # The number of periods to return.  There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
]: nothing -> record<reportInfo: any, reportItems: table<accountCategory: any, accountId: string, accountName: string, balance: float, date: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportDate" $reportDate "scalar") (serialize-qp "numberOfPeriods" $numberOfPeriods "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/reports/enhancedProfitAndLoss/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List account categories
#
# GET /data/assess/accounts/categories
# DEPRECATED
# operationId: list-available-account-categories
@deprecated
export def "data-assess-accounts-categories list-available-account-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<detailType: string, subtype: string, type: string, detailTypeDescription: string, detailTypeDisplayName: string, subtypeDisplayName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data/assess/accounts/categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists data integrity details for date type
#
# GET /data/companies/{companyId}/assess/dataTypes/{dataType}/dataIntegrity/details
# operationId: get-data-integrity-details
export def "data-companies-assess-data-types-data-integrity-details get-data-integrity-details" [
  companyId: any
  dataType: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1, e.g. 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100, e.g. 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results). (e.g. -modifiedDate)
]: nothing -> record<results: table<amount: float, connectionId: string, currency: string, date: any, description: string, id: string, matches: list, type: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/data/companies/($companyId)/assess/dataTypes/($dataType)/dataIntegrity/details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get data integrity status
#
# GET /data/companies/{companyId}/assess/dataTypes/{dataType}/dataIntegrity/status
# operationId: get-data-integrity-status
export def "data-companies-assess-data-types-data-integrity-status get-data-integrity-status" [
  companyId: string
  dataType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<metadata: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data/companies/($companyId)/assess/dataTypes/($dataType)/dataIntegrity/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get data integrity summary
#
# GET /data/companies/{companyId}/assess/dataTypes/{dataType}/dataIntegrity/summaries
# operationId: get-data-integrity-summaries
export def "data-companies-assess-data-types-data-integrity-summaries get-data-integrity-summaries" [
  companyId: any
  dataType: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
]: nothing -> record<summaries: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/data/companies/($companyId)/assess/dataTypes/($dataType)/dataIntegrity/summaries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get status of Excel report
#
# GET /data/companies/{companyId}/assess/excel
# operationId: get-excel-report-generation-status
export def "data-companies-assess-excel get-excel-report-generation-status" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportType: string@reportType-completer # The type of report you want to generate and download.
]: nothing -> record<errorMessage: string, fileSize: int, inProgress: bool, lastGenerated: string, lastInvocationId: string, queued: string, reportType: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportType" $reportType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/data/companies/($companyId)/assess/excel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate an Excel report
#
# POST /data/companies/{companyId}/assess/excel
# operationId: generate-excel-report
export def "data-companies-assess-excel generate-excel-report" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportType: string@reportType-completer # The type of report you want to generate and download.
]: nothing -> record<errorMessage: string, fileSize: int, inProgress: bool, lastGenerated: string, lastInvocationId: string, queued: string, reportType: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportType" $reportType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/data/companies/($companyId)/assess/excel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download generated excel report
#
# GET /data/companies/{companyId}/assess/excel/download
# operationId: get-excel-report
export def "data-companies-assess-excel-download get-excel-report" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportType: string@reportType-completer # The type of report you want to generate and download.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportType" $reportType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/data/companies/($companyId)/assess/excel/download" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download generated excel report
#
# POST /data/companies/{companyId}/assess/excel/download
# DEPRECATED
# operationId: download-excel-report
@deprecated
export def "data-companies-assess-excel-download download-excel-report" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportType: string@reportType-completer # The type of report you want to generate and download.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportType" $reportType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/data/companies/($companyId)/assess/excel/download" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the marketing metrics from an accounting source for a given company.
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/accountingMetrics/marketing
# operationId: get-accounting-marketing-metrics
export def "data-companies-connections-assess-accounting-metrics-marketing get-accounting-marketing-metrics" [
  companyId: any
  connectionId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportDate: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --periodLength: int # The number of months per period. E.g. 2 = 2 months per period.
  --numberOfPeriods: int # The number of periods to return.  There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
  --periodUnit: string@periodUnit-completer # The period unit of time returned.
  --includeDisplayNames: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
  --showInputValues: oneof<nothing, bool> # If set to true, then the system includes the input values within the response.
]: nothing -> record<dimensions: list<any>, errors: list<any>, measures: list<any>, reportData: list<any>, reportInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportDate" $reportDate "scalar") (serialize-qp "periodLength" $periodLength "scalar") (serialize-qp "numberOfPeriods" $numberOfPeriods "scalar") (serialize-qp "periodUnit" $periodUnit "scalar") (serialize-qp "includeDisplayNames" $includeDisplayNames "scalar") (serialize-qp "showInputValues" $showInputValues "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/data/companies/($companyId)/connections/($connectionId)/assess/accountingMetrics/marketing" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List suggested and confirmed account categories
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/accounts/categories
# DEPRECATED
# operationId: list-accounts-categories
@deprecated
export def "data-companies-connections-assess-accounts-categories list-accounts-categories" [
  companyId: any
  connectionId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1, e.g. 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100, e.g. 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results). (e.g. -modifiedDate)
]: nothing -> record<results: table<accountRef: any, confirmed: any, suggested: any>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/data/companies/($companyId)/connections/($connectionId)/assess/accounts/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Confirm categories for accounts
#
# PATCH /data/companies/{companyId}/connections/{connectionId}/assess/accounts/categories
# DEPRECATED
# operationId: update-accounts-categories
# --categories item shape: {accountRef?: record, confirmed?: record}
@deprecated
export def "data-companies-connections-assess-accounts-categories update-accounts-categories" [
  companyId: string
  connectionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories: list # List of confirmed account categories set manually by the user.  — item shape: {accountRef?: record, confirmed?: record}
]: any -> table<accountRef: any, confirmed: any, suggested: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data/companies/($companyId)/connections/($connectionId)/assess/accounts/categories")
  let body = {categories: $categories} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get suggested and/or confirmed category for a specific account
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/accounts/{accountId}/categories
# DEPRECATED
# operationId: get-account-category
@deprecated
export def "data-companies-connections-assess-accounts-categories get-account-category" [
  companyId: string
  connectionId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accountRef: any, confirmed: any, suggested: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data/companies/($companyId)/connections/($connectionId)/assess/accounts/($accountId)/categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch account categories
#
# PATCH /data/companies/{companyId}/connections/{connectionId}/assess/accounts/{accountId}/categories
# DEPRECATED
# operationId: update-account-category
# --confirmed shape: {detailType?: string, subtype?: string, type?: string}
@deprecated
export def "data-companies-connections-assess-accounts-categories update-account-category" [
  companyId: string
  connectionId: string
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  confirmed: record # shape: {detailType?: string, subtype?: string, type?: string}
]: any -> record<accountRef: any, confirmed: any, suggested: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data/companies/($companyId)/connections/($connectionId)/assess/accounts/($accountId)/categories")
  let body = {confirmed: $confirmed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the customer retention metrics for a specific company.
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/commerceMetrics/customerRetention
# operationId: get-commerce-customer-retention-metrics
export def "data-companies-connections-assess-commerce-metrics-customer-retention get-commerce-customer-retention-metrics" [
  companyId: any
  connectionId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportDate: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --periodLength: int # The number of months per period. E.g. 2 = 2 months per period.
  --numberOfPeriods: int # The number of periods to return.  There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
  --periodUnit: string@periodUnit-completer # The period unit of time returned.
  --includeDisplayNames: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
]: nothing -> record<dimensions: list<any>, errors: list<any>, measures: list<any>, reportData: list<any>, reportInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportDate" $reportDate "scalar") (serialize-qp "periodLength" $periodLength "scalar") (serialize-qp "numberOfPeriods" $numberOfPeriods "scalar") (serialize-qp "periodUnit" $periodUnit "scalar") (serialize-qp "includeDisplayNames" $includeDisplayNames "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/data/companies/($companyId)/connections/($connectionId)/assess/commerceMetrics/customerRetention" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the lifetime value metric for a specific company.
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/commerceMetrics/lifetimeValue
# operationId: get-commerce-lifetime-value-metrics
export def "data-companies-connections-assess-commerce-metrics-lifetime-value get-commerce-lifetime-value-metrics" [
  companyId: any
  connectionId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportDate: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --periodLength: int # The number of months per period. E.g. 2 = 2 months per period.
  --numberOfPeriods: int # The number of periods to return.  There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
  --periodUnit: string@periodUnit-completer # The period unit of time returned.
  --includeDisplayNames: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
]: nothing -> record<dimensions: list<any>, errors: list<any>, measures: list<any>, reportData: list<any>, reportInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportDate" $reportDate "scalar") (serialize-qp "periodLength" $periodLength "scalar") (serialize-qp "numberOfPeriods" $numberOfPeriods "scalar") (serialize-qp "periodUnit" $periodUnit "scalar") (serialize-qp "includeDisplayNames" $includeDisplayNames "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/data/companies/($companyId)/connections/($connectionId)/assess/commerceMetrics/lifetimeValue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get order information for a specific company
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/commerceMetrics/orders
# operationId: get-commerce-orders-metrics
export def "data-companies-connections-assess-commerce-metrics-orders get-commerce-orders-metrics" [
  companyId: any
  connectionId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportDate: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --periodLength: int # The number of months per period. E.g. 2 = 2 months per period.
  --numberOfPeriods: int # The number of periods to return.  There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
  --periodUnit: string@periodUnit-completer # The period unit of time returned.
  --includeDisplayNames: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
]: nothing -> record<dimensions: list<any>, errors: list<any>, measures: list<any>, reportData: list<any>, reportInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportDate" $reportDate "scalar") (serialize-qp "periodLength" $periodLength "scalar") (serialize-qp "numberOfPeriods" $numberOfPeriods "scalar") (serialize-qp "periodUnit" $periodUnit "scalar") (serialize-qp "includeDisplayNames" $includeDisplayNames "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/data/companies/($companyId)/connections/($connectionId)/assess/commerceMetrics/orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the refunds information for a specific company
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/commerceMetrics/refunds
# operationId: get-commerce-refunds-metrics
export def "data-companies-connections-assess-commerce-metrics-refunds get-commerce-refunds-metrics" [
  companyId: any
  connectionId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportDate: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --periodLength: int # The number of months per period. E.g. 2 = 2 months per period.
  --numberOfPeriods: int # The number of periods to return.  There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
  --periodUnit: string@periodUnit-completer # The period unit of time returned.
  --includeDisplayNames: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
]: nothing -> record<dimensions: list<any>, errors: list<any>, measures: list<any>, reportData: list<any>, reportInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportDate" $reportDate "scalar") (serialize-qp "periodLength" $periodLength "scalar") (serialize-qp "numberOfPeriods" $numberOfPeriods "scalar") (serialize-qp "periodUnit" $periodUnit "scalar") (serialize-qp "includeDisplayNames" $includeDisplayNames "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/data/companies/($companyId)/connections/($connectionId)/assess/commerceMetrics/refunds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Commerce Revenue Metrics
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/commerceMetrics/revenue
# operationId: get-commerce-revenue-metrics
export def "data-companies-connections-assess-commerce-metrics-revenue get-commerce-revenue-metrics" [
  companyId: any
  connectionId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportDate: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --periodLength: int # The number of months per period. E.g. 2 = 2 months per period.
  --numberOfPeriods: int # The number of periods to return.  There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
  --periodUnit: string@periodUnit-completer # The period unit of time returned.
  --includeDisplayNames: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
]: nothing -> record<dimensions: list<any>, errors: list<any>, measures: list<any>, reportData: list<any>, reportInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportDate" $reportDate "scalar") (serialize-qp "periodLength" $periodLength "scalar") (serialize-qp "numberOfPeriods" $numberOfPeriods "scalar") (serialize-qp "periodUnit" $periodUnit "scalar") (serialize-qp "includeDisplayNames" $includeDisplayNames "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/data/companies/($companyId)/connections/($connectionId)/assess/commerceMetrics/revenue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enhanced Balance Sheet
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/enhancedBalanceSheet
# DEPRECATED
# operationId: get-enhanced-balance-sheet
@deprecated
export def "data-companies-connections-assess-enhanced-balance-sheet get-enhanced-balance-sheet" [
  companyId: any
  connectionId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportDate: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --periodLength: int # The number of months per period. E.g. 2 = 2 months per period.
  --numberOfPeriods: int # The number of periods to return.  There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
  --includeDisplayNames: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
]: nothing -> record<dimensions: list<any>, errors: list<any>, measures: list<any>, reportData: list<any>, reportInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportDate" $reportDate "scalar") (serialize-qp "periodLength" $periodLength "scalar") (serialize-qp "numberOfPeriods" $numberOfPeriods "scalar") (serialize-qp "includeDisplayNames" $includeDisplayNames "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/data/companies/($companyId)/connections/($connectionId)/assess/enhancedBalanceSheet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enhanced Profit and Loss
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/enhancedProfitAndLoss
# DEPRECATED
# operationId: get-enhanced-profit-and-loss
@deprecated
export def "data-companies-connections-assess-enhanced-profit-and-loss get-enhanced-profit-and-loss" [
  companyId: any
  connectionId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportDate: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --periodLength: int # The number of months per period. E.g. 2 = 2 months per period.
  --numberOfPeriods: int # The number of periods to return.  There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
  --includeDisplayNames: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
]: nothing -> record<dimensions: list<any>, errors: list<any>, measures: list<any>, reportData: list<any>, reportInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportDate" $reportDate "scalar") (serialize-qp "periodLength" $periodLength "scalar") (serialize-qp "numberOfPeriods" $numberOfPeriods "scalar") (serialize-qp "includeDisplayNames" $includeDisplayNames "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/data/companies/($companyId)/connections/($connectionId)/assess/enhancedProfitAndLoss" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List financial metrics
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/financialMetrics
# DEPRECATED
# operationId: get-enhanced-financial-metrics
@deprecated
export def "data-companies-connections-assess-financial-metrics get-enhanced-financial-metrics" [
  companyId: any
  connectionId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportDate: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --periodLength: int # The number of months per period. E.g. 2 = 2 months per period.
  --numberOfPeriods: int # The number of periods to return.  There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
  --showMetricInputs: oneof<nothing, bool> # If set to true, then the system includes the input values within the response.
]: nothing -> record<currency: string, errors: list<any>, metrics: list<any>, periodUnit: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportDate" $reportDate "scalar") (serialize-qp "periodLength" $periodLength "scalar") (serialize-qp "numberOfPeriods" $numberOfPeriods "scalar") (serialize-qp "showMetricInputs" $showMetricInputs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/data/companies/($companyId)/connections/($connectionId)/assess/financialMetrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get key metrics for subscription revenue
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/subscriptions/mrr
# operationId: get-recurring-revenue-metrics
export def "data-companies-connections-assess-subscriptions-mrr get-recurring-revenue-metrics" [
  companyId: string
  connectionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dimensions: list<any>, errors: list<any>, measures: list<any>, reportData: list<any>, reportInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data/companies/($companyId)/connections/($connectionId)/assess/subscriptions/mrr")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request production of key subscription revenue metrics
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/subscriptions/process
# operationId: request-recurring-revenue-metrics
export def "data-companies-connections-assess-subscriptions-process request-recurring-revenue-metrics" [
  companyId: string
  connectionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dimensions: list<any>, errors: list<any>, measures: list<any>, reportData: list<any>, reportInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/data/companies/($companyId)/connections/($connectionId)/assess/subscriptions/process")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
