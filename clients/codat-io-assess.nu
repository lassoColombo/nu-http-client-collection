# Auto-generated client for Assess API v1.0
# Source: https://api.apis.guru/v2/specs/codat.io/assess/1.0/openapi.json
# Auth: --token flag or $env.ASSESS_API_TOKEN

const BASE_URL = "https://api.codat.io"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ASSESS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.codat.io"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def report-type-completer [] { ["audit" "enhancedFinancials"] }
def period-unit-completer [] { ["Day" "Month" "Week" "Year"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "companies-reports-enhanced-balance-sheet-accounts get" } } | get name | first)
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
export def "companies-reports-enhanced-balance-sheet-accounts get" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
]: nothing -> record<reportInfo: record<companyName: string, currency: string, generatedDate: string, reportName: string>, reportItems: table<accountCategory: record, accountId: string, accountName: string, balance: float, date: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let qp = [(serialize-qp "reportDate" $report_date "scalar") (serialize-qp "numberOfPeriods" $number_of_periods "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/reports/enhancedBalanceSheet/accounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"reportDate": $report_date, "numberOfPeriods": $number_of_periods} | compact), body: null}
}

# Get enhanced cash flow report
#
# GET /companies/{companyId}/reports/enhancedCashFlow/transactions
# operationId: get-enhanced-cash-flow-transactions
export def "companies-reports-enhanced-cash-flow-transactions get" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1, e.g. 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100, e.g. 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
]: nothing -> record<dataSources: table<accounts: list>, reportInfo: record<companyName: string, generatedDate: string, pageNumber: int, pageSize: int, reportName: string, totalResults: int>, reportItems: table<transactions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/reports/enhancedCashFlow/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "pageSize": $page_size, "query": $query} | compact), body: null}
}

# Enhanced Invoices Report
#
# GET /companies/{companyId}/reports/enhancedInvoices
# operationId: get-enhanced-invoices-report
export def "companies-reports-enhanced-invoices get" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1, e.g. 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100, e.g. 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
]: nothing -> record<reportInfo: record<companyName: string, generatedDate: string, pageNumber: int, pageSize: int, reportName: string, totalResults: int>, reportItems: table<invoices: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/reports/enhancedInvoices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "pageSize": $page_size, "query": $query} | compact), body: null}
}

# Enhanced Profit and Loss Accounts
#
# GET /companies/{companyId}/reports/enhancedProfitAndLoss/accounts
# operationId: get-accounts-for-enhanced-profit-and-loss
export def "companies-reports-enhanced-profit-and-loss-accounts get" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
]: nothing -> record<reportInfo: record<companyName: string, currency: string, generatedDate: string, reportName: string>, reportItems: table<accountCategory: record, accountId: string, accountName: string, balance: float, date: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let qp = [(serialize-qp "reportDate" $report_date "scalar") (serialize-qp "numberOfPeriods" $number_of_periods "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/reports/enhancedProfitAndLoss/accounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"reportDate": $report_date, "numberOfPeriods": $number_of_periods} | compact), body: null}
}

# List account categories
#
# GET /data/assess/accounts/categories
# DEPRECATED
# operationId: list-available-account-categories
@deprecated
export def "data-assess-accounts-categories list-available" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<detailType: string, subtype: string, type: string, detailTypeDescription: string, detailTypeDisplayName: string, subtypeDisplayName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/data/assess/accounts/categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists data integrity details for date type
#
# GET /data/companies/{companyId}/assess/dataTypes/{dataType}/dataIntegrity/details
# operationId: get-data-integrity-details
export def "data-companies-assess-data-types-data-integrity-details get" [
  company_id: any
  data_type: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1, e.g. 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100, e.g. 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results). (e.g. -modifiedDate)
]: nothing -> record<results: table<amount: float, connectionId: string, currency: string, date: string, description: string, id: string, matches: list, type: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($data_type | is-empty) { error make --unspanned { msg: "path parameter 'dataType' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), data_type: (encode-path-segment $data_type)} | format pattern "/data/companies/{company_id}/assess/dataTypes/{data_type}/dataIntegrity/details") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact), body: null}
}

# Get data integrity status
#
# GET /data/companies/{companyId}/assess/dataTypes/{dataType}/dataIntegrity/status
# operationId: get-data-integrity-status
export def "data-companies-assess-data-types-data-integrity-status get" [
  company_id: string
  data_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<metadata: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($data_type | is-empty) { error make --unspanned { msg: "path parameter 'dataType' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), data_type: (encode-path-segment $data_type)} | format pattern "/data/companies/{company_id}/assess/dataTypes/{data_type}/dataIntegrity/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get data integrity summary
#
# GET /data/companies/{companyId}/assess/dataTypes/{dataType}/dataIntegrity/summaries
# operationId: get-data-integrity-summaries
export def "data-companies-assess-data-types-data-integrity-summaries get" [
  company_id: any
  data_type: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
]: nothing -> record<summaries: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($data_type | is-empty) { error make --unspanned { msg: "path parameter 'dataType' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), data_type: (encode-path-segment $data_type)} | format pattern "/data/companies/{company_id}/assess/dataTypes/{data_type}/dataIntegrity/summaries") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query} | compact), body: null}
}

# Get status of Excel report
#
# GET /data/companies/{companyId}/assess/excel
# operationId: get-excel-report-generation-status
export def "data-companies-assess-excel get-report-generation-status" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-type: string@report-type-completer # The type of report you want to generate and download.
]: nothing -> record<errorMessage: string, fileSize: int, inProgress: bool, lastGenerated: string, lastInvocationId: string, queued: string, reportType: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let qp = [(serialize-qp "reportType" $report_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/data/companies/{company_id}/assess/excel") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"reportType": $report_type} | compact), body: null}
}

# Generate an Excel report
#
# POST /data/companies/{companyId}/assess/excel
# operationId: generate-excel-report
export def "data-companies-assess-excel generate-report" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-type: string@report-type-completer # The type of report you want to generate and download.
]: nothing -> record<errorMessage: string, fileSize: int, inProgress: bool, lastGenerated: string, lastInvocationId: string, queued: string, reportType: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let qp = [(serialize-qp "reportType" $report_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/data/companies/{company_id}/assess/excel") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"reportType": $report_type} | compact), body: null}
}

# Download generated excel report
#
# GET /data/companies/{companyId}/assess/excel/download
# operationId: get-excel-report
export def "data-companies-assess-excel-download get-report" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-type: string@report-type-completer # The type of report you want to generate and download.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let qp = [(serialize-qp "reportType" $report_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/data/companies/{company_id}/assess/excel/download") $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"reportType": $report_type} | compact), body: null}
}

# Download generated excel report
#
# POST /data/companies/{companyId}/assess/excel/download
# DEPRECATED
# operationId: download-excel-report
@deprecated
export def "data-companies-assess-excel-download download-report" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-type: string@report-type-completer # The type of report you want to generate and download.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let qp = [(serialize-qp "reportType" $report_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/data/companies/{company_id}/assess/excel/download") $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"reportType": $report_type} | compact), body: null}
}

# Get the marketing metrics from an accounting source for a given company.
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/accountingMetrics/marketing
# operationId: get-accounting-marketing-metrics
export def "data-companies-connections-assess-accounting-metrics-marketing get" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --period-length: int # The number of months per period. E.g. 2 = 2 months per period.
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
  --period-unit: string@period-unit-completer # The period unit of time returned.
  --include-display-names: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
  --show-input-values: oneof<nothing, bool> # If set to true, then the system includes the input values within the response.
]: nothing -> record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "reportDate" $report_date "scalar") (serialize-qp "periodLength" $period_length "scalar") (serialize-qp "numberOfPeriods" $number_of_periods "scalar") (serialize-qp "periodUnit" $period_unit "scalar") (serialize-qp "includeDisplayNames" $include_display_names "scalar") (serialize-qp "showInputValues" $show_input_values "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/data/companies/{company_id}/connections/{connection_id}/assess/accountingMetrics/marketing") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"reportDate": $report_date, "periodLength": $period_length, "numberOfPeriods": $number_of_periods, "periodUnit": $period_unit, "includeDisplayNames": $include_display_names, "showInputValues": $show_input_values} | compact), body: null}
}

# List suggested and confirmed account categories
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/accounts/categories
# DEPRECATED
# operationId: list-accounts-categories
@deprecated
export def "data-companies-connections-assess-accounts-categories list" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1, e.g. 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100, e.g. 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results). (e.g. -modifiedDate)
]: nothing -> record<results: table<accountRef: record, confirmed: record, suggested: record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/data/companies/{company_id}/connections/{connection_id}/assess/accounts/categories") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact), body: null}
}

# Confirm categories for accounts
#
# PATCH /data/companies/{companyId}/connections/{connectionId}/assess/accounts/categories
# DEPRECATED
# operationId: update-accounts-categories
# --categories item shape: {accountRef?: record, confirmed?: record}
@deprecated
export def "data-companies-connections-assess-accounts-categories update" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories: list # List of confirmed account categories set manually by the user. — item shape: {accountRef?: record, confirmed?: record}
]: any -> table<accountRef: record<id: string, name: string>, confirmed: record, suggested: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/data/companies/{company_id}/connections/{connection_id}/assess/accounts/categories"))
  let req_body = {"categories": $categories} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get suggested and/or confirmed category for a specific account
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/accounts/{accountId}/categories
# DEPRECATED
# operationId: get-account-category
@deprecated
export def "data-companies-connections-assess-accounts-categories get-category" [
  company_id: string
  connection_id: string
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
]: nothing -> record<accountRef: record<id: string, name: string>, confirmed: record, suggested: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), account_id: (encode-path-segment $account_id)} | format pattern "/data/companies/{company_id}/connections/{connection_id}/assess/accounts/{account_id}/categories"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Patch account categories
#
# PATCH /data/companies/{companyId}/connections/{connectionId}/assess/accounts/{accountId}/categories
# DEPRECATED
# operationId: update-account-category
# --confirmed shape: {detailType?: string, subtype?: string, type?: string}
@deprecated
export def "data-companies-connections-assess-accounts-categories update-category" [
  company_id: string
  connection_id: string
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
  confirmed: record # shape: {detailType?: string, subtype?: string, type?: string}
]: any -> record<accountRef: record<id: string, name: string>, confirmed: record, suggested: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), account_id: (encode-path-segment $account_id)} | format pattern "/data/companies/{company_id}/connections/{connection_id}/assess/accounts/{account_id}/categories"))
  let req_body = {"confirmed": $confirmed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get the customer retention metrics for a specific company.
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/commerceMetrics/customerRetention
# operationId: get-commerce-customer-retention-metrics
export def "data-companies-connections-assess-commerce-metrics-customer-retention get" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --period-length: int # The number of months per period. E.g. 2 = 2 months per period.
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
  --period-unit: string@period-unit-completer # The period unit of time returned.
  --include-display-names: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
]: nothing -> record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "reportDate" $report_date "scalar") (serialize-qp "periodLength" $period_length "scalar") (serialize-qp "numberOfPeriods" $number_of_periods "scalar") (serialize-qp "periodUnit" $period_unit "scalar") (serialize-qp "includeDisplayNames" $include_display_names "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/data/companies/{company_id}/connections/{connection_id}/assess/commerceMetrics/customerRetention") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"reportDate": $report_date, "periodLength": $period_length, "numberOfPeriods": $number_of_periods, "periodUnit": $period_unit, "includeDisplayNames": $include_display_names} | compact), body: null}
}

# Get the lifetime value metric for a specific company.
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/commerceMetrics/lifetimeValue
# operationId: get-commerce-lifetime-value-metrics
export def "data-companies-connections-assess-commerce-metrics-lifetime-value get" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --period-length: int # The number of months per period. E.g. 2 = 2 months per period.
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
  --period-unit: string@period-unit-completer # The period unit of time returned.
  --include-display-names: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
]: nothing -> record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "reportDate" $report_date "scalar") (serialize-qp "periodLength" $period_length "scalar") (serialize-qp "numberOfPeriods" $number_of_periods "scalar") (serialize-qp "periodUnit" $period_unit "scalar") (serialize-qp "includeDisplayNames" $include_display_names "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/data/companies/{company_id}/connections/{connection_id}/assess/commerceMetrics/lifetimeValue") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"reportDate": $report_date, "periodLength": $period_length, "numberOfPeriods": $number_of_periods, "periodUnit": $period_unit, "includeDisplayNames": $include_display_names} | compact), body: null}
}

# Get order information for a specific company
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/commerceMetrics/orders
# operationId: get-commerce-orders-metrics
export def "data-companies-connections-assess-commerce-metrics-orders get" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --period-length: int # The number of months per period. E.g. 2 = 2 months per period.
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
  --period-unit: string@period-unit-completer # The period unit of time returned.
  --include-display-names: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
]: nothing -> record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "reportDate" $report_date "scalar") (serialize-qp "periodLength" $period_length "scalar") (serialize-qp "numberOfPeriods" $number_of_periods "scalar") (serialize-qp "periodUnit" $period_unit "scalar") (serialize-qp "includeDisplayNames" $include_display_names "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/data/companies/{company_id}/connections/{connection_id}/assess/commerceMetrics/orders") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"reportDate": $report_date, "periodLength": $period_length, "numberOfPeriods": $number_of_periods, "periodUnit": $period_unit, "includeDisplayNames": $include_display_names} | compact), body: null}
}

# Get the refunds information for a specific company
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/commerceMetrics/refunds
# operationId: get-commerce-refunds-metrics
export def "data-companies-connections-assess-commerce-metrics-refunds get" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --period-length: int # The number of months per period. E.g. 2 = 2 months per period.
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
  --period-unit: string@period-unit-completer # The period unit of time returned.
  --include-display-names: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
]: nothing -> record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "reportDate" $report_date "scalar") (serialize-qp "periodLength" $period_length "scalar") (serialize-qp "numberOfPeriods" $number_of_periods "scalar") (serialize-qp "periodUnit" $period_unit "scalar") (serialize-qp "includeDisplayNames" $include_display_names "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/data/companies/{company_id}/connections/{connection_id}/assess/commerceMetrics/refunds") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"reportDate": $report_date, "periodLength": $period_length, "numberOfPeriods": $number_of_periods, "periodUnit": $period_unit, "includeDisplayNames": $include_display_names} | compact), body: null}
}

# Commerce Revenue Metrics
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/commerceMetrics/revenue
# operationId: get-commerce-revenue-metrics
export def "data-companies-connections-assess-commerce-metrics-revenue get" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --period-length: int # The number of months per period. E.g. 2 = 2 months per period.
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
  --period-unit: string@period-unit-completer # The period unit of time returned.
  --include-display-names: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
]: nothing -> record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "reportDate" $report_date "scalar") (serialize-qp "periodLength" $period_length "scalar") (serialize-qp "numberOfPeriods" $number_of_periods "scalar") (serialize-qp "periodUnit" $period_unit "scalar") (serialize-qp "includeDisplayNames" $include_display_names "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/data/companies/{company_id}/connections/{connection_id}/assess/commerceMetrics/revenue") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"reportDate": $report_date, "periodLength": $period_length, "numberOfPeriods": $number_of_periods, "periodUnit": $period_unit, "includeDisplayNames": $include_display_names} | compact), body: null}
}

# Enhanced Balance Sheet
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/enhancedBalanceSheet
# DEPRECATED
# operationId: get-enhanced-balance-sheet
@deprecated
export def "data-companies-connections-assess-enhanced-balance-sheet get" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --period-length: int # The number of months per period. E.g. 2 = 2 months per period.
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
  --include-display-names: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
]: nothing -> record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "reportDate" $report_date "scalar") (serialize-qp "periodLength" $period_length "scalar") (serialize-qp "numberOfPeriods" $number_of_periods "scalar") (serialize-qp "includeDisplayNames" $include_display_names "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/data/companies/{company_id}/connections/{connection_id}/assess/enhancedBalanceSheet") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"reportDate": $report_date, "periodLength": $period_length, "numberOfPeriods": $number_of_periods, "includeDisplayNames": $include_display_names} | compact), body: null}
}

# Enhanced Profit and Loss
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/enhancedProfitAndLoss
# DEPRECATED
# operationId: get-enhanced-profit-and-loss
@deprecated
export def "data-companies-connections-assess-enhanced-profit-and-loss get" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --period-length: int # The number of months per period. E.g. 2 = 2 months per period.
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
  --include-display-names: oneof<nothing, bool> # Shows the dimensionDisplayName and itemDisplayName in measures to make the report data human-readable.
]: nothing -> record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "reportDate" $report_date "scalar") (serialize-qp "periodLength" $period_length "scalar") (serialize-qp "numberOfPeriods" $number_of_periods "scalar") (serialize-qp "includeDisplayNames" $include_display_names "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/data/companies/{company_id}/connections/{connection_id}/assess/enhancedProfitAndLoss") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"reportDate": $report_date, "periodLength": $period_length, "numberOfPeriods": $number_of_periods, "includeDisplayNames": $include_display_names} | compact), body: null}
}

# List financial metrics
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/financialMetrics
# DEPRECATED
# operationId: get-enhanced-financial-metrics
@deprecated
export def "data-companies-connections-assess-financial-metrics get-enhanced" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # The date in which the report is created up to. Users must specify a specific date, however the response will be provided for the full month. (e.g. 29-09-2020)
  --period-length: int # The number of months per period. E.g. 2 = 2 months per period.
  --number-of-periods: int # The number of periods to return. There will be no pagination as a query parameter, however Codat will limit the number of periods to request to 12 periods.
  --show-metric-inputs: oneof<nothing, bool> # If set to true, then the system includes the input values within the response.
]: nothing -> record<currency: string, errors: table<message: string, type: string>, metrics: table<errors: list, key: string, metricUnit: string, name: string, periods: list>, periodUnit: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "reportDate" $report_date "scalar") (serialize-qp "periodLength" $period_length "scalar") (serialize-qp "numberOfPeriods" $number_of_periods "scalar") (serialize-qp "showMetricInputs" $show_metric_inputs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/data/companies/{company_id}/connections/{connection_id}/assess/financialMetrics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"reportDate": $report_date, "periodLength": $period_length, "numberOfPeriods": $number_of_periods, "showMetricInputs": $show_metric_inputs} | compact), body: null}
}

# Get key metrics for subscription revenue
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/subscriptions/mrr
# operationId: get-recurring-revenue-metrics
export def "data-companies-connections-assess-subscriptions-mrr get-recurring-revenue-metrics" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/data/companies/{company_id}/connections/{connection_id}/assess/subscriptions/mrr"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Request production of key subscription revenue metrics
#
# GET /data/companies/{companyId}/connections/{connectionId}/assess/subscriptions/process
# operationId: request-recurring-revenue-metrics
export def "data-companies-connections-assess-subscriptions-process request-recurring-revenue-metrics" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dimensions: table<displayName: string, index: int, items: list, type: string>, errors: table<details: record, message: string, type: string>, measures: table<displayName: string, index: int, type: string, units: string>, reportData: table<components: list, dimension: int, dimensionDisplayName: string, item: int, itemDisplayName: string, measures: list>, reportInfo: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/data/companies/{company_id}/connections/{connection_id}/assess/subscriptions/process"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
