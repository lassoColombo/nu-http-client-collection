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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk (issue 11.B).
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://api.codat.io"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["Active" "Archived" "Pending" "Unknown"] }
def type-completer [] { ["Asset" "Equity" "Expense" "Income" "Liability" "Unknown"] }
def account-type-completer [] { ["Credit" "Debit" "Unknown"] }
def status-completer-1 [] { ["Draft" "Paid" "PartiallyPaid" "Submitted" "Unknown" "Void"] }
def status-completer-2 [] { ["Draft" "Open" "Paid" "PartiallyPaid" "Unknown" "Void"] }
def status-completer-3 [] { ["Active" "Archived" "Unknown"] }
def item-status-completer [] { ["Active" "Archived" "Unknown"] }
def status-completer-4 [] { ["Closed" "Draft" "Open" "Unknown" "Void"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "companies-connections-data-account-transactions list" } } | get name | first)
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
export def "companies-connections-data-account-transactions list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/accountTransactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get account transaction
#
# GET /companies/{companyId}/connections/{connectionId}/data/accountTransactions/{accountTransactionId}
# operationId: get-account-transaction
export def "companies-connections-data-account-transactions get" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), account_transaction_id: (encode-path-segment $account_transaction_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/accountTransactions/{account_transaction_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List bank accounts
#
# GET /companies/{companyId}/connections/{connectionId}/data/bankAccounts
# operationId: list-bank-accounts
export def "companies-connections-data-bank-accounts list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/bankAccounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get bank account
#
# GET /companies/{companyId}/connections/{connectionId}/data/bankAccounts/{accountId}
# DEPRECATED
# operationId: get-bank-account
@deprecated
export def "companies-connections-data-bank-accounts get" [
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), account_id: (encode-path-segment $account_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/bankAccounts/{account_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List bank transactions for bank account
#
# GET /companies/{companyId}/connections/{connectionId}/data/bankAccounts/{accountId}/bankTransactions
# operationId: list-bank-account-transactions
export def "companies-connections-data-bank-accounts-bank-transactions list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: table<accountId: string, transactions: list>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), account_id: (encode-path-segment $account_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/bankAccounts/{account_id}/bankTransactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List bill attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/bills/{billId}/attachments
# operationId: get-bill-attachments
export def "companies-connections-data-bills-attachments list" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachments: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), bill_id: (encode-path-segment $bill_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/bills/{bill_id}/attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get bill attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/bills/{billId}/attachments/{attachmentId}
# operationId: get-bill-attachment
export def "companies-connections-data-bills-attachments get" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), bill_id: (encode-path-segment $bill_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/bills/{bill_id}/attachments/{attachment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Download bill attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/bills/{billId}/attachments/{attachmentId}/download
# operationId: download-bill-attachment
export def "companies-connections-data-bills-attachments-download download" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), bill_id: (encode-path-segment $bill_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/bills/{bill_id}/attachments/{attachment_id}/download"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List customer attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/customers/{customerId}/attachments
# operationId: get-customer-attachments
export def "companies-connections-data-customers-attachments list" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachments: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), customer_id: (encode-path-segment $customer_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/customers/{customer_id}/attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get customer attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/customers/{customerId}/attachments/{attachmentId}
# operationId: get-customer-attachment
export def "companies-connections-data-customers-attachments get" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), customer_id: (encode-path-segment $customer_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/customers/{customer_id}/attachments/{attachment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Download customer attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/customers/{customerId}/attachments/{attachmentId}/download
# operationId: download-customer-attachment
export def "companies-connections-data-customers-attachments-download download" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), customer_id: (encode-path-segment $customer_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/customers/{customer_id}/attachments/{attachment_id}/download"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List direct costs
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts
# operationId: get-direct-costs
export def "companies-connections-data-direct-costs list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directCosts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get direct cost
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}
# DEPRECATED
# operationId: get-direct-cost
@deprecated
export def "companies-connections-data-direct-costs get" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), direct_cost_id: (encode-path-segment $direct_cost_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directCosts/{direct_cost_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List direct cost attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}/attachments
# operationId: list-direct-cost-attachments
export def "companies-connections-data-direct-costs-attachments list" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachments: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), direct_cost_id: (encode-path-segment $direct_cost_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directCosts/{direct_cost_id}/attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get direct cost attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}/attachments/{attachmentId}
# operationId: get-direct-cost-attachment
export def "companies-connections-data-direct-costs-attachments get" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), direct_cost_id: (encode-path-segment $direct_cost_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directCosts/{direct_cost_id}/attachments/{attachment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Download direct cost attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}/attachments/{attachmentId}/download
# operationId: download-direct-cost-attachment
export def "companies-connections-data-direct-costs-attachments-download download" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), direct_cost_id: (encode-path-segment $direct_cost_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directCosts/{direct_cost_id}/attachments/{attachment_id}/download"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get direct incomes
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes
# operationId: get-direct-incomes
export def "companies-connections-data-direct-incomes list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directIncomes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get direct income
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}
# DEPRECATED
# operationId: get-direct-income
@deprecated
export def "companies-connections-data-direct-incomes get" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), direct_income_id: (encode-path-segment $direct_income_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directIncomes/{direct_income_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List direct income attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}/attachments
# operationId: list-direct-income-attachments
export def "companies-connections-data-direct-incomes-attachments list" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachments: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), direct_income_id: (encode-path-segment $direct_income_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directIncomes/{direct_income_id}/attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get direct income attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}/attachments/{attachmentId}
# operationId: get-direct-income-attachment
export def "companies-connections-data-direct-incomes-attachments get" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), direct_income_id: (encode-path-segment $direct_income_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directIncomes/{direct_income_id}/attachments/{attachment_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Download direct income attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}/attachments/{attachmentId}/download
# operationId: download-direct-income-attachment
export def "companies-connections-data-direct-incomes-attachments-download download" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), direct_income_id: (encode-path-segment $direct_income_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directIncomes/{direct_income_id}/attachments/{attachment_id}/download"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get invoice attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/invoices/{invoiceId}/attachments
# operationId: get-invoice-attachments
export def "companies-connections-data-invoices-attachments list" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachments: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/invoices/{invoice_id}/attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get invoice attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/invoices/{invoiceId}/attachments/{attachmentId}
# operationId: get-invoice-attachment
export def "companies-connections-data-invoices-attachments get" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), invoice_id: (encode-path-segment $invoice_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/invoices/{invoice_id}/attachments/{attachment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Download invoice attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/invoices/{invoiceId}/attachments/{attachmentId}/download
# operationId: download-invoice-attachment
export def "companies-connections-data-invoices-attachments-download download" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), invoice_id: (encode-path-segment $invoice_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/invoices/{invoice_id}/attachments/{attachment_id}/download"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List supplier attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/suppliers/{supplierId}/attachments
# operationId: list-supplier-attachments
export def "companies-connections-data-suppliers-attachments list" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachments: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), supplier_id: (encode-path-segment $supplier_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/suppliers/{supplier_id}/attachments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get supplier attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/suppliers/{supplierId}/attachments/{attachmentId}
# operationId: get-supplier-attachment
export def "companies-connections-data-suppliers-attachments get" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), supplier_id: (encode-path-segment $supplier_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/suppliers/{supplier_id}/attachments/{attachment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Download supplier attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/suppliers/{supplierId}/attachments/{attachmentId}/download
# operationId: download-supplier-attachment
export def "companies-connections-data-suppliers-attachments-download download" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), supplier_id: (encode-path-segment $supplier_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/suppliers/{supplier_id}/attachments/{attachment_id}/download"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List transfers
#
# GET /companies/{companyId}/connections/{connectionId}/data/transfers
# operationId: list-transfers
export def "companies-connections-data-transfers list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/transfers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get transfer
#
# GET /companies/{companyId}/connections/{connectionId}/data/transfers/{transferId}
# DEPRECATED
# operationId: get-transfer
@deprecated
export def "companies-connections-data-transfers get" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), transfer_id: (encode-path-segment $transfer_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/transfers/{transfer_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get create/update bank account model
#
# GET /companies/{companyId}/connections/{connectionId}/options/bankAccounts
# operationId: get-create-update-bankAccounts-model
export def "companies-connections-options-bank-accounts get-create-update-model" [
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
]: nothing -> record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/bankAccounts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List push options for bank account bank transactions
#
# GET /companies/{companyId}/connections/{connectionId}/options/bankAccounts/{accountId}/bankTransactions
# operationId: get-create-bank-account-model
export def "companies-connections-options-bank-accounts-bank-transactions get-create-model" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), account_id: (encode-path-segment $account_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/bankAccounts/{account_id}/bankTransactions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get create/update bill credit note model
#
# GET /companies/{companyId}/connections/{connectionId}/options/billCreditNotes
# operationId: get-create-update-billCreditNotes-model
export def "companies-connections-options-bill-credit-notes get-create-update-model" [
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
]: nothing -> record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/billCreditNotes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get create bill payment model
#
# GET /companies/{companyId}/connections/{connectionId}/options/billPayments
# operationId: get-create-billPayments-model
export def "companies-connections-options-bill-payments get-create-model" [
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
]: nothing -> record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/billPayments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get create/update bill model
#
# GET /companies/{companyId}/connections/{connectionId}/options/bills
# operationId: get-create-update-bills-model
export def "companies-connections-options-bills get-create-update-model" [
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
]: nothing -> record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/bills"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get create account model
#
# GET /companies/{companyId}/connections/{connectionId}/options/chartOfAccounts
# operationId: get-create-chartOfAccounts-model
export def "companies-connections-options-chart-of-accounts get-create-model" [
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
]: nothing -> record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/chartOfAccounts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get create/update credit note model
#
# GET /companies/{companyId}/connections/{connectionId}/options/creditNotes
# operationId: get-create-update-creditNotes-model
export def "companies-connections-options-credit-notes get-create-update-model" [
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
]: nothing -> record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/creditNotes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get create/update customer model
#
# GET /companies/{companyId}/connections/{connectionId}/options/customers
# operationId: get-create-update-customers-model
export def "companies-connections-options-customers get-create-update-model" [
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
]: nothing -> record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/customers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get create direct cost model
#
# GET /companies/{companyId}/connections/{connectionId}/options/directCosts
# operationId: get-create-directCosts-model
export def "companies-connections-options-direct-costs get-create-model" [
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
]: nothing -> record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/directCosts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get create direct income model
#
# GET /companies/{companyId}/connections/{connectionId}/options/directIncomes
# operationId: get-create-directIncomes-model
export def "companies-connections-options-direct-incomes get-create-model" [
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
]: nothing -> record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/directIncomes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get create/update invoice model
#
# GET /companies/{companyId}/connections/{connectionId}/options/invoices
# operationId: get-create-update-invoices-model
export def "companies-connections-options-invoices get-create-update-model" [
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
]: nothing -> record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/invoices"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get create item model
#
# GET /companies/{companyId}/connections/{connectionId}/options/items
# operationId: get-create-items-model
export def "companies-connections-options-items get-create-model" [
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
]: nothing -> record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/items"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get create journal entry model
#
# GET /companies/{companyId}/connections/{connectionId}/options/journalEntries
# operationId: get-create-journalEntries-model
export def "companies-connections-options-journal-entries get-create-model" [
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
]: nothing -> record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/journalEntries"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get create journal model
#
# GET /companies/{companyId}/connections/{connectionId}/options/journals
# operationId: get-create-journals-model
export def "companies-connections-options-journals get-create-model" [
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
]: nothing -> record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/journals"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get create payment model
#
# GET /companies/{companyId}/connections/{connectionId}/options/payments
# operationId: get-create-payments-model
export def "companies-connections-options-payments get-create-model" [
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
]: nothing -> record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/payments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get create/update purchase order model
#
# GET /companies/{companyId}/connections/{connectionId}/options/purchaseOrders
# operationId: get-create-update-purchaseOrders-model
export def "companies-connections-options-purchase-orders get-create-update-model" [
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
]: nothing -> record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/purchaseOrders"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get create/update supplier model
#
# GET /companies/{companyId}/connections/{connectionId}/options/suppliers
# operationId: get-create-update-suppliers-model
export def "companies-connections-options-suppliers get-create-update-model" [
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
]: nothing -> record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/suppliers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get create transfer model
#
# GET /companies/{companyId}/connections/{connectionId}/options/transfers
# operationId: get-create-transfers-model
export def "companies-connections-options-transfers get-create-model" [
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
]: nothing -> record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/transfers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create account
#
# POST /companies/{companyId}/connections/{connectionId}/push/accounts
# operationId: create-account
# --metadata shape: {isDeleted?: bool}
# --validDatatypeLinks item shape: {links?: list<string>, property?: string}
export def "companies-connections-push-accounts create" [
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
  --timeout-in-minutes: int # format: int32
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --current-balance: float # Current balance in the account. (nullable)
  --description: string # Description for the account. (nullable)
  --fully-qualified-category: string # Full category of the account. For example: Liability.Current or Income.Revenue. See example data. (nullable)
  --fully-qualified-name: string # Full name of the account, for example: - `Liability.Current.VAT` - `Income.Revenue.Sales` (nullable)
  --id: string # Identifier for the account, unique for the company.
  --is-bank-account: oneof<nothing, bool> # Confirms whether the account is a bank account or not.
  --metadata: record # shape: {isDeleted?: bool}
  --name: string # Name of the account. (nullable)
  --nominal-code: string # Reference given to each nominal account for a business. It ensures money is allocated to the correct account. This code isn't a unique identifier in the Codat system. (nullable)
  status: string@status-completer # Status of the account
  type: string@type-completer # Type of account
  --valid-datatype-links: list # 'The validDatatypeLinks can be used to determine whether an account can be correctly mapped to another object; for example, accounts with a `type` of `income` might only support being used on an Invoice and Direct Income. For more information, see Valid Data Type Links.' (nullable) — item shape: {links?: list<string>, property?: string}
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/accounts") $qp)
  let req_body = {"currency": $currency, "currentBalance": $current_balance, "description": $description, "fullyQualifiedCategory": $fully_qualified_category, "fullyQualifiedName": $fully_qualified_name, "id": $id, "isBankAccount": $is_bank_account, "metadata": $metadata, "name": $name, "nominalCode": $nominal_code, "status": $status, "type": $type, "validDatatypeLinks": $valid_datatype_links} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create bank account
#
# POST /companies/{companyId}/connections/{connectionId}/push/bankAccounts
# operationId: create-bank-account
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-bank-accounts create" [
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
  --allow-sync-on-push-complete: oneof<nothing, bool> # default: true
  --timeout-in-minutes: int # format: int32
  --account-name: string # Name of the bank account in the accounting platform. (nullable)
  --account-number: string # Account number for the bank account. Xero integrations Only a UK account number shows for bank accounts with GBP currency and a combined total of sort code and account number that equals 14 digits, For non-GBP accounts, the full bank account number is populated. FreeAgent integrations For Credit accounts, only the last four digits are required. For other types, the field is optional. (nullable)
  --account-type: string@account-type-completer # The type of transactions and balances on the account. For Credit accounts, positive balances are liabilities, and positive transactions **reduce** liabilities. For Debit accounts, positive balances are assets, and positive transactions **increase** assets.
  --available-balance: float # Total available balance of the bank account as reported by the underlying data source. This may take into account overdrafts or pending transactions for example. (nullable)
  --balance: float # Balance of the bank account. (nullable)
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --i-ban: string # International bank account number of the account. Often used when making or receiving international payments. (nullable)
  --id: string # Identifier for the account, unique for the company in the accounting platform.
  --institution: string # The institution of the bank account. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --nominal-code: string # Code used to identify each nominal account for a business. (nullable)
  --overdraft-limit: float # Pre-arranged overdraft limit of the account. The value is always positive. For example, an overdraftLimit of `1000` means that the balance of the account can go down to `-1000`. (nullable)
  --sort-code: string # Sort code for the bank account. Xero integrations The sort code is only displayed when the currency = GBP and the sort code and account number sum to 14 digits. For non-GBP accounts, this field is not populated. (nullable)
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allowSyncOnPushComplete" $allow_sync_on_push_complete "scalar") (serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/bankAccounts") $qp)
  let req_body = {"accountName": $account_name, "accountNumber": $account_number, "accountType": $account_type, "availableBalance": $available_balance, "balance": $balance, "currency": $currency, "iBan": $i_ban, "id": $id, "institution": $institution, "metadata": $metadata, "nominalCode": $nominal_code, "overdraftLimit": $overdraft_limit, "sortCode": $sort_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create bank transactions
#
# POST /companies/{companyId}/connections/{connectionId}/push/bankAccounts/{accountId}/bankTransactions
# operationId: create-bank-transactions
# --transactions item shape: {amount: float, balance: float, clearedOnDate?: string, counterparty?: string, description?: string, id?: string, reconciled: bool, reference?: string, transactionType: "Unknown"|"Credit"|"Debit"|"Int"|"Div"|"Fee"|"SerChg"|"Dep"|"Atm"|"Pos"|"Xfer"|"Check"|"Payment"|"Cash"|"DirectDep"|"DirectDebit"|"RepeatPmt"|"Other"}
export def "companies-connections-push-bank-accounts-bank-transactions create" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sync-on-push-complete: oneof<nothing, bool> # default: true
  --timeout-in-minutes: int # format: int32
  --body-account-id: string # nullable
  --transactions: list # nullable — item shape: {amount: float, balance: float, clearedOnDate?: string, counterparty?: string, description?: string, id?: string, reconciled: bool, reference?: string, transactionType: "Unknown"|"Credit"|"Debit"|"Int"|"Div"|"Fee"|"SerChg"|"Dep"|"Atm"|"Pos"|"Xfer"|"Check"|"Payment"|"Cash"|"DirectDep"|"DirectDebit"|"RepeatPmt"|"Other"}
]: any -> record<data: record<accountId: string, transactions: list<record>>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allowSyncOnPushComplete" $allow_sync_on_push_complete "scalar") (serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), account_id: (encode-path-segment $account_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/bankAccounts/{account_id}/bankTransactions") $qp)
  let req_body = {"accountId": $body_account_id, "transactions": $transactions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update bank account
#
# PUT /companies/{companyId}/connections/{connectionId}/push/bankAccounts/{bankAccountId}
# operationId: update-bank-account
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-bank-accounts update" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --account-name: string # Name of the bank account in the accounting platform. (nullable)
  --account-number: string # Account number for the bank account. Xero integrations Only a UK account number shows for bank accounts with GBP currency and a combined total of sort code and account number that equals 14 digits, For non-GBP accounts, the full bank account number is populated. FreeAgent integrations For Credit accounts, only the last four digits are required. For other types, the field is optional. (nullable)
  --account-type: string@account-type-completer # The type of transactions and balances on the account. For Credit accounts, positive balances are liabilities, and positive transactions **reduce** liabilities. For Debit accounts, positive balances are assets, and positive transactions **increase** assets.
  --available-balance: float # Total available balance of the bank account as reported by the underlying data source. This may take into account overdrafts or pending transactions for example. (nullable)
  --balance: float # Balance of the bank account. (nullable)
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --i-ban: string # International bank account number of the account. Often used when making or receiving international payments. (nullable)
  --id: string # Identifier for the account, unique for the company in the accounting platform.
  --institution: string # The institution of the bank account. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --nominal-code: string # Code used to identify each nominal account for a business. (nullable)
  --overdraft-limit: float # Pre-arranged overdraft limit of the account. The value is always positive. For example, an overdraftLimit of `1000` means that the balance of the account can go down to `-1000`. (nullable)
  --sort-code: string # Sort code for the bank account. Xero integrations The sort code is only displayed when the currency = GBP and the sort code and account number sum to 14 digits. For non-GBP accounts, this field is not populated. (nullable)
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), bank_account_id: (encode-path-segment $bank_account_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/bankAccounts/{bank_account_id}") $qp)
  let req_body = {"accountName": $account_name, "accountNumber": $account_number, "accountType": $account_type, "availableBalance": $available_balance, "balance": $balance, "currency": $currency, "iBan": $i_ban, "id": $id, "institution": $institution, "metadata": $metadata, "nominalCode": $nominal_code, "overdraftLimit": $overdraft_limit, "sortCode": $sort_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create bill credit note
#
# POST /companies/{companyId}/connections/{connectionId}/push/billCreditNotes
# operationId: create-bill-credit-note
# --lineItems item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
# --metadata shape: {isDeleted?: bool}
# --paymentAllocations item shape: {allocation: record, payment: record}
# --supplementalData shape: {content?: record}
# --supplierRef shape: {id: string, supplierName?: string}
# --withholdingTax item shape: {amount: float, name: string}
export def "companies-connections-push-bill-credit-notes create" [
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
  --timeout-in-minutes: int # format: int32
  --allocated-on-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --bill-credit-note-number: string # Friendly reference for the bill credit note. (nullable)
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  discount_percentage: float # Percentage rate of any discount applied to the bill credit note.
  --id: string # Identifier for the bill credit note that is unique to a company in the accounting platform.
  --issue-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # An array of line (nullable) — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the bill credit note. (nullable)
  --payment-allocations: list # An array of payment allocations. (nullable) — item shape: {allocation: record, payment: record}
  remaining_credit: float # Amount of the bill credit note that is still outstanding.
  status: string@status-completer-1 # Current state of the bill credit note
  sub_total: float # Total amount of the bill credit note, including discounts but excluding tax.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --supplier-ref: record # Reference to the supplier the record relates to. — shape: {id: string, supplierName?: string}
  total_amount: float # Total amount of credit that has been applied to the business' account with the supplier, including discounts and tax.
  total_discount: float # Total value of any discounts applied.
  total_tax_amount: float # Amount of tax included in the bill credit note.
  --withholding-tax: list # nullable — item shape: {amount: float, name: string}
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/billCreditNotes") $qp)
  let req_body = {"allocatedOnDate": $allocated_on_date, "billCreditNoteNumber": $bill_credit_note_number, "currency": $currency, "currencyRate": $currency_rate, "discountPercentage": $discount_percentage, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "remainingCredit": $remaining_credit, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "supplierRef": $supplier_ref, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount, "withholdingTax": $withholding_tax} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update bill credit note
#
# PUT /companies/{companyId}/connections/{connectionId}/push/billCreditNotes/{billCreditNoteId}
# operationId: update-bill-credit-note
# --lineItems item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
# --metadata shape: {isDeleted?: bool}
# --paymentAllocations item shape: {allocation: record, payment: record}
# --supplementalData shape: {content?: record}
# --supplierRef shape: {id: string, supplierName?: string}
# --withholdingTax item shape: {amount: float, name: string}
export def "companies-connections-push-bill-credit-notes update" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --allocated-on-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --bill-credit-note-number: string # Friendly reference for the bill credit note. (nullable)
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  discount_percentage: float # Percentage rate of any discount applied to the bill credit note.
  --id: string # Identifier for the bill credit note that is unique to a company in the accounting platform.
  --issue-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # An array of line (nullable) — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the bill credit note. (nullable)
  --payment-allocations: list # An array of payment allocations. (nullable) — item shape: {allocation: record, payment: record}
  remaining_credit: float # Amount of the bill credit note that is still outstanding.
  status: string@status-completer-1 # Current state of the bill credit note
  sub_total: float # Total amount of the bill credit note, including discounts but excluding tax.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --supplier-ref: record # Reference to the supplier the record relates to. — shape: {id: string, supplierName?: string}
  total_amount: float # Total amount of credit that has been applied to the business' account with the supplier, including discounts and tax.
  total_discount: float # Total value of any discounts applied.
  total_tax_amount: float # Amount of tax included in the bill credit note.
  --withholding-tax: list # nullable — item shape: {amount: float, name: string}
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), bill_credit_note_id: (encode-path-segment $bill_credit_note_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/billCreditNotes/{bill_credit_note_id}") $qp)
  let req_body = {"allocatedOnDate": $allocated_on_date, "billCreditNoteNumber": $bill_credit_note_number, "currency": $currency, "currencyRate": $currency_rate, "discountPercentage": $discount_percentage, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "remainingCredit": $remaining_credit, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "supplierRef": $supplier_ref, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount, "withholdingTax": $withholding_tax} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create bill payments
#
# POST /companies/{companyId}/connections/{connectionId}/push/billPayments
# operationId: create-bill-payment
# --accountRef shape: {id?: string, name?: string}
# --lines item shape: {allocatedOnDate?: string, amount: float, links?: list}
# --metadata shape: {isDeleted?: bool}
# --paymentMethodRef shape: {id?: string, name?: string}
# --supplementalData shape: {content?: record}
# --supplierRef shape: {id: string, supplierName?: string}
export def "companies-connections-push-bill-payments create" [
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
  --timeout-in-minutes: int # format: int32
  --account-ref: record # Data types that reference an account, for example bill and invoice line items, use an accountRef that includes the ID and name of the linked account. — shape: {id?: string, name?: string}
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the bill payment, unique for the company in the accounting platform.
  --lines: list # An array of bill payment lines. (nullable) — item shape: {allocatedOnDate?: string, amount: float, links?: list}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Additional information associated with the payment. (nullable)
  --payment-method-ref: record # shape: {id?: string, name?: string}
  --reference: string # Additional information associated with the payment. (nullable)
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --supplier-ref: record # Reference to the supplier the record relates to. — shape: {id: string, supplierName?: string}
  --total-amount: float # Amount of the payment in the payment currency. This value never changes and represents the amount of money that is paid into the supplier's account.
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/billPayments") $qp)
  let req_body = {"accountRef": $account_ref, "currency": $currency, "currencyRate": $currency_rate, "date": $date, "id": $id, "lines": $lines, "metadata": $metadata, "note": $note, "paymentMethodRef": $payment_method_ref, "reference": $reference, "supplementalData": $supplemental_data, "supplierRef": $supplier_ref, "totalAmount": $total_amount} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete bill payment
#
# DELETE /companies/{companyId}/connections/{connectionId}/push/billPayments/{billPaymentId}
# operationId: delete-billPayment
export def "companies-connections-push-bill-payments delete" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), bill_payment_id: (encode-path-segment $bill_payment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/billPayments/{bill_payment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create bill
#
# POST /companies/{companyId}/connections/{connectionId}/push/bills
# operationId: create-bill
# --lineItems item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, isDirectCost?: bool, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
# --metadata shape: {isDeleted?: bool}
# --paymentAllocations item shape: {allocation: record, payment: record}
# --purchaseOrderRefs item shape: {id?: string, purchaseOrderNumber?: string}
# --supplementalData shape: {content?: record}
# --supplierRef shape: {id: string, supplierName?: string}
# --withholdingTax item shape: {amount: float, name: string}
export def "companies-connections-push-bills create" [
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
  --timeout-in-minutes: int # format: int32
  --amount-due: float # Amount outstanding on the bill. (nullable)
  --currency: any
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --due-date: any
  --id: string # Identifier for the bill, unique for the company in the accounting platform.
  issue_date: any
  --line-items: list # Array of Bill line items. (nullable) — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, isDirectCost?: bool, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any private, company notes about the bill, such as payment information. (nullable)
  --payment-allocations: list # An array of payment allocations. (nullable) — item shape: {allocation: record, payment: record}
  --purchase-order-refs: list # nullable — item shape: {id?: string, purchaseOrderNumber?: string}
  --reference: string # User-friendly reference for the bill. (nullable)
  status: string@status-completer-2 # Current state of the bill.
  sub_total: float # Total amount of the bill, excluding any taxes.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --supplier-ref: record # Reference to the supplier the record relates to. — shape: {id: string, supplierName?: string}
  tax_amount: float # Amount of tax on the bill.
  total_amount: float # Amount of the bill, including tax.
  --withholding-tax: list # nullable — item shape: {amount: float, name: string}
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/bills") $qp)
  let req_body = {"amountDue": $amount_due, "currency": $currency, "currencyRate": $currency_rate, "dueDate": $due_date, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "purchaseOrderRefs": $purchase_order_refs, "reference": $reference, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "supplierRef": $supplier_ref, "taxAmount": $tax_amount, "totalAmount": $total_amount, "withholdingTax": $withholding_tax} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete bill
#
# DELETE /companies/{companyId}/connections/{connectionId}/push/bills/{billId}
# operationId: delete-bill
export def "companies-connections-push-bills delete" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), bill_id: (encode-path-segment $bill_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/bills/{bill_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update bill
#
# PUT /companies/{companyId}/connections/{connectionId}/push/bills/{billId}
# operationId: update-bill
# --lineItems item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, isDirectCost?: bool, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
# --metadata shape: {isDeleted?: bool}
# --paymentAllocations item shape: {allocation: record, payment: record}
# --purchaseOrderRefs item shape: {id?: string, purchaseOrderNumber?: string}
# --supplementalData shape: {content?: record}
# --supplierRef shape: {id: string, supplierName?: string}
# --withholdingTax item shape: {amount: float, name: string}
export def "companies-connections-push-bills update" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --amount-due: float # Amount outstanding on the bill. (nullable)
  --currency: any
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --due-date: any
  --id: string # Identifier for the bill, unique for the company in the accounting platform.
  issue_date: any
  --line-items: list # Array of Bill line items. (nullable) — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, isDirectCost?: bool, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any private, company notes about the bill, such as payment information. (nullable)
  --payment-allocations: list # An array of payment allocations. (nullable) — item shape: {allocation: record, payment: record}
  --purchase-order-refs: list # nullable — item shape: {id?: string, purchaseOrderNumber?: string}
  --reference: string # User-friendly reference for the bill. (nullable)
  status: string@status-completer-2 # Current state of the bill.
  sub_total: float # Total amount of the bill, excluding any taxes.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --supplier-ref: record # Reference to the supplier the record relates to. — shape: {id: string, supplierName?: string}
  tax_amount: float # Amount of tax on the bill.
  total_amount: float # Amount of the bill, including tax.
  --withholding-tax: list # nullable — item shape: {amount: float, name: string}
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), bill_id: (encode-path-segment $bill_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/bills/{bill_id}") $qp)
  let req_body = {"amountDue": $amount_due, "currency": $currency, "currencyRate": $currency_rate, "dueDate": $due_date, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "purchaseOrderRefs": $purchase_order_refs, "reference": $reference, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "supplierRef": $supplier_ref, "taxAmount": $tax_amount, "totalAmount": $total_amount, "withholdingTax": $withholding_tax} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Upload bill attachments
#
# POST /companies/{companyId}/connections/{connectionId}/push/bills/{billId}/attachments
# operationId: upload-bill-attachments
export def "companies-connections-push-bills-attachments upload" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), bill_id: (encode-path-segment $bill_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/bills/{bill_id}/attachments"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Create credit note
#
# POST /companies/{companyId}/connections/{connectionId}/push/creditNotes
# operationId: create-credit-note
# --customerRef shape: {companyName?: string, id: string}
# --lineItems item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, isDirectIncome?: bool, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
# --metadata shape: {isDeleted?: bool}
# --paymentAllocations item shape: {allocation: record, payment: record}
# --supplementalData shape: {content?: record}
# --withholdingTax item shape: {amount: float, name: string}
export def "companies-connections-push-credit-notes create" [
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
  --timeout-in-minutes: int # format: int32
  --additional-tax-amount: float
  --additional-tax-percentage: float
  --allocated-on-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --credit-note-number: string # Friendly reference for the credit note. (nullable)
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --customer-ref: record # shape: {companyName?: string, id: string}
  discount_percentage: float # Percentage rate (from 0 to 100) of discounts applied to the credit note.
  --id: string # Identifier for the credit note, unique to the company in the accounting platform.
  --issue-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # nullable — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, isDirectIncome?: bool, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the credit note. Where possible, Codat links to a data field in the accounting platform that is publicly available. This means that the contents of the note field are included when a credit note is emailed from the accounting platform to the customer. (nullable)
  --payment-allocations: list # An array of payment allocations. (nullable) — item shape: {allocation: record, payment: record}
  remaining_credit: float # Unused balance of totalAmount originally raised.
  status: string@status-completer-1
  sub_total: float # Value of the credit note, including discounts and excluding tax.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  total_amount: float # Total amount of credit that has been applied to the customer's accounts receivable
  total_discount: float # Any discounts applied to the credit note amount.
  total_tax_amount: float # Any tax applied to the credit note amount.
  --withholding-tax: list # nullable — item shape: {amount: float, name: string}
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/creditNotes") $qp)
  let req_body = {"additionalTaxAmount": $additional_tax_amount, "additionalTaxPercentage": $additional_tax_percentage, "allocatedOnDate": $allocated_on_date, "creditNoteNumber": $credit_note_number, "currency": $currency, "currencyRate": $currency_rate, "customerRef": $customer_ref, "discountPercentage": $discount_percentage, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "remainingCredit": $remaining_credit, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount, "withholdingTax": $withholding_tax} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update creditNote
#
# PUT /companies/{companyId}/connections/{connectionId}/push/creditNotes/{creditNoteId}
# operationId: update-credit-note
# --customerRef shape: {companyName?: string, id: string}
# --lineItems item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, isDirectIncome?: bool, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
# --metadata shape: {isDeleted?: bool}
# --paymentAllocations item shape: {allocation: record, payment: record}
# --supplementalData shape: {content?: record}
# --withholdingTax item shape: {amount: float, name: string}
export def "companies-connections-push-credit-notes update" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --additional-tax-amount: float
  --additional-tax-percentage: float
  --allocated-on-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --credit-note-number: string # Friendly reference for the credit note. (nullable)
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --customer-ref: record # shape: {companyName?: string, id: string}
  discount_percentage: float # Percentage rate (from 0 to 100) of discounts applied to the credit note.
  --id: string # Identifier for the credit note, unique to the company in the accounting platform.
  --issue-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # nullable — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, isDirectIncome?: bool, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the credit note. Where possible, Codat links to a data field in the accounting platform that is publicly available. This means that the contents of the note field are included when a credit note is emailed from the accounting platform to the customer. (nullable)
  --payment-allocations: list # An array of payment allocations. (nullable) — item shape: {allocation: record, payment: record}
  remaining_credit: float # Unused balance of totalAmount originally raised.
  status: string@status-completer-1
  sub_total: float # Value of the credit note, including discounts and excluding tax.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  total_amount: float # Total amount of credit that has been applied to the customer's accounts receivable
  total_discount: float # Any discounts applied to the credit note amount.
  total_tax_amount: float # Any tax applied to the credit note amount.
  --withholding-tax: list # nullable — item shape: {amount: float, name: string}
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), credit_note_id: (encode-path-segment $credit_note_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/creditNotes/{credit_note_id}") $qp)
  let req_body = {"additionalTaxAmount": $additional_tax_amount, "additionalTaxPercentage": $additional_tax_percentage, "allocatedOnDate": $allocated_on_date, "creditNoteNumber": $credit_note_number, "currency": $currency, "currencyRate": $currency_rate, "customerRef": $customer_ref, "discountPercentage": $discount_percentage, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "remainingCredit": $remaining_credit, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount, "withholdingTax": $withholding_tax} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create customer
#
# POST /companies/{companyId}/connections/{connectionId}/push/customers
# operationId: create-customer
# --addresses item shape: {city?: string, country?: string, line1?: string, line2?: string, postalCode?: string, region?: string, type: "Unknown"|"Billing"|"Delivery"}
# --contacts item shape: {address?: record, email?: string, modifiedDate?: string, name?: string, phone?: list, status: "Unknown"|"Active"|"Archived"}
# --metadata shape: {isDeleted?: bool}
# --supplementalData shape: {content?: record}
export def "companies-connections-push-customers create" [
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
  --timeout-in-minutes: int # format: int32
  --addresses: list # An array of Addresses. (nullable) — item shape: {city?: string, country?: string, line1?: string, line2?: string, postalCode?: string, region?: string, type: "Unknown"|"Billing"|"Delivery"}
  --contact-name: string # Name of the main contact for the identified customer. (nullable)
  --contacts: list # An array of Contacts. (nullable) — item shape: {address?: record, email?: string, modifiedDate?: string, name?: string, phone?: list, status: "Unknown"|"Active"|"Archived"}
  --customer-name: string # Name of the customer as recorded in the accounting system, typically the company name. (nullable)
  --default-currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --email-address: string # Email address the customer can be contacted by. (nullable)
  --id: string # Identifier for the customer, unique to the company in the accounting platform.
  --metadata: record # shape: {isDeleted?: bool}
  --phone: string # Phone number the customer can be contacted by. (nullable)
  --registration-number: string # Company number. In the UK, this is typically the Companies House company registration number. (nullable)
  status: string@status-completer-3 # Status of customer.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --tax-number: string # Company tax number. (nullable)
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/customers") $qp)
  let req_body = {"addresses": $addresses, "contactName": $contact_name, "contacts": $contacts, "customerName": $customer_name, "defaultCurrency": $default_currency, "emailAddress": $email_address, "id": $id, "metadata": $metadata, "phone": $phone, "registrationNumber": $registration_number, "status": $status, "supplementalData": $supplemental_data, "taxNumber": $tax_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update customer
#
# PUT /companies/{companyId}/connections/{connectionId}/push/customers/{customerId}
# operationId: update-customer
# --addresses item shape: {city?: string, country?: string, line1?: string, line2?: string, postalCode?: string, region?: string, type: "Unknown"|"Billing"|"Delivery"}
# --contacts item shape: {address?: record, email?: string, modifiedDate?: string, name?: string, phone?: list, status: "Unknown"|"Active"|"Archived"}
# --metadata shape: {isDeleted?: bool}
# --supplementalData shape: {content?: record}
export def "companies-connections-push-customers update" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --addresses: list # An array of Addresses. (nullable) — item shape: {city?: string, country?: string, line1?: string, line2?: string, postalCode?: string, region?: string, type: "Unknown"|"Billing"|"Delivery"}
  --contact-name: string # Name of the main contact for the identified customer. (nullable)
  --contacts: list # An array of Contacts. (nullable) — item shape: {address?: record, email?: string, modifiedDate?: string, name?: string, phone?: list, status: "Unknown"|"Active"|"Archived"}
  --customer-name: string # Name of the customer as recorded in the accounting system, typically the company name. (nullable)
  --default-currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --email-address: string # Email address the customer can be contacted by. (nullable)
  --id: string # Identifier for the customer, unique to the company in the accounting platform.
  --metadata: record # shape: {isDeleted?: bool}
  --phone: string # Phone number the customer can be contacted by. (nullable)
  --registration-number: string # Company number. In the UK, this is typically the Companies House company registration number. (nullable)
  status: string@status-completer-3 # Status of customer.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --tax-number: string # Company tax number. (nullable)
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), customer_id: (encode-path-segment $customer_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/customers/{customer_id}") $qp)
  let req_body = {"addresses": $addresses, "contactName": $contact_name, "contacts": $contacts, "customerName": $customer_name, "defaultCurrency": $default_currency, "emailAddress": $email_address, "id": $id, "metadata": $metadata, "phone": $phone, "registrationNumber": $registration_number, "status": $status, "supplementalData": $supplemental_data, "taxNumber": $tax_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create direct cost
#
# POST /companies/{companyId}/connections/{connectionId}/push/directCosts
# operationId: create-direct-cost
# --contactRef shape: {dataType?: string, id: string}
# --lineItems item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
# --metadata shape: {isDeleted?: bool}
# --paymentAllocations item shape: {allocation: record, payment: record}
# --supplementalData shape: {content?: record}
export def "companies-connections-push-direct-costs create" [
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
  --timeout-in-minutes: int # format: int32
  --contact-ref: record # The customer or supplier for the transfer, if available. — shape: {dataType?: string, id: string}
  currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --id: string # Identifier of the direct cost, unique for the company.
  issue_date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  line_items: list # An array of line items. — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # A note attached to the direct cost. (nullable)
  payment_allocations: list # An array of payment allocations. — item shape: {allocation: record, payment: record}
  --reference: string # User-friendly reference for the direct cost. (nullable)
  sub_total: float # The total amount of the direct costs, excluding any taxes.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  tax_amount: float # The total amount of tax on the direct costs.
  total_amount: float # The amount of the direct costs, inclusive of tax.
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/directCosts") $qp)
  let req_body = {"contactRef": $contact_ref, "currency": $currency, "currencyRate": $currency_rate, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "reference": $reference, "subTotal": $sub_total, "supplementalData": $supplemental_data, "taxAmount": $tax_amount, "totalAmount": $total_amount} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Upload direct cost attachment
#
# POST /companies/{companyId}/connections/{connectionId}/push/directCosts/{directCostId}/attachment
# operationId: upload-direct-cost-attachment
export def "companies-connections-push-direct-costs-attachment upload" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), direct_cost_id: (encode-path-segment $direct_cost_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/directCosts/{direct_cost_id}/attachment"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Create direct income
#
# POST /companies/{companyId}/connections/{connectionId}/push/directIncomes
# operationId: create-direct-income
# --contactRef shape: {dataType?: string, id: string}
# --lineItems item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, trackingCategoryRefs?: list, unitAmount: float}
# --metadata shape: {isDeleted?: bool}
# --paymentAllocations item shape: {allocation: record, payment: record}
# --supplementalData shape: {content?: record}
export def "companies-connections-push-direct-incomes create" [
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
  --timeout-in-minutes: int # format: int32
  --contact-ref: record # The customer or supplier for the transfer, if available. — shape: {dataType?: string, id: string}
  currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --id: string # Identifier of the direct income, unique for the company.
  issue_date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  line_items: list # An array of line items. — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, trackingCategoryRefs?: list, unitAmount: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # nullable
  payment_allocations: list # item shape: {allocation: record, payment: record}
  --reference: string # User-friendly reference for the direct income. (nullable)
  sub_total: float # The total amount of the direct incomes, excluding any taxes.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  tax_amount: float # The total amount of tax on the direct incomes.
  total_amount: float # The amount of the direct incomes, inclusive of tax.
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/directIncomes") $qp)
  let req_body = {"contactRef": $contact_ref, "currency": $currency, "currencyRate": $currency_rate, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "reference": $reference, "subTotal": $sub_total, "supplementalData": $supplemental_data, "taxAmount": $tax_amount, "totalAmount": $total_amount} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create direct income attachment
#
# POST /companies/{companyId}/connections/{connectionId}/push/directIncomes/{directIncomeId}/attachment
# operationId: upload-direct-income-attachment
export def "companies-connections-push-direct-incomes-attachment upload" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), direct_income_id: (encode-path-segment $direct_income_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/directIncomes/{direct_income_id}/attachment"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Create invoice
#
# POST /companies/{companyId}/connections/{connectionId}/push/invoices
# operationId: create-invoice
# --customerRef shape: {companyName?: string, id: string}
# --lineItems item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, isDirectIncome?: bool, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
# --metadata shape: {isDeleted?: bool}
# --paymentAllocations item shape: {allocation: record, payment: record}
# --supplementalData shape: {content?: record}
# --withholdingTax item shape: {amount: float, name: string}
export def "companies-connections-push-invoices create" [
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
  --timeout-in-minutes: int # format: int32
  --additional-tax-amount: float
  --additional-tax-percentage: float
  amount_due: float # Amount outstanding on the invoice.
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --customer-ref: record # shape: {companyName?: string, id: string}
  --discount-percentage: float # Percentage rate (from 0 to 100) of discounts applied to the invoice. For example: A 5% discount will return a value of `5`, not `0.05`. (nullable)
  --due-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the invoice, unique to the company in the accounting platform.
  --invoice-number: string # Friendly reference for the invoice. If available, this appears in the file name of invoice attachments. (nullable)
  issue_date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # An array of line items. (nullable) — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, isDirectIncome?: bool, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the invoice. Where possible, Codat links to a data field in the accounting platform that is publicly available. This means that the contents of the note field are included when an invoice is emailed from the accounting platform to the customer. (nullable)
  --paid-on-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --payment-allocations: list # An array of payment allocations. (nullable) — item shape: {allocation: record, payment: record}
  --sales-order-refs: list<string> # List of references to related Sales orders. (nullable)
  status: string@status-completer-1 # Current state of the invoice: - `Draft` - Invoice hasn't been submitted to the supplier. It may be in a pending state or is scheduled for future submission, for example by email. - `Submitted` - Invoice is no longer a draft. It has been processed and, or, sent to the customer. In this state, it will impact the ledger. It also has no payments made against it (amountDue == totalAmount). - `PartiallyPaid` - The balance paid against the invoice is positive, but less than the total invoice amount (0 < amountDue < totalAmount). - `Paid` - Invoice is paid in full. This includes if the invoice has been credited or overpaid (amountDue == 0). - `Void` - An invoice can become Void when it's deleted, refunded, written off, or cancelled. A voided invoice may still be PartiallyPaid, and so all outstanding amounts on voided invoices are removed from the accounts receivable account.
  --sub-total: float # Total amount of the invoice excluding any taxes. (nullable)
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  total_amount: float # Amount of the invoice, inclusive of tax.
  --total-discount: float # Numerical value of discounts applied to the invoice. (nullable)
  total_tax_amount: float # Amount of tax on the invoice.
  --withholding-tax: list # nullable — item shape: {amount: float, name: string}
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/invoices") $qp)
  let req_body = {"additionalTaxAmount": $additional_tax_amount, "additionalTaxPercentage": $additional_tax_percentage, "amountDue": $amount_due, "currency": $currency, "currencyRate": $currency_rate, "customerRef": $customer_ref, "discountPercentage": $discount_percentage, "dueDate": $due_date, "id": $id, "invoiceNumber": $invoice_number, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paidOnDate": $paid_on_date, "paymentAllocations": $payment_allocations, "salesOrderRefs": $sales_order_refs, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount, "withholdingTax": $withholding_tax} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete invoice
#
# DELETE /companies/{companyId}/connections/{connectionId}/push/invoices/{invoiceId}
# operationId: delete-invoice
export def "companies-connections-push-invoices delete" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/invoices/{invoice_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update invoice
#
# PUT /companies/{companyId}/connections/{connectionId}/push/invoices/{invoiceId}
# operationId: update-invoice
# --customerRef shape: {companyName?: string, id: string}
# --lineItems item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, isDirectIncome?: bool, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
# --metadata shape: {isDeleted?: bool}
# --paymentAllocations item shape: {allocation: record, payment: record}
# --supplementalData shape: {content?: record}
# --withholdingTax item shape: {amount: float, name: string}
export def "companies-connections-push-invoices update" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --additional-tax-amount: float
  --additional-tax-percentage: float
  amount_due: float # Amount outstanding on the invoice.
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --customer-ref: record # shape: {companyName?: string, id: string}
  --discount-percentage: float # Percentage rate (from 0 to 100) of discounts applied to the invoice. For example: A 5% discount will return a value of `5`, not `0.05`. (nullable)
  --due-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the invoice, unique to the company in the accounting platform.
  --invoice-number: string # Friendly reference for the invoice. If available, this appears in the file name of invoice attachments. (nullable)
  issue_date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # An array of line items. (nullable) — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, isDirectIncome?: bool, itemRef?: record, quantity: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, tracking?: record, trackingCategoryRefs?: list, unitAmount: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information about the invoice. Where possible, Codat links to a data field in the accounting platform that is publicly available. This means that the contents of the note field are included when an invoice is emailed from the accounting platform to the customer. (nullable)
  --paid-on-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --payment-allocations: list # An array of payment allocations. (nullable) — item shape: {allocation: record, payment: record}
  --sales-order-refs: list<string> # List of references to related Sales orders. (nullable)
  status: string@status-completer-1 # Current state of the invoice: - `Draft` - Invoice hasn't been submitted to the supplier. It may be in a pending state or is scheduled for future submission, for example by email. - `Submitted` - Invoice is no longer a draft. It has been processed and, or, sent to the customer. In this state, it will impact the ledger. It also has no payments made against it (amountDue == totalAmount). - `PartiallyPaid` - The balance paid against the invoice is positive, but less than the total invoice amount (0 < amountDue < totalAmount). - `Paid` - Invoice is paid in full. This includes if the invoice has been credited or overpaid (amountDue == 0). - `Void` - An invoice can become Void when it's deleted, refunded, written off, or cancelled. A voided invoice may still be PartiallyPaid, and so all outstanding amounts on voided invoices are removed from the accounts receivable account.
  --sub-total: float # Total amount of the invoice excluding any taxes. (nullable)
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  total_amount: float # Amount of the invoice, inclusive of tax.
  --total-discount: float # Numerical value of discounts applied to the invoice. (nullable)
  total_tax_amount: float # Amount of tax on the invoice.
  --withholding-tax: list # nullable — item shape: {amount: float, name: string}
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/invoices/{invoice_id}") $qp)
  let req_body = {"additionalTaxAmount": $additional_tax_amount, "additionalTaxPercentage": $additional_tax_percentage, "amountDue": $amount_due, "currency": $currency, "currencyRate": $currency_rate, "customerRef": $customer_ref, "discountPercentage": $discount_percentage, "dueDate": $due_date, "id": $id, "invoiceNumber": $invoice_number, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paidOnDate": $paid_on_date, "paymentAllocations": $payment_allocations, "salesOrderRefs": $sales_order_refs, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount, "withholdingTax": $withholding_tax} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Push invoice attachment
#
# POST /companies/{companyId}/connections/{connectionId}/push/invoices/{invoiceId}/attachment
# operationId: upload-invoice-attachment
export def "companies-connections-push-invoices-attachment upload" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/invoices/{invoice_id}/attachment"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Create item
#
# POST /companies/{companyId}/connections/{connectionId}/push/items
# operationId: create-item
# --billItem shape: {accountRef?: record, description?: string, taxRateRef?: record, unitPrice?: float}
# --invoiceItem shape: {accountRef?: record, description?: string, taxRateRef?: record, unitPrice?: float}
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-items create" [
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
  --timeout-in-minutes: int # format: int32
  --bill-item: record # Item details that are only for bills. — shape: {accountRef?: record, description?: string, taxRateRef?: record, unitPrice?: float}
  --code: string # Friendly reference for the item. (nullable)
  --id: string # Identifier for the item that is unique to a company in the accounting platform.
  --invoice-item: record # Item details that are only for bills. — shape: {accountRef?: record, description?: string, taxRateRef?: record, unitPrice?: float}
  --is-bill-item: oneof<nothing, bool> # Whether you can use this item for bills.
  --is-invoice-item: oneof<nothing, bool> # Whether you can use this item for invoices.
  item_status: string@item-status-completer # Current state of the item, either: - `Active`: Available for use - `Archived`: Unavailable - `Unknown` Due to a [limitation in Xero's API](https://docs.codat.io/integrations/accounting/xero/xero-faq#why-do-all-of-my-items-from-xero-have-their-status-as-unknown), all items from Xero are mapped as `Unknown`.
  --metadata: record # shape: {isDeleted?: bool}
  --name: string # Name of the item in the accounting platform. (nullable)
  type: any
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/items") $qp)
  let req_body = {"billItem": $bill_item, "code": $code, "id": $id, "invoiceItem": $invoice_item, "isBillItem": $is_bill_item, "isInvoiceItem": $is_invoice_item, "itemStatus": $item_status, "metadata": $metadata, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create journal entry
#
# POST /companies/{companyId}/connections/{connectionId}/push/journalEntries
# operationId: create-journal-entry
# --journalLines item shape: {accountRef?: record, currency?: string, description?: string, netAmount: float, tracking?: record}
# --journalRef shape: {id: string, name?: string}
# --metadata shape: {isDeleted?: bool}
# --recordRef shape: {dataType?: string, id?: string}
# --supplementalData shape: {content?: record}
export def "companies-connections-push-journal-entries create-entry" [
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
  --timeout-in-minutes: int # format: int32
  --created-on: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --description: string # Optional description of the journal entry. (nullable)
  --id: string # Unique identifier of the journal entry for the company in the accounting platform.
  --journal-lines: list # An array of journal lines. (nullable) — item shape: {accountRef?: record, currency?: string, description?: string, netAmount: float, tracking?: record}
  --journal-ref: record # Links journal entries to the relevant journal in accounting integrations that use multi-book accounting (multiple journals). — shape: {id: string, name?: string}
  --metadata: record # shape: {isDeleted?: bool}
  --posted-on: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --record-ref: record # Links to the underlying record or data type. Found on: - Journal entries - Account transactions - Invoices - Transfers — shape: {dataType?: string, id?: string}
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --updated-on: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/journalEntries") $qp)
  let req_body = {"createdOn": $created_on, "description": $description, "id": $id, "journalLines": $journal_lines, "journalRef": $journal_ref, "metadata": $metadata, "postedOn": $posted_on, "recordRef": $record_ref, "supplementalData": $supplemental_data, "updatedOn": $updated_on} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete journal entry
#
# DELETE /companies/{companyId}/connections/{connectionId}/push/journalEntries/{journalEntryId}
# operationId: delete-journal-entry
export def "companies-connections-push-journal-entries delete-entry" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), journal_entry_id: (encode-path-segment $journal_entry_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/journalEntries/{journal_entry_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create journal
#
# POST /companies/{companyId}/connections/{connectionId}/push/journals
# operationId: push-journal
# --metadata shape: {isDeleted?: bool}
export def "companies-connections-push-journals push" [
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
  --timeout-in-minutes: int # format: int32
  --created-on: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --has-children: oneof<nothing, bool> # If the journal has child journals, this value is true. If it doesn’t, it is false.
  --id: string # Journal ID.
  --journal-code: string # Native journal number or code. (nullable)
  --metadata: record # shape: {isDeleted?: bool}
  --name: string # Journal name. The maximum length for a journal name is 256 characters. All characters above that number will be truncated. (nullable)
  --parent-id: string # Parent journal ID. If the journal is a parent journal, this value is not present. (nullable)
  --status: string@status-completer-3 # Current journal status.
  --type: string # The type of the journal. (nullable)
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/journals") $qp)
  let req_body = {"createdOn": $created_on, "hasChildren": $has_children, "id": $id, "journalCode": $journal_code, "metadata": $metadata, "name": $name, "parentId": $parent_id, "status": $status, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create payment
#
# POST /companies/{companyId}/connections/{connectionId}/push/payments
# operationId: create-payment
# --accountRef shape: {id?: string, name?: string}
# --customerRef shape: {companyName?: string, id: string}
# --lines item shape: {allocatedOnDate?: string, amount: float, links?: list}
# --metadata shape: {isDeleted?: bool}
# --paymentMethodRef shape: {id?: string, name?: string}
# --supplementalData shape: {content?: record}
export def "companies-connections-push-payments create" [
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
  --timeout-in-minutes: int # format: int32
  --account-ref: record # Data types that reference an account, for example bill and invoice line items, use an accountRef that includes the ID and name of the linked account. — shape: {id?: string, name?: string}
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --customer-ref: record # shape: {companyName?: string, id: string}
  date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the payment, unique to the company in the accounting platform.
  --lines: list # An array of payment lines. (nullable) — item shape: {allocatedOnDate?: string, amount: float, links?: list}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information associated with the payment. (nullable)
  --payment-method-ref: record # shape: {id?: string, name?: string}
  --reference: string # Friendly reference for the payment. (nullable)
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --total-amount: float # Amount of the payment in the payment currency. This value should never change and represents the amount of money paid into the customer's account.
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/payments") $qp)
  let req_body = {"accountRef": $account_ref, "currency": $currency, "currencyRate": $currency_rate, "customerRef": $customer_ref, "date": $date, "id": $id, "lines": $lines, "metadata": $metadata, "note": $note, "paymentMethodRef": $payment_method_ref, "reference": $reference, "supplementalData": $supplemental_data, "totalAmount": $total_amount} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create purchase order
#
# POST /companies/{companyId}/connections/{connectionId}/push/purchaseOrders
# operationId: create-purchase-order
# --lineItems item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, itemRef?: record, quantity?: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, trackingCategoryRefs?: list, unitAmount?: float}
# --metadata shape: {isDeleted?: bool}
# --shipTo shape: {address?: record, contact?: record}
# --supplierRef shape: {id: string, supplierName?: string}
export def "companies-connections-push-purchase-orders create" [
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
  --timeout-in-minutes: int # format: int32
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --delivery-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --expected-delivery-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the purchase order, unique for the company in the accounting platform.
  --issue-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # Array of line items. (nullable) — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, itemRef?: record, quantity?: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, trackingCategoryRefs?: list, unitAmount?: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information associated with the purchase order. (nullable)
  --payment-due-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --purchase-order-number: string # Friendly reference for the purchase order, commonly generated by the accounting platform. (nullable)
  --ship-to: record # Delivery details for any goods that have been ordered. — shape: {address?: record, contact?: record}
  --status: string@status-completer-4 # Current state of the purchase order
  --sub-total: float # Total amount of the purchase order, including discounts but excluding tax.
  --supplier-ref: record # Reference to the supplier the record relates to. — shape: {id: string, supplierName?: string}
  --total-amount: float # Total amount of the purchase order, including discounts and tax.
  --total-discount: float # Total value of any discounts applied to the purchase order.
  --total-tax-amount: float # Total amount of tax included in the purchase order.
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/purchaseOrders") $qp)
  let req_body = {"currency": $currency, "currencyRate": $currency_rate, "deliveryDate": $delivery_date, "expectedDeliveryDate": $expected_delivery_date, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentDueDate": $payment_due_date, "purchaseOrderNumber": $purchase_order_number, "shipTo": $ship_to, "status": $status, "subTotal": $sub_total, "supplierRef": $supplier_ref, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update purchase order
#
# PUT /companies/{companyId}/connections/{connectionId}/push/purchaseOrders/{purchaseOrderId}
# operationId: update-purchase-order
# --lineItems item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, itemRef?: record, quantity?: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, trackingCategoryRefs?: list, unitAmount?: float}
# --metadata shape: {isDeleted?: bool}
# --shipTo shape: {address?: record, contact?: record}
# --supplierRef shape: {id: string, supplierName?: string}
export def "companies-connections-push-purchase-orders update" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --delivery-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --expected-delivery-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --id: string # Identifier for the purchase order, unique for the company in the accounting platform.
  --issue-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --line-items: list # Array of line items. (nullable) — item shape: {accountRef?: record, description?: string, discountAmount?: float, discountPercentage?: float, itemRef?: record, quantity?: float, subTotal?: float, taxAmount?: float, taxRateRef?: record, totalAmount?: float, trackingCategoryRefs?: list, unitAmount?: float}
  --metadata: record # shape: {isDeleted?: bool}
  --note: string # Any additional information associated with the purchase order. (nullable)
  --payment-due-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --purchase-order-number: string # Friendly reference for the purchase order, commonly generated by the accounting platform. (nullable)
  --ship-to: record # Delivery details for any goods that have been ordered. — shape: {address?: record, contact?: record}
  --status: string@status-completer-4 # Current state of the purchase order
  --sub-total: float # Total amount of the purchase order, including discounts but excluding tax.
  --supplier-ref: record # Reference to the supplier the record relates to. — shape: {id: string, supplierName?: string}
  --total-amount: float # Total amount of the purchase order, including discounts and tax.
  --total-discount: float # Total value of any discounts applied to the purchase order.
  --total-tax-amount: float # Total amount of tax included in the purchase order.
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), purchase_order_id: (encode-path-segment $purchase_order_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/purchaseOrders/{purchase_order_id}") $qp)
  let req_body = {"currency": $currency, "currencyRate": $currency_rate, "deliveryDate": $delivery_date, "expectedDeliveryDate": $expected_delivery_date, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentDueDate": $payment_due_date, "purchaseOrderNumber": $purchase_order_number, "shipTo": $ship_to, "status": $status, "subTotal": $sub_total, "supplierRef": $supplier_ref, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create suppliers
#
# POST /companies/{companyId}/connections/{connectionId}/push/suppliers
# operationId: create-supplier
# --addresses item shape: {city?: string, country?: string, line1?: string, line2?: string, postalCode?: string, region?: string, type: "Unknown"|"Billing"|"Delivery"}
# --metadata shape: {isDeleted?: bool}
# --supplementalData shape: {content?: record}
export def "companies-connections-push-suppliers create" [
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
  --timeout-in-minutes: int # format: int32
  --addresses: list # An array of Addresses. (nullable) — item shape: {city?: string, country?: string, line1?: string, line2?: string, postalCode?: string, region?: string, type: "Unknown"|"Billing"|"Delivery"}
  --contact-name: string # Name of the main contact for the supplier. (nullable)
  --default-currency: string # Default currency the supplier's transactional data is recorded in. (nullable)
  --email-address: string # Email address that the supplier may be contacted on. (nullable)
  --id: string # Identifier for the supplier, unique to the company in the accounting platform.
  --metadata: record # shape: {isDeleted?: bool}
  --phone: string # Phone number that the supplier may be contacted on. (nullable)
  --registration-number: string # Company number of the supplier. In the UK, this is typically the company registration number issued by Companies House. (nullable)
  status: string@status-completer-3 # Status of the supplier.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --supplier-name: string # Name of the supplier as recorded in the accounting system, typically the company name. (nullable)
  --tax-number: string # Supplier's company tax number. (nullable)
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/suppliers") $qp)
  let req_body = {"addresses": $addresses, "contactName": $contact_name, "defaultCurrency": $default_currency, "emailAddress": $email_address, "id": $id, "metadata": $metadata, "phone": $phone, "registrationNumber": $registration_number, "status": $status, "supplementalData": $supplemental_data, "supplierName": $supplier_name, "taxNumber": $tax_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update supplier
#
# PUT /companies/{companyId}/connections/{connectionId}/push/suppliers/{supplierId}
# operationId: put-supplier
# --addresses item shape: {city?: string, country?: string, line1?: string, line2?: string, postalCode?: string, region?: string, type: "Unknown"|"Billing"|"Delivery"}
# --metadata shape: {isDeleted?: bool}
# --supplementalData shape: {content?: record}
export def "companies-connections-push-suppliers update" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --addresses: list # An array of Addresses. (nullable) — item shape: {city?: string, country?: string, line1?: string, line2?: string, postalCode?: string, region?: string, type: "Unknown"|"Billing"|"Delivery"}
  --contact-name: string # Name of the main contact for the supplier. (nullable)
  --default-currency: string # Default currency the supplier's transactional data is recorded in. (nullable)
  --email-address: string # Email address that the supplier may be contacted on. (nullable)
  --id: string # Identifier for the supplier, unique to the company in the accounting platform.
  --metadata: record # shape: {isDeleted?: bool}
  --phone: string # Phone number that the supplier may be contacted on. (nullable)
  --registration-number: string # Company number of the supplier. In the UK, this is typically the company registration number issued by Companies House. (nullable)
  status: string@status-completer-3 # Status of the supplier.
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --supplier-name: string # Name of the supplier as recorded in the accounting system, typically the company name. (nullable)
  --tax-number: string # Supplier's company tax number. (nullable)
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), supplier_id: (encode-path-segment $supplier_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/suppliers/{supplier_id}") $qp)
  let req_body = {"addresses": $addresses, "contactName": $contact_name, "defaultCurrency": $default_currency, "emailAddress": $email_address, "id": $id, "metadata": $metadata, "phone": $phone, "registrationNumber": $registration_number, "status": $status, "supplementalData": $supplemental_data, "supplierName": $supplier_name, "taxNumber": $tax_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create transfer
#
# POST /companies/{companyId}/connections/{connectionId}/push/transfers
# operationId: create-transfer
# --contactRef shape: {dataType?: string, id: string}
# --from shape: {accountRef?: record, amount?: float, currency?: string}
# --metadata shape: {isDeleted?: bool}
# --supplementalData shape: {content?: record}
# --to shape: {accountRef?: record, amount?: float, currency?: string}
# --trackingCategoryRefs item shape: {id: string, name?: string}
export def "companies-connections-push-transfers create" [
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
  --contact-ref: record # The customer or supplier for the transfer, if available. — shape: {dataType?: string, id: string}
  --date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --deposited-record-refs: list<string> # nullable
  --description: string # Description of the transfer. (nullable)
  --body-from: record # shape: {accountRef?: record, amount?: float, currency?: string}
  --id: string # Unique identifier for the transfer.
  --metadata: record # shape: {isDeleted?: bool}
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --body-to: record # shape: {accountRef?: record, amount?: float, currency?: string}
  --tracking-category-refs: list # Reference to the tracking categories this transfer is being tracked against. (nullable) — item shape: {id: string, name?: string}
]: any -> record<data: record, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/transfers"))
  let req_body = {"contactRef": $contact_ref, "date": $date, "depositedRecordRefs": $deposited_record_refs, "description": $description, "from": $body_from, "id": $id, "metadata": $metadata, "supplementalData": $supplemental_data, "to": $body_to, "trackingCategoryRefs": $tracking_category_refs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List accounts
#
# GET /companies/{companyId}/data/accounts
# operationId: list-accounts
export def "companies-data-accounts list" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/accounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get account
#
# GET /companies/{companyId}/data/accounts/{accountId}
# DEPRECATED
# operationId: get-account
@deprecated
export def "companies-data-accounts get" [
  company_id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), account_id: (encode-path-segment $account_id)} | format pattern "/companies/{company_id}/data/accounts/{account_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get bank account
#
# GET /companies/{companyId}/data/bankAccounts/{accountId}
# DEPRECATED
# operationId: get-all-bank-account
@deprecated
export def "companies-data-bank-accounts get-list" [
  company_id: any
  account_id: any
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
]: nothing -> record<accountName: string, accountNumber: string, availableBalance: float, balance: float, currency: string, fromDate: string, iban: string, id: string, institution: string, modifiedDate: record<modifiedDate: string>, nominalCode: string, overdraftLimit: float, sortCode: string, sourceModifiedDate: record<sourceModifiedDate: string>, toDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), account_id: (encode-path-segment $account_id)} | format pattern "/companies/{company_id}/data/bankAccounts/{account_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List all bank transactions
#
# GET /companies/{companyId}/data/bankAccounts/{accountId}/transactions
# operationId: list-bank-transactions
export def "companies-data-bank-accounts-transactions list" [
  company_id: any
  account_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), account_id: (encode-path-segment $account_id)} | format pattern "/companies/{company_id}/data/bankAccounts/{account_id}/transactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List bill credit notes
#
# GET /companies/{companyId}/data/billCreditNotes
# operationId: list-bill-credit-notes
export def "companies-data-bill-credit-notes list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/billCreditNotes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get bill credit note
#
# GET /companies/{companyId}/data/billCreditNotes/{billCreditNoteId}
# DEPRECATED
# operationId: get-bill-credit-note
@deprecated
export def "companies-data-bill-credit-notes get" [
  company_id: string
  bill_credit_note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), bill_credit_note_id: (encode-path-segment $bill_credit_note_id)} | format pattern "/companies/{company_id}/data/billCreditNotes/{bill_credit_note_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List bill payments
#
# GET /companies/{companyId}/data/billPayments
# operationId: list-bill-payments
export def "companies-data-bill-payments list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/billPayments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get bill payment
#
# GET /companies/{companyId}/data/billPayments/{billPaymentId}
# DEPRECATED
# operationId: get-bill-payments
@deprecated
export def "companies-data-bill-payments get" [
  company_id: string
  bill_payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), bill_payment_id: (encode-path-segment $bill_payment_id)} | format pattern "/companies/{company_id}/data/billPayments/{bill_payment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List bills
#
# GET /companies/{companyId}/data/bills
# operationId: list-bills
export def "companies-data-bills list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/bills") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get bill
#
# GET /companies/{companyId}/data/bills/{billId}
# operationId: get-bill
export def "companies-data-bills get" [
  company_id: string
  bill_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), bill_id: (encode-path-segment $bill_id)} | format pattern "/companies/{company_id}/data/bills/{bill_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List credit notes
#
# GET /companies/{companyId}/data/creditNotes
# operationId: list-credit-notes
export def "companies-data-credit-notes list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/creditNotes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get credit note
#
# GET /companies/{companyId}/data/creditNotes/{creditNoteId}
# DEPRECATED
# operationId: get-credit-note
@deprecated
export def "companies-data-credit-notes get" [
  company_id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), credit_note_id: (encode-path-segment $credit_note_id)} | format pattern "/companies/{company_id}/data/creditNotes/{credit_note_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List customers
#
# GET /companies/{companyId}/data/customers
# operationId: get-customers
export def "companies-data-customers list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/customers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get customer
#
# GET /companies/{companyId}/data/customers/{customerId}
# DEPRECATED
# operationId: get-customer
@deprecated
export def "companies-data-customers get" [
  company_id: string
  customer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), customer_id: (encode-path-segment $customer_id)} | format pattern "/companies/{company_id}/data/customers/{customer_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get balance sheet
#
# GET /companies/{companyId}/data/financials/balanceSheet
# operationId: get-balance-sheet
export def "companies-data-financials-balance-sheet get" [
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
  --period-length: int # format: int32
  --periods-to-compare: int # format: int32
  --start-month: string
]: nothing -> record<currency: string, earliestAvailableMonth: string, mostRecentAvailableMonth: string, reports: table<assets: record, date: string, equity: record, liabilities: record, netAssets: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "periodLength" $period_length "scalar") (serialize-qp "periodsToCompare" $periods_to_compare "scalar") (serialize-qp "startMonth" $start_month "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/financials/balanceSheet") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get cash flow statement
#
# GET /companies/{companyId}/data/financials/cashFlowStatement
# operationId: get-cash-flow-statement
export def "companies-data-financials-cash-flow-statement get" [
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
  --period-length: int # format: int32
  --periods-to-compare: int # format: int32
  --start-month: string
]: nothing -> record<currency: string, earliestAvailableMonth: string, mostRecentAvailableMonth: string, reportBasis: string, reportInput: string, reports: table<cashPayments: record, cashReceipts: record, fromDate: string, toDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "periodLength" $period_length "scalar") (serialize-qp "periodsToCompare" $periods_to_compare "scalar") (serialize-qp "startMonth" $start_month "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/financials/cashFlowStatement") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get profit and loss
#
# GET /companies/{companyId}/data/financials/profitAndLoss
# operationId: get-profit-and-loss
export def "companies-data-financials-profit-and-loss get" [
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
  --period-length: int # format: int32
  --periods-to-compare: int # format: int32
  --start-month: string
]: nothing -> record<currency: string, earliestAvailableMonth: string, mostRecentAvailableMonth: string, reportBasis: string, reports: table<costOfSales: record, expenses: record, fromDate: string, grossProfit: float, income: record, netOperatingProfit: float, netOtherIncome: float, netProfit: float, otherExpenses: record, otherIncome: record, toDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "periodLength" $period_length "scalar") (serialize-qp "periodsToCompare" $periods_to_compare "scalar") (serialize-qp "startMonth" $start_month "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/financials/profitAndLoss") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get company info
#
# GET /companies/{companyId}/data/info
# operationId: get-company-info
export def "companies-data-info get-company" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accountingPlatformRef: string, addresses: table<city: string, country: string, line1: string, line2: string, postalCode: string, region: string, type: string>, baseCurrency: string, companyLegalName: string, companyName: string, createdDate: string, financialYearStartDate: string, ledgerLockDate: string, phoneNumbers: table<number: string, type: string>, registrationNumber: string, sourceUrls: record, taxNumber: string, webLinks: table<type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/info"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Refresh company info
#
# POST /companies/{companyId}/data/info
# operationId: post-sync-info
export def "companies-data-info create-sync" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<companyId: string, completed: string, connectionId: string, dataType: string, datasetLogsUrl: string, errorMessage: string, id: string, isCompleted: bool, isErrored: bool, progress: int, requested: string, status: string, validationInformationUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/info"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List invoices
#
# GET /companies/{companyId}/data/invoices
# operationId: list-invoices
export def "companies-data-invoices list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/invoices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get invoice
#
# GET /companies/{companyId}/data/invoices/{invoiceId}
# DEPRECATED
# operationId: get-invoice
@deprecated
export def "companies-data-invoices get" [
  company_id: any
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/companies/{company_id}/data/invoices/{invoice_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get invoice as PDF
#
# GET /companies/{companyId}/data/invoices/{invoiceId}/pdf
# operationId: Download-invoice-pdf
export def "companies-data-invoices-pdf download" [
  company_id: any
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/companies/{company_id}/data/invoices/{invoice_id}/pdf"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List items
#
# GET /companies/{companyId}/data/items
# operationId: list-items
export def "companies-data-items list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/items") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get item
#
# GET /companies/{companyId}/data/items/{itemId}
# DEPRECATED
# operationId: get-item
@deprecated
export def "companies-data-items get" [
  company_id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), item_id: (encode-path-segment $item_id)} | format pattern "/companies/{company_id}/data/items/{item_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List journal entries
#
# GET /companies/{companyId}/data/journalEntries
# operationId: list-journal-entries
export def "companies-data-journal-entries list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/journalEntries") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get journal entry
#
# GET /companies/{companyId}/data/journalEntries/{journalEntryId}
# DEPRECATED
# operationId: get-journal-entry
@deprecated
export def "companies-data-journal-entries get-entry" [
  company_id: string
  journal_entry_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), journal_entry_id: (encode-path-segment $journal_entry_id)} | format pattern "/companies/{company_id}/data/journalEntries/{journal_entry_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List journals
#
# GET /companies/{companyId}/data/journals
# operationId: list-journals
export def "companies-data-journals list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/journals") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get journal
#
# GET /companies/{companyId}/data/journals/{journalId}
# DEPRECATED
# operationId: get-journal
@deprecated
export def "companies-data-journals get" [
  company_id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), journal_id: (encode-path-segment $journal_id)} | format pattern "/companies/{company_id}/data/journals/{journal_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List all payment methods
#
# GET /companies/{companyId}/data/paymentMethods
# DEPRECATED
# operationId: list-payment-methods
@deprecated
export def "companies-data-payment-methods list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/paymentMethods") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get payment method
#
# GET /companies/{companyId}/data/paymentMethods/{paymentMethodId}
# DEPRECATED
# operationId: get-payment-method
@deprecated
export def "companies-data-payment-methods get" [
  company_id: string
  payment_method_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), payment_method_id: (encode-path-segment $payment_method_id)} | format pattern "/companies/{company_id}/data/paymentMethods/{payment_method_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List payments
#
# GET /companies/{companyId}/data/payments
# operationId: list-payments
export def "companies-data-payments list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<any>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/payments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get payment
#
# GET /companies/{companyId}/data/payments/{paymentId}
# DEPRECATED
# operationId: get-payment
@deprecated
export def "companies-data-payments get" [
  company_id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), payment_id: (encode-path-segment $payment_id)} | format pattern "/companies/{company_id}/data/payments/{payment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List purchase orders
#
# GET /companies/{companyId}/data/purchaseOrders
# operationId: list-purchase-orders
export def "companies-data-purchase-orders list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/purchaseOrders") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get purchase order
#
# GET /companies/{companyId}/data/purchaseOrders/{purchaseOrderId}
# DEPRECATED
# operationId: get-purchase-order
@deprecated
export def "companies-data-purchase-orders get" [
  company_id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), purchase_order_id: (encode-path-segment $purchase_order_id)} | format pattern "/companies/{company_id}/data/purchaseOrders/{purchase_order_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List sales orders
#
# GET /companies/{companyId}/data/salesOrders
# operationId: list-sales-orders
export def "companies-data-sales-orders list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/salesOrders") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get sales order
#
# GET /companies/{companyId}/data/salesOrders/{salesOrderId}
# DEPRECATED
# operationId: get-sales-order
@deprecated
export def "companies-data-sales-orders get" [
  company_id: string
  sales_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), sales_order_id: (encode-path-segment $sales_order_id)} | format pattern "/companies/{company_id}/data/salesOrders/{sales_order_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List suppliers
#
# GET /companies/{companyId}/data/suppliers
# operationId: list-suppliers
export def "companies-data-suppliers list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/suppliers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get supplier
#
# GET /companies/{companyId}/data/suppliers/{supplierId}
# DEPRECATED
# operationId: get-supplier
@deprecated
export def "companies-data-suppliers get" [
  company_id: string
  supplier_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), supplier_id: (encode-path-segment $supplier_id)} | format pattern "/companies/{company_id}/data/suppliers/{supplier_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List all tax rates
#
# GET /companies/{companyId}/data/taxRates
# operationId: list-tax-rates
export def "companies-data-tax-rates list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/taxRates") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get tax rate
#
# GET /companies/{companyId}/data/taxRates/{taxRateId}
# DEPRECATED
# operationId: get-tax-rate
@deprecated
export def "companies-data-tax-rates get" [
  company_id: string
  tax_rate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), tax_rate_id: (encode-path-segment $tax_rate_id)} | format pattern "/companies/{company_id}/data/taxRates/{tax_rate_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List tracking categories
#
# GET /companies/{companyId}/data/trackingCategories
# operationId: list-tracking-categories
export def "companies-data-tracking-categories list" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> record<results: list<record>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/trackingCategories") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get tracking categories
#
# GET /companies/{companyId}/data/trackingCategories/{trackingCategoryId}
# DEPRECATED
# operationId: get-tracking-category
@deprecated
export def "companies-data-tracking-categories get-category" [
  company_id: string
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), tracking_category_id: (encode-path-segment $tracking_category_id)} | format pattern "/companies/{company_id}/data/trackingCategories/{tracking_category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Aged creditors report
#
# GET /companies/{companyId}/reports/agedCreditor
# operationId: get-aged-creditors-report
export def "companies-reports-aged-creditor get" [
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
  --report-date: string # Date the report is generated up to. (format: date)
  --number-of-periods: int # Number of periods to include in the report. (format: int32)
  --period-length-days: int # The length of period in days. (format: int32)
]: nothing -> record<data: table<agedCurrencyOutstanding: list, supplierId: string, supplierName: string>, generated: string, reportDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportDate" $report_date "scalar") (serialize-qp "numberOfPeriods" $number_of_periods "scalar") (serialize-qp "periodLengthDays" $period_length_days "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/reports/agedCreditor") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Aged creditors report available
#
# GET /companies/{companyId}/reports/agedCreditor/available
# operationId: is-aged-creditors-report-available
export def "companies-reports-aged-creditor-available get-is" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/reports/agedCreditor/available"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Aged debtors report
#
# GET /companies/{companyId}/reports/agedDebtor
# operationId: get-aged-debtors-report
export def "companies-reports-aged-debtor get" [
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
  --report-date: string # Date the report is generated up to. (format: date)
  --number-of-periods: int # Number of periods to include in the report. (format: int32)
  --period-length-days: int # The length of period in days. (format: int32)
]: nothing -> record<data: table<agedCurrencyOutstanding: list, customerId: string, customerName: string>, generated: string, reportDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportDate" $report_date "scalar") (serialize-qp "numberOfPeriods" $number_of_periods "scalar") (serialize-qp "periodLengthDays" $period_length_days "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/reports/agedDebtor") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Aged debtors report available
#
# GET /companies/{companyId}/reports/agedDebtor/available
# operationId: is-aged-debtor-report-available
export def "companies-reports-aged-debtor-available get-is" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/reports/agedDebtor/available"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
