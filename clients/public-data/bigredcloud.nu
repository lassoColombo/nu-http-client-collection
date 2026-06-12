# Auto-generated client for Big Red Cloud API vv1
# Source: https://api.apis.guru/v2/specs/bigredcloud.com/v1/openapi.json
# Auth: --token flag or $env.BIG_RED_CLOUD_API_TOKEN

const BASE_URL = "https://app.bigredcloud.com/api"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BIG_RED_CLOUD_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://app.bigredcloud.com/api"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts Get" } } | get name | first)
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

# Returns a list of company's Accounts. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" and "code" fields.
#
# GET /v1/accounts
# operationId: Accounts_Get
export def "accounts Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<accountGroup: string, accountType: string, code: string, description: string, id: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/accounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of company's Analysis Categories. Supports OData querying protocol. Filtering is allowed by "categoryTypeId" field. Ordering is allowed by "id" and "orderIndex" fields.
#
# GET /v1/analysisCategories
# operationId: AnalysisCategories_Get
export def "analysis-categories Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<accountCode: string, accountId: int, categoryTypeId: int, description: string, id: int, orderIndex: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/analysisCategories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of company's Bank Account. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" and "acCode" fields.
#
# GET /v1/bankAccounts
# operationId: BankAccounts_Get
export def "bank-accounts Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<acCode: string, accountName: string, accountNumber: string, address: list, bankFeedSource: int, businessIdentifierCodes: string, categoryId: int, creditorScheme: string, details: string, id: int, internationalBankAccountNumber: string, isDefaultBank: bool, lastChq: string, nominalAcCode: string, sortCode: string, timestamp: string>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/bankAccounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Bank Account.
#
# POST /v1/bankAccounts
# operationId: BankAccounts_Post
export def "bank-accounts Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acCode: string
  --accountName: string
  --accountNumber: string
  --address: list
  --bankFeedSource: int # format: int32
  --businessIdentifierCodes: string
  --categoryId: int # format: int64
  --creditorScheme: string
  --details: string
  --id: int # format: int64
  --internationalBankAccountNumber: string
  --isDefaultBank: oneof<nothing, bool>
  --lastChq: string
  --nominalAcCode: string
  --oBalance: float # format: double
  --sortCode: string
  --timestamp: string # format: byte
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/bankAccounts")
  let body = {acCode: $acCode, accountName: $accountName, accountNumber: $accountNumber, address: $address, bankFeedSource: $bankFeedSource, businessIdentifierCodes: $businessIdentifierCodes, categoryId: $categoryId, creditorScheme: $creditorScheme, details: $details, id: $id, internationalBankAccountNumber: $internationalBankAccountNumber, isDefaultBank: $isDefaultBank, lastChq: $lastChq, nominalAcCode: $nominalAcCode, oBalance: $oBalance, sortCode: $sortCode, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Processes a batch of Bank Accounts.
#
# PUT /v1/bankAccounts/batch
# operationId: BankAccounts_ProcessBatch
export def "bank-accounts-batch ProcessBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/bankAccounts/batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes an existing Bank Account.
#
# DELETE /v1/bankAccounts/{id}
# operationId: BankAccounts_Delete
export def "bank-accounts Delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Bank Account to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/bankAccounts/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about a single Bank Account.
#
# GET /v1/bankAccounts/{id}
export def "bank-accounts get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acCode: string, accountName: string, accountNumber: string, address: list<string>, bankFeedSource: int, businessIdentifierCodes: string, categoryId: int, creditorScheme: string, details: string, id: int, internationalBankAccountNumber: string, isDefaultBank: bool, lastChq: string, nominalAcCode: string, oBalance: float, sortCode: string, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/bankAccounts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing Bank Account.
#
# PUT /v1/bankAccounts/{id}
# operationId: BankAccounts_Put
export def "bank-accounts Put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acCode: string
  --accountName: string
  --accountNumber: string
  --address: list
  --bankFeedSource: int # format: int32
  --businessIdentifierCodes: string
  --categoryId: int # format: int64
  --creditorScheme: string
  --details: string
  --body-id: int # format: int64
  --internationalBankAccountNumber: string
  --isDefaultBank: oneof<nothing, bool>
  --lastChq: string
  --nominalAcCode: string
  --oBalance: float # format: double
  --sortCode: string
  --timestamp: string # format: byte
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/bankAccounts/($id)")
  let body = {acCode: $acCode, accountName: $accountName, accountNumber: $accountNumber, address: $address, bankFeedSource: $bankFeedSource, businessIdentifierCodes: $businessIdentifierCodes, categoryId: $categoryId, creditorScheme: $creditorScheme, details: $details, id: $body_id, internationalBankAccountNumber: $internationalBankAccountNumber, isDefaultBank: $isDefaultBank, lastChq: $lastChq, nominalAcCode: $nominalAcCode, oBalance: $oBalance, sortCode: $sortCode, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of global Book Transactions' Types. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/bookTranTypes
# operationId: BookTranTypes_Get
export def "book-tran-types Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<code: string, description: string, id: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/bookTranTypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of company's Cash Payments. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/cashPayments
# operationId: CashPayments_Get
export def "cash-payments Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<acCode: string, acEntries: list, bankAccountCode: string, bankAccountId: int, bookTranTypeId: int, customFields: list, detailCollection: list, discount: float, entryDate: string, id: int, ledger: float, lodgement: float, note: string, plaidTransactionId: string, procDate: string, supplierId: int, timestamp: string, total: float, unallocated: float>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/cashPayments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Cash Payment.
#
# POST /v1/cashPayments
# operationId: CashPayments_Post
# --acEntries item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
export def "cash-payments Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acCode: string
  --acEntries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --bankAccountCode: string
  --bankAccountId: int # format: int64
  --bookTranTypeId: int # format: int64
  --customFields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --detailCollection: list
  --discount: float # format: double
  --entryDate: string # format: date-time
  --id: int # format: int64
  --ledger: float # format: double
  --lodgement: float # format: double
  --note: string
  --plaidTransactionId: string
  --procDate: string # format: date-time
  --supplierId: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/cashPayments")
  let body = {acCode: $acCode, acEntries: $acEntries, bankAccountCode: $bankAccountCode, bankAccountId: $bankAccountId, bookTranTypeId: $bookTranTypeId, customFields: $customFields, detailCollection: $detailCollection, discount: $discount, entryDate: $entryDate, id: $id, ledger: $ledger, lodgement: $lodgement, note: $note, plaidTransactionId: $plaidTransactionId, procDate: $procDate, supplierId: $supplierId, timestamp: $timestamp, total: $total} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Processes a batch of Cash Payments.
#
# PUT /v1/cashPayments/batch
# operationId: CashPayments_ProcessBatch
export def "cash-payments-batch ProcessBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/cashPayments/batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes an existing Cash Payment.
#
# DELETE /v1/cashPayments/{id}
# operationId: CashPayments_Delete
export def "cash-payments Delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Cash Receipt to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/cashPayments/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about a single Cash Payment.
#
# GET /v1/cashPayments/{id}
export def "cash-payments get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acCode: string, acEntries: table<accountCode: string, analysisCategoryId: int, description: string, id: int, value: float>, bankAccountCode: string, bankAccountId: int, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, detailCollection: list<string>, discount: float, entryDate: string, id: int, ledger: float, lodgement: float, note: string, plaidTransactionId: string, procDate: string, supplierId: int, timestamp: string, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/cashPayments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing Cash Payment.
#
# PUT /v1/cashPayments/{id}
# operationId: CashPayments_Put
# --acEntries item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
export def "cash-payments Put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acCode: string
  --acEntries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --bankAccountCode: string
  --bankAccountId: int # format: int64
  --bookTranTypeId: int # format: int64
  --customFields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --detailCollection: list
  --discount: float # format: double
  --entryDate: string # format: date-time
  --body-id: int # format: int64
  --ledger: float # format: double
  --lodgement: float # format: double
  --note: string
  --plaidTransactionId: string
  --procDate: string # format: date-time
  --supplierId: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/cashPayments/($id)")
  let body = {acCode: $acCode, acEntries: $acEntries, bankAccountCode: $bankAccountCode, bankAccountId: $bankAccountId, bookTranTypeId: $bookTranTypeId, customFields: $customFields, detailCollection: $detailCollection, discount: $discount, entryDate: $entryDate, id: $body_id, ledger: $ledger, lodgement: $lodgement, note: $note, plaidTransactionId: $plaidTransactionId, procDate: $procDate, supplierId: $supplierId, timestamp: $timestamp, total: $total} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of company's Cash Receipts. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/cashReceipts
# operationId: CashReceipts_Get
export def "cash-receipts Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<acCode: string, acEntries: list, bookTranTypeId: int, customFields: list, customerId: int, detailCollection: list, discount: float, entryDate: string, id: int, ledger: float, note: string, plaidTransactionId: string, procDate: string, timestamp: string, total: float, unallocated: float, vatEntries: list, vatTypeId: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/cashReceipts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Cash Receipt.
#
# POST /v1/cashReceipts
# operationId: CashReceipts_Post
# --acEntries item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --vatEntries item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
export def "cash-receipts Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acCode: string
  --acEntries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --bookTranTypeId: int # format: int64
  --customFields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customerId: int # format: int64
  --detailCollection: list
  --discount: float # format: double
  --entryDate: string # format: date-time
  --id: int # format: int64
  --ledger: float # format: double
  --note: string
  --plaidTransactionId: string
  --procDate: string # format: date-time
  --timestamp: string # format: byte
  --total: float # format: double
  --unallocated: float # format: double
  --vatEntries: list # item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
  --vatTypeId: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/cashReceipts")
  let body = {acCode: $acCode, acEntries: $acEntries, bookTranTypeId: $bookTranTypeId, customFields: $customFields, customerId: $customerId, detailCollection: $detailCollection, discount: $discount, entryDate: $entryDate, id: $id, ledger: $ledger, note: $note, plaidTransactionId: $plaidTransactionId, procDate: $procDate, timestamp: $timestamp, total: $total, unallocated: $unallocated, vatEntries: $vatEntries, vatTypeId: $vatTypeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Processes a batch of Cash Receipts.
#
# PUT /v1/cashReceipts/batch
# operationId: CashReceipts_ProcessBatch
export def "cash-receipts-batch ProcessBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/cashReceipts/batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes an existing Cash Receipt.
#
# DELETE /v1/cashReceipts/{id}
# operationId: CashReceipts_Delete
export def "cash-receipts Delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Cash Receipt to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/cashReceipts/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about a single Cash Receipt.
#
# GET /v1/cashReceipts/{id}
export def "cash-receipts get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acCode: string, acEntries: table<accountCode: string, analysisCategoryId: int, description: string, id: int, value: float>, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, customerId: int, detailCollection: list<string>, discount: float, entryDate: string, id: int, ledger: float, note: string, plaidTransactionId: string, procDate: string, timestamp: string, total: float, unallocated: float, vatEntries: table<amount: float, id: int, percentage: float, vatRateId: int>, vatTypeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/cashReceipts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing Cash Receipt.
#
# PUT /v1/cashReceipts/{id}
# operationId: CashReceipts_Put
# --acEntries item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --vatEntries item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
export def "cash-receipts Put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acCode: string
  --acEntries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --bookTranTypeId: int # format: int64
  --customFields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customerId: int # format: int64
  --detailCollection: list
  --discount: float # format: double
  --entryDate: string # format: date-time
  --body-id: int # format: int64
  --ledger: float # format: double
  --note: string
  --plaidTransactionId: string
  --procDate: string # format: date-time
  --timestamp: string # format: byte
  --total: float # format: double
  --unallocated: float # format: double
  --vatEntries: list # item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
  --vatTypeId: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/cashReceipts/($id)")
  let body = {acCode: $acCode, acEntries: $acEntries, bookTranTypeId: $bookTranTypeId, customFields: $customFields, customerId: $customerId, detailCollection: $detailCollection, discount: $discount, entryDate: $entryDate, id: $body_id, ledger: $ledger, note: $note, plaidTransactionId: $plaidTransactionId, procDate: $procDate, timestamp: $timestamp, total: $total, unallocated: $unallocated, vatEntries: $vatEntries, vatTypeId: $vatTypeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of company's Category Types. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/categoryTypes
# operationId: CategoryTypes_Get
export def "category-types Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<description: string, id: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/categoryTypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of company settings. Supports OData querying protocol. Filtering is forbidden.
#
# GET /v1/companySettings
# operationId: CompanySettings_Get
export def "company-settings Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<enableVOCRReporting: bool, id: int, useAllocations: bool, value: string, vocrSettingValue: bool>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/companySettings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the company configuration settings.
#
# GET /v1/companySetupConfig
# operationId: CompanySetupConfig_Get
export def "company-setup-config Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<financialYear: record<firstMonth: int, startMonth: int, startYear: int>, generalDetails: record<companyAddresses: list<string>, companyName: string, currencyCode: string, currencyDescription: string, currencyId: int, currentcySymbol: string, emails: list<string>, faxes: list<string>, phones: list<string>, regionDescription: string, regionId: int, vatReg: string>, options: record<allowEntryOfGrossPriceInInvoicing: bool, creditInputForReverseChargeVAT: bool, creditNoteJournalAgeingName: string, creditNoteJournalAgeingValue: int, discrepancyAllowed: float, enableVOCRReporting: bool, marginVatScheme: bool, printOSItemsOnly: bool, purchasesVatAnalysisType: int, salesVatAnalysisType: int, useAllocations: bool, useNominal: bool, useNominalCode: bool, vocrSettingValue: bool>, referenceSettings: record<creditorsJournal: bool, debtorsJournal: bool, purchases: bool, sales: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/companySetupConfig")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the company option setting.
#
# GET /v1/companySetupConfig/getCompanyOptions
# operationId: CompanySetupConfig_GetCompanyOptions
export def "company-setup-config-get-company-options GetCompanyOptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allowEntryOfGrossPriceInInvoicing: bool, creditInputForReverseChargeVAT: bool, creditNoteJournalAgeingName: string, creditNoteJournalAgeingValue: int, discrepancyAllowed: float, enableVOCRReporting: bool, marginVatScheme: bool, printOSItemsOnly: bool, purchasesVatAnalysisType: int, salesVatAnalysisType: int, useAllocations: bool, useNominal: bool, useNominalCode: bool, vocrSettingValue: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/companySetupConfig/getCompanyOptions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the financial year.
#
# GET /v1/companySetupConfig/getFinancialYear
# operationId: CompanySetupConfig_GetFinancialYear
export def "company-setup-config-get-financial-year GetFinancialYear" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<firstMonth: int, startMonth: int, startYear: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/companySetupConfig/getFinancialYear")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of company's Customers. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" and "code" fields.
#
# GET /v1/customers
# operationId: Customers_Get
export def "customers Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<accountName: string, accountNumber: string, additionalEmails: list, address: list, authCode: string, bank: record, businessIdentifierCode: string, code: string, contact: string, delivery: list, eFTReference: string, email: string, fax: string, id: int, internationalBankAccountNumber: string, mobile: string, name: string, ourCode: string, ownerTypeId: int, phone: string, timestamp: string, vatAnalysisTypeId: int, vatReg: string, vatType: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/customers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Customer.
#
# POST /v1/customers
# operationId: Customers_Post
# --bank shape: {branch?: string, id?: int, name?: string, sortCode?: string}
# --openingBalance shape: {currentMonth?: float, oneMonthOld?: float, threeMonthsOld?: float, twoMonthsOld?: float}
# --openingBalances item shape: {entryDate?: string, id?: int, isChanged?: bool, procDate?: string, reference?: string, timestamp?: string, total?: float, totalVAT?: float, unpaid?: float, vatEntries?: list}
export def "customers Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountName: string
  --accountNumber: string
  --additionalEmails: list
  --address: list
  --authCode: string
  --bank: record # shape: {branch?: string, id?: int, name?: string, sortCode?: string}
  --businessIdentifierCode: string
  --code: string
  --contact: string
  --delivery: list
  --eFTReference: string
  --email: string
  --fax: string
  --id: int # format: int64
  --internationalBankAccountNumber: string
  --ledgerBalance: float # format: double
  --mobile: string
  --name: string
  --openingBalance: record # shape: {currentMonth?: float, oneMonthOld?: float, threeMonthsOld?: float, twoMonthsOld?: float}
  --openingBalances: list # item shape: {entryDate?: string, id?: int, isChanged?: bool, procDate?: string, reference?: string, timestamp?: string, total?: float, totalVAT?: float, unpaid?: float, vatEntries?: list}
  --ourCode: string
  --ownerTypeId: int # format: int64
  --phone: string
  --timestamp: string # format: byte
  --vatAnalysisTypeId: int # format: int64
  --vatReg: string
  --vatType: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/customers")
  let body = {accountName: $accountName, accountNumber: $accountNumber, additionalEmails: $additionalEmails, address: $address, authCode: $authCode, bank: $bank, businessIdentifierCode: $businessIdentifierCode, code: $code, contact: $contact, delivery: $delivery, eFTReference: $eFTReference, email: $email, fax: $fax, id: $id, internationalBankAccountNumber: $internationalBankAccountNumber, ledgerBalance: $ledgerBalance, mobile: $mobile, name: $name, openingBalance: $openingBalance, openingBalances: $openingBalances, ourCode: $ourCode, ownerTypeId: $ownerTypeId, phone: $phone, timestamp: $timestamp, vatAnalysisTypeId: $vatAnalysisTypeId, vatReg: $vatReg, vatType: $vatType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Processes a batch of Customers.
#
# PUT /v1/customers/batch
# operationId: Customers_ProcessBatch
export def "customers-batch ProcessBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/customers/batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes an existing Customer.
#
# DELETE /v1/customers/{id}
# operationId: Customers_Delete
export def "customers Delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Customer to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/customers/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about a single Customer. You may specify that Customer's ledger balance should be calculated.
#
# GET /v1/customers/{id}
export def "customers get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --needBalance: oneof<nothing, bool> # If "true" then Customer's ledger balance will be calculated; otherwise balance will be returned as 0.
]: nothing -> record<accountName: string, accountNumber: string, additionalEmails: list<string>, address: list<string>, authCode: string, bank: record<branch: string, id: int, name: string, sortCode: string>, businessIdentifierCode: string, code: string, contact: string, delivery: list<string>, eFTReference: string, email: string, fax: string, id: int, internationalBankAccountNumber: string, ledgerBalance: float, mobile: string, name: string, openingBalance: record<currentMonth: float, oneMonthOld: float, threeMonthsOld: float, twoMonthsOld: float>, openingBalances: table<entryDate: string, id: int, isChanged: bool, procDate: string, reference: string, timestamp: string, total: float, totalVAT: float, unpaid: float, vatEntries: list>, ourCode: string, ownerTypeId: int, phone: string, timestamp: string, vatAnalysisTypeId: int, vatReg: string, vatType: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "needBalance" $needBalance "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/customers/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing Customer.
#
# PUT /v1/customers/{id}
# operationId: Customers_Put
# --bank shape: {branch?: string, id?: int, name?: string, sortCode?: string}
# --openingBalance shape: {currentMonth?: float, oneMonthOld?: float, threeMonthsOld?: float, twoMonthsOld?: float}
# --openingBalances item shape: {entryDate?: string, id?: int, isChanged?: bool, procDate?: string, reference?: string, timestamp?: string, total?: float, totalVAT?: float, unpaid?: float, vatEntries?: list}
export def "customers Put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountName: string
  --accountNumber: string
  --additionalEmails: list
  --address: list
  --authCode: string
  --bank: record # shape: {branch?: string, id?: int, name?: string, sortCode?: string}
  --businessIdentifierCode: string
  --code: string
  --contact: string
  --delivery: list
  --eFTReference: string
  --email: string
  --fax: string
  --body-id: int # format: int64
  --internationalBankAccountNumber: string
  --ledgerBalance: float # format: double
  --mobile: string
  --name: string
  --openingBalance: record # shape: {currentMonth?: float, oneMonthOld?: float, threeMonthsOld?: float, twoMonthsOld?: float}
  --openingBalances: list # item shape: {entryDate?: string, id?: int, isChanged?: bool, procDate?: string, reference?: string, timestamp?: string, total?: float, totalVAT?: float, unpaid?: float, vatEntries?: list}
  --ourCode: string
  --ownerTypeId: int # format: int64
  --phone: string
  --timestamp: string # format: byte
  --vatAnalysisTypeId: int # format: int64
  --vatReg: string
  --vatType: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/customers/($id)")
  let body = {accountName: $accountName, accountNumber: $accountNumber, additionalEmails: $additionalEmails, address: $address, authCode: $authCode, bank: $bank, businessIdentifierCode: $businessIdentifierCode, code: $code, contact: $contact, delivery: $delivery, eFTReference: $eFTReference, email: $email, fax: $fax, id: $body_id, internationalBankAccountNumber: $internationalBankAccountNumber, ledgerBalance: $ledgerBalance, mobile: $mobile, name: $name, openingBalance: $openingBalance, openingBalances: $openingBalances, ourCode: $ourCode, ownerTypeId: $ownerTypeId, phone: $phone, timestamp: $timestamp, vatAnalysisTypeId: $vatAnalysisTypeId, vatReg: $vatReg, vatType: $vatType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of Customer's account transactions.
#
# GET /v1/customers/{itemId}/accountTrans
# operationId: Customers_GetAccountTrans
export def "customers-account-trans GetAccountTrans" [
  itemId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<bookTranId: int, bookTranTypeId: int, bookTransactionReference: string, bookTypeDesc: string, credit: float, debit: float, id: int, procDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/customers/($itemId)/accountTrans")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a Customer's opening balances, calculated for the next periods: current month, one month old, two months old, three and more months old.
#
# GET /v1/customers/{itemId}/openingBalance
# operationId: Customers_GetOpeningBalance
export def "customers-opening-balance GetOpeningBalance" [
  itemId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<currentMonth: float, oneMonthOld: float, threeMonthsOld: float, twoMonthsOld: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/customers/($itemId)/openingBalance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of Customer's opening balance transactions.
#
# GET /v1/customers/{itemId}/openingBalanceList
# operationId: Customers_GetOpeningBalanceList
export def "customers-opening-balance-list GetOpeningBalanceList" [
  itemId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<entryDate: string, id: int, isChanged: bool, procDate: string, reference: string, timestamp: string, total: float, totalVAT: float, unpaid: float, vatEntries: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/customers/($itemId)/openingBalanceList")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of Customer's quotes.
#
# GET /v1/customers/{itemId}/quotes
# operationId: Customers_GetQuotes
export def "customers-quotes GetQuotes" [
  itemId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<acCode: string, closedDate: string, comments: string, companyId: int, customFields: list<record>, customerOwnerId: int, customerOwnerName: string, ddNumber: string, deliveryList: string, deliveryTo: list<string>, entryDate: string, id: int, layoutType: int, note: string, poNumber: string, procDate: string, productTrans: list<record>, reference: string, saleInvoiceId: int, saleRepCode: string, saleRepId: int, timeStamp: string, total: float, totalNet: float, totalVat: float, vatTypeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/customers/($itemId)/quotes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sends a Statement email. If "toAddress" is not empty then email will be sent to this address. Otherwise email will be sent to Statement Customer's address.
#
# POST /v1/email/sendEmailStatement
# operationId: Email_SendEmailStatement
export def "email-send-email-statement SendEmailStatement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bccAddresses: list
  --customerId: int # format: int64
  --fromPeriod: string # format: date-time
  --messageBody: string
  --minimumBalance: float # format: double
  --toAddress: string
  --toPeriod: string # format: date-time
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/email/sendEmailStatement")
  let body = {bccAddresses: $bccAddresses, customerId: $customerId, fromPeriod: $fromPeriod, messageBody: $messageBody, minimumBalance: $minimumBalance, toAddress: $toAddress, toPeriod: $toPeriod} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sends a Quote email. If "toAddress" is not empty then email will be sent to this address. Otherwise email will be sent to Statement Customer's address.
#
# POST /v1/email/sendQuote
# operationId: Email_SendQuote
export def "email-send-quote SendQuote" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bccAddresses: list
  --messageBody: string
  --quoteId: int # format: int64
  --toAddress: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/email/sendQuote")
  let body = {bccAddresses: $bccAddresses, messageBody: $messageBody, quoteId: $quoteId, toAddress: $toAddress} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sends a Sales Invoice email. If "toAddress" is not empty then email will be sent to this address. Otherwise email will be sent to Sales Invoice Customer's address.
#
# POST /v1/email/sendSalesInvoice
# operationId: Email_SendSalesInvoice
export def "email-send-sales-invoice SendSalesInvoice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bccAddresses: list
  --messageBody: string
  --salesInvoiceId: int # format: int64
  --toAddress: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/email/sendSalesInvoice")
  let body = {bccAddresses: $bccAddresses, messageBody: $messageBody, salesInvoiceId: $salesInvoiceId, toAddress: $toAddress} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of global Owner Type Groups. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/ownerTypeGroups
# operationId: OwnerTypeGroups_Get
export def "owner-type-groups Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<description: string, id: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ownerTypeGroups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of global Owner Types. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/ownerTypes
# operationId: OwnerTypes_Get
export def "owner-types Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<description: string, id: int, recordTypeGroupId: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ownerTypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of company's Payments. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/payments
# operationId: Payments_Get
export def "payments Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<acCode: string, acEntries: list, bankAccountCode: string, bankAccountId: int, bookTranTypeId: int, customFields: list, detailCollection: list, discount: float, entryDate: string, id: int, note: string, plaidTransactionId: string, procDate: string, reference: string, supplierId: int, timestamp: string, total: float, transferBankCode: string, transferBankId: int, unallocated: float>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/payments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Payment.
#
# POST /v1/payments
# operationId: Payments_Post
# --acEntries item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
export def "payments Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acCode: string
  --acEntries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --bankAccountCode: string
  --bankAccountId: int # format: int64
  --bookTranTypeId: int # format: int64
  --customFields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --detailCollection: list
  --discount: float # format: double
  --entryDate: string # format: date-time
  --id: int # format: int64
  --note: string
  --plaidTransactionId: string
  --procDate: string # format: date-time
  --reference: string
  --supplierId: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --transferBankCode: string
  --transferBankId: int # format: int64
  --unallocated: float # format: double
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/payments")
  let body = {acCode: $acCode, acEntries: $acEntries, bankAccountCode: $bankAccountCode, bankAccountId: $bankAccountId, bookTranTypeId: $bookTranTypeId, customFields: $customFields, detailCollection: $detailCollection, discount: $discount, entryDate: $entryDate, id: $id, note: $note, plaidTransactionId: $plaidTransactionId, procDate: $procDate, reference: $reference, supplierId: $supplierId, timestamp: $timestamp, total: $total, transferBankCode: $transferBankCode, transferBankId: $transferBankId, unallocated: $unallocated} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Processes a batch of Payments.
#
# PUT /v1/payments/batch
# operationId: Payments_ProcessBatch
export def "payments-batch ProcessBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/payments/batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes an existing Payment.
#
# DELETE /v1/payments/{id}
# operationId: Payments_Delete
export def "payments Delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Payment to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/payments/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about a single Payments.
#
# GET /v1/payments/{id}
export def "payments get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acCode: string, acEntries: table<accountCode: string, analysisCategoryId: int, description: string, id: int, value: float>, bankAccountCode: string, bankAccountId: int, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, detailCollection: list<string>, discount: float, entryDate: string, id: int, note: string, plaidTransactionId: string, procDate: string, reference: string, supplierId: int, timestamp: string, total: float, transferBankCode: string, transferBankId: int, unallocated: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/payments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing Payment.
#
# PUT /v1/payments/{id}
# operationId: Payments_Put
# --acEntries item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
export def "payments Put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acCode: string
  --acEntries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --bankAccountCode: string
  --bankAccountId: int # format: int64
  --bookTranTypeId: int # format: int64
  --customFields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --detailCollection: list
  --discount: float # format: double
  --entryDate: string # format: date-time
  --body-id: int # format: int64
  --note: string
  --plaidTransactionId: string
  --procDate: string # format: date-time
  --reference: string
  --supplierId: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --transferBankCode: string
  --transferBankId: int # format: int64
  --unallocated: float # format: double
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/payments/($id)")
  let body = {acCode: $acCode, acEntries: $acEntries, bankAccountCode: $bankAccountCode, bankAccountId: $bankAccountId, bookTranTypeId: $bookTranTypeId, customFields: $customFields, detailCollection: $detailCollection, discount: $discount, entryDate: $entryDate, id: $body_id, note: $note, plaidTransactionId: $plaidTransactionId, procDate: $procDate, reference: $reference, supplierId: $supplierId, timestamp: $timestamp, total: $total, transferBankCode: $transferBankCode, transferBankId: $transferBankId, unallocated: $unallocated} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of global Product Types. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/productTypes
# operationId: ProductTypes_Get
export def "product-types Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<description: string, id: int, recordTypeGroupId: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/productTypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of company's Products. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" and "stockCode" fields.
#
# GET /v1/products
# operationId: Products_Get
export def "products Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<details: list, grossUnitPrice: bool, hasDefaultVatRate: bool, id: int, productTypeId: int, stockCode: string, timestamp: string, unitPrice: float, vatAnalysisTypeId: int, vatRateId: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/products")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Product.
#
# POST /v1/products
# operationId: Products_Post
export def "products Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --details: list
  --grossUnitPrice: oneof<nothing, bool>
  --hasDefaultVatRate: oneof<nothing, bool>
  --id: int # format: int64
  --productTypeId: int # format: int64
  --stockCode: string
  --timestamp: string # format: byte
  --unitPrice: float # format: double
  --vatAnalysisTypeId: int # format: int64
  --vatRateId: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/products")
  let body = {details: $details, grossUnitPrice: $grossUnitPrice, hasDefaultVatRate: $hasDefaultVatRate, id: $id, productTypeId: $productTypeId, stockCode: $stockCode, timestamp: $timestamp, unitPrice: $unitPrice, vatAnalysisTypeId: $vatAnalysisTypeId, vatRateId: $vatRateId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Processes a batch of Products.
#
# PUT /v1/products/batch
# operationId: Products_ProcessBatch
export def "products-batch ProcessBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/products/batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes an existing Product.
#
# DELETE /v1/products/{id}
# operationId: Products_Delete
export def "products Delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Product to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/products/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about a single Product.
#
# GET /v1/products/{id}
export def "products get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<details: list<string>, grossUnitPrice: bool, hasDefaultVatRate: bool, id: int, productTypeId: int, stockCode: string, timestamp: string, unitPrice: float, vatAnalysisTypeId: int, vatRateId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/products/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing Product.
#
# PUT /v1/products/{id}
# operationId: Products_Put
export def "products Put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --details: list
  --grossUnitPrice: oneof<nothing, bool>
  --hasDefaultVatRate: oneof<nothing, bool>
  --body-id: int # format: int64
  --productTypeId: int # format: int64
  --stockCode: string
  --timestamp: string # format: byte
  --unitPrice: float # format: double
  --vatAnalysisTypeId: int # format: int64
  --vatRateId: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/products/($id)")
  let body = {details: $details, grossUnitPrice: $grossUnitPrice, hasDefaultVatRate: $hasDefaultVatRate, id: $body_id, productTypeId: $productTypeId, stockCode: $stockCode, timestamp: $timestamp, unitPrice: $unitPrice, vatAnalysisTypeId: $vatAnalysisTypeId, vatRateId: $vatRateId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of company's Purchases. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/purchases
# operationId: Purchases_Get
export def "purchases Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<acCode: string, acEntries: list, bookTranTypeId: int, customFields: list, detailCollection: list, entryDate: string, id: int, netGoods: float, netServices: float, note: string, postponedAccounting: bool, procDate: string, reference: string, supplierId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unallocated: float, unpaid: float, vatEntries: list, vatTypeId: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/purchases")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Purchase.
#
# POST /v1/purchases
# operationId: Purchases_Post
# --acEntries item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --vatEntries item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
export def "purchases Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acCode: string
  --acEntries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --bookTranTypeId: int # format: int64
  --customFields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --detailCollection: list
  --entryDate: string # format: date-time
  --id: int # format: int64
  --isDiscrepancyAccepted: oneof<nothing, bool>
  --netGoods: float # format: double
  --netServices: float # format: double
  --note: string
  --postponedAccounting: oneof<nothing, bool>
  --procDate: string # format: date-time
  --reference: string
  --supplierId: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --totalNet: float # format: double
  --totalVAT: float # format: double
  --unallocated: float # format: double
  --unpaid: float # format: double
  --vatEntries: list # item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
  --vatTypeId: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/purchases")
  let body = {acCode: $acCode, acEntries: $acEntries, bookTranTypeId: $bookTranTypeId, customFields: $customFields, detailCollection: $detailCollection, entryDate: $entryDate, id: $id, isDiscrepancyAccepted: $isDiscrepancyAccepted, netGoods: $netGoods, netServices: $netServices, note: $note, postponedAccounting: $postponedAccounting, procDate: $procDate, reference: $reference, supplierId: $supplierId, timestamp: $timestamp, total: $total, totalNet: $totalNet, totalVAT: $totalVAT, unallocated: $unallocated, unpaid: $unpaid, vatEntries: $vatEntries, vatTypeId: $vatTypeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Processes a batch of Purchases.
#
# PUT /v1/purchases/batch
# operationId: Purchases_ProcessBatch
export def "purchases-batch ProcessBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/purchases/batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes an existing Purchase.
#
# DELETE /v1/purchases/{id}
# operationId: Purchases_Delete
export def "purchases Delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Purchase to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/purchases/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about a single Purchases.
#
# GET /v1/purchases/{id}
export def "purchases get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acCode: string, acEntries: table<accountCode: string, analysisCategoryId: int, description: string, id: int, value: float>, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, detailCollection: list<string>, entryDate: string, id: int, isDiscrepancyAccepted: bool, netGoods: float, netServices: float, note: string, postponedAccounting: bool, procDate: string, reference: string, supplierId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unallocated: float, unpaid: float, vatEntries: table<amount: float, id: int, percentage: float, vatRateId: int>, vatTypeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/purchases/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing Purchase.
#
# PUT /v1/purchases/{id}
# operationId: Purchases_Put
# --acEntries item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --vatEntries item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
export def "purchases Put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acCode: string
  --acEntries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --bookTranTypeId: int # format: int64
  --customFields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --detailCollection: list
  --entryDate: string # format: date-time
  --body-id: int # format: int64
  --isDiscrepancyAccepted: oneof<nothing, bool>
  --netGoods: float # format: double
  --netServices: float # format: double
  --note: string
  --postponedAccounting: oneof<nothing, bool>
  --procDate: string # format: date-time
  --reference: string
  --supplierId: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --totalNet: float # format: double
  --totalVAT: float # format: double
  --unallocated: float # format: double
  --unpaid: float # format: double
  --vatEntries: list # item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
  --vatTypeId: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/purchases/($id)")
  let body = {acCode: $acCode, acEntries: $acEntries, bookTranTypeId: $bookTranTypeId, customFields: $customFields, detailCollection: $detailCollection, entryDate: $entryDate, id: $body_id, isDiscrepancyAccepted: $isDiscrepancyAccepted, netGoods: $netGoods, netServices: $netServices, note: $note, postponedAccounting: $postponedAccounting, procDate: $procDate, reference: $reference, supplierId: $supplierId, timestamp: $timestamp, total: $total, totalNet: $totalNet, totalVAT: $totalVAT, unallocated: $unallocated, unpaid: $unpaid, vatEntries: $vatEntries, vatTypeId: $vatTypeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of company's Quotes. Filtering is forbidden. Ordering is allowed by "id".
#
# GET /v1/quotes
# operationId: Quote_Get
export def "quotes Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<acCode: string, closedDate: string, comments: string, companyId: int, customFields: list, customerOwnerId: int, customerOwnerName: string, ddNumber: string, deliveryList: string, deliveryTo: list, entryDate: string, id: int, layoutType: int, note: string, poNumber: string, procDate: string, productTrans: list, reference: string, saleInvoiceId: int, saleRepCode: string, saleRepId: int, timeStamp: string, total: float, totalNet: float, totalVat: float, vatTypeId: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/quotes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Quote.
#
# POST /v1/quotes
# operationId: Quote_Post
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --productTrans item shape: {acEntries?: list, amount?: float, companyId?: int, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list, unitPrice?: float, vatAmount?: float, vatAnalysisTypeId?: int, vatRateId?: int}
export def "quotes Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acCode: string
  --closedDate: string # format: date-time
  --comments: string
  --companyId: int # format: int64
  --customFields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customerOwnerId: int # format: int64
  --customerOwnerName: string
  --ddNumber: string
  --deliveryList: string
  --deliveryTo: list
  --entryDate: string # format: date-time
  --id: int # format: int64
  --layoutType: int # format: int32
  --note: string
  --poNumber: string
  --procDate: string # format: date-time
  --productTrans: list # item shape: {acEntries?: list, amount?: float, companyId?: int, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list, unitPrice?: float, vatAmount?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --reference: string
  --saleInvoiceId: int # format: int64
  --saleRepCode: string
  --saleRepId: int # format: int64
  --timeStamp: string # format: byte
  --total: float # format: double
  --totalNet: float # format: double
  --totalVat: float # format: double
  --vatTypeId: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/quotes")
  let body = {acCode: $acCode, closedDate: $closedDate, comments: $comments, companyId: $companyId, customFields: $customFields, customerOwnerId: $customerOwnerId, customerOwnerName: $customerOwnerName, ddNumber: $ddNumber, deliveryList: $deliveryList, deliveryTo: $deliveryTo, entryDate: $entryDate, id: $id, layoutType: $layoutType, note: $note, poNumber: $poNumber, procDate: $procDate, productTrans: $productTrans, reference: $reference, saleInvoiceId: $saleInvoiceId, saleRepCode: $saleRepCode, saleRepId: $saleRepId, timeStamp: $timeStamp, total: $total, totalNet: $totalNet, totalVat: $totalVat, vatTypeId: $vatTypeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Processes a batch of Quote.
#
# PUT /v1/quotes/batch
# operationId: Quote_ProcessBatch
export def "quotes-batch ProcessBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/quotes/batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Close a Quote.
#
# PUT /v1/quotes/close/{id}
# operationId: Quote_Close
export def "quotes-close Close" [
  id: int
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
  let full_url = (build-url $base $"/v1/quotes/close/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Quote with auto generating reference.
#
# POST /v1/quotes/createQuoteWithGeneratingReference
# operationId: Quote_Post_CreateQuoteWithGeneratingReference
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --productTrans item shape: {acEntries?: list, amount?: float, companyId?: int, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list, unitPrice?: float, vatAmount?: float, vatAnalysisTypeId?: int, vatRateId?: int}
export def "quotes-create-quote-with-generating-reference CreateQuoteWithGeneratingReference" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acCode: string
  --closedDate: string # format: date-time
  --comments: string
  --companyId: int # format: int64
  --customFields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customerOwnerId: int # format: int64
  --customerOwnerName: string
  --ddNumber: string
  --deliveryList: string
  --deliveryTo: list
  --entryDate: string # format: date-time
  --id: int # format: int64
  --layoutType: int # format: int32
  --note: string
  --poNumber: string
  --procDate: string # format: date-time
  --productTrans: list # item shape: {acEntries?: list, amount?: float, companyId?: int, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list, unitPrice?: float, vatAmount?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --reference: string
  --saleInvoiceId: int # format: int64
  --saleRepCode: string
  --saleRepId: int # format: int64
  --timeStamp: string # format: byte
  --total: float # format: double
  --totalNet: float # format: double
  --totalVat: float # format: double
  --vatTypeId: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/quotes/createQuoteWithGeneratingReference")
  let body = {acCode: $acCode, closedDate: $closedDate, comments: $comments, companyId: $companyId, customFields: $customFields, customerOwnerId: $customerOwnerId, customerOwnerName: $customerOwnerName, ddNumber: $ddNumber, deliveryList: $deliveryList, deliveryTo: $deliveryTo, entryDate: $entryDate, id: $id, layoutType: $layoutType, note: $note, poNumber: $poNumber, procDate: $procDate, productTrans: $productTrans, reference: $reference, saleInvoiceId: $saleInvoiceId, saleRepCode: $saleRepCode, saleRepId: $saleRepId, timeStamp: $timeStamp, total: $total, totalNet: $totalNet, totalVat: $totalVat, vatTypeId: $vatTypeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate a sale invoice from a Quote. When sale invoice is empty, new sale invoice will be generated from Quote.
#
# POST /v1/quotes/generateSaleInvoice
# operationId: Quote_Post_GenerateSaleInvoice
# --saleInvoice shape: {acCode?: string, bookTranTypeId?: int, customFields?: list, customerId?: int, deliveryTo?: list, details?: string, entryDate?: string, id?: int, loType?: string, netGoods?: float, netServices?: float, note?: string, ourReference?: string, procDate?: string, productTrans?: list, quoteId?: int, reference?: string, saleRepCode?: string, saleRepId?: int, timestamp?: string, total?: float, totalNet?: float, totalVAT?: float, unpaid?: float, vatTypeId?: int, yourReference?: string}
export def "quotes-generate-sale-invoice GenerateSaleInvoice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --quoteId: int # format: int64
  --saleInvoice: record # e.g. {acCode: CUS3, bookTranTypeId: 7, customFields: [{description: acudf_1, id: 1, userDefinedFieldId: 1, value: acudfv_1}, {description: acudf_2, id: 2, userDefinedFieldId: 1, value: acudfv_2}], customerId: 70585, deliveryTo: [dt_1, dt_2], details: detail_1, entryDate: 2016-06-01T00:00:00, id: 75813, loType: 1, note: Customer 3, ourReference: ddNumber_1, procDate: 2016-06-24T00:00:00, productTrans: [{acEntries: [{accountCode: SA02, analysisCategoryId: 40889, description: AnCat1, id: 73455, value: -200}], amount: -220, amountNet: -200, id: 51820, percentage: 10, productCode: PRO2, productId: 20108, quantity: -1, tranNotes: [tn_1, tn_2], unitPrice: 200, vat: -20, vatAnalysisTypeId: 0, vatRateId: 30657}], saleRepId: 33110, timestamp: oq6NcBIe2wg=, total: -220, totalNet: -200, totalVAT: -20, unpaid: -220, vatTypeId: 1, yourReference: poNumber_1} — shape: {acCode?: string, bookTranTypeId?: int, customFields?: list, customerId?: int, deliveryTo?: list, details?: string, entryDate?: string, id?: int, loType?: string, netGoods?: float, netServices?: float, note?: string, ourReference?: string, procDate?: string, productTrans?: list, quoteId?: int, reference?: string, saleRepCode?: string, saleRepId?: int, timestamp?: string, total?: float, totalNet?: float, totalVAT?: float, unpaid?: float, vatTypeId?: int, yourReference?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/quotes/generateSaleInvoice")
  let body = {quoteId: $quoteId, saleInvoice: $saleInvoice} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reopen a Quote.
#
# PUT /v1/quotes/reopen/{id}
# operationId: Quote_Reopen
export def "quotes-reopen Reopen" [
  id: int
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
  let full_url = (build-url $base $"/v1/quotes/reopen/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes an existing Quote.
#
# DELETE /v1/quotes/{id}
# operationId: Quote_Delete
export def "quotes Delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Quote to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/quotes/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about a single Quote.
#
# GET /v1/quotes/{id}
export def "quotes get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acCode: string, closedDate: string, comments: string, companyId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, customerOwnerId: int, customerOwnerName: string, ddNumber: string, deliveryList: string, deliveryTo: list<string>, entryDate: string, id: int, layoutType: int, note: string, poNumber: string, procDate: string, productTrans: table<acEntries: list, amount: float, companyId: int, id: int, percentage: float, productCode: string, productId: int, quantity: float, tranNotes: list, unitPrice: float, vatAmount: float, vatAnalysisTypeId: int, vatRateId: int>, reference: string, saleInvoiceId: int, saleRepCode: string, saleRepId: int, timeStamp: string, total: float, totalNet: float, totalVat: float, vatTypeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/quotes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing Quote.
#
# PUT /v1/quotes/{id}
# operationId: Quote_Put
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --productTrans item shape: {acEntries?: list, amount?: float, companyId?: int, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list, unitPrice?: float, vatAmount?: float, vatAnalysisTypeId?: int, vatRateId?: int}
export def "quotes Put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acCode: string
  --closedDate: string # format: date-time
  --comments: string
  --companyId: int # format: int64
  --customFields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customerOwnerId: int # format: int64
  --customerOwnerName: string
  --ddNumber: string
  --deliveryList: string
  --deliveryTo: list
  --entryDate: string # format: date-time
  --body-id: int # format: int64
  --layoutType: int # format: int32
  --note: string
  --poNumber: string
  --procDate: string # format: date-time
  --productTrans: list # item shape: {acEntries?: list, amount?: float, companyId?: int, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list, unitPrice?: float, vatAmount?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --reference: string
  --saleInvoiceId: int # format: int64
  --saleRepCode: string
  --saleRepId: int # format: int64
  --timeStamp: string # format: byte
  --total: float # format: double
  --totalNet: float # format: double
  --totalVat: float # format: double
  --vatTypeId: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/quotes/($id)")
  let body = {acCode: $acCode, closedDate: $closedDate, comments: $comments, companyId: $companyId, customFields: $customFields, customerOwnerId: $customerOwnerId, customerOwnerName: $customerOwnerName, ddNumber: $ddNumber, deliveryList: $deliveryList, deliveryTo: $deliveryTo, entryDate: $entryDate, id: $body_id, layoutType: $layoutType, note: $note, poNumber: $poNumber, procDate: $procDate, productTrans: $productTrans, reference: $reference, saleInvoiceId: $saleInvoiceId, saleRepCode: $saleRepCode, saleRepId: $saleRepId, timeStamp: $timeStamp, total: $total, totalNet: $totalNet, totalVat: $totalVat, vatTypeId: $vatTypeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of company's Sales Entries, Sales Invoices and Sales Credit Notes. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/sales
# operationId: Sales_Get
export def "sales Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<acCode: string, acEntries: list, bookTranTypeId: int, customFields: list, customerId: int, details: string, entryDate: string, id: int, loType: string, note: string, procDate: string, reference: string, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatEntries: list, vatTypeId: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sales")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of company's Sales Credit Notes. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/salesCreditNotes
# operationId: SalesCreditNotes_Get
export def "sales-credit-notes Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<acCode: string, bookTranTypeId: int, customFields: list, customerId: int, deliveryTo: list, details: string, entryDate: string, id: int, loType: string, netGoods: float, netServices: float, note: string, ourReference: string, procDate: string, productTrans: list, quoteId: int, reference: string, saleRepCode: string, saleRepId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatTypeId: int, yourReference: string>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesCreditNotes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Sales Credit Note.
#
# POST /v1/salesCreditNotes
# operationId: SalesCreditNotes_Post
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --productTrans item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
export def "sales-credit-notes Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acCode: string
  --bookTranTypeId: int # format: int64
  --customFields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customerId: int # format: int64
  --deliveryTo: list
  --details: string
  --entryDate: string # format: date-time
  --id: int # format: int64
  --loType: string
  --netGoods: float # format: double
  --netServices: float # format: double
  --note: string
  --ourReference: string
  --procDate: string # format: date-time
  --productTrans: list # item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --quoteId: int # format: int64
  --reference: string
  --saleRepCode: string
  --saleRepId: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --totalNet: float # format: double
  --totalVAT: float # format: double
  --unpaid: float # format: double
  --vatTypeId: int # format: int64
  --yourReference: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesCreditNotes")
  let body = {acCode: $acCode, bookTranTypeId: $bookTranTypeId, customFields: $customFields, customerId: $customerId, deliveryTo: $deliveryTo, details: $details, entryDate: $entryDate, id: $id, loType: $loType, netGoods: $netGoods, netServices: $netServices, note: $note, ourReference: $ourReference, procDate: $procDate, productTrans: $productTrans, quoteId: $quoteId, reference: $reference, saleRepCode: $saleRepCode, saleRepId: $saleRepId, timestamp: $timestamp, total: $total, totalNet: $totalNet, totalVAT: $totalVAT, unpaid: $unpaid, vatTypeId: $vatTypeId, yourReference: $yourReference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Processes a batch of Sales Credit Notes.
#
# PUT /v1/salesCreditNotes/batch
# operationId: SalesCreditNotes_ProcessBatch
export def "sales-credit-notes-batch ProcessBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesCreditNotes/batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes an existing Sales Credit Note.
#
# DELETE /v1/salesCreditNotes/{id}
# operationId: SalesCreditNotes_Delete
export def "sales-credit-notes Delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Sales Credit Note to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/salesCreditNotes/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about a single Sales Credit Note.
#
# GET /v1/salesCreditNotes/{id}
export def "sales-credit-notes get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acCode: string, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, customerId: int, deliveryTo: list<string>, details: string, entryDate: string, id: int, loType: string, netGoods: float, netServices: float, note: string, ourReference: string, procDate: string, productTrans: table<acEntries: list, amount: float, amountNet: float, id: int, percentage: float, productCode: string, productId: int, quantity: float, tranNotes: list, unitPrice: float, vat: float, vatAnalysisTypeId: int, vatRateId: int>, quoteId: int, reference: string, saleRepCode: string, saleRepId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatTypeId: int, yourReference: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/salesCreditNotes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing Sales Credit Note.
#
# PUT /v1/salesCreditNotes/{id}
# operationId: SalesCreditNotes_Put
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --productTrans item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
export def "sales-credit-notes Put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acCode: string
  --bookTranTypeId: int # format: int64
  --customFields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customerId: int # format: int64
  --deliveryTo: list
  --details: string
  --entryDate: string # format: date-time
  --body-id: int # format: int64
  --loType: string
  --netGoods: float # format: double
  --netServices: float # format: double
  --note: string
  --ourReference: string
  --procDate: string # format: date-time
  --productTrans: list # item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --quoteId: int # format: int64
  --reference: string
  --saleRepCode: string
  --saleRepId: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --totalNet: float # format: double
  --totalVAT: float # format: double
  --unpaid: float # format: double
  --vatTypeId: int # format: int64
  --yourReference: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/salesCreditNotes/($id)")
  let body = {acCode: $acCode, bookTranTypeId: $bookTranTypeId, customFields: $customFields, customerId: $customerId, deliveryTo: $deliveryTo, details: $details, entryDate: $entryDate, id: $body_id, loType: $loType, netGoods: $netGoods, netServices: $netServices, note: $note, ourReference: $ourReference, procDate: $procDate, productTrans: $productTrans, quoteId: $quoteId, reference: $reference, saleRepCode: $saleRepCode, saleRepId: $saleRepId, timestamp: $timestamp, total: $total, totalNet: $totalNet, totalVAT: $totalVAT, unpaid: $unpaid, vatTypeId: $vatTypeId, yourReference: $yourReference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of company's Sales Entries. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/salesEntries
# operationId: SalesEntries_Get
export def "sales-entries Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<acCode: string, acEntries: list, bookTranTypeId: int, customFields: list, customerId: int, detailCollection: list, details: string, entryDate: string, id: int, netGoods: float, netServices: float, note: string, procDate: string, reference: string, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatEntries: list, vatTypeId: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesEntries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Sales Entry.
#
# POST /v1/salesEntries
# operationId: SalesEntries_Post
# --acEntries item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --vatEntries item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
export def "sales-entries Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acCode: string
  --acEntries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --bookTranTypeId: int # format: int64
  --customFields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customerId: int # format: int64
  --detailCollection: list
  --details: string
  --entryDate: string # format: date-time
  --id: int # format: int64
  --netGoods: float # format: double
  --netServices: float # format: double
  --note: string
  --procDate: string # format: date-time
  --reference: string
  --timestamp: string # format: byte
  --total: float # format: double
  --totalNet: float # format: double
  --totalVAT: float # format: double
  --unpaid: float # format: double
  --vatEntries: list # item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
  --vatTypeId: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesEntries")
  let body = {acCode: $acCode, acEntries: $acEntries, bookTranTypeId: $bookTranTypeId, customFields: $customFields, customerId: $customerId, detailCollection: $detailCollection, details: $details, entryDate: $entryDate, id: $id, netGoods: $netGoods, netServices: $netServices, note: $note, procDate: $procDate, reference: $reference, timestamp: $timestamp, total: $total, totalNet: $totalNet, totalVAT: $totalVAT, unpaid: $unpaid, vatEntries: $vatEntries, vatTypeId: $vatTypeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Processes a batch of Sales Entries.
#
# PUT /v1/salesEntries/batch
# operationId: SalesEntries_ProcessBatch
export def "sales-entries-batch ProcessBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesEntries/batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes an existing Sales Entry.
#
# DELETE /v1/salesEntries/{id}
# operationId: SalesEntries_Delete
export def "sales-entries Delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Sales Entry to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/salesEntries/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about a single Sales Entry.
#
# GET /v1/salesEntries/{id}
export def "sales-entries get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acCode: string, acEntries: table<accountCode: string, analysisCategoryId: int, description: string, id: int, value: float>, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, customerId: int, detailCollection: list<string>, details: string, entryDate: string, id: int, netGoods: float, netServices: float, note: string, procDate: string, reference: string, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatEntries: table<amount: float, id: int, percentage: float, vatRateId: int>, vatTypeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/salesEntries/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing Sales Entry.
#
# PUT /v1/salesEntries/{id}
# operationId: SalesEntries_Put
# --acEntries item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --vatEntries item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
export def "sales-entries Put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acCode: string
  --acEntries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --bookTranTypeId: int # format: int64
  --customFields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customerId: int # format: int64
  --detailCollection: list
  --details: string
  --entryDate: string # format: date-time
  --body-id: int # format: int64
  --netGoods: float # format: double
  --netServices: float # format: double
  --note: string
  --procDate: string # format: date-time
  --reference: string
  --timestamp: string # format: byte
  --total: float # format: double
  --totalNet: float # format: double
  --totalVAT: float # format: double
  --unpaid: float # format: double
  --vatEntries: list # item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
  --vatTypeId: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/salesEntries/($id)")
  let body = {acCode: $acCode, acEntries: $acEntries, bookTranTypeId: $bookTranTypeId, customFields: $customFields, customerId: $customerId, detailCollection: $detailCollection, details: $details, entryDate: $entryDate, id: $body_id, netGoods: $netGoods, netServices: $netServices, note: $note, procDate: $procDate, reference: $reference, timestamp: $timestamp, total: $total, totalNet: $totalNet, totalVAT: $totalVAT, unpaid: $unpaid, vatEntries: $vatEntries, vatTypeId: $vatTypeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of company's Sales Invoices. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/salesInvoices
# operationId: SalesInvoices_Get
export def "sales-invoices Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<acCode: string, bookTranTypeId: int, customFields: list, customerId: int, deliveryTo: list, details: string, entryDate: string, id: int, loType: string, netGoods: float, netServices: float, note: string, ourReference: string, procDate: string, productTrans: list, quoteId: int, reference: string, saleRepCode: string, saleRepId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatTypeId: int, yourReference: string>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesInvoices")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Sales Invoice.
#
# POST /v1/salesInvoices
# operationId: SalesInvoices_Post
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --productTrans item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
export def "sales-invoices Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acCode: string
  --bookTranTypeId: int # format: int64
  --customFields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customerId: int # format: int64
  --deliveryTo: list
  --details: string
  --entryDate: string # format: date-time
  --id: int # format: int64
  --loType: string
  --netGoods: float # format: double
  --netServices: float # format: double
  --note: string
  --ourReference: string
  --procDate: string # format: date-time
  --productTrans: list # item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --quoteId: int # format: int64
  --reference: string
  --saleRepCode: string
  --saleRepId: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --totalNet: float # format: double
  --totalVAT: float # format: double
  --unpaid: float # format: double
  --vatTypeId: int # format: int64
  --yourReference: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesInvoices")
  let body = {acCode: $acCode, bookTranTypeId: $bookTranTypeId, customFields: $customFields, customerId: $customerId, deliveryTo: $deliveryTo, details: $details, entryDate: $entryDate, id: $id, loType: $loType, netGoods: $netGoods, netServices: $netServices, note: $note, ourReference: $ourReference, procDate: $procDate, productTrans: $productTrans, quoteId: $quoteId, reference: $reference, saleRepCode: $saleRepCode, saleRepId: $saleRepId, timestamp: $timestamp, total: $total, totalNet: $totalNet, totalVAT: $totalVAT, unpaid: $unpaid, vatTypeId: $vatTypeId, yourReference: $yourReference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Processes a batch of Sales Invoices.
#
# PUT /v1/salesInvoices/batch
# operationId: SalesInvoices_ProcessBatch
export def "sales-invoices-batch ProcessBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesInvoices/batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new Sale Invoice with auto generating reference.
#
# POST /v1/salesInvoices/createSaleInvoiceWithGeneratingReference
# operationId: SalesInvoices_Post_CreateSaleInvoiceWithGeneratingReference
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --productTrans item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
export def "sales-invoices-create-sale-invoice-with-generating-reference CreateSaleInvoiceWithGeneratingReference" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acCode: string
  --bookTranTypeId: int # format: int64
  --customFields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customerId: int # format: int64
  --deliveryTo: list
  --details: string
  --entryDate: string # format: date-time
  --id: int # format: int64
  --loType: string
  --netGoods: float # format: double
  --netServices: float # format: double
  --note: string
  --ourReference: string
  --procDate: string # format: date-time
  --productTrans: list # item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --quoteId: int # format: int64
  --reference: string
  --saleRepCode: string
  --saleRepId: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --totalNet: float # format: double
  --totalVAT: float # format: double
  --unpaid: float # format: double
  --vatTypeId: int # format: int64
  --yourReference: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesInvoices/createSaleInvoiceWithGeneratingReference")
  let body = {acCode: $acCode, bookTranTypeId: $bookTranTypeId, customFields: $customFields, customerId: $customerId, deliveryTo: $deliveryTo, details: $details, entryDate: $entryDate, id: $id, loType: $loType, netGoods: $netGoods, netServices: $netServices, note: $note, ourReference: $ourReference, procDate: $procDate, productTrans: $productTrans, quoteId: $quoteId, reference: $reference, saleRepCode: $saleRepCode, saleRepId: $saleRepId, timestamp: $timestamp, total: $total, totalNet: $totalNet, totalVAT: $totalVAT, unpaid: $unpaid, vatTypeId: $vatTypeId, yourReference: $yourReference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes an existing Sales Invoice.
#
# DELETE /v1/salesInvoices/{id}
# operationId: SalesInvoices_Delete
export def "sales-invoices Delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Sales Invoice to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/salesInvoices/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about a single Sales Invoice.
#
# GET /v1/salesInvoices/{id}
export def "sales-invoices get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acCode: string, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, customerId: int, deliveryTo: list<string>, details: string, entryDate: string, id: int, loType: string, netGoods: float, netServices: float, note: string, ourReference: string, procDate: string, productTrans: table<acEntries: list, amount: float, amountNet: float, id: int, percentage: float, productCode: string, productId: int, quantity: float, tranNotes: list, unitPrice: float, vat: float, vatAnalysisTypeId: int, vatRateId: int>, quoteId: int, reference: string, saleRepCode: string, saleRepId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatTypeId: int, yourReference: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/salesInvoices/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing Sales Invoice.
#
# PUT /v1/salesInvoices/{id}
# operationId: SalesInvoices_Put
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --productTrans item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
export def "sales-invoices Put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acCode: string
  --bookTranTypeId: int # format: int64
  --customFields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customerId: int # format: int64
  --deliveryTo: list
  --details: string
  --entryDate: string # format: date-time
  --body-id: int # format: int64
  --loType: string
  --netGoods: float # format: double
  --netServices: float # format: double
  --note: string
  --ourReference: string
  --procDate: string # format: date-time
  --productTrans: list # item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --quoteId: int # format: int64
  --reference: string
  --saleRepCode: string
  --saleRepId: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --totalNet: float # format: double
  --totalVAT: float # format: double
  --unpaid: float # format: double
  --vatTypeId: int # format: int64
  --yourReference: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/salesInvoices/($id)")
  let body = {acCode: $acCode, bookTranTypeId: $bookTranTypeId, customFields: $customFields, customerId: $customerId, deliveryTo: $deliveryTo, details: $details, entryDate: $entryDate, id: $body_id, loType: $loType, netGoods: $netGoods, netServices: $netServices, note: $note, ourReference: $ourReference, procDate: $procDate, productTrans: $productTrans, quoteId: $quoteId, reference: $reference, saleRepCode: $saleRepCode, saleRepId: $saleRepId, timestamp: $timestamp, total: $total, totalNet: $totalNet, totalVAT: $totalVAT, unpaid: $unpaid, vatTypeId: $vatTypeId, yourReference: $yourReference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of company's SaleRep. Filtering is forbidden. Ordering is allowed by "id".
#
# GET /v1/salesReps
# operationId: SalesRep_Get
export def "sales-reps Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<code: string, companyId: int, email: string, id: int, name: string, phone: string, timeStamp: string>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesReps")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new SaleRep.
#
# POST /v1/salesReps
# operationId: SalesRep_Post
export def "sales-reps Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string
  --companyId: int # format: int64
  --email: string
  --id: int # format: int64
  --name: string
  --phone: string
  --timeStamp: string # format: byte
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesReps")
  let body = {code: $code, companyId: $companyId, email: $email, id: $id, name: $name, phone: $phone, timeStamp: $timeStamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Processes a batch of Sale Rep.
#
# PUT /v1/salesReps/batch
# operationId: SalesRep_ProcessBatch
export def "sales-reps-batch ProcessBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesReps/batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes an existing Sale Rep.
#
# DELETE /v1/salesReps/{id}
# operationId: SalesRep_Delete
export def "sales-reps Delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Sale Rep to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/salesReps/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about a single SaleRep.
#
# GET /v1/salesReps/{id}
export def "sales-reps get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, companyId: int, email: string, id: int, name: string, phone: string, timeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/salesReps/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing Sale Rep.
#
# PUT /v1/salesReps/{id}
# operationId: SalesRep_Put
export def "sales-reps Put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string
  --companyId: int # format: int64
  --email: string
  --body-id: int # format: int64
  --name: string
  --phone: string
  --timeStamp: string # format: byte
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/salesReps/($id)")
  let body = {code: $code, companyId: $companyId, email: $email, id: $body_id, name: $name, phone: $phone, timeStamp: $timeStamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of company's Suppliers. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" and "code" fields.
#
# GET /v1/suppliers
# operationId: Suppliers_Get
export def "suppliers Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<accountName: string, accountNumber: string, additionalEmails: list, address: list, authCode: string, bank: record, businessIdentifierCode: string, code: string, contact: string, eFTReference: string, email: string, fax: string, id: int, internationalBankAccountNumber: string, mobile: string, name: string, ourCode: string, ownerTypeId: int, phone: string, postponedAccounting: bool, timestamp: string, vatAnalysisTypeId: int, vatReg: string, vatType: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/suppliers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Supplier.
#
# POST /v1/suppliers
# operationId: Suppliers_Post
# --bank shape: {branch?: string, id?: int, name?: string, sortCode?: string}
# --openingBalance shape: {currentMonth?: float, oneMonthOld?: float, threeMonthsOld?: float, twoMonthsOld?: float}
# --openingBalances item shape: {entryDate?: string, id?: int, isChanged?: bool, procDate?: string, reference?: string, timestamp?: string, total?: float, totalVAT?: float, unpaid?: float, vatEntries?: list}
export def "suppliers Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountName: string
  --accountNumber: string
  --additionalEmails: list
  --address: list
  --authCode: string
  --bank: record # shape: {branch?: string, id?: int, name?: string, sortCode?: string}
  --businessIdentifierCode: string
  --code: string
  --contact: string
  --eFTReference: string
  --email: string
  --fax: string
  --id: int # format: int64
  --internationalBankAccountNumber: string
  --ledgerBalance: float # format: double
  --mobile: string
  --name: string
  --openingBalance: record # shape: {currentMonth?: float, oneMonthOld?: float, threeMonthsOld?: float, twoMonthsOld?: float}
  --openingBalances: list # item shape: {entryDate?: string, id?: int, isChanged?: bool, procDate?: string, reference?: string, timestamp?: string, total?: float, totalVAT?: float, unpaid?: float, vatEntries?: list}
  --ourCode: string
  --ownerTypeId: int # format: int64
  --phone: string
  --postponedAccounting: oneof<nothing, bool>
  --timestamp: string # format: byte
  --vatAnalysisTypeId: int # format: int64
  --vatReg: string
  --vatType: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/suppliers")
  let body = {accountName: $accountName, accountNumber: $accountNumber, additionalEmails: $additionalEmails, address: $address, authCode: $authCode, bank: $bank, businessIdentifierCode: $businessIdentifierCode, code: $code, contact: $contact, eFTReference: $eFTReference, email: $email, fax: $fax, id: $id, internationalBankAccountNumber: $internationalBankAccountNumber, ledgerBalance: $ledgerBalance, mobile: $mobile, name: $name, openingBalance: $openingBalance, openingBalances: $openingBalances, ourCode: $ourCode, ownerTypeId: $ownerTypeId, phone: $phone, postponedAccounting: $postponedAccounting, timestamp: $timestamp, vatAnalysisTypeId: $vatAnalysisTypeId, vatReg: $vatReg, vatType: $vatType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Processes a batch of Suppliers.
#
# PUT /v1/suppliers/batch
# operationId: Suppliers_ProcessBatch
export def "suppliers-batch ProcessBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/suppliers/batch")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes an existing Supplier.
#
# DELETE /v1/suppliers/{id}
# operationId: Suppliers_Delete
export def "suppliers Delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Supplier to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/suppliers/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns information about a single Supplier. You may specify that Supplier's ledger balance should be calculated.
#
# GET /v1/suppliers/{id}
export def "suppliers get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --needBalance: oneof<nothing, bool> # If "true" then Supplier's ledger balance will be calculated; otherwise balance will be returned as 0.
]: nothing -> record<accountName: string, accountNumber: string, additionalEmails: list<string>, address: list<string>, authCode: string, bank: record<branch: string, id: int, name: string, sortCode: string>, businessIdentifierCode: string, code: string, contact: string, eFTReference: string, email: string, fax: string, id: int, internationalBankAccountNumber: string, ledgerBalance: float, mobile: string, name: string, openingBalance: record<currentMonth: float, oneMonthOld: float, threeMonthsOld: float, twoMonthsOld: float>, openingBalances: table<entryDate: string, id: int, isChanged: bool, procDate: string, reference: string, timestamp: string, total: float, totalVAT: float, unpaid: float, vatEntries: list>, ourCode: string, ownerTypeId: int, phone: string, postponedAccounting: bool, timestamp: string, vatAnalysisTypeId: int, vatReg: string, vatType: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "needBalance" $needBalance "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/suppliers/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing Supplier.
#
# PUT /v1/suppliers/{id}
# operationId: Suppliers_Put
# --bank shape: {branch?: string, id?: int, name?: string, sortCode?: string}
# --openingBalance shape: {currentMonth?: float, oneMonthOld?: float, threeMonthsOld?: float, twoMonthsOld?: float}
# --openingBalances item shape: {entryDate?: string, id?: int, isChanged?: bool, procDate?: string, reference?: string, timestamp?: string, total?: float, totalVAT?: float, unpaid?: float, vatEntries?: list}
export def "suppliers Put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountName: string
  --accountNumber: string
  --additionalEmails: list
  --address: list
  --authCode: string
  --bank: record # shape: {branch?: string, id?: int, name?: string, sortCode?: string}
  --businessIdentifierCode: string
  --code: string
  --contact: string
  --eFTReference: string
  --email: string
  --fax: string
  --body-id: int # format: int64
  --internationalBankAccountNumber: string
  --ledgerBalance: float # format: double
  --mobile: string
  --name: string
  --openingBalance: record # shape: {currentMonth?: float, oneMonthOld?: float, threeMonthsOld?: float, twoMonthsOld?: float}
  --openingBalances: list # item shape: {entryDate?: string, id?: int, isChanged?: bool, procDate?: string, reference?: string, timestamp?: string, total?: float, totalVAT?: float, unpaid?: float, vatEntries?: list}
  --ourCode: string
  --ownerTypeId: int # format: int64
  --phone: string
  --postponedAccounting: oneof<nothing, bool>
  --timestamp: string # format: byte
  --vatAnalysisTypeId: int # format: int64
  --vatReg: string
  --vatType: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/suppliers/($id)")
  let body = {accountName: $accountName, accountNumber: $accountNumber, additionalEmails: $additionalEmails, address: $address, authCode: $authCode, bank: $bank, businessIdentifierCode: $businessIdentifierCode, code: $code, contact: $contact, eFTReference: $eFTReference, email: $email, fax: $fax, id: $body_id, internationalBankAccountNumber: $internationalBankAccountNumber, ledgerBalance: $ledgerBalance, mobile: $mobile, name: $name, openingBalance: $openingBalance, openingBalances: $openingBalances, ourCode: $ourCode, ownerTypeId: $ownerTypeId, phone: $phone, postponedAccounting: $postponedAccounting, timestamp: $timestamp, vatAnalysisTypeId: $vatAnalysisTypeId, vatReg: $vatReg, vatType: $vatType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of Supplier's account transactions.
#
# GET /v1/suppliers/{itemId}/accountTrans
# operationId: Suppliers_GetAccountTrans
export def "suppliers-account-trans GetAccountTrans" [
  itemId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<bookTranId: int, bookTranTypeId: int, bookTransactionReference: string, bookTypeDesc: string, credit: float, debit: float, id: int, procDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/suppliers/($itemId)/accountTrans")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a Supplier's opening balances, calculated for the next periods: current month, one month old, two months old, three and more months old.
#
# GET /v1/suppliers/{itemId}/openingBalance
# operationId: Suppliers_GetOpeningBalance
export def "suppliers-opening-balance GetOpeningBalance" [
  itemId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<currentMonth: float, oneMonthOld: float, threeMonthsOld: float, twoMonthsOld: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/suppliers/($itemId)/openingBalance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of Supplier's opening balance transactions.
#
# GET /v1/suppliers/{itemId}/openingBalanceList
# operationId: Suppliers_GetOpeningBalanceList
export def "suppliers-opening-balance-list GetOpeningBalanceList" [
  itemId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<entryDate: string, id: int, isChanged: bool, procDate: string, reference: string, timestamp: string, total: float, totalVAT: float, unpaid: float, vatEntries: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/suppliers/($itemId)/openingBalanceList")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of company's User Defined Fields. Supports OData querying protocol. Filtering is allowed by "categoryTypeId" field. Ordering is allowed by "id" and "orderIndex" fields.
#
# GET /v1/userDefinedFields
# operationId: UserDefinedFields_Get
export def "user-defined-fields Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<categoryTypeId: int, description: string, id: int, orderIndex: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/userDefinedFields")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of global Vat Analysis Types. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/vatAnalysisTypes
# operationId: VatAnalysisTypes_Get
export def "vat-analysis-types Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<description: string, id: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/vatAnalysisTypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of global Vat Categories. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/vatCategories
# operationId: VatCategories_Get
export def "vat-categories Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<description: string, id: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/vatCategories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Process Vat Rates
#
# POST /v1/vatCategories/vatRates
# operationId: VatCategories_ProcessVatRates
export def "vat-categories-vat-rates ProcessVatRates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/vatCategories/vatRates")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of company's Vat Rates. Supports OData querying protocol. Filtering is allowed by "vatCategoryId" field. Ordering is allowed by "id" and "orderIndex" fields.
#
# GET /v1/vatRates
# operationId: VatRates_Get
export def "vat-rates Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<id: int, isActive: bool, isDefault: bool, orderIndex: int, percentage: float, timestamp: string, vatCategoryId: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/vatRates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of global Vat Types. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/vatTypes
# operationId: VatTypes_Get
export def "vat-types Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<code: string, description: string, id: int, isNotApplicable: bool, isOnlyZero: bool>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/vatTypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
