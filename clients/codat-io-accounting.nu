# Auto-generated client for Accounting API v2.1.0
# Source: https://api.apis.guru/v2/specs/codat.io/accounting/2.1.0/openapi.json
# Auth: --token flag or $env.ACCOUNTING_API_TOKEN

const BASE_URL = "https://api.codat.io"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ACCOUNTING_API_TOKEN | default "" }
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
def account-type-completer [] { ["Credit" "Debit" "Unknown"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "companies-connections-data-account-transactions list-account-transactions" } } | get name | first)
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

# List account transactions
#
# GET /companies/{companyId}/connections/{connectionId}/data/accountTransactions
# operationId: list-account-transactions
export def "companies-connections-data-account-transactions list-account-transactions" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/accountTransactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get account transaction
#
# GET /companies/{companyId}/connections/{connectionId}/data/accountTransactions/{accountTransactionId}
# operationId: get-account-transaction
export def "companies-connections-data-account-transactions get-account-transaction" [
  company_id: string
  connection_id: string
  account_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, account_transaction_id: $account_transaction_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/accountTransactions/{account_transaction_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List bank accounts
#
# GET /companies/{companyId}/connections/{connectionId}/data/bankAccounts
# operationId: list-bank-accounts
export def "companies-connections-data-bank-accounts list-bank-accounts" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/bankAccounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bank account
#
# GET /companies/{companyId}/connections/{connectionId}/data/bankAccounts/{accountId}
# DEPRECATED
# operationId: get-bank-account
@deprecated
export def "companies-connections-data-bank-accounts get-bank-account" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, account_id: $account_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/bankAccounts/{account_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List bank transactions for bank account
#
# GET /companies/{companyId}/connections/{connectionId}/data/bankAccounts/{accountId}/bankTransactions
# operationId: list-bank-account-transactions
export def "companies-connections-data-bank-accounts-bank-transactions list-bank-account-transactions" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: table<accountId: string, transactions: list>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, account_id: $account_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/bankAccounts/{account_id}/bankTransactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List bill attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/bills/{billId}/attachments
# operationId: get-bill-attachments
export def "companies-connections-data-bills-attachments get-bill-attachments" [
  company_id: string
  connection_id: string
  bill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachments: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, bill_id: $bill_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/bills/{bill_id}/attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bill attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/bills/{billId}/attachments/{attachmentId}
# operationId: get-bill-attachment
export def "companies-connections-data-bills-attachments get-bill-attachment" [
  company_id: any
  connection_id: any
  bill_id: any
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, bill_id: $bill_id, attachment_id: $attachment_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/bills/{bill_id}/attachments/{attachment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download bill attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/bills/{billId}/attachments/{attachmentId}/download
# operationId: download-bill-attachment
export def "companies-connections-data-bills-attachments-download download-bill-attachment" [
  company_id: any
  connection_id: any
  bill_id: any
  attachment_id: string
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
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, bill_id: $bill_id, attachment_id: $attachment_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/bills/{bill_id}/attachments/{attachment_id}/download"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List customer attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/customers/{customerId}/attachments
# operationId: get-customer-attachments
export def "companies-connections-data-customers-attachments get-customer-attachments" [
  company_id: string
  connection_id: string
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachments: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, customer_id: $customer_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/customers/{customer_id}/attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get customer attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/customers/{customerId}/attachments/{attachmentId}
# operationId: get-customer-attachment
export def "companies-connections-data-customers-attachments get-customer-attachment" [
  company_id: string
  connection_id: string
  customer_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, customer_id: $customer_id, attachment_id: $attachment_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/customers/{customer_id}/attachments/{attachment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download customer attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/customers/{customerId}/attachments/{attachmentId}/download
# operationId: download-customer-attachment
export def "companies-connections-data-customers-attachments-download download-customer-attachment" [
  company_id: string
  connection_id: string
  customer_id: string
  attachment_id: string
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
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, customer_id: $customer_id, attachment_id: $attachment_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/customers/{customer_id}/attachments/{attachment_id}/download"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List direct costs
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts
# operationId: get-direct-costs
export def "companies-connections-data-direct-costs get-direct-costs" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directCosts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get direct cost
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}
# DEPRECATED
# operationId: get-direct-cost
@deprecated
export def "companies-connections-data-direct-costs get-direct-cost" [
  company_id: string
  connection_id: string
  direct_cost_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, direct_cost_id: $direct_cost_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directCosts/{direct_cost_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List direct cost attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}/attachments
# operationId: list-direct-cost-attachments
export def "companies-connections-data-direct-costs-attachments list-direct-cost-attachments" [
  company_id: string
  connection_id: string
  direct_cost_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachments: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, direct_cost_id: $direct_cost_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directCosts/{direct_cost_id}/attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get direct cost attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}/attachments/{attachmentId}
# operationId: get-direct-cost-attachment
export def "companies-connections-data-direct-costs-attachments get-direct-cost-attachment" [
  company_id: any
  connection_id: any
  direct_cost_id: any
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, direct_cost_id: $direct_cost_id, attachment_id: $attachment_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directCosts/{direct_cost_id}/attachments/{attachment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download direct cost attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}/attachments/{attachmentId}/download
# operationId: download-direct-cost-attachment
export def "companies-connections-data-direct-costs-attachments-download download-direct-cost-attachment" [
  company_id: any
  connection_id: any
  direct_cost_id: any
  attachment_id: string
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
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, direct_cost_id: $direct_cost_id, attachment_id: $attachment_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directCosts/{direct_cost_id}/attachments/{attachment_id}/download"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get direct incomes
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes
# operationId: get-direct-incomes
export def "companies-connections-data-direct-incomes get-direct-incomes" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directIncomes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get direct income
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}
# DEPRECATED
# operationId: get-direct-income
@deprecated
export def "companies-connections-data-direct-incomes get-direct-income" [
  company_id: string
  connection_id: string
  direct_income_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, direct_income_id: $direct_income_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directIncomes/{direct_income_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List direct income attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}/attachments
# operationId: list-direct-income-attachments
export def "companies-connections-data-direct-incomes-attachments list-direct-income-attachments" [
  company_id: string
  connection_id: string
  direct_income_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachments: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, direct_income_id: $direct_income_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directIncomes/{direct_income_id}/attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get direct income attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}/attachments/{attachmentId}
# operationId: get-direct-income-attachment
export def "companies-connections-data-direct-incomes-attachments get-direct-income-attachment" [
  company_id: any
  connection_id: any
  direct_income_id: any
  attachment_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, direct_income_id: $direct_income_id, attachment_id: $attachment_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directIncomes/{direct_income_id}/attachments/{attachment_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download direct income attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}/attachments/{attachmentId}/download
# operationId: download-direct-income-attachment
export def "companies-connections-data-direct-incomes-attachments-download download-direct-income-attachment" [
  company_id: any
  connection_id: any
  direct_income_id: any
  attachment_id: string
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
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, direct_income_id: $direct_income_id, attachment_id: $attachment_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directIncomes/{direct_income_id}/attachments/{attachment_id}/download"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get invoice attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/invoices/{invoiceId}/attachments
# operationId: get-invoice-attachments
export def "companies-connections-data-invoices-attachments get-invoice-attachments" [
  company_id: any
  connection_id: any
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachments: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, invoice_id: $invoice_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/invoices/{invoice_id}/attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get invoice attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/invoices/{invoiceId}/attachments/{attachmentId}
# operationId: get-invoice-attachment
export def "companies-connections-data-invoices-attachments get-invoice-attachment" [
  company_id: any
  connection_id: any
  invoice_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, invoice_id: $invoice_id, attachment_id: $attachment_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/invoices/{invoice_id}/attachments/{attachment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download invoice attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/invoices/{invoiceId}/attachments/{attachmentId}/download
# operationId: download-invoice-attachment
export def "companies-connections-data-invoices-attachments-download download-invoice-attachment" [
  company_id: any
  connection_id: any
  invoice_id: string
  attachment_id: string
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
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, invoice_id: $invoice_id, attachment_id: $attachment_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/invoices/{invoice_id}/attachments/{attachment_id}/download"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List supplier attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/suppliers/{supplierId}/attachments
# operationId: list-supplier-attachments
export def "companies-connections-data-suppliers-attachments list-supplier-attachments" [
  company_id: string
  connection_id: string
  supplier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachments: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, supplier_id: $supplier_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/suppliers/{supplier_id}/attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get supplier attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/suppliers/{supplierId}/attachments/{attachmentId}
# operationId: get-supplier-attachment
export def "companies-connections-data-suppliers-attachments get-supplier-attachment" [
  company_id: string
  connection_id: string
  supplier_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, supplier_id: $supplier_id, attachment_id: $attachment_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/suppliers/{supplier_id}/attachments/{attachment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download supplier attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/suppliers/{supplierId}/attachments/{attachmentId}/download
# operationId: download-supplier-attachment
export def "companies-connections-data-suppliers-attachments-download download-supplier-attachment" [
  company_id: string
  connection_id: string
  supplier_id: string
  attachment_id: string
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
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, supplier_id: $supplier_id, attachment_id: $attachment_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/suppliers/{supplier_id}/attachments/{attachment_id}/download"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List transfers
#
# GET /companies/{companyId}/connections/{connectionId}/data/transfers
# operationId: list-transfers
export def "companies-connections-data-transfers list-transfers" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/transfers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get transfer
#
# GET /companies/{companyId}/connections/{connectionId}/data/transfers/{transferId}
# DEPRECATED
# operationId: get-transfer
@deprecated
export def "companies-connections-data-transfers get-transfer" [
  company_id: string
  connection_id: string
  transfer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, transfer_id: $transfer_id} | format pattern "/companies/{company_id}/connections/{connection_id}/data/transfers/{transfer_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create/update bank account model
#
# GET /companies/{companyId}/connections/{connectionId}/options/bankAccounts
# operationId: get-create-update-bankAccounts-model
export def "companies-connections-options-bank-accounts get-create-update-bankAccounts-model" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/options/bankAccounts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List push options for bank account bank transactions
#
# GET /companies/{companyId}/connections/{connectionId}/options/bankAccounts/{accountId}/bankTransactions
# operationId: get-create-bank-account-model
export def "companies-connections-options-bank-accounts-bank-transactions get-create-bank-account-model" [
  company_id: string
  connection_id: string
  account_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, account_id: $account_id} | format pattern "/companies/{company_id}/connections/{connection_id}/options/bankAccounts/{account_id}/bankTransactions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create/update bill credit note model
#
# GET /companies/{companyId}/connections/{connectionId}/options/billCreditNotes
# operationId: get-create-update-billCreditNotes-model
export def "companies-connections-options-bill-credit-notes get-create-update-billCreditNotes-model" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/options/billCreditNotes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create bill payment model
#
# GET /companies/{companyId}/connections/{connectionId}/options/billPayments
# operationId: get-create-billPayments-model
export def "companies-connections-options-bill-payments get-create-billPayments-model" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/options/billPayments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create/update bill model
#
# GET /companies/{companyId}/connections/{connectionId}/options/bills
# operationId: get-create-update-bills-model
export def "companies-connections-options-bills get-create-update-bills-model" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/options/bills"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create account model
#
# GET /companies/{companyId}/connections/{connectionId}/options/chartOfAccounts
# operationId: get-create-chartOfAccounts-model
export def "companies-connections-options-chart-of-accounts get-create-chartOfAccounts-model" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/options/chartOfAccounts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create/update credit note model
#
# GET /companies/{companyId}/connections/{connectionId}/options/creditNotes
# operationId: get-create-update-creditNotes-model
export def "companies-connections-options-credit-notes get-create-update-creditNotes-model" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/options/creditNotes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create/update customer model
#
# GET /companies/{companyId}/connections/{connectionId}/options/customers
# operationId: get-create-update-customers-model
export def "companies-connections-options-customers get-create-update-customers-model" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/options/customers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create direct cost model
#
# GET /companies/{companyId}/connections/{connectionId}/options/directCosts
# operationId: get-create-directCosts-model
export def "companies-connections-options-direct-costs get-create-directCosts-model" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/options/directCosts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create direct income model
#
# GET /companies/{companyId}/connections/{connectionId}/options/directIncomes
# operationId: get-create-directIncomes-model
export def "companies-connections-options-direct-incomes get-create-directIncomes-model" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/options/directIncomes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create/update invoice model
#
# GET /companies/{companyId}/connections/{connectionId}/options/invoices
# operationId: get-create-update-invoices-model
export def "companies-connections-options-invoices get-create-update-invoices-model" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/options/invoices"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create item model
#
# GET /companies/{companyId}/connections/{connectionId}/options/items
# operationId: get-create-items-model
export def "companies-connections-options-items get-create-items-model" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/options/items"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create journal entry model
#
# GET /companies/{companyId}/connections/{connectionId}/options/journalEntries
# operationId: get-create-journalEntries-model
export def "companies-connections-options-journal-entries get-create-journalEntries-model" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/options/journalEntries"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create journal model
#
# GET /companies/{companyId}/connections/{connectionId}/options/journals
# operationId: get-create-journals-model
export def "companies-connections-options-journals get-create-journals-model" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/options/journals"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create payment model
#
# GET /companies/{companyId}/connections/{connectionId}/options/payments
# operationId: get-create-payments-model
export def "companies-connections-options-payments get-create-payments-model" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/options/payments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create/update purchase order model
#
# GET /companies/{companyId}/connections/{connectionId}/options/purchaseOrders
# operationId: get-create-update-purchaseOrders-model
export def "companies-connections-options-purchase-orders get-create-update-purchaseOrders-model" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/options/purchaseOrders"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create/update supplier model
#
# GET /companies/{companyId}/connections/{connectionId}/options/suppliers
# operationId: get-create-update-suppliers-model
export def "companies-connections-options-suppliers get-create-update-suppliers-model" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/options/suppliers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create transfer model
#
# GET /companies/{companyId}/connections/{connectionId}/options/transfers
# operationId: get-create-transfers-model
export def "companies-connections-options-transfers get-create-transfers-model" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/options/transfers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create account
#
# POST /companies/{companyId}/connections/{connectionId}/push/accounts
# operationId: create-account
# --metadata shape: {isDeleted?: bool}
# --validDatatypeLinks item shape: {links?: list, property?: string}
export def "companies-connections-push-accounts create-account" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --currency: any
  --current-balance: float # Current balance in the account. (nullable)
  --description: string # Description for the account. (nullable)
  --fully-qualified-category: string # Full category of the account. For example: Liability.Current or Income.Revenue. See example data. (nullable)
  --fully-qualified-name: string # Full name of the account, for example: - `Liability.Current.VAT` - `Income.Revenue.Sales` (nullable)
  --id: string # Identifier for the account, unique for the company.
  --is-bank-account: oneof<nothing, bool> # Confirms whether the account is a bank account or not.
  --metadata: record # shape: {isDeleted?: bool}
  --name: string # Name of the account. (nullable)
  --nominal-code: string # Reference given to each nominal account for a business. It ensures money is allocated to the correct account. This code isn't a unique identifier in the Codat system. (nullable)
  status: any
  type: any
  --valid-datatype-links: list # 'The validDatatypeLinks can be used to determine whether an account can be correctly mapped to another object; for example, accounts with a `type` of `income` might only support being used on an Invoice and Direct Income. For more information, see Valid Data Type Links.' (nullable) — item shape: {links?: list, property?: string}
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/accounts") $qp)
  let body = {"currency": $currency, "currentBalance": $current_balance, "description": $description, "fullyQualifiedCategory": $fully_qualified_category, "fullyQualifiedName": $fully_qualified_name, "id": $id, "isBankAccount": $is_bank_account, "metadata": $metadata, "name": $name, "nominalCode": $nominal_code, "status": $status, "type": $type, "validDatatypeLinks": $valid_datatype_links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create bank account
#
# POST /companies/{companyId}/connections/{connectionId}/push/bankAccounts
# operationId: create-bank-account
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-bank-accounts create-bank-account" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sync-on-push-complete: oneof<nothing, bool> # default: true
  --timeout-in-minutes: int # format: int32
  --account-name: string # Name of the bank account in the accounting platform. (nullable)
  --account-number: string # Account number for the bank account.  Xero integrations Only a UK account number shows for bank accounts with GBP currency and a combined total of sort code and account number that equals 14 digits, For non-GBP accounts, the full bank account number is populated.  FreeAgent integrations For Credit accounts, only the last four digits are required. For other types, the field is optional. (nullable)
  --account-type: string@account-type-completer # The type of transactions and balances on the account.   For Credit accounts, positive balances are liabilities, and positive transactions **reduce** liabilities.   For Debit accounts, positive balances are assets, and positive transactions **increase** assets.
  --available-balance: float # Total available balance of the bank account as reported by the underlying data source. This may take into account overdrafts or pending transactions for example. (nullable)
  --balance: float # Balance of the bank account. (nullable)
  --currency: any # Base currency of the bank account.
  --i-ban: string # International bank account number of the account. Often used when making or receiving international payments. (nullable)
  --id: string # Identifier for the account, unique for the company in the accounting platform.
  --institution: string # The institution of the bank account. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --nominal-code: string # Code used to identify each nominal account for a business. (nullable)
  --overdraft-limit: float # Pre-arranged overdraft limit of the account.  The value is always positive. For example, an overdraftLimit of `1000` means that the balance of the account can go down to `-1000`. (nullable)
  --sort-code: string # Sort code for the bank account.  Xero integrations The sort code is only displayed when the currency = GBP and the sort code and account number sum to 14 digits. For non-GBP accounts, this field is not populated. (nullable)
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allowSyncOnPushComplete" $allow_sync_on_push_complete "scalar") (serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/bankAccounts") $qp)
  let body = {"accountName": $account_name, "accountNumber": $account_number, "accountType": $account_type, "availableBalance": $available_balance, "balance": $balance, "currency": $currency, "iBan": $i_ban, "id": $id, "institution": $institution, "metadata": $metadata, "nominalCode": $nominal_code, "overdraftLimit": $overdraft_limit, "sortCode": $sort_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create bank transactions
#
# POST /companies/{companyId}/connections/{connectionId}/push/bankAccounts/{accountId}/bankTransactions
# operationId: create-bank-transactions
export def "companies-connections-push-bank-accounts-bank-transactions create-bank-transactions" [
  company_id: string
  connection_id: string
  account_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sync-on-push-complete: oneof<nothing, bool> # default: true
  --timeout-in-minutes: int # format: int32
  --body-account-id: string # nullable
  --transactions: list # nullable
]: any -> record<data: record<accountId: string, transactions: list<any>>, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allowSyncOnPushComplete" $allow_sync_on_push_complete "scalar") (serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, account_id: $account_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/bankAccounts/{account_id}/bankTransactions") $qp)
  let body = {"accountId": $body_account_id, "transactions": $transactions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update bank account
#
# PUT /companies/{companyId}/connections/{connectionId}/push/bankAccounts/{bankAccountId}
# operationId: update-bank-account
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-bank-accounts update-bank-account" [
  company_id: any
  connection_id: any
  bank_account_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --account-name: string # Name of the bank account in the accounting platform. (nullable)
  --account-number: string # Account number for the bank account.  Xero integrations Only a UK account number shows for bank accounts with GBP currency and a combined total of sort code and account number that equals 14 digits, For non-GBP accounts, the full bank account number is populated.  FreeAgent integrations For Credit accounts, only the last four digits are required. For other types, the field is optional. (nullable)
  --account-type: string@account-type-completer # The type of transactions and balances on the account.   For Credit accounts, positive balances are liabilities, and positive transactions **reduce** liabilities.   For Debit accounts, positive balances are assets, and positive transactions **increase** assets.
  --available-balance: float # Total available balance of the bank account as reported by the underlying data source. This may take into account overdrafts or pending transactions for example. (nullable)
  --balance: float # Balance of the bank account. (nullable)
  --currency: any # Base currency of the bank account.
  --i-ban: string # International bank account number of the account. Often used when making or receiving international payments. (nullable)
  --id: string # Identifier for the account, unique for the company in the accounting platform.
  --institution: string # The institution of the bank account. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --nominal-code: string # Code used to identify each nominal account for a business. (nullable)
  --overdraft-limit: float # Pre-arranged overdraft limit of the account.  The value is always positive. For example, an overdraftLimit of `1000` means that the balance of the account can go down to `-1000`. (nullable)
  --sort-code: string # Sort code for the bank account.  Xero integrations The sort code is only displayed when the currency = GBP and the sort code and account number sum to 14 digits. For non-GBP accounts, this field is not populated. (nullable)
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, bank_account_id: $bank_account_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/bankAccounts/{bank_account_id}") $qp)
  let body = {"accountName": $account_name, "accountNumber": $account_number, "accountType": $account_type, "availableBalance": $available_balance, "balance": $balance, "currency": $currency, "iBan": $i_ban, "id": $id, "institution": $institution, "metadata": $metadata, "nominalCode": $nominal_code, "overdraftLimit": $overdraft_limit, "sortCode": $sort_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create bill credit note
#
# POST /companies/{companyId}/connections/{connectionId}/push/billCreditNotes
# operationId: create-bill-credit-note
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-bill-credit-notes create-bill-credit-note" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --allocated-on-date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --bill-credit-note-number: string # Friendly reference for the bill credit note. (nullable)
  --currency: any # Currency of the bill credit note.
  --currency-rate: any
  discount_percentage: float # Percentage rate of any discount applied to the bill credit note.
  --id: string # Identifier for the bill credit note that is unique to a company in the accounting platform.
  --issue-date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # An array of line  (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the bill credit note. (nullable)
  --payment-allocations: list # An array of payment allocations. (nullable)
  remaining_credit: float # Amount of the bill credit note that is still outstanding.
  status: any
  sub_total: float # Total amount of the bill credit note, including discounts but excluding tax.
  --supplemental-data: any
  --supplier-ref: any
  total_amount: float # Total amount of credit that has been applied to the business' account with the supplier, including discounts and tax.
  total_discount: float # Total value of any discounts applied.
  total_tax_amount: float # Amount of tax included in the bill credit note.
  --withholding-tax: list # nullable
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/billCreditNotes") $qp)
  let body = {"allocatedOnDate": $allocated_on_date, "billCreditNoteNumber": $bill_credit_note_number, "currency": $currency, "currencyRate": $currency_rate, "discountPercentage": $discount_percentage, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "remainingCredit": $remaining_credit, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "supplierRef": $supplier_ref, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount, "withholdingTax": $withholding_tax} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update bill credit note
#
# PUT /companies/{companyId}/connections/{connectionId}/push/billCreditNotes/{billCreditNoteId}
# operationId: update-bill-credit-note
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-bill-credit-notes update-bill-credit-note" [
  company_id: any
  connection_id: any
  bill_credit_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --allocated-on-date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --bill-credit-note-number: string # Friendly reference for the bill credit note. (nullable)
  --currency: any # Currency of the bill credit note.
  --currency-rate: any
  discount_percentage: float # Percentage rate of any discount applied to the bill credit note.
  --id: string # Identifier for the bill credit note that is unique to a company in the accounting platform.
  --issue-date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # An array of line  (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the bill credit note. (nullable)
  --payment-allocations: list # An array of payment allocations. (nullable)
  remaining_credit: float # Amount of the bill credit note that is still outstanding.
  status: any
  sub_total: float # Total amount of the bill credit note, including discounts but excluding tax.
  --supplemental-data: any
  --supplier-ref: any
  total_amount: float # Total amount of credit that has been applied to the business' account with the supplier, including discounts and tax.
  total_discount: float # Total value of any discounts applied.
  total_tax_amount: float # Amount of tax included in the bill credit note.
  --withholding-tax: list # nullable
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, bill_credit_note_id: $bill_credit_note_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/billCreditNotes/{bill_credit_note_id}") $qp)
  let body = {"allocatedOnDate": $allocated_on_date, "billCreditNoteNumber": $bill_credit_note_number, "currency": $currency, "currencyRate": $currency_rate, "discountPercentage": $discount_percentage, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "remainingCredit": $remaining_credit, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "supplierRef": $supplier_ref, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount, "withholdingTax": $withholding_tax} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create bill payments
#
# POST /companies/{companyId}/connections/{connectionId}/push/billPayments
# operationId: create-bill-payment
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-bill-payments create-bill-payment" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --account-ref: any # Account the payment is linked to in the accounting platform.
  --currency: any
  --currency-rate: any
  date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the bill payment, unique for the company in the accounting platform.
  --lines: list # An array of bill payment lines. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Additional information associated with the payment. (nullable)
  --payment-method-ref: any # The Payment Method to which the payment is linked in the accounting platform.
  --reference: string # Additional information associated with the payment. (nullable)
  --supplemental-data: any
  --supplier-ref: any
  --total-amount: float # Amount of the payment in the payment currency. This value never changes and represents the amount of money that is paid into the supplier's account.
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/billPayments") $qp)
  let body = {"accountRef": $account_ref, "currency": $currency, "currencyRate": $currency_rate, "date": $date, "id": $id, "lines": $lines, "metadata": $metadata, "note": $note, "paymentMethodRef": $payment_method_ref, "reference": $reference, "supplementalData": $supplemental_data, "supplierRef": $supplier_ref, "totalAmount": $total_amount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete bill payment
#
# DELETE /companies/{companyId}/connections/{connectionId}/push/billPayments/{billPaymentId}
# operationId: delete-billPayment
export def "companies-connections-push-bill-payments delete-billPayment" [
  company_id: string
  connection_id: string
  bill_payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, bill_payment_id: $bill_payment_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/billPayments/{bill_payment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create bill
#
# POST /companies/{companyId}/connections/{connectionId}/push/bills
# operationId: create-bill
# --metadata shape: {isDeleted?: bool}
# --paymentAllocations item shape: {allocation: record, payment: any}
# --supplementalData shape: {content?: record}
# --withholdingTax item shape: {amount: float, name: string}
export def "companies-connections-push-bills create-bill" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --amount-due: float # Amount outstanding on the bill. (nullable)
  --currency: any
  --currency-rate: any
  --due-date: any
  --id: string # Identifier for the bill, unique for the company in the accounting platform.
  issue_date: any
  --line-items: list # Array of Bill line items. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any private, company notes about the bill, such as payment information. (nullable)
  --payment-allocations: list # An array of payment allocations. (nullable) — item shape: {allocation: record, payment: any}
  --purchase-order-refs: list # nullable
  --reference: string # User-friendly reference for the bill. (nullable)
  status: any
  sub_total: float # Total amount of the bill, excluding any taxes.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --supplier-ref: any
  tax_amount: float # Amount of tax on the bill.
  total_amount: float # Amount of the bill, including tax.
  --withholding-tax: list # nullable — item shape: {amount: float, name: string}
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/bills") $qp)
  let body = {"amountDue": $amount_due, "currency": $currency, "currencyRate": $currency_rate, "dueDate": $due_date, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "purchaseOrderRefs": $purchase_order_refs, "reference": $reference, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "supplierRef": $supplier_ref, "taxAmount": $tax_amount, "totalAmount": $total_amount, "withholdingTax": $withholding_tax} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete bill
#
# DELETE /companies/{companyId}/connections/{connectionId}/push/bills/{billId}
# operationId: delete-bill
export def "companies-connections-push-bills delete-bill" [
  company_id: string
  connection_id: string
  bill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, bill_id: $bill_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/bills/{bill_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update bill
#
# PUT /companies/{companyId}/connections/{connectionId}/push/bills/{billId}
# operationId: update-bill
# --metadata shape: {isDeleted?: bool}
# --paymentAllocations item shape: {allocation: record, payment: any}
# --supplementalData shape: {content?: record}
# --withholdingTax item shape: {amount: float, name: string}
export def "companies-connections-push-bills update-bill" [
  company_id: any
  connection_id: any
  bill_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --amount-due: float # Amount outstanding on the bill. (nullable)
  --currency: any
  --currency-rate: any
  --due-date: any
  --id: string # Identifier for the bill, unique for the company in the accounting platform.
  issue_date: any
  --line-items: list # Array of Bill line items. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any private, company notes about the bill, such as payment information. (nullable)
  --payment-allocations: list # An array of payment allocations. (nullable) — item shape: {allocation: record, payment: any}
  --purchase-order-refs: list # nullable
  --reference: string # User-friendly reference for the bill. (nullable)
  status: any
  sub_total: float # Total amount of the bill, excluding any taxes.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --supplier-ref: any
  tax_amount: float # Amount of tax on the bill.
  total_amount: float # Amount of the bill, including tax.
  --withholding-tax: list # nullable — item shape: {amount: float, name: string}
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, bill_id: $bill_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/bills/{bill_id}") $qp)
  let body = {"amountDue": $amount_due, "currency": $currency, "currencyRate": $currency_rate, "dueDate": $due_date, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "purchaseOrderRefs": $purchase_order_refs, "reference": $reference, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "supplierRef": $supplier_ref, "taxAmount": $tax_amount, "totalAmount": $total_amount, "withholdingTax": $withholding_tax} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upload bill attachments
#
# POST /companies/{companyId}/connections/{connectionId}/push/bills/{billId}/attachments
# operationId: upload-bill-attachments
export def "companies-connections-push-bills-attachments upload-bill-attachments" [
  company_id: string
  connection_id: string
  bill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, bill_id: $bill_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/bills/{bill_id}/attachments"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Create credit note
#
# POST /companies/{companyId}/connections/{connectionId}/push/creditNotes
# operationId: create-credit-note
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-credit-notes create-credit-note" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --additional-tax-amount: float
  --additional-tax-percentage: float
  --allocated-on-date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --credit-note-number: string # Friendly reference for the credit note. (nullable)
  --currency: any # Currency of the credit note.
  --currency-rate: any
  --customer-ref: any # Reference to the customer the credit note has been issued to.
  discount_percentage: float # Percentage rate (from 0 to 100) of discounts applied to the credit note.
  --id: string # Identifier for the credit note, unique to the company in the accounting platform.
  --issue-date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # nullable
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the credit note. Where possible, Codat links to a data field in the accounting platform that is publicly available. This means that the contents of the note field are included when a credit note is emailed from the accounting platform to the customer. (nullable)
  --payment-allocations: list # An array of payment allocations. (nullable)
  remaining_credit: float # Unused balance of totalAmount originally raised.
  status: any # Current state of the credit note.
  sub_total: float # Value of the credit note, including discounts and excluding tax.
  --supplemental-data: any
  total_amount: float # Total amount of credit that has been applied to the customer's accounts receivable
  total_discount: float # Any discounts applied to the credit note amount.
  total_tax_amount: float # Any tax applied to the credit note amount.
  --withholding-tax: list # nullable
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/creditNotes") $qp)
  let body = {"additionalTaxAmount": $additional_tax_amount, "additionalTaxPercentage": $additional_tax_percentage, "allocatedOnDate": $allocated_on_date, "creditNoteNumber": $credit_note_number, "currency": $currency, "currencyRate": $currency_rate, "customerRef": $customer_ref, "discountPercentage": $discount_percentage, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "remainingCredit": $remaining_credit, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount, "withholdingTax": $withholding_tax} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update creditNote
#
# PUT /companies/{companyId}/connections/{connectionId}/push/creditNotes/{creditNoteId}
# operationId: update-credit-note
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-credit-notes update-credit-note" [
  company_id: any
  connection_id: any
  credit_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --additional-tax-amount: float
  --additional-tax-percentage: float
  --allocated-on-date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --credit-note-number: string # Friendly reference for the credit note. (nullable)
  --currency: any # Currency of the credit note.
  --currency-rate: any
  --customer-ref: any # Reference to the customer the credit note has been issued to.
  discount_percentage: float # Percentage rate (from 0 to 100) of discounts applied to the credit note.
  --id: string # Identifier for the credit note, unique to the company in the accounting platform.
  --issue-date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # nullable
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the credit note. Where possible, Codat links to a data field in the accounting platform that is publicly available. This means that the contents of the note field are included when a credit note is emailed from the accounting platform to the customer. (nullable)
  --payment-allocations: list # An array of payment allocations. (nullable)
  remaining_credit: float # Unused balance of totalAmount originally raised.
  status: any # Current state of the credit note.
  sub_total: float # Value of the credit note, including discounts and excluding tax.
  --supplemental-data: any
  total_amount: float # Total amount of credit that has been applied to the customer's accounts receivable
  total_discount: float # Any discounts applied to the credit note amount.
  total_tax_amount: float # Any tax applied to the credit note amount.
  --withholding-tax: list # nullable
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, credit_note_id: $credit_note_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/creditNotes/{credit_note_id}") $qp)
  let body = {"additionalTaxAmount": $additional_tax_amount, "additionalTaxPercentage": $additional_tax_percentage, "allocatedOnDate": $allocated_on_date, "creditNoteNumber": $credit_note_number, "currency": $currency, "currencyRate": $currency_rate, "customerRef": $customer_ref, "discountPercentage": $discount_percentage, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "remainingCredit": $remaining_credit, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount, "withholdingTax": $withholding_tax} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create customer
#
# POST /companies/{companyId}/connections/{connectionId}/push/customers
# operationId: create-customer
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-customers create-customer" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --addresses: list # An array of Addresses. (nullable)
  --contact-name: string # Name of the main contact for the identified customer. (nullable)
  --contacts: list # An array of Contacts. (nullable)
  --customer-name: string # Name of the customer as recorded in the accounting system, typically the company name. (nullable)
  --default-currency: any # Default currency the transactional data of the customer is recorded in.
  --email-address: string # Email address the customer can be contacted by. (nullable)
  --id: string # Identifier for the customer, unique to the company in the accounting platform.
  --metadata: record # shape: {isDeleted?: bool}
  --phone: string # Phone number the customer can be contacted by. (nullable)
  --registration-number: string # Company number. In the UK, this is typically the Companies House company registration number. (nullable)
  status: any # Current state of the customer.
  --supplemental-data: any
  --tax-number: string # Company tax number. (nullable)
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/customers") $qp)
  let body = {"addresses": $addresses, "contactName": $contact_name, "contacts": $contacts, "customerName": $customer_name, "defaultCurrency": $default_currency, "emailAddress": $email_address, "id": $id, "metadata": $metadata, "phone": $phone, "registrationNumber": $registration_number, "status": $status, "supplementalData": $supplemental_data, "taxNumber": $tax_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update customer
#
# PUT /companies/{companyId}/connections/{connectionId}/push/customers/{customerId}
# operationId: update-customer
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-customers update-customer" [
  company_id: any
  connection_id: any
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --addresses: list # An array of Addresses. (nullable)
  --contact-name: string # Name of the main contact for the identified customer. (nullable)
  --contacts: list # An array of Contacts. (nullable)
  --customer-name: string # Name of the customer as recorded in the accounting system, typically the company name. (nullable)
  --default-currency: any # Default currency the transactional data of the customer is recorded in.
  --email-address: string # Email address the customer can be contacted by. (nullable)
  --id: string # Identifier for the customer, unique to the company in the accounting platform.
  --metadata: record # shape: {isDeleted?: bool}
  --phone: string # Phone number the customer can be contacted by. (nullable)
  --registration-number: string # Company number. In the UK, this is typically the Companies House company registration number. (nullable)
  status: any # Current state of the customer.
  --supplemental-data: any
  --tax-number: string # Company tax number. (nullable)
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, customer_id: $customer_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/customers/{customer_id}") $qp)
  let body = {"addresses": $addresses, "contactName": $contact_name, "contacts": $contacts, "customerName": $customer_name, "defaultCurrency": $default_currency, "emailAddress": $email_address, "id": $id, "metadata": $metadata, "phone": $phone, "registrationNumber": $registration_number, "status": $status, "supplementalData": $supplemental_data, "taxNumber": $tax_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create direct cost
#
# POST /companies/{companyId}/connections/{connectionId}/push/directCosts
# operationId: create-direct-cost
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-direct-costs create-direct-cost" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --contact-ref: any # A customer or supplier associated with the direct cost.
  currency: any # Currency of the direct cost.
  --currency-rate: any
  --id: string # Identifier of the direct cost, unique for the company.
  issue_date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  line_items: list # An array of line items.
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # A note attached to the direct cost. (nullable)
  payment_allocations: list # An array of payment allocations.
  --reference: string # User-friendly reference for the direct cost. (nullable)
  sub_total: float # The total amount of the direct costs, excluding any taxes.
  --supplemental-data: any
  tax_amount: float # The total amount of tax on the direct costs.
  total_amount: float # The amount of the direct costs, inclusive of tax.
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/directCosts") $qp)
  let body = {"contactRef": $contact_ref, "currency": $currency, "currencyRate": $currency_rate, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "reference": $reference, "subTotal": $sub_total, "supplementalData": $supplemental_data, "taxAmount": $tax_amount, "totalAmount": $total_amount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upload direct cost attachment
#
# POST /companies/{companyId}/connections/{connectionId}/push/directCosts/{directCostId}/attachment
# operationId: upload-direct-cost-attachment
export def "companies-connections-push-direct-costs-attachment upload-direct-cost-attachment" [
  company_id: string
  connection_id: string
  direct_cost_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, direct_cost_id: $direct_cost_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/directCosts/{direct_cost_id}/attachment"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Create direct income
#
# POST /companies/{companyId}/connections/{connectionId}/push/directIncomes
# operationId: create-direct-income
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-direct-incomes create-direct-income" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --contact-ref: any # A customer or supplier associated with the direct income.
  currency: any # The currency of the direct income.
  --currency-rate: any
  --id: string # Identifier of the direct income, unique for the company.
  issue_date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  line_items: list # An array of line items.
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # nullable
  payment_allocations: list
  --reference: string # User-friendly reference for the direct income. (nullable)
  sub_total: float # The total amount of the direct incomes, excluding any taxes.
  --supplemental-data: any
  tax_amount: float # The total amount of tax on the direct incomes.
  total_amount: float # The amount of the direct incomes, inclusive of tax.
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/directIncomes") $qp)
  let body = {"contactRef": $contact_ref, "currency": $currency, "currencyRate": $currency_rate, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "reference": $reference, "subTotal": $sub_total, "supplementalData": $supplemental_data, "taxAmount": $tax_amount, "totalAmount": $total_amount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create direct income attachment
#
# POST /companies/{companyId}/connections/{connectionId}/push/directIncomes/{directIncomeId}/attachment
# operationId: upload-direct-income-attachment
export def "companies-connections-push-direct-incomes-attachment upload-direct-income-attachment" [
  company_id: string
  connection_id: string
  direct_income_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, direct_income_id: $direct_income_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/directIncomes/{direct_income_id}/attachment"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Create invoice
#
# POST /companies/{companyId}/connections/{connectionId}/push/invoices
# operationId: create-invoice
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-invoices create-invoice" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --additional-tax-amount: float
  --additional-tax-percentage: float
  amount_due: float # Amount outstanding on the invoice.
  --currency: any # Currency of the invoice.
  --currency-rate: any
  --customer-ref: any # Reference to the customer the invoice has been issued to.
  --discount-percentage: float # Percentage rate (from 0 to 100) of discounts applied to the invoice. For example: A 5% discount will return a value of `5`, not `0.05`. (nullable)
  --due-date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the invoice, unique to the company in the accounting platform.
  --invoice-number: string # Friendly reference for the invoice. If available, this appears in the file name of invoice attachments. (nullable)
  issue_date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # An array of line items. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the invoice. Where possible, Codat links to a data field in the accounting platform that is publicly available. This means that the contents of the note field are included when an invoice is emailed from the accounting platform to the customer. (nullable)
  --paid-on-date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --payment-allocations: list # An array of payment allocations. (nullable)
  --sales-order-refs: list # List of references to related Sales orders. (nullable)
  status: any
  --sub-total: float # Total amount of the invoice excluding any taxes. (nullable)
  --supplemental-data: any
  total_amount: float # Amount of the invoice, inclusive of tax.
  --total-discount: float # Numerical value of discounts applied to the invoice. (nullable)
  total_tax_amount: float # Amount of tax on the invoice.
  --withholding-tax: list # nullable
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/invoices") $qp)
  let body = {"additionalTaxAmount": $additional_tax_amount, "additionalTaxPercentage": $additional_tax_percentage, "amountDue": $amount_due, "currency": $currency, "currencyRate": $currency_rate, "customerRef": $customer_ref, "discountPercentage": $discount_percentage, "dueDate": $due_date, "id": $id, "invoiceNumber": $invoice_number, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paidOnDate": $paid_on_date, "paymentAllocations": $payment_allocations, "salesOrderRefs": $sales_order_refs, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount, "withholdingTax": $withholding_tax} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete invoice
#
# DELETE /companies/{companyId}/connections/{connectionId}/push/invoices/{invoiceId}
# operationId: delete-invoice
export def "companies-connections-push-invoices delete-invoice" [
  company_id: string
  connection_id: string
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, invoice_id: $invoice_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/invoices/{invoice_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update invoice
#
# PUT /companies/{companyId}/connections/{connectionId}/push/invoices/{invoiceId}
# operationId: update-invoice
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-invoices update-invoice" [
  company_id: any
  connection_id: any
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --additional-tax-amount: float
  --additional-tax-percentage: float
  amount_due: float # Amount outstanding on the invoice.
  --currency: any # Currency of the invoice.
  --currency-rate: any
  --customer-ref: any # Reference to the customer the invoice has been issued to.
  --discount-percentage: float # Percentage rate (from 0 to 100) of discounts applied to the invoice. For example: A 5% discount will return a value of `5`, not `0.05`. (nullable)
  --due-date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the invoice, unique to the company in the accounting platform.
  --invoice-number: string # Friendly reference for the invoice. If available, this appears in the file name of invoice attachments. (nullable)
  issue_date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # An array of line items. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the invoice. Where possible, Codat links to a data field in the accounting platform that is publicly available. This means that the contents of the note field are included when an invoice is emailed from the accounting platform to the customer. (nullable)
  --paid-on-date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --payment-allocations: list # An array of payment allocations. (nullable)
  --sales-order-refs: list # List of references to related Sales orders. (nullable)
  status: any
  --sub-total: float # Total amount of the invoice excluding any taxes. (nullable)
  --supplemental-data: any
  total_amount: float # Amount of the invoice, inclusive of tax.
  --total-discount: float # Numerical value of discounts applied to the invoice. (nullable)
  total_tax_amount: float # Amount of tax on the invoice.
  --withholding-tax: list # nullable
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, invoice_id: $invoice_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/invoices/{invoice_id}") $qp)
  let body = {"additionalTaxAmount": $additional_tax_amount, "additionalTaxPercentage": $additional_tax_percentage, "amountDue": $amount_due, "currency": $currency, "currencyRate": $currency_rate, "customerRef": $customer_ref, "discountPercentage": $discount_percentage, "dueDate": $due_date, "id": $id, "invoiceNumber": $invoice_number, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paidOnDate": $paid_on_date, "paymentAllocations": $payment_allocations, "salesOrderRefs": $sales_order_refs, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount, "withholdingTax": $withholding_tax} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Push invoice attachment
#
# POST /companies/{companyId}/connections/{connectionId}/push/invoices/{invoiceId}/attachment
# operationId: upload-invoice-attachment
export def "companies-connections-push-invoices-attachment upload-invoice-attachment" [
  company_id: any
  connection_id: any
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, invoice_id: $invoice_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/invoices/{invoice_id}/attachment"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Create item
#
# POST /companies/{companyId}/connections/{connectionId}/push/items
# operationId: create-item
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-items create-item" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --bill-item: any
  --code: string # Friendly reference for the item. (nullable)
  --id: string # Identifier for the item that is unique to a company in the accounting platform.
  --invoice-item: any
  --is-bill-item: oneof<nothing, bool> # Whether you can use this item for bills.
  --is-invoice-item: oneof<nothing, bool> # Whether you can use this item for invoices.
  item_status: any
  --metadata: record # shape: {isDeleted?: bool}
  --name: string # Name of the item in the accounting platform. (nullable)
  type: any
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/items") $qp)
  let body = {"billItem": $bill_item, "code": $code, "id": $id, "invoiceItem": $invoice_item, "isBillItem": $is_bill_item, "isInvoiceItem": $is_invoice_item, "itemStatus": $item_status, "metadata": $metadata, "name": $name, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create journal entry
#
# POST /companies/{companyId}/connections/{connectionId}/push/journalEntries
# operationId: create-journal-entry
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-journal-entries create-journal-entry" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --created-on: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --description: string # Optional description of the journal entry. (nullable)
  --id: string # Unique identifier of the journal entry for the company in the accounting platform.
  --journal-lines: list # An array of journal lines. (nullable)
  --journal-ref: any
  --metadata: record # shape: {isDeleted?: bool}
  --posted-on: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --record-ref: any
  --supplemental-data: any
  --updated-on: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/journalEntries") $qp)
  let body = {"createdOn": $created_on, "description": $description, "id": $id, "journalLines": $journal_lines, "journalRef": $journal_ref, "metadata": $metadata, "postedOn": $posted_on, "recordRef": $record_ref, "supplementalData": $supplemental_data, "updatedOn": $updated_on} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete journal entry
#
# DELETE /companies/{companyId}/connections/{connectionId}/push/journalEntries/{journalEntryId}
# operationId: delete-journal-entry
export def "companies-connections-push-journal-entries delete-journal-entry" [
  company_id: string
  connection_id: string
  journal_entry_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, journal_entry_id: $journal_entry_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/journalEntries/{journal_entry_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create journal
#
# POST /companies/{companyId}/connections/{connectionId}/push/journals
# operationId: push-journal
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-journals push-journal" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --created-on: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --has-children: oneof<nothing, bool> # If the journal has child journals, this value is true. If it doesn’t, it is false.
  --id: string # Journal ID.
  --journal-code: string # Native journal number or code. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --name: string # Journal name. The maximum length for a journal name is 256 characters. All characters above that number will be truncated. (nullable)
  --parent-id: string # Parent journal ID. If the journal is a parent journal, this value is not present. (nullable)
  --status: any
  --type: string # The type of the journal. (nullable)
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/journals") $qp)
  let body = {"createdOn": $created_on, "hasChildren": $has_children, "id": $id, "journalCode": $journal_code, "metadata": $metadata, "name": $name, "parentId": $parent_id, "status": $status, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create payment
#
# POST /companies/{companyId}/connections/{connectionId}/push/payments
# operationId: create-payment
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-payments create-payment" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --account-ref: any # Account the payment is recorded against in the accounting platform.
  --currency: any # ISO currency code recorded for the payment in the accounting platform.
  --currency-rate: any
  --customer-ref: any # Customer the payment is recorded against in the accounting platform.
  date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the payment, unique to the company in the accounting platform.
  --lines: list # An array of payment lines. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information associated with the payment. (nullable)
  --payment-method-ref: any # The Payment Method to which the payment is linked in the accounting platform.
  --reference: string # Friendly reference for the payment. (nullable)
  --supplemental-data: any
  --total-amount: float # Amount of the payment in the payment currency. This value should never change and represents the amount of money paid into the customer's account.
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/payments") $qp)
  let body = {"accountRef": $account_ref, "currency": $currency, "currencyRate": $currency_rate, "customerRef": $customer_ref, "date": $date, "id": $id, "lines": $lines, "metadata": $metadata, "note": $note, "paymentMethodRef": $payment_method_ref, "reference": $reference, "supplementalData": $supplemental_data, "totalAmount": $total_amount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create purchase order
#
# POST /companies/{companyId}/connections/{connectionId}/push/purchaseOrders
# operationId: create-purchase-order
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-purchase-orders create-purchase-order" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --currency: any # Currency of the purchase order.
  --currency-rate: any
  --delivery-date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --expected-delivery-date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the purchase order, unique for the company in the accounting platform.
  --issue-date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # Array of line items. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information associated with the purchase order. (nullable)
  --payment-due-date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --purchase-order-number: string # Friendly reference for the purchase order, commonly generated by the accounting platform. (nullable)
  --ship-to: any # Delivery details for any goods that have been ordered.
  --status: any
  --sub-total: float # Total amount of the purchase order, including discounts but excluding tax.
  --supplier-ref: any # Supplier that the purchase order is recorded against in the accounting system.
  --total-amount: float # Total amount of the purchase order, including discounts and tax.
  --total-discount: float # Total value of any discounts applied to the purchase order.
  --total-tax-amount: float # 	 Total amount of tax included in the purchase order.
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/purchaseOrders") $qp)
  let body = {"currency": $currency, "currencyRate": $currency_rate, "deliveryDate": $delivery_date, "expectedDeliveryDate": $expected_delivery_date, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentDueDate": $payment_due_date, "purchaseOrderNumber": $purchase_order_number, "shipTo": $ship_to, "status": $status, "subTotal": $sub_total, "supplierRef": $supplier_ref, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update purchase order
#
# PUT /companies/{companyId}/connections/{connectionId}/push/purchaseOrders/{purchaseOrderId}
# operationId: update-purchase-order
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-purchase-orders update-purchase-order" [
  company_id: any
  connection_id: any
  purchase_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --currency: any # Currency of the purchase order.
  --currency-rate: any
  --delivery-date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --expected-delivery-date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the purchase order, unique for the company in the accounting platform.
  --issue-date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # Array of line items. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information associated with the purchase order. (nullable)
  --payment-due-date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --purchase-order-number: string # Friendly reference for the purchase order, commonly generated by the accounting platform. (nullable)
  --ship-to: any # Delivery details for any goods that have been ordered.
  --status: any
  --sub-total: float # Total amount of the purchase order, including discounts but excluding tax.
  --supplier-ref: any # Supplier that the purchase order is recorded against in the accounting system.
  --total-amount: float # Total amount of the purchase order, including discounts and tax.
  --total-discount: float # Total value of any discounts applied to the purchase order.
  --total-tax-amount: float # 	 Total amount of tax included in the purchase order.
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, purchase_order_id: $purchase_order_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/purchaseOrders/{purchase_order_id}") $qp)
  let body = {"currency": $currency, "currencyRate": $currency_rate, "deliveryDate": $delivery_date, "expectedDeliveryDate": $expected_delivery_date, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentDueDate": $payment_due_date, "purchaseOrderNumber": $purchase_order_number, "shipTo": $ship_to, "status": $status, "subTotal": $sub_total, "supplierRef": $supplier_ref, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create suppliers
#
# POST /companies/{companyId}/connections/{connectionId}/push/suppliers
# operationId: create-supplier
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-suppliers create-supplier" [
  company_id: any
  connection_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --addresses: list # An array of Addresses. (nullable)
  --contact-name: string # Name of the main contact for the supplier. (nullable)
  --default-currency: string # Default currency the supplier's transactional data is recorded in. (nullable)
  --email-address: string # Email address that the supplier may be contacted on. (nullable)
  --id: string # Identifier for the supplier, unique to the company in the accounting platform.
  --metadata: record # shape: {isDeleted?: bool}
  --phone: string # Phone number that the supplier may be contacted on. (nullable)
  --registration-number: string # Company number of the supplier. In the UK, this is typically the company registration number issued by Companies House. (nullable)
  status: any
  --supplemental-data: any
  --supplier-name: string # Name of the supplier as recorded in the accounting system, typically the company name. (nullable)
  --tax-number: string # Supplier's company tax number. (nullable)
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/suppliers") $qp)
  let body = {"addresses": $addresses, "contactName": $contact_name, "defaultCurrency": $default_currency, "emailAddress": $email_address, "id": $id, "metadata": $metadata, "phone": $phone, "registrationNumber": $registration_number, "status": $status, "supplementalData": $supplemental_data, "supplierName": $supplier_name, "taxNumber": $tax_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update supplier
#
# PUT /companies/{companyId}/connections/{connectionId}/push/suppliers/{supplierId}
# operationId: put-supplier
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-suppliers put-supplier" [
  company_id: any
  connection_id: any
  supplier_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --addresses: list # An array of Addresses. (nullable)
  --contact-name: string # Name of the main contact for the supplier. (nullable)
  --default-currency: string # Default currency the supplier's transactional data is recorded in. (nullable)
  --email-address: string # Email address that the supplier may be contacted on. (nullable)
  --id: string # Identifier for the supplier, unique to the company in the accounting platform.
  --metadata: record # shape: {isDeleted?: bool}
  --phone: string # Phone number that the supplier may be contacted on. (nullable)
  --registration-number: string # Company number of the supplier. In the UK, this is typically the company registration number issued by Companies House. (nullable)
  status: any
  --supplemental-data: any
  --supplier-name: string # Name of the supplier as recorded in the accounting system, typically the company name. (nullable)
  --tax-number: string # Supplier's company tax number. (nullable)
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id, supplier_id: $supplier_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/suppliers/{supplier_id}") $qp)
  let body = {"addresses": $addresses, "contactName": $contact_name, "defaultCurrency": $default_currency, "emailAddress": $email_address, "id": $id, "metadata": $metadata, "phone": $phone, "registrationNumber": $registration_number, "status": $status, "supplementalData": $supplemental_data, "supplierName": $supplier_name, "taxNumber": $tax_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create transfer
#
# POST /companies/{companyId}/connections/{connectionId}/push/transfers
# operationId: create-transfer
# --contactRef shape: {dataType?: string, id: string}
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-transfers create-transfer" [
  company_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-ref: record # The customer or supplier for the transfer, if available. — shape: {dataType?: string, id: string}
  --date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --deposited-record-refs: list # nullable
  --description: string # Description of the transfer. (nullable)
  --body-from: any # The details of the accounts the transfer is moving from.
  --id: string # Unique identifier for the transfer.
  --metadata: record # shape: {isDeleted?: bool}
  --supplemental-data: any
  --body-to: any # The details of the accounts the transfer is moving to.
  --tracking-category-refs: list # Reference to the tracking categories this transfer is being tracked against. (nullable)
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, connection_id: $connection_id} | format pattern "/companies/{company_id}/connections/{connection_id}/push/transfers"))
  let body = {"contactRef": $contact_ref, "date": $date, "depositedRecordRefs": $deposited_record_refs, "description": $description, "from": $body_from, "id": $id, "metadata": $metadata, "supplementalData": $supplemental_data, "to": $body_to, "trackingCategoryRefs": $tracking_category_refs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List accounts
#
# GET /companies/{companyId}/data/accounts
# operationId: list-accounts
export def "companies-data-accounts list-accounts" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/accounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get account
#
# GET /companies/{companyId}/data/accounts/{accountId}
# DEPRECATED
# operationId: get-account
@deprecated
export def "companies-data-accounts get-account" [
  company_id: string
  account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, account_id: $account_id} | format pattern "/companies/{company_id}/data/accounts/{account_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bank account
#
# GET /companies/{companyId}/data/bankAccounts/{accountId}
# DEPRECATED
# operationId: get-all-bank-account
@deprecated
export def "companies-data-bank-accounts get-all-bank-account" [
  company_id: any
  account_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
]: nothing -> record<accountName: string, accountNumber: string, availableBalance: float, balance: float, currency: string, fromDate: string, iban: string, id: string, institution: string, modifiedDate: any, nominalCode: string, overdraftLimit: float, sortCode: string, sourceModifiedDate: any, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, account_id: $account_id} | format pattern "/companies/{company_id}/data/bankAccounts/{account_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all bank transactions
#
# GET /companies/{companyId}/data/bankAccounts/{accountId}/transactions
# operationId: list-bank-transactions
export def "companies-data-bank-accounts-transactions list-bank-transactions" [
  company_id: any
  account_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<any>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id, account_id: $account_id} | format pattern "/companies/{company_id}/data/bankAccounts/{account_id}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List bill credit notes
#
# GET /companies/{companyId}/data/billCreditNotes
# operationId: list-bill-credit-notes
export def "companies-data-bill-credit-notes list-bill-credit-notes" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/billCreditNotes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bill credit note
#
# GET /companies/{companyId}/data/billCreditNotes/{billCreditNoteId}
# DEPRECATED
# operationId: get-bill-credit-note
@deprecated
export def "companies-data-bill-credit-notes get-bill-credit-note" [
  company_id: string
  bill_credit_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, bill_credit_note_id: $bill_credit_note_id} | format pattern "/companies/{company_id}/data/billCreditNotes/{bill_credit_note_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List bill payments
#
# GET /companies/{companyId}/data/billPayments
# operationId: list-bill-payments
export def "companies-data-bill-payments list-bill-payments" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/billPayments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bill payment
#
# GET /companies/{companyId}/data/billPayments/{billPaymentId}
# DEPRECATED
# operationId: get-bill-payments
@deprecated
export def "companies-data-bill-payments get-bill-payments" [
  company_id: string
  bill_payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, bill_payment_id: $bill_payment_id} | format pattern "/companies/{company_id}/data/billPayments/{bill_payment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List bills
#
# GET /companies/{companyId}/data/bills
# operationId: list-bills
export def "companies-data-bills list-bills" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/bills") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bill
#
# GET /companies/{companyId}/data/bills/{billId}
# operationId: get-bill
export def "companies-data-bills get-bill" [
  company_id: string
  bill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, bill_id: $bill_id} | format pattern "/companies/{company_id}/data/bills/{bill_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List credit notes
#
# GET /companies/{companyId}/data/creditNotes
# operationId: list-credit-notes
export def "companies-data-credit-notes list-credit-notes" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/creditNotes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get credit note
#
# GET /companies/{companyId}/data/creditNotes/{creditNoteId}
# DEPRECATED
# operationId: get-credit-note
@deprecated
export def "companies-data-credit-notes get-credit-note" [
  company_id: string
  credit_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, credit_note_id: $credit_note_id} | format pattern "/companies/{company_id}/data/creditNotes/{credit_note_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List customers
#
# GET /companies/{companyId}/data/customers
# operationId: get-customers
export def "companies-data-customers get-customers" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/customers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get customer
#
# GET /companies/{companyId}/data/customers/{customerId}
# DEPRECATED
# operationId: get-customer
@deprecated
export def "companies-data-customers get-customer" [
  company_id: string
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, customer_id: $customer_id} | format pattern "/companies/{company_id}/data/customers/{customer_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get balance sheet
#
# GET /companies/{companyId}/data/financials/balanceSheet
# operationId: get-balance-sheet
export def "companies-data-financials-balance-sheet get-balance-sheet" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --period-length: int # format: int32
  --periods-to-compare: int # format: int32
  --start-month: string
]: nothing -> record<currency: any, earliestAvailableMonth: string, mostRecentAvailableMonth: string, reports: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "periodLength" $period_length "scalar") (serialize-qp "periodsToCompare" $periods_to_compare "scalar") (serialize-qp "startMonth" $start_month "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/financials/balanceSheet") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get cash flow statement
#
# GET /companies/{companyId}/data/financials/cashFlowStatement
# operationId: get-cash-flow-statement
export def "companies-data-financials-cash-flow-statement get-cash-flow-statement" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --period-length: int # format: int32
  --periods-to-compare: int # format: int32
  --start-month: string
]: nothing -> record<currency: any, earliestAvailableMonth: string, mostRecentAvailableMonth: string, reportBasis: any, reportInput: any, reports: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "periodLength" $period_length "scalar") (serialize-qp "periodsToCompare" $periods_to_compare "scalar") (serialize-qp "startMonth" $start_month "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/financials/cashFlowStatement") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get profit and loss
#
# GET /companies/{companyId}/data/financials/profitAndLoss
# operationId: get-profit-and-loss
export def "companies-data-financials-profit-and-loss get-profit-and-loss" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --period-length: int # format: int32
  --periods-to-compare: int # format: int32
  --start-month: string
]: nothing -> record<currency: string, earliestAvailableMonth: string, mostRecentAvailableMonth: string, reportBasis: any, reports: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "periodLength" $period_length "scalar") (serialize-qp "periodsToCompare" $periods_to_compare "scalar") (serialize-qp "startMonth" $start_month "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/financials/profitAndLoss") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get company info
#
# GET /companies/{companyId}/data/info
# operationId: get-company-info
export def "companies-data-info get-company-info" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accountingPlatformRef: string, addresses: table<city: string, country: string, line1: string, line2: string, postalCode: string, region: string, type: any>, baseCurrency: string, companyLegalName: string, companyName: string, createdDate: string, financialYearStartDate: string, ledgerLockDate: string, phoneNumbers: table<number: string, type: any>, registrationNumber: string, sourceUrls: record, taxNumber: string, webLinks: table<type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/info"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Refresh company info
#
# POST /companies/{companyId}/data/info
# operationId: post-sync-info
export def "companies-data-info post-sync-info" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<companyId: string, completed: string, connectionId: string, dataType: string, datasetLogsUrl: string, errorMessage: string, id: string, isCompleted: bool, isErrored: bool, progress: int, requested: string, status: string, validationInformationUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/info"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List invoices
#
# GET /companies/{companyId}/data/invoices
# operationId: list-invoices
export def "companies-data-invoices list-invoices" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/invoices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get invoice
#
# GET /companies/{companyId}/data/invoices/{invoiceId}
# DEPRECATED
# operationId: get-invoice
@deprecated
export def "companies-data-invoices get-invoice" [
  company_id: any
  invoice_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, invoice_id: $invoice_id} | format pattern "/companies/{company_id}/data/invoices/{invoice_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get invoice as PDF
#
# GET /companies/{companyId}/data/invoices/{invoiceId}/pdf
# operationId: Download-invoice-pdf
export def "companies-data-invoices-pdf get" [
  company_id: any
  invoice_id: string
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
  let full_url = (build-url $base ({company_id: $company_id, invoice_id: $invoice_id} | format pattern "/companies/{company_id}/data/invoices/{invoice_id}/pdf"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List items
#
# GET /companies/{companyId}/data/items
# operationId: list-items
export def "companies-data-items list-items" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/items") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get item
#
# GET /companies/{companyId}/data/items/{itemId}
# DEPRECATED
# operationId: get-item
@deprecated
export def "companies-data-items get-item" [
  company_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, item_id: $item_id} | format pattern "/companies/{company_id}/data/items/{item_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List journal entries
#
# GET /companies/{companyId}/data/journalEntries
# operationId: list-journal-entries
export def "companies-data-journal-entries list-journal-entries" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/journalEntries") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get journal entry
#
# GET /companies/{companyId}/data/journalEntries/{journalEntryId}
# DEPRECATED
# operationId: get-journal-entry
@deprecated
export def "companies-data-journal-entries get-journal-entry" [
  company_id: string
  journal_entry_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, journal_entry_id: $journal_entry_id} | format pattern "/companies/{company_id}/data/journalEntries/{journal_entry_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List journals
#
# GET /companies/{companyId}/data/journals
# operationId: list-journals
export def "companies-data-journals list-journals" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/journals") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get journal
#
# GET /companies/{companyId}/data/journals/{journalId}
# DEPRECATED
# operationId: get-journal
@deprecated
export def "companies-data-journals get-journal" [
  company_id: string
  journal_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, journal_id: $journal_id} | format pattern "/companies/{company_id}/data/journals/{journal_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all payment methods
#
# GET /companies/{companyId}/data/paymentMethods
# DEPRECATED
# operationId: list-payment-methods
@deprecated
export def "companies-data-payment-methods list-payment-methods" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/paymentMethods") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get payment method
#
# GET /companies/{companyId}/data/paymentMethods/{paymentMethodId}
# DEPRECATED
# operationId: get-payment-method
@deprecated
export def "companies-data-payment-methods get-payment-method" [
  company_id: string
  payment_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, payment_method_id: $payment_method_id} | format pattern "/companies/{company_id}/data/paymentMethods/{payment_method_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List payments
#
# GET /companies/{companyId}/data/payments
# operationId: list-payments
export def "companies-data-payments list-payments" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<any>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/payments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get payment
#
# GET /companies/{companyId}/data/payments/{paymentId}
# DEPRECATED
# operationId: get-payment
@deprecated
export def "companies-data-payments get-payment" [
  company_id: string
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, payment_id: $payment_id} | format pattern "/companies/{company_id}/data/payments/{payment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List purchase orders
#
# GET /companies/{companyId}/data/purchaseOrders
# operationId: list-purchase-orders
export def "companies-data-purchase-orders list-purchase-orders" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/purchaseOrders") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get purchase order
#
# GET /companies/{companyId}/data/purchaseOrders/{purchaseOrderId}
# DEPRECATED
# operationId: get-purchase-order
@deprecated
export def "companies-data-purchase-orders get-purchase-order" [
  company_id: string
  purchase_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, purchase_order_id: $purchase_order_id} | format pattern "/companies/{company_id}/data/purchaseOrders/{purchase_order_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List sales orders
#
# GET /companies/{companyId}/data/salesOrders
# operationId: list-sales-orders
export def "companies-data-sales-orders list-sales-orders" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/salesOrders") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get sales order
#
# GET /companies/{companyId}/data/salesOrders/{salesOrderId}
# DEPRECATED
# operationId: get-sales-order
@deprecated
export def "companies-data-sales-orders get-sales-order" [
  company_id: string
  sales_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, sales_order_id: $sales_order_id} | format pattern "/companies/{company_id}/data/salesOrders/{sales_order_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List suppliers
#
# GET /companies/{companyId}/data/suppliers
# operationId: list-suppliers
export def "companies-data-suppliers list-suppliers" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/suppliers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get supplier
#
# GET /companies/{companyId}/data/suppliers/{supplierId}
# DEPRECATED
# operationId: get-supplier
@deprecated
export def "companies-data-suppliers get-supplier" [
  company_id: string
  supplier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, supplier_id: $supplier_id} | format pattern "/companies/{company_id}/data/suppliers/{supplier_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all tax rates
#
# GET /companies/{companyId}/data/taxRates
# operationId: list-tax-rates
export def "companies-data-tax-rates list-tax-rates" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/taxRates") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tax rate
#
# GET /companies/{companyId}/data/taxRates/{taxRateId}
# DEPRECATED
# operationId: get-tax-rate
@deprecated
export def "companies-data-tax-rates get-tax-rate" [
  company_id: string
  tax_rate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, tax_rate_id: $tax_rate_id} | format pattern "/companies/{company_id}/data/taxRates/{tax_rate_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List tracking categories
#
# GET /companies/{companyId}/data/trackingCategories
# operationId: list-tracking-categories
export def "companies-data-tracking-categories list-tracking-categories" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/data/trackingCategories") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tracking categories
#
# GET /companies/{companyId}/data/trackingCategories/{trackingCategoryId}
# DEPRECATED
# operationId: get-tracking-category
@deprecated
export def "companies-data-tracking-categories get-tracking-category" [
  company_id: string
  tracking_category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id, tracking_category_id: $tracking_category_id} | format pattern "/companies/{company_id}/data/trackingCategories/{tracking_category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aged creditors report
#
# GET /companies/{companyId}/reports/agedCreditor
# operationId: get-aged-creditors-report
export def "companies-reports-aged-creditor get-aged-creditors-report" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # Date the report is generated up to. (format: date)
  --number-of-periods: int # Number of periods to include in the report. (format: int32)
  --period-length-days: int # The length of period in days. (format: int32)
]: nothing -> record<data: list<any>, generated: string, reportDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportDate" $report_date "scalar") (serialize-qp "numberOfPeriods" $number_of_periods "scalar") (serialize-qp "periodLengthDays" $period_length_days "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/reports/agedCreditor") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aged creditors report available
#
# GET /companies/{companyId}/reports/agedCreditor/available
# operationId: is-aged-creditors-report-available
export def "companies-reports-aged-creditor-available is-aged-creditors-report-available" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/reports/agedCreditor/available"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aged debtors report
#
# GET /companies/{companyId}/reports/agedDebtor
# operationId: get-aged-debtors-report
export def "companies-reports-aged-debtor get-aged-debtors-report" [
  company_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-date: string # Date the report is generated up to. (format: date)
  --number-of-periods: int # Number of periods to include in the report. (format: int32)
  --period-length-days: int # The length of period in days. (format: int32)
]: nothing -> record<data: list<any>, generated: string, reportDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportDate" $report_date "scalar") (serialize-qp "numberOfPeriods" $number_of_periods "scalar") (serialize-qp "periodLengthDays" $period_length_days "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/reports/agedDebtor") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aged debtors report available
#
# GET /companies/{companyId}/reports/agedDebtor/available
# operationId: is-aged-debtor-report-available
export def "companies-reports-aged-debtor-available is-aged-debtor-report-available" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/companies/{company_id}/reports/agedDebtor/available"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
