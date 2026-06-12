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
def accountType-completer [] { ["Credit" "Debit" "Unknown"] }

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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/accountTransactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get account transaction
#
# GET /companies/{companyId}/connections/{connectionId}/data/accountTransactions/{accountTransactionId}
# operationId: get-account-transaction
export def "companies-connections-data-account-transactions get-account-transaction" [
  companyId: string
  connectionId: string
  accountTransactionId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/accountTransactions/($accountTransactionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List bank accounts
#
# GET /companies/{companyId}/connections/{connectionId}/data/bankAccounts
# operationId: list-bank-accounts
export def "companies-connections-data-bank-accounts list-bank-accounts" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/bankAccounts" $qp)
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
  companyId: string
  accountId: string
  connectionId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/bankAccounts/($accountId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List bank transactions for bank account
#
# GET /companies/{companyId}/connections/{connectionId}/data/bankAccounts/{accountId}/bankTransactions
# operationId: list-bank-account-transactions
export def "companies-connections-data-bank-accounts-bank-transactions list-bank-account-transactions" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: table<accountId: string, transactions: list>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/bankAccounts/($accountId)/bankTransactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List bill attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/bills/{billId}/attachments
# operationId: get-bill-attachments
export def "companies-connections-data-bills-attachments get-bill-attachments" [
  billId: string
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
]: nothing -> record<attachments: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/bills/($billId)/attachments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bill attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/bills/{billId}/attachments/{attachmentId}
# operationId: get-bill-attachment
export def "companies-connections-data-bills-attachments get-bill-attachment" [
  attachmentId: string
  companyId: any
  connectionId: any
  billId: any
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
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/bills/($billId)/attachments/($attachmentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download bill attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/bills/{billId}/attachments/{attachmentId}/download
# operationId: download-bill-attachment
export def "companies-connections-data-bills-attachments-download download-bill-attachment" [
  attachmentId: string
  companyId: any
  connectionId: any
  billId: any
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
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/bills/($billId)/attachments/($attachmentId)/download")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List customer attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/customers/{customerId}/attachments
# operationId: get-customer-attachments
export def "companies-connections-data-customers-attachments get-customer-attachments" [
  companyId: string
  connectionId: string
  customerId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/customers/($customerId)/attachments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get customer attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/customers/{customerId}/attachments/{attachmentId}
# operationId: get-customer-attachment
export def "companies-connections-data-customers-attachments get-customer-attachment" [
  companyId: string
  connectionId: string
  customerId: string
  attachmentId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/customers/($customerId)/attachments/($attachmentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download customer attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/customers/{customerId}/attachments/{attachmentId}/download
# operationId: download-customer-attachment
export def "companies-connections-data-customers-attachments-download download-customer-attachment" [
  companyId: string
  connectionId: string
  customerId: string
  attachmentId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/customers/($customerId)/attachments/($attachmentId)/download")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List direct costs
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts
# operationId: get-direct-costs
export def "companies-connections-data-direct-costs get-direct-costs" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/directCosts" $qp)
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
  companyId: string
  connectionId: string
  directCostId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/directCosts/($directCostId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List direct cost attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}/attachments
# operationId: list-direct-cost-attachments
export def "companies-connections-data-direct-costs-attachments list-direct-cost-attachments" [
  companyId: string
  connectionId: string
  directCostId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/directCosts/($directCostId)/attachments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get direct cost attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}/attachments/{attachmentId}
# operationId: get-direct-cost-attachment
export def "companies-connections-data-direct-costs-attachments get-direct-cost-attachment" [
  attachmentId: string
  companyId: any
  connectionId: any
  directCostId: any
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
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/directCosts/($directCostId)/attachments/($attachmentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download direct cost attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}/attachments/{attachmentId}/download
# operationId: download-direct-cost-attachment
export def "companies-connections-data-direct-costs-attachments-download download-direct-cost-attachment" [
  attachmentId: string
  companyId: any
  connectionId: any
  directCostId: any
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
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/directCosts/($directCostId)/attachments/($attachmentId)/download")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get direct incomes
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes
# operationId: get-direct-incomes
export def "companies-connections-data-direct-incomes get-direct-incomes" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/directIncomes" $qp)
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
  companyId: string
  connectionId: string
  directIncomeId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/directIncomes/($directIncomeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List direct income attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}/attachments
# operationId: list-direct-income-attachments
export def "companies-connections-data-direct-incomes-attachments list-direct-income-attachments" [
  companyId: string
  connectionId: string
  directIncomeId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/directIncomes/($directIncomeId)/attachments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get direct income attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}/attachments/{attachmentId}
# operationId: get-direct-income-attachment
export def "companies-connections-data-direct-incomes-attachments get-direct-income-attachment" [
  companyId: any
  connectionId: any
  directIncomeId: any
  attachmentId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeoutInMinutes: int # format: int32
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/directIncomes/($directIncomeId)/attachments/($attachmentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download direct income attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}/attachments/{attachmentId}/download
# operationId: download-direct-income-attachment
export def "companies-connections-data-direct-incomes-attachments-download download-direct-income-attachment" [
  attachmentId: string
  companyId: any
  connectionId: any
  directIncomeId: any
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
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/directIncomes/($directIncomeId)/attachments/($attachmentId)/download")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get invoice attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/invoices/{invoiceId}/attachments
# operationId: get-invoice-attachments
export def "companies-connections-data-invoices-attachments get-invoice-attachments" [
  invoiceId: string
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
]: nothing -> record<attachments: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/invoices/($invoiceId)/attachments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get invoice attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/invoices/{invoiceId}/attachments/{attachmentId}
# operationId: get-invoice-attachment
export def "companies-connections-data-invoices-attachments get-invoice-attachment" [
  invoiceId: string
  attachmentId: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/invoices/($invoiceId)/attachments/($attachmentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download invoice attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/invoices/{invoiceId}/attachments/{attachmentId}/download
# operationId: download-invoice-attachment
export def "companies-connections-data-invoices-attachments-download download-invoice-attachment" [
  invoiceId: string
  attachmentId: string
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/invoices/($invoiceId)/attachments/($attachmentId)/download")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List supplier attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/suppliers/{supplierId}/attachments
# operationId: list-supplier-attachments
export def "companies-connections-data-suppliers-attachments list-supplier-attachments" [
  supplierId: string
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
]: nothing -> record<attachments: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/suppliers/($supplierId)/attachments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get supplier attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/suppliers/{supplierId}/attachments/{attachmentId}
# operationId: get-supplier-attachment
export def "companies-connections-data-suppliers-attachments get-supplier-attachment" [
  supplierId: string
  companyId: string
  connectionId: string
  attachmentId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/suppliers/($supplierId)/attachments/($attachmentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download supplier attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/suppliers/{supplierId}/attachments/{attachmentId}/download
# operationId: download-supplier-attachment
export def "companies-connections-data-suppliers-attachments-download download-supplier-attachment" [
  supplierId: string
  companyId: string
  connectionId: string
  attachmentId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/suppliers/($supplierId)/attachments/($attachmentId)/download")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List transfers
#
# GET /companies/{companyId}/connections/{connectionId}/data/transfers
# operationId: list-transfers
export def "companies-connections-data-transfers list-transfers" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/transfers" $qp)
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
  companyId: string
  connectionId: string
  transferId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/data/transfers/($transferId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create/update bank account model
#
# GET /companies/{companyId}/connections/{connectionId}/options/bankAccounts
# operationId: get-create-update-bankAccounts-model
export def "companies-connections-options-bank-accounts get-create-update-bankAccounts-model" [
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
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/options/bankAccounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List push options for bank account bank transactions
#
# GET /companies/{companyId}/connections/{connectionId}/options/bankAccounts/{accountId}/bankTransactions
# operationId: get-create-bank-account-model
export def "companies-connections-options-bank-accounts-bank-transactions get-create-bank-account-model" [
  companyId: string
  connectionId: string
  accountId: any
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
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/options/bankAccounts/($accountId)/bankTransactions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create/update bill credit note model
#
# GET /companies/{companyId}/connections/{connectionId}/options/billCreditNotes
# operationId: get-create-update-billCreditNotes-model
export def "companies-connections-options-bill-credit-notes get-create-update-billCreditNotes-model" [
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
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/options/billCreditNotes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create bill payment model
#
# GET /companies/{companyId}/connections/{connectionId}/options/billPayments
# operationId: get-create-billPayments-model
export def "companies-connections-options-bill-payments get-create-billPayments-model" [
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
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/options/billPayments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create/update bill model
#
# GET /companies/{companyId}/connections/{connectionId}/options/bills
# operationId: get-create-update-bills-model
export def "companies-connections-options-bills get-create-update-bills-model" [
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
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/options/bills")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create account model
#
# GET /companies/{companyId}/connections/{connectionId}/options/chartOfAccounts
# operationId: get-create-chartOfAccounts-model
export def "companies-connections-options-chart-of-accounts get-create-chartOfAccounts-model" [
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
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/options/chartOfAccounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create/update credit note model
#
# GET /companies/{companyId}/connections/{connectionId}/options/creditNotes
# operationId: get-create-update-creditNotes-model
export def "companies-connections-options-credit-notes get-create-update-creditNotes-model" [
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
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/options/creditNotes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create/update customer model
#
# GET /companies/{companyId}/connections/{connectionId}/options/customers
# operationId: get-create-update-customers-model
export def "companies-connections-options-customers get-create-update-customers-model" [
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
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/options/customers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create direct cost model
#
# GET /companies/{companyId}/connections/{connectionId}/options/directCosts
# operationId: get-create-directCosts-model
export def "companies-connections-options-direct-costs get-create-directCosts-model" [
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
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/options/directCosts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create direct income model
#
# GET /companies/{companyId}/connections/{connectionId}/options/directIncomes
# operationId: get-create-directIncomes-model
export def "companies-connections-options-direct-incomes get-create-directIncomes-model" [
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
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/options/directIncomes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create/update invoice model
#
# GET /companies/{companyId}/connections/{connectionId}/options/invoices
# operationId: get-create-update-invoices-model
export def "companies-connections-options-invoices get-create-update-invoices-model" [
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
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/options/invoices")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create item model
#
# GET /companies/{companyId}/connections/{connectionId}/options/items
# operationId: get-create-items-model
export def "companies-connections-options-items get-create-items-model" [
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
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/options/items")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create journal entry model
#
# GET /companies/{companyId}/connections/{connectionId}/options/journalEntries
# operationId: get-create-journalEntries-model
export def "companies-connections-options-journal-entries get-create-journalEntries-model" [
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
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/options/journalEntries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create journal model
#
# GET /companies/{companyId}/connections/{connectionId}/options/journals
# operationId: get-create-journals-model
export def "companies-connections-options-journals get-create-journals-model" [
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
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/options/journals")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create payment model
#
# GET /companies/{companyId}/connections/{connectionId}/options/payments
# operationId: get-create-payments-model
export def "companies-connections-options-payments get-create-payments-model" [
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
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/options/payments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create/update purchase order model
#
# GET /companies/{companyId}/connections/{connectionId}/options/purchaseOrders
# operationId: get-create-update-purchaseOrders-model
export def "companies-connections-options-purchase-orders get-create-update-purchaseOrders-model" [
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
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/options/purchaseOrders")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create/update supplier model
#
# GET /companies/{companyId}/connections/{connectionId}/options/suppliers
# operationId: get-create-update-suppliers-model
export def "companies-connections-options-suppliers get-create-update-suppliers-model" [
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
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/options/suppliers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get create transfer model
#
# GET /companies/{companyId}/connections/{connectionId}/options/transfers
# operationId: get-create-transfers-model
export def "companies-connections-options-transfers get-create-transfers-model" [
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
]: nothing -> record<description: string, displayName: string, options: list<any>, properties: record, required: bool, type: any, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/options/transfers")
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
  --timeoutInMinutes: int # format: int32
  --currency: any
  --currentBalance: float # Current balance in the account. (nullable)
  --description: string # Description for the account. (nullable)
  --fullyQualifiedCategory: string # Full category of the account. For example: Liability.Current or Income.Revenue. See example data. (nullable)
  --fullyQualifiedName: string # Full name of the account, for example: - `Liability.Current.VAT` - `Income.Revenue.Sales` (nullable)
  --id: string # Identifier for the account, unique for the company.
  --isBankAccount: oneof<nothing, bool> # Confirms whether the account is a bank account or not.
  --metadata: record # shape: {isDeleted?: bool}
  --name: string # Name of the account. (nullable)
  --nominalCode: string # Reference given to each nominal account for a business. It ensures money is allocated to the correct account. This code isn't a unique identifier in the Codat system. (nullable)
  status: any
  type: any
  --validDatatypeLinks: list # 'The validDatatypeLinks can be used to determine whether an account can be correctly mapped to another object; for example, accounts with a `type` of `income` might only support being used on an Invoice and Direct Income. For more information, see Valid Data Type Links.' (nullable) — item shape: {links?: list, property?: string}
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/accounts" $qp)
  let body = {currency: $currency, currentBalance: $currentBalance, description: $description, fullyQualifiedCategory: $fullyQualifiedCategory, fullyQualifiedName: $fullyQualifiedName, id: $id, isBankAccount: $isBankAccount, metadata: $metadata, name: $name, nominalCode: $nominalCode, status: $status, type: $type, validDatatypeLinks: $validDatatypeLinks} | compact
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
  --allowSyncOnPushComplete: oneof<nothing, bool> # default: true
  --timeoutInMinutes: int # format: int32
  --accountName: string # Name of the bank account in the accounting platform. (nullable)
  --accountNumber: string # Account number for the bank account.  Xero integrations Only a UK account number shows for bank accounts with GBP currency and a combined total of sort code and account number that equals 14 digits, For non-GBP accounts, the full bank account number is populated.  FreeAgent integrations For Credit accounts, only the last four digits are required. For other types, the field is optional. (nullable)
  --accountType: string@accountType-completer # The type of transactions and balances on the account.   For Credit accounts, positive balances are liabilities, and positive transactions **reduce** liabilities.   For Debit accounts, positive balances are assets, and positive transactions **increase** assets.
  --availableBalance: float # Total available balance of the bank account as reported by the underlying data source. This may take into account overdrafts or pending transactions for example. (nullable)
  --balance: float # Balance of the bank account. (nullable)
  --currency: any # Base currency of the bank account.
  --iBan: string # International bank account number of the account. Often used when making or receiving international payments. (nullable)
  --id: string # Identifier for the account, unique for the company in the accounting platform.
  --institution: string # The institution of the bank account. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --nominalCode: string # Code used to identify each nominal account for a business. (nullable)
  --overdraftLimit: float # Pre-arranged overdraft limit of the account.  The value is always positive. For example, an overdraftLimit of `1000` means that the balance of the account can go down to `-1000`. (nullable)
  --sortCode: string # Sort code for the bank account.  Xero integrations The sort code is only displayed when the currency = GBP and the sort code and account number sum to 14 digits. For non-GBP accounts, this field is not populated. (nullable)
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allowSyncOnPushComplete" $allowSyncOnPushComplete "scalar") (serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/bankAccounts" $qp)
  let body = {accountName: $accountName, accountNumber: $accountNumber, accountType: $accountType, availableBalance: $availableBalance, balance: $balance, currency: $currency, iBan: $iBan, id: $id, institution: $institution, metadata: $metadata, nominalCode: $nominalCode, overdraftLimit: $overdraftLimit, sortCode: $sortCode} | compact
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
  companyId: string
  connectionId: string
  accountId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowSyncOnPushComplete: oneof<nothing, bool> # default: true
  --timeoutInMinutes: int # format: int32
  --body-accountId: string # nullable
  --transactions: list # nullable
]: any -> record<data: record<accountId: string, transactions: list<any>>, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allowSyncOnPushComplete" $allowSyncOnPushComplete "scalar") (serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/bankAccounts/($accountId)/bankTransactions" $qp)
  let body = {accountId: $body_accountId, transactions: $transactions} | compact
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
  companyId: any
  connectionId: any
  bankAccountId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeoutInMinutes: int # format: int32
  --forceUpdate: oneof<nothing, bool> # default: false
  --accountName: string # Name of the bank account in the accounting platform. (nullable)
  --accountNumber: string # Account number for the bank account.  Xero integrations Only a UK account number shows for bank accounts with GBP currency and a combined total of sort code and account number that equals 14 digits, For non-GBP accounts, the full bank account number is populated.  FreeAgent integrations For Credit accounts, only the last four digits are required. For other types, the field is optional. (nullable)
  --accountType: string@accountType-completer # The type of transactions and balances on the account.   For Credit accounts, positive balances are liabilities, and positive transactions **reduce** liabilities.   For Debit accounts, positive balances are assets, and positive transactions **increase** assets.
  --availableBalance: float # Total available balance of the bank account as reported by the underlying data source. This may take into account overdrafts or pending transactions for example. (nullable)
  --balance: float # Balance of the bank account. (nullable)
  --currency: any # Base currency of the bank account.
  --iBan: string # International bank account number of the account. Often used when making or receiving international payments. (nullable)
  --id: string # Identifier for the account, unique for the company in the accounting platform.
  --institution: string # The institution of the bank account. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --nominalCode: string # Code used to identify each nominal account for a business. (nullable)
  --overdraftLimit: float # Pre-arranged overdraft limit of the account.  The value is always positive. For example, an overdraftLimit of `1000` means that the balance of the account can go down to `-1000`. (nullable)
  --sortCode: string # Sort code for the bank account.  Xero integrations The sort code is only displayed when the currency = GBP and the sort code and account number sum to 14 digits. For non-GBP accounts, this field is not populated. (nullable)
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar") (serialize-qp "forceUpdate" $forceUpdate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/bankAccounts/($bankAccountId)" $qp)
  let body = {accountName: $accountName, accountNumber: $accountNumber, accountType: $accountType, availableBalance: $availableBalance, balance: $balance, currency: $currency, iBan: $iBan, id: $id, institution: $institution, metadata: $metadata, nominalCode: $nominalCode, overdraftLimit: $overdraftLimit, sortCode: $sortCode} | compact
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
  --timeoutInMinutes: int # format: int32
  --allocatedOnDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --billCreditNoteNumber: string # Friendly reference for the bill credit note. (nullable)
  --currency: any # Currency of the bill credit note.
  --currencyRate: any
  discountPercentage: float # Percentage rate of any discount applied to the bill credit note.
  --id: string # Identifier for the bill credit note that is unique to a company in the accounting platform.
  --issueDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --lineItems: list # An array of line  (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the bill credit note. (nullable)
  --paymentAllocations: list # An array of payment allocations. (nullable)
  remainingCredit: float # Amount of the bill credit note that is still outstanding.
  status: any
  subTotal: float # Total amount of the bill credit note, including discounts but excluding tax.
  --supplementalData: any
  --supplierRef: any
  totalAmount: float # Total amount of credit that has been applied to the business' account with the supplier, including discounts and tax.
  totalDiscount: float # Total value of any discounts applied.
  totalTaxAmount: float # Amount of tax included in the bill credit note.
  --withholdingTax: list # nullable
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/billCreditNotes" $qp)
  let body = {allocatedOnDate: $allocatedOnDate, billCreditNoteNumber: $billCreditNoteNumber, currency: $currency, currencyRate: $currencyRate, discountPercentage: $discountPercentage, id: $id, issueDate: $issueDate, lineItems: $lineItems, metadata: $metadata, note: $note, paymentAllocations: $paymentAllocations, remainingCredit: $remainingCredit, status: $status, subTotal: $subTotal, supplementalData: $supplementalData, supplierRef: $supplierRef, totalAmount: $totalAmount, totalDiscount: $totalDiscount, totalTaxAmount: $totalTaxAmount, withholdingTax: $withholdingTax} | compact
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
  billCreditNoteId: string
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
  --timeoutInMinutes: int # format: int32
  --forceUpdate: oneof<nothing, bool> # default: false
  --allocatedOnDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --billCreditNoteNumber: string # Friendly reference for the bill credit note. (nullable)
  --currency: any # Currency of the bill credit note.
  --currencyRate: any
  discountPercentage: float # Percentage rate of any discount applied to the bill credit note.
  --id: string # Identifier for the bill credit note that is unique to a company in the accounting platform.
  --issueDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --lineItems: list # An array of line  (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the bill credit note. (nullable)
  --paymentAllocations: list # An array of payment allocations. (nullable)
  remainingCredit: float # Amount of the bill credit note that is still outstanding.
  status: any
  subTotal: float # Total amount of the bill credit note, including discounts but excluding tax.
  --supplementalData: any
  --supplierRef: any
  totalAmount: float # Total amount of credit that has been applied to the business' account with the supplier, including discounts and tax.
  totalDiscount: float # Total value of any discounts applied.
  totalTaxAmount: float # Amount of tax included in the bill credit note.
  --withholdingTax: list # nullable
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar") (serialize-qp "forceUpdate" $forceUpdate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/billCreditNotes/($billCreditNoteId)" $qp)
  let body = {allocatedOnDate: $allocatedOnDate, billCreditNoteNumber: $billCreditNoteNumber, currency: $currency, currencyRate: $currencyRate, discountPercentage: $discountPercentage, id: $id, issueDate: $issueDate, lineItems: $lineItems, metadata: $metadata, note: $note, paymentAllocations: $paymentAllocations, remainingCredit: $remainingCredit, status: $status, subTotal: $subTotal, supplementalData: $supplementalData, supplierRef: $supplierRef, totalAmount: $totalAmount, totalDiscount: $totalDiscount, totalTaxAmount: $totalTaxAmount, withholdingTax: $withholdingTax} | compact
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
  --timeoutInMinutes: int # format: int32
  --accountRef: any # Account the payment is linked to in the accounting platform.
  --currency: any
  --currencyRate: any
  date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the bill payment, unique for the company in the accounting platform.
  --lines: list # An array of bill payment lines. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Additional information associated with the payment. (nullable)
  --paymentMethodRef: any # The Payment Method to which the payment is linked in the accounting platform.
  --reference: string # Additional information associated with the payment. (nullable)
  --supplementalData: any
  --supplierRef: any
  --totalAmount: float # Amount of the payment in the payment currency. This value never changes and represents the amount of money that is paid into the supplier's account.
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/billPayments" $qp)
  let body = {accountRef: $accountRef, currency: $currency, currencyRate: $currencyRate, date: $date, id: $id, lines: $lines, metadata: $metadata, note: $note, paymentMethodRef: $paymentMethodRef, reference: $reference, supplementalData: $supplementalData, supplierRef: $supplierRef, totalAmount: $totalAmount} | compact
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
  companyId: string
  connectionId: string
  billPaymentId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/billPayments/($billPaymentId)")
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
  --timeoutInMinutes: int # format: int32
  --amountDue: float # Amount outstanding on the bill. (nullable)
  --currency: any
  --currencyRate: any
  --dueDate: any
  --id: string # Identifier for the bill, unique for the company in the accounting platform.
  issueDate: any
  --lineItems: list # Array of Bill line items. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any private, company notes about the bill, such as payment information. (nullable)
  --paymentAllocations: list # An array of payment allocations. (nullable) — item shape: {allocation: record, payment: any}
  --purchaseOrderRefs: list # nullable
  --reference: string # User-friendly reference for the bill. (nullable)
  status: any
  subTotal: float # Total amount of the bill, excluding any taxes.
  --supplementalData: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --supplierRef: any
  taxAmount: float # Amount of tax on the bill.
  totalAmount: float # Amount of the bill, including tax.
  --withholdingTax: list # nullable — item shape: {amount: float, name: string}
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/bills" $qp)
  let body = {amountDue: $amountDue, currency: $currency, currencyRate: $currencyRate, dueDate: $dueDate, id: $id, issueDate: $issueDate, lineItems: $lineItems, metadata: $metadata, note: $note, paymentAllocations: $paymentAllocations, purchaseOrderRefs: $purchaseOrderRefs, reference: $reference, status: $status, subTotal: $subTotal, supplementalData: $supplementalData, supplierRef: $supplierRef, taxAmount: $taxAmount, totalAmount: $totalAmount, withholdingTax: $withholdingTax} | compact
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
  billId: string
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
]: nothing -> record<changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/bills/($billId)")
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
  companyId: any
  connectionId: any
  billId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeoutInMinutes: int # format: int32
  --forceUpdate: oneof<nothing, bool> # default: false
  --amountDue: float # Amount outstanding on the bill. (nullable)
  --currency: any
  --currencyRate: any
  --dueDate: any
  --id: string # Identifier for the bill, unique for the company in the accounting platform.
  issueDate: any
  --lineItems: list # Array of Bill line items. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any private, company notes about the bill, such as payment information. (nullable)
  --paymentAllocations: list # An array of payment allocations. (nullable) — item shape: {allocation: record, payment: any}
  --purchaseOrderRefs: list # nullable
  --reference: string # User-friendly reference for the bill. (nullable)
  status: any
  subTotal: float # Total amount of the bill, excluding any taxes.
  --supplementalData: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --supplierRef: any
  taxAmount: float # Amount of tax on the bill.
  totalAmount: float # Amount of the bill, including tax.
  --withholdingTax: list # nullable — item shape: {amount: float, name: string}
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar") (serialize-qp "forceUpdate" $forceUpdate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/bills/($billId)" $qp)
  let body = {amountDue: $amountDue, currency: $currency, currencyRate: $currencyRate, dueDate: $dueDate, id: $id, issueDate: $issueDate, lineItems: $lineItems, metadata: $metadata, note: $note, paymentAllocations: $paymentAllocations, purchaseOrderRefs: $purchaseOrderRefs, reference: $reference, status: $status, subTotal: $subTotal, supplementalData: $supplementalData, supplierRef: $supplierRef, taxAmount: $taxAmount, totalAmount: $totalAmount, withholdingTax: $withholdingTax} | compact
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
  billId: string
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
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/bills/($billId)/attachments")
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
  --timeoutInMinutes: int # format: int32
  --additionalTaxAmount: float
  --additionalTaxPercentage: float
  --allocatedOnDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --creditNoteNumber: string # Friendly reference for the credit note. (nullable)
  --currency: any # Currency of the credit note.
  --currencyRate: any
  --customerRef: any # Reference to the customer the credit note has been issued to.
  discountPercentage: float # Percentage rate (from 0 to 100) of discounts applied to the credit note.
  --id: string # Identifier for the credit note, unique to the company in the accounting platform.
  --issueDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --lineItems: list # nullable
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the credit note. Where possible, Codat links to a data field in the accounting platform that is publicly available. This means that the contents of the note field are included when a credit note is emailed from the accounting platform to the customer. (nullable)
  --paymentAllocations: list # An array of payment allocations. (nullable)
  remainingCredit: float # Unused balance of totalAmount originally raised.
  status: any # Current state of the credit note.
  subTotal: float # Value of the credit note, including discounts and excluding tax.
  --supplementalData: any
  totalAmount: float # Total amount of credit that has been applied to the customer's accounts receivable
  totalDiscount: float # Any discounts applied to the credit note amount.
  totalTaxAmount: float # Any tax applied to the credit note amount.
  --withholdingTax: list # nullable
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/creditNotes" $qp)
  let body = {additionalTaxAmount: $additionalTaxAmount, additionalTaxPercentage: $additionalTaxPercentage, allocatedOnDate: $allocatedOnDate, creditNoteNumber: $creditNoteNumber, currency: $currency, currencyRate: $currencyRate, customerRef: $customerRef, discountPercentage: $discountPercentage, id: $id, issueDate: $issueDate, lineItems: $lineItems, metadata: $metadata, note: $note, paymentAllocations: $paymentAllocations, remainingCredit: $remainingCredit, status: $status, subTotal: $subTotal, supplementalData: $supplementalData, totalAmount: $totalAmount, totalDiscount: $totalDiscount, totalTaxAmount: $totalTaxAmount, withholdingTax: $withholdingTax} | compact
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
  creditNoteId: string
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
  --timeoutInMinutes: int # format: int32
  --forceUpdate: oneof<nothing, bool> # default: false
  --additionalTaxAmount: float
  --additionalTaxPercentage: float
  --allocatedOnDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --creditNoteNumber: string # Friendly reference for the credit note. (nullable)
  --currency: any # Currency of the credit note.
  --currencyRate: any
  --customerRef: any # Reference to the customer the credit note has been issued to.
  discountPercentage: float # Percentage rate (from 0 to 100) of discounts applied to the credit note.
  --id: string # Identifier for the credit note, unique to the company in the accounting platform.
  --issueDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --lineItems: list # nullable
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the credit note. Where possible, Codat links to a data field in the accounting platform that is publicly available. This means that the contents of the note field are included when a credit note is emailed from the accounting platform to the customer. (nullable)
  --paymentAllocations: list # An array of payment allocations. (nullable)
  remainingCredit: float # Unused balance of totalAmount originally raised.
  status: any # Current state of the credit note.
  subTotal: float # Value of the credit note, including discounts and excluding tax.
  --supplementalData: any
  totalAmount: float # Total amount of credit that has been applied to the customer's accounts receivable
  totalDiscount: float # Any discounts applied to the credit note amount.
  totalTaxAmount: float # Any tax applied to the credit note amount.
  --withholdingTax: list # nullable
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar") (serialize-qp "forceUpdate" $forceUpdate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/creditNotes/($creditNoteId)" $qp)
  let body = {additionalTaxAmount: $additionalTaxAmount, additionalTaxPercentage: $additionalTaxPercentage, allocatedOnDate: $allocatedOnDate, creditNoteNumber: $creditNoteNumber, currency: $currency, currencyRate: $currencyRate, customerRef: $customerRef, discountPercentage: $discountPercentage, id: $id, issueDate: $issueDate, lineItems: $lineItems, metadata: $metadata, note: $note, paymentAllocations: $paymentAllocations, remainingCredit: $remainingCredit, status: $status, subTotal: $subTotal, supplementalData: $supplementalData, totalAmount: $totalAmount, totalDiscount: $totalDiscount, totalTaxAmount: $totalTaxAmount, withholdingTax: $withholdingTax} | compact
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
  --timeoutInMinutes: int # format: int32
  --addresses: list # An array of Addresses. (nullable)
  --contactName: string # Name of the main contact for the identified customer. (nullable)
  --contacts: list # An array of Contacts. (nullable)
  --customerName: string # Name of the customer as recorded in the accounting system, typically the company name. (nullable)
  --defaultCurrency: any # Default currency the transactional data of the customer is recorded in.
  --emailAddress: string # Email address the customer can be contacted by. (nullable)
  --id: string # Identifier for the customer, unique to the company in the accounting platform.
  --metadata: record # shape: {isDeleted?: bool}
  --phone: string # Phone number the customer can be contacted by. (nullable)
  --registrationNumber: string # Company number. In the UK, this is typically the Companies House company registration number. (nullable)
  status: any # Current state of the customer.
  --supplementalData: any
  --taxNumber: string # Company tax number. (nullable)
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/customers" $qp)
  let body = {addresses: $addresses, contactName: $contactName, contacts: $contacts, customerName: $customerName, defaultCurrency: $defaultCurrency, emailAddress: $emailAddress, id: $id, metadata: $metadata, phone: $phone, registrationNumber: $registrationNumber, status: $status, supplementalData: $supplementalData, taxNumber: $taxNumber} | compact
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
  customerId: string
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
  --timeoutInMinutes: int # format: int32
  --forceUpdate: oneof<nothing, bool> # default: false
  --addresses: list # An array of Addresses. (nullable)
  --contactName: string # Name of the main contact for the identified customer. (nullable)
  --contacts: list # An array of Contacts. (nullable)
  --customerName: string # Name of the customer as recorded in the accounting system, typically the company name. (nullable)
  --defaultCurrency: any # Default currency the transactional data of the customer is recorded in.
  --emailAddress: string # Email address the customer can be contacted by. (nullable)
  --id: string # Identifier for the customer, unique to the company in the accounting platform.
  --metadata: record # shape: {isDeleted?: bool}
  --phone: string # Phone number the customer can be contacted by. (nullable)
  --registrationNumber: string # Company number. In the UK, this is typically the Companies House company registration number. (nullable)
  status: any # Current state of the customer.
  --supplementalData: any
  --taxNumber: string # Company tax number. (nullable)
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar") (serialize-qp "forceUpdate" $forceUpdate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/customers/($customerId)" $qp)
  let body = {addresses: $addresses, contactName: $contactName, contacts: $contacts, customerName: $customerName, defaultCurrency: $defaultCurrency, emailAddress: $emailAddress, id: $id, metadata: $metadata, phone: $phone, registrationNumber: $registrationNumber, status: $status, supplementalData: $supplementalData, taxNumber: $taxNumber} | compact
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
  --timeoutInMinutes: int # format: int32
  --contactRef: any # A customer or supplier associated with the direct cost.
  currency: any # Currency of the direct cost.
  --currencyRate: any
  --id: string # Identifier of the direct cost, unique for the company.
  issueDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  lineItems: list # An array of line items.
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # A note attached to the direct cost. (nullable)
  paymentAllocations: list # An array of payment allocations.
  --reference: string # User-friendly reference for the direct cost. (nullable)
  subTotal: float # The total amount of the direct costs, excluding any taxes.
  --supplementalData: any
  taxAmount: float # The total amount of tax on the direct costs.
  totalAmount: float # The amount of the direct costs, inclusive of tax.
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/directCosts" $qp)
  let body = {contactRef: $contactRef, currency: $currency, currencyRate: $currencyRate, id: $id, issueDate: $issueDate, lineItems: $lineItems, metadata: $metadata, note: $note, paymentAllocations: $paymentAllocations, reference: $reference, subTotal: $subTotal, supplementalData: $supplementalData, taxAmount: $taxAmount, totalAmount: $totalAmount} | compact
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
  companyId: string
  connectionId: string
  directCostId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/directCosts/($directCostId)/attachment")
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
  --timeoutInMinutes: int # format: int32
  --contactRef: any # A customer or supplier associated with the direct income.
  currency: any # The currency of the direct income.
  --currencyRate: any
  --id: string # Identifier of the direct income, unique for the company.
  issueDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  lineItems: list # An array of line items.
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # nullable
  paymentAllocations: list
  --reference: string # User-friendly reference for the direct income. (nullable)
  subTotal: float # The total amount of the direct incomes, excluding any taxes.
  --supplementalData: any
  taxAmount: float # The total amount of tax on the direct incomes.
  totalAmount: float # The amount of the direct incomes, inclusive of tax.
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/directIncomes" $qp)
  let body = {contactRef: $contactRef, currency: $currency, currencyRate: $currencyRate, id: $id, issueDate: $issueDate, lineItems: $lineItems, metadata: $metadata, note: $note, paymentAllocations: $paymentAllocations, reference: $reference, subTotal: $subTotal, supplementalData: $supplementalData, taxAmount: $taxAmount, totalAmount: $totalAmount} | compact
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
  companyId: string
  connectionId: string
  directIncomeId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/directIncomes/($directIncomeId)/attachment")
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
  --timeoutInMinutes: int # format: int32
  --additionalTaxAmount: float
  --additionalTaxPercentage: float
  amountDue: float # Amount outstanding on the invoice.
  --currency: any # Currency of the invoice.
  --currencyRate: any
  --customerRef: any # Reference to the customer the invoice has been issued to.
  --discountPercentage: float # Percentage rate (from 0 to 100) of discounts applied to the invoice. For example: A 5% discount will return a value of `5`, not `0.05`. (nullable)
  --dueDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the invoice, unique to the company in the accounting platform.
  --invoiceNumber: string # Friendly reference for the invoice. If available, this appears in the file name of invoice attachments. (nullable)
  issueDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --lineItems: list # An array of line items. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the invoice. Where possible, Codat links to a data field in the accounting platform that is publicly available. This means that the contents of the note field are included when an invoice is emailed from the accounting platform to the customer. (nullable)
  --paidOnDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --paymentAllocations: list # An array of payment allocations. (nullable)
  --salesOrderRefs: list # List of references to related Sales orders. (nullable)
  status: any
  --subTotal: float # Total amount of the invoice excluding any taxes. (nullable)
  --supplementalData: any
  totalAmount: float # Amount of the invoice, inclusive of tax.
  --totalDiscount: float # Numerical value of discounts applied to the invoice. (nullable)
  totalTaxAmount: float # Amount of tax on the invoice.
  --withholdingTax: list # nullable
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/invoices" $qp)
  let body = {additionalTaxAmount: $additionalTaxAmount, additionalTaxPercentage: $additionalTaxPercentage, amountDue: $amountDue, currency: $currency, currencyRate: $currencyRate, customerRef: $customerRef, discountPercentage: $discountPercentage, dueDate: $dueDate, id: $id, invoiceNumber: $invoiceNumber, issueDate: $issueDate, lineItems: $lineItems, metadata: $metadata, note: $note, paidOnDate: $paidOnDate, paymentAllocations: $paymentAllocations, salesOrderRefs: $salesOrderRefs, status: $status, subTotal: $subTotal, supplementalData: $supplementalData, totalAmount: $totalAmount, totalDiscount: $totalDiscount, totalTaxAmount: $totalTaxAmount, withholdingTax: $withholdingTax} | compact
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
  invoiceId: string
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
]: nothing -> record<changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/invoices/($invoiceId)")
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
  invoiceId: string
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
  --timeoutInMinutes: int # format: int32
  --forceUpdate: oneof<nothing, bool> # default: false
  --additionalTaxAmount: float
  --additionalTaxPercentage: float
  amountDue: float # Amount outstanding on the invoice.
  --currency: any # Currency of the invoice.
  --currencyRate: any
  --customerRef: any # Reference to the customer the invoice has been issued to.
  --discountPercentage: float # Percentage rate (from 0 to 100) of discounts applied to the invoice. For example: A 5% discount will return a value of `5`, not `0.05`. (nullable)
  --dueDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the invoice, unique to the company in the accounting platform.
  --invoiceNumber: string # Friendly reference for the invoice. If available, this appears in the file name of invoice attachments. (nullable)
  issueDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --lineItems: list # An array of line items. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the invoice. Where possible, Codat links to a data field in the accounting platform that is publicly available. This means that the contents of the note field are included when an invoice is emailed from the accounting platform to the customer. (nullable)
  --paidOnDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --paymentAllocations: list # An array of payment allocations. (nullable)
  --salesOrderRefs: list # List of references to related Sales orders. (nullable)
  status: any
  --subTotal: float # Total amount of the invoice excluding any taxes. (nullable)
  --supplementalData: any
  totalAmount: float # Amount of the invoice, inclusive of tax.
  --totalDiscount: float # Numerical value of discounts applied to the invoice. (nullable)
  totalTaxAmount: float # Amount of tax on the invoice.
  --withholdingTax: list # nullable
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar") (serialize-qp "forceUpdate" $forceUpdate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/invoices/($invoiceId)" $qp)
  let body = {additionalTaxAmount: $additionalTaxAmount, additionalTaxPercentage: $additionalTaxPercentage, amountDue: $amountDue, currency: $currency, currencyRate: $currencyRate, customerRef: $customerRef, discountPercentage: $discountPercentage, dueDate: $dueDate, id: $id, invoiceNumber: $invoiceNumber, issueDate: $issueDate, lineItems: $lineItems, metadata: $metadata, note: $note, paidOnDate: $paidOnDate, paymentAllocations: $paymentAllocations, salesOrderRefs: $salesOrderRefs, status: $status, subTotal: $subTotal, supplementalData: $supplementalData, totalAmount: $totalAmount, totalDiscount: $totalDiscount, totalTaxAmount: $totalTaxAmount, withholdingTax: $withholdingTax} | compact
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
  invoiceId: string
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
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/invoices/($invoiceId)/attachment")
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
  --timeoutInMinutes: int # format: int32
  --billItem: any
  --code: string # Friendly reference for the item. (nullable)
  --id: string # Identifier for the item that is unique to a company in the accounting platform.
  --invoiceItem: any
  --isBillItem: oneof<nothing, bool> # Whether you can use this item for bills.
  --isInvoiceItem: oneof<nothing, bool> # Whether you can use this item for invoices.
  itemStatus: any
  --metadata: record # shape: {isDeleted?: bool}
  --name: string # Name of the item in the accounting platform. (nullable)
  type: any
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/items" $qp)
  let body = {billItem: $billItem, code: $code, id: $id, invoiceItem: $invoiceItem, isBillItem: $isBillItem, isInvoiceItem: $isInvoiceItem, itemStatus: $itemStatus, metadata: $metadata, name: $name, type: $type} | compact
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
  --timeoutInMinutes: int # format: int32
  --createdOn: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --description: string # Optional description of the journal entry. (nullable)
  --id: string # Unique identifier of the journal entry for the company in the accounting platform.
  --journalLines: list # An array of journal lines. (nullable)
  --journalRef: any
  --metadata: record # shape: {isDeleted?: bool}
  --postedOn: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --recordRef: any
  --supplementalData: any
  --updatedOn: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/journalEntries" $qp)
  let body = {createdOn: $createdOn, description: $description, id: $id, journalLines: $journalLines, journalRef: $journalRef, metadata: $metadata, postedOn: $postedOn, recordRef: $recordRef, supplementalData: $supplementalData, updatedOn: $updatedOn} | compact
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
  journalEntryId: string
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
]: nothing -> record<changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/journalEntries/($journalEntryId)")
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
  --timeoutInMinutes: int # format: int32
  --createdOn: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --hasChildren: oneof<nothing, bool> # If the journal has child journals, this value is true. If it doesn’t, it is false.
  --id: string # Journal ID.
  --journalCode: string # Native journal number or code. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --name: string # Journal name. The maximum length for a journal name is 256 characters. All characters above that number will be truncated. (nullable)
  --parentId: string # Parent journal ID. If the journal is a parent journal, this value is not present. (nullable)
  --status: any
  --type: string # The type of the journal. (nullable)
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/journals" $qp)
  let body = {createdOn: $createdOn, hasChildren: $hasChildren, id: $id, journalCode: $journalCode, metadata: $metadata, name: $name, parentId: $parentId, status: $status, type: $type} | compact
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
  --timeoutInMinutes: int # format: int32
  --accountRef: any # Account the payment is recorded against in the accounting platform.
  --currency: any # ISO currency code recorded for the payment in the accounting platform.
  --currencyRate: any
  --customerRef: any # Customer the payment is recorded against in the accounting platform.
  date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the payment, unique to the company in the accounting platform.
  --lines: list # An array of payment lines. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information associated with the payment. (nullable)
  --paymentMethodRef: any # The Payment Method to which the payment is linked in the accounting platform.
  --reference: string # Friendly reference for the payment. (nullable)
  --supplementalData: any
  --totalAmount: float # Amount of the payment in the payment currency. This value should never change and represents the amount of money paid into the customer's account.
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/payments" $qp)
  let body = {accountRef: $accountRef, currency: $currency, currencyRate: $currencyRate, customerRef: $customerRef, date: $date, id: $id, lines: $lines, metadata: $metadata, note: $note, paymentMethodRef: $paymentMethodRef, reference: $reference, supplementalData: $supplementalData, totalAmount: $totalAmount} | compact
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
  --timeoutInMinutes: int # format: int32
  --currency: any # Currency of the purchase order.
  --currencyRate: any
  --deliveryDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --expectedDeliveryDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the purchase order, unique for the company in the accounting platform.
  --issueDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --lineItems: list # Array of line items. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information associated with the purchase order. (nullable)
  --paymentDueDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --purchaseOrderNumber: string # Friendly reference for the purchase order, commonly generated by the accounting platform. (nullable)
  --shipTo: any # Delivery details for any goods that have been ordered.
  --status: any
  --subTotal: float # Total amount of the purchase order, including discounts but excluding tax.
  --supplierRef: any # Supplier that the purchase order is recorded against in the accounting system.
  --totalAmount: float # Total amount of the purchase order, including discounts and tax.
  --totalDiscount: float # Total value of any discounts applied to the purchase order.
  --totalTaxAmount: float # 	 Total amount of tax included in the purchase order.
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/purchaseOrders" $qp)
  let body = {currency: $currency, currencyRate: $currencyRate, deliveryDate: $deliveryDate, expectedDeliveryDate: $expectedDeliveryDate, id: $id, issueDate: $issueDate, lineItems: $lineItems, metadata: $metadata, note: $note, paymentDueDate: $paymentDueDate, purchaseOrderNumber: $purchaseOrderNumber, shipTo: $shipTo, status: $status, subTotal: $subTotal, supplierRef: $supplierRef, totalAmount: $totalAmount, totalDiscount: $totalDiscount, totalTaxAmount: $totalTaxAmount} | compact
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
  purchaseOrderId: string
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
  --timeoutInMinutes: int # format: int32
  --forceUpdate: oneof<nothing, bool> # default: false
  --currency: any # Currency of the purchase order.
  --currencyRate: any
  --deliveryDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --expectedDeliveryDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the purchase order, unique for the company in the accounting platform.
  --issueDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --lineItems: list # Array of line items. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information associated with the purchase order. (nullable)
  --paymentDueDate: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --purchaseOrderNumber: string # Friendly reference for the purchase order, commonly generated by the accounting platform. (nullable)
  --shipTo: any # Delivery details for any goods that have been ordered.
  --status: any
  --subTotal: float # Total amount of the purchase order, including discounts but excluding tax.
  --supplierRef: any # Supplier that the purchase order is recorded against in the accounting system.
  --totalAmount: float # Total amount of the purchase order, including discounts and tax.
  --totalDiscount: float # Total value of any discounts applied to the purchase order.
  --totalTaxAmount: float # 	 Total amount of tax included in the purchase order.
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar") (serialize-qp "forceUpdate" $forceUpdate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/purchaseOrders/($purchaseOrderId)" $qp)
  let body = {currency: $currency, currencyRate: $currencyRate, deliveryDate: $deliveryDate, expectedDeliveryDate: $expectedDeliveryDate, id: $id, issueDate: $issueDate, lineItems: $lineItems, metadata: $metadata, note: $note, paymentDueDate: $paymentDueDate, purchaseOrderNumber: $purchaseOrderNumber, shipTo: $shipTo, status: $status, subTotal: $subTotal, supplierRef: $supplierRef, totalAmount: $totalAmount, totalDiscount: $totalDiscount, totalTaxAmount: $totalTaxAmount} | compact
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
  --timeoutInMinutes: int # format: int32
  --addresses: list # An array of Addresses. (nullable)
  --contactName: string # Name of the main contact for the supplier. (nullable)
  --defaultCurrency: string # Default currency the supplier's transactional data is recorded in. (nullable)
  --emailAddress: string # Email address that the supplier may be contacted on. (nullable)
  --id: string # Identifier for the supplier, unique to the company in the accounting platform.
  --metadata: record # shape: {isDeleted?: bool}
  --phone: string # Phone number that the supplier may be contacted on. (nullable)
  --registrationNumber: string # Company number of the supplier. In the UK, this is typically the company registration number issued by Companies House. (nullable)
  status: any
  --supplementalData: any
  --supplierName: string # Name of the supplier as recorded in the accounting system, typically the company name. (nullable)
  --taxNumber: string # Supplier's company tax number. (nullable)
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/suppliers" $qp)
  let body = {addresses: $addresses, contactName: $contactName, defaultCurrency: $defaultCurrency, emailAddress: $emailAddress, id: $id, metadata: $metadata, phone: $phone, registrationNumber: $registrationNumber, status: $status, supplementalData: $supplementalData, supplierName: $supplierName, taxNumber: $taxNumber} | compact
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
  companyId: any
  connectionId: any
  supplierId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeoutInMinutes: int # format: int32
  --forceUpdate: oneof<nothing, bool> # default: false
  --addresses: list # An array of Addresses. (nullable)
  --contactName: string # Name of the main contact for the supplier. (nullable)
  --defaultCurrency: string # Default currency the supplier's transactional data is recorded in. (nullable)
  --emailAddress: string # Email address that the supplier may be contacted on. (nullable)
  --id: string # Identifier for the supplier, unique to the company in the accounting platform.
  --metadata: record # shape: {isDeleted?: bool}
  --phone: string # Phone number that the supplier may be contacted on. (nullable)
  --registrationNumber: string # Company number of the supplier. In the UK, this is typically the company registration number issued by Companies House. (nullable)
  status: any
  --supplementalData: any
  --supplierName: string # Name of the supplier as recorded in the accounting system, typically the company name. (nullable)
  --taxNumber: string # Supplier's company tax number. (nullable)
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeoutInMinutes "scalar") (serialize-qp "forceUpdate" $forceUpdate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/suppliers/($supplierId)" $qp)
  let body = {addresses: $addresses, contactName: $contactName, defaultCurrency: $defaultCurrency, emailAddress: $emailAddress, id: $id, metadata: $metadata, phone: $phone, registrationNumber: $registrationNumber, status: $status, supplementalData: $supplementalData, supplierName: $supplierName, taxNumber: $taxNumber} | compact
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
  --contactRef: record # The customer or supplier for the transfer, if available. — shape: {dataType?: string, id: string}
  --date: string # In Codat's data model, dates and times are represented using the <a class="external" href="https://en.wikipedia.org/wiki/ISO_8601" target="_blank">ISO 8601 standard</a>. Date and time fields are formatted as strings; for example:  ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ```    When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information:  - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00`  > Time zones >  > Not all dates from Codat will contain information about time zones.   > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --depositedRecordRefs: list # nullable
  --description: string # Description of the transfer. (nullable)
  --body-from: any # The details of the accounts the transfer is moving from.
  --id: string # Unique identifier for the transfer.
  --metadata: record # shape: {isDeleted?: bool}
  --supplementalData: any
  --body-to: any # The details of the accounts the transfer is moving to.
  --trackingCategoryRefs: list # Reference to the tracking categories this transfer is being tracked against. (nullable)
]: any -> record<data: record, changes: list<any>, companyId: any, completedOnUtc: string, dataConnectionKey: any, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: any, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($companyId)/connections/($connectionId)/push/transfers")
  let body = {contactRef: $contactRef, date: $date, depositedRecordRefs: $depositedRecordRefs, description: $description, from: $body_from, id: $id, metadata: $metadata, supplementalData: $supplementalData, to: $body_to, trackingCategoryRefs: $trackingCategoryRefs} | compact
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
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/accounts" $qp)
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
  companyId: string
  accountId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/data/accounts/($accountId)")
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
  companyId: any
  accountId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
]: nothing -> record<accountName: string, accountNumber: string, availableBalance: float, balance: float, currency: string, fromDate: string, iban: string, id: string, institution: string, modifiedDate: any, nominalCode: string, overdraftLimit: float, sortCode: string, sourceModifiedDate: any, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/bankAccounts/($accountId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all bank transactions
#
# GET /companies/{companyId}/data/bankAccounts/{accountId}/transactions
# operationId: list-bank-transactions
export def "companies-data-bank-accounts-transactions list-bank-transactions" [
  companyId: any
  accountId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<any>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/bankAccounts/($accountId)/transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List bill credit notes
#
# GET /companies/{companyId}/data/billCreditNotes
# operationId: list-bill-credit-notes
export def "companies-data-bill-credit-notes list-bill-credit-notes" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/billCreditNotes" $qp)
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
  companyId: string
  billCreditNoteId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/data/billCreditNotes/($billCreditNoteId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List bill payments
#
# GET /companies/{companyId}/data/billPayments
# operationId: list-bill-payments
export def "companies-data-bill-payments list-bill-payments" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/billPayments" $qp)
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
  companyId: string
  billPaymentId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/data/billPayments/($billPaymentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List bills
#
# GET /companies/{companyId}/data/bills
# operationId: list-bills
export def "companies-data-bills list-bills" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/bills" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bill
#
# GET /companies/{companyId}/data/bills/{billId}
# operationId: get-bill
export def "companies-data-bills get-bill" [
  billId: string
  companyId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/data/bills/($billId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List credit notes
#
# GET /companies/{companyId}/data/creditNotes
# operationId: list-credit-notes
export def "companies-data-credit-notes list-credit-notes" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/creditNotes" $qp)
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
  companyId: string
  creditNoteId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/data/creditNotes/($creditNoteId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List customers
#
# GET /companies/{companyId}/data/customers
# operationId: get-customers
export def "companies-data-customers get-customers" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/customers" $qp)
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
  companyId: string
  customerId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/data/customers/($customerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get balance sheet
#
# GET /companies/{companyId}/data/financials/balanceSheet
# operationId: get-balance-sheet
export def "companies-data-financials-balance-sheet get-balance-sheet" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --periodLength: int # format: int32
  --periodsToCompare: int # format: int32
  --startMonth: string
]: nothing -> record<currency: any, earliestAvailableMonth: string, mostRecentAvailableMonth: string, reports: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "periodLength" $periodLength "scalar") (serialize-qp "periodsToCompare" $periodsToCompare "scalar") (serialize-qp "startMonth" $startMonth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/financials/balanceSheet" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get cash flow statement
#
# GET /companies/{companyId}/data/financials/cashFlowStatement
# operationId: get-cash-flow-statement
export def "companies-data-financials-cash-flow-statement get-cash-flow-statement" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --periodLength: int # format: int32
  --periodsToCompare: int # format: int32
  --startMonth: string
]: nothing -> record<currency: any, earliestAvailableMonth: string, mostRecentAvailableMonth: string, reportBasis: any, reportInput: any, reports: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "periodLength" $periodLength "scalar") (serialize-qp "periodsToCompare" $periodsToCompare "scalar") (serialize-qp "startMonth" $startMonth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/financials/cashFlowStatement" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get profit and loss
#
# GET /companies/{companyId}/data/financials/profitAndLoss
# operationId: get-profit-and-loss
export def "companies-data-financials-profit-and-loss get-profit-and-loss" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --periodLength: int # format: int32
  --periodsToCompare: int # format: int32
  --startMonth: string
]: nothing -> record<currency: string, earliestAvailableMonth: string, mostRecentAvailableMonth: string, reportBasis: any, reports: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "periodLength" $periodLength "scalar") (serialize-qp "periodsToCompare" $periodsToCompare "scalar") (serialize-qp "startMonth" $startMonth "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/financials/profitAndLoss" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get company info
#
# GET /companies/{companyId}/data/info
# operationId: get-company-info
export def "companies-data-info get-company-info" [
  companyId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/data/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Refresh company info
#
# POST /companies/{companyId}/data/info
# operationId: post-sync-info
export def "companies-data-info post-sync-info" [
  companyId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/data/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List invoices
#
# GET /companies/{companyId}/data/invoices
# operationId: list-invoices
export def "companies-data-invoices list-invoices" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/invoices" $qp)
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
  invoiceId: string
  companyId: any
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
  let full_url = (build-url $base $"/companies/($companyId)/data/invoices/($invoiceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get invoice as PDF
#
# GET /companies/{companyId}/data/invoices/{invoiceId}/pdf
# operationId: Download-invoice-pdf
export def "companies-data-invoices-pdf Download-invoice-pdf" [
  invoiceId: string
  companyId: any
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
  let full_url = (build-url $base $"/companies/($companyId)/data/invoices/($invoiceId)/pdf")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List items
#
# GET /companies/{companyId}/data/items
# operationId: list-items
export def "companies-data-items list-items" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/items" $qp)
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
  companyId: string
  itemId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/data/items/($itemId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List journal entries
#
# GET /companies/{companyId}/data/journalEntries
# operationId: list-journal-entries
export def "companies-data-journal-entries list-journal-entries" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/journalEntries" $qp)
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
  companyId: string
  journalEntryId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/data/journalEntries/($journalEntryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List journals
#
# GET /companies/{companyId}/data/journals
# operationId: list-journals
export def "companies-data-journals list-journals" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/journals" $qp)
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
  companyId: string
  journalId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/data/journals/($journalId)")
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
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/paymentMethods" $qp)
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
  companyId: string
  paymentMethodId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/data/paymentMethods/($paymentMethodId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List payments
#
# GET /companies/{companyId}/data/payments
# operationId: list-payments
export def "companies-data-payments list-payments" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<any>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/payments" $qp)
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
  companyId: string
  paymentId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/data/payments/($paymentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List purchase orders
#
# GET /companies/{companyId}/data/purchaseOrders
# operationId: list-purchase-orders
export def "companies-data-purchase-orders list-purchase-orders" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/purchaseOrders" $qp)
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
  companyId: string
  purchaseOrderId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/data/purchaseOrders/($purchaseOrderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List sales orders
#
# GET /companies/{companyId}/data/salesOrders
# operationId: list-sales-orders
export def "companies-data-sales-orders list-sales-orders" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/salesOrders" $qp)
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
  companyId: string
  salesOrderId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/data/salesOrders/($salesOrderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List suppliers
#
# GET /companies/{companyId}/data/suppliers
# operationId: list-suppliers
export def "companies-data-suppliers list-suppliers" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/suppliers" $qp)
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
  supplierId: string
  companyId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/data/suppliers/($supplierId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all tax rates
#
# GET /companies/{companyId}/data/taxRates
# operationId: list-tax-rates
export def "companies-data-tax-rates list-tax-rates" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/taxRates" $qp)
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
  companyId: string
  taxRateId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/data/taxRates/($taxRateId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List tracking categories
#
# GET /companies/{companyId}/data/trackingCategories
# operationId: list-tracking-categories
export def "companies-data-tracking-categories list-tracking-categories" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --pageSize: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --qp-query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --orderBy: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "orderBy" $orderBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/data/trackingCategories" $qp)
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
  companyId: string
  trackingCategoryId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/data/trackingCategories/($trackingCategoryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aged creditors report
#
# GET /companies/{companyId}/reports/agedCreditor
# operationId: get-aged-creditors-report
export def "companies-reports-aged-creditor get-aged-creditors-report" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportDate: string # Date the report is generated up to. (format: date)
  --numberOfPeriods: int # Number of periods to include in the report. (format: int32)
  --periodLengthDays: int # The length of period in days. (format: int32)
]: nothing -> record<data: list<any>, generated: string, reportDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportDate" $reportDate "scalar") (serialize-qp "numberOfPeriods" $numberOfPeriods "scalar") (serialize-qp "periodLengthDays" $periodLengthDays "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/reports/agedCreditor" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aged creditors report available
#
# GET /companies/{companyId}/reports/agedCreditor/available
# operationId: is-aged-creditors-report-available
export def "companies-reports-aged-creditor-available is-aged-creditors-report-available" [
  companyId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/reports/agedCreditor/available")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aged debtors report
#
# GET /companies/{companyId}/reports/agedDebtor
# operationId: get-aged-debtors-report
export def "companies-reports-aged-debtor get-aged-debtors-report" [
  companyId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportDate: string # Date the report is generated up to. (format: date)
  --numberOfPeriods: int # Number of periods to include in the report. (format: int32)
  --periodLengthDays: int # The length of period in days. (format: int32)
]: nothing -> record<data: list<any>, generated: string, reportDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportDate" $reportDate "scalar") (serialize-qp "numberOfPeriods" $numberOfPeriods "scalar") (serialize-qp "periodLengthDays" $periodLengthDays "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/companies/($companyId)/reports/agedDebtor" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aged debtors report available
#
# GET /companies/{companyId}/reports/agedDebtor/available
# operationId: is-aged-debtor-report-available
export def "companies-reports-aged-debtor-available is-aged-debtor-report-available" [
  companyId: string
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
  let full_url = (build-url $base $"/companies/($companyId)/reports/agedDebtor/available")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
