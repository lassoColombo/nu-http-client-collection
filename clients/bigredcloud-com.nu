# Auto-generated client for Big Red Cloud API vv1
# Source: https://api.apis.guru/v2/specs/bigredcloud.com/v1/openapi.json
# Auth: --token flag or $env.BIG_RED_CLOUD_API_TOKEN

const BASE_URL = "https://app.bigredcloud.com/api"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o BIG_RED_CLOUD_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://app.bigredcloud.com/api"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts get" } } | get name | first)
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
export def "accounts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<accountGroup: string, accountType: string, code: string, description: string, id: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/accounts" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of company's Analysis Categories. Supports OData querying protocol. Filtering is allowed by "categoryTypeId" field. Ordering is allowed by "id" and "orderIndex" fields.
#
# GET /v1/analysisCategories
# operationId: AnalysisCategories_Get
export def "analysis-categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<accountCode: string, accountId: int, categoryTypeId: int, description: string, id: int, orderIndex: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/analysisCategories" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of company's Bank Account. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" and "acCode" fields.
#
# GET /v1/bankAccounts
# operationId: BankAccounts_Get
export def "bank-accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<acCode: string, accountName: string, accountNumber: string, address: list, bankFeedSource: int, businessIdentifierCodes: string, categoryId: int, creditorScheme: string, details: string, id: int, internationalBankAccountNumber: string, isDefaultBank: bool, lastChq: string, nominalAcCode: string, sortCode: string, timestamp: string>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/bankAccounts" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Bank Account.
#
# POST /v1/bankAccounts
# operationId: BankAccounts_Post
export def "bank-accounts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --account-name: string
  --account-number: string
  --address: list<string>
  --bank-feed-source: int # format: int32
  --business-identifier-codes: string
  --category-id: int # format: int64
  --creditor-scheme: string
  --details: string
  --id: int # format: int64
  --international-bank-account-number: string
  --is-default-bank: oneof<nothing, bool>
  --last-chq: string
  --nominal-ac-code: string
  --o-balance: float # format: double
  --sort-code: string
  --timestamp: string # format: byte
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/bankAccounts" $auth.query)
  let req_body = {"acCode": $ac_code, "accountName": $account_name, "accountNumber": $account_number, "address": $address, "bankFeedSource": $bank_feed_source, "businessIdentifierCodes": $business_identifier_codes, "categoryId": $category_id, "creditorScheme": $creditor_scheme, "details": $details, "id": $id, "internationalBankAccountNumber": $international_bank_account_number, "isDefaultBank": $is_default_bank, "lastChq": $last_chq, "nominalAcCode": $nominal_ac_code, "oBalance": $o_balance, "sortCode": $sort_code, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Processes a batch of Bank Accounts.
#
# PUT /v1/bankAccounts/batch
# operationId: BankAccounts_ProcessBatch
export def "bank-accounts-batch update-process" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/bankAccounts/batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes an existing Bank Account.
#
# DELETE /v1/bankAccounts/{id}
# operationId: BankAccounts_Delete
export def "bank-accounts delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Bank Account to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/bankAccounts/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"timestamp": $timestamp} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acCode: string, accountName: string, accountNumber: string, address: list<string>, bankFeedSource: int, businessIdentifierCodes: string, categoryId: int, creditorScheme: string, details: string, id: int, internationalBankAccountNumber: string, isDefaultBank: bool, lastChq: string, nominalAcCode: string, oBalance: float, sortCode: string, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/bankAccounts/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing Bank Account.
#
# PUT /v1/bankAccounts/{id}
# operationId: BankAccounts_Put
export def "bank-accounts update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --account-name: string
  --account-number: string
  --address: list<string>
  --bank-feed-source: int # format: int32
  --business-identifier-codes: string
  --category-id: int # format: int64
  --creditor-scheme: string
  --details: string
  --body-id: int # format: int64
  --international-bank-account-number: string
  --is-default-bank: oneof<nothing, bool>
  --last-chq: string
  --nominal-ac-code: string
  --o-balance: float # format: double
  --sort-code: string
  --timestamp: string # format: byte
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/bankAccounts/{id}") $auth.query)
  let req_body = {"acCode": $ac_code, "accountName": $account_name, "accountNumber": $account_number, "address": $address, "bankFeedSource": $bank_feed_source, "businessIdentifierCodes": $business_identifier_codes, "categoryId": $category_id, "creditorScheme": $creditor_scheme, "details": $details, "id": $body_id, "internationalBankAccountNumber": $international_bank_account_number, "isDefaultBank": $is_default_bank, "lastChq": $last_chq, "nominalAcCode": $nominal_ac_code, "oBalance": $o_balance, "sortCode": $sort_code, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of global Book Transactions' Types. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/bookTranTypes
# operationId: BookTranTypes_Get
export def "book-tran-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<code: string, description: string, id: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/bookTranTypes" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of company's Cash Payments. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/cashPayments
# operationId: CashPayments_Get
export def "cash-payments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<acCode: string, acEntries: list, bankAccountCode: string, bankAccountId: int, bookTranTypeId: int, customFields: list, detailCollection: list, discount: float, entryDate: string, id: int, ledger: float, lodgement: float, note: string, plaidTransactionId: string, procDate: string, supplierId: int, timestamp: string, total: float, unallocated: float>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/cashPayments" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Cash Payment.
#
# POST /v1/cashPayments
# operationId: CashPayments_Post
# --acEntries item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
export def "cash-payments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --ac-entries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --bank-account-code: string
  --bank-account-id: int # format: int64
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --detail-collection: list<string>
  --discount: float # format: double
  --entry-date: string # format: date-time
  --id: int # format: int64
  --ledger: float # format: double
  --lodgement: float # format: double
  --note: string
  --plaid-transaction-id: string
  --proc-date: string # format: date-time
  --supplier-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/cashPayments" $auth.query)
  let req_body = {"acCode": $ac_code, "acEntries": $ac_entries, "bankAccountCode": $bank_account_code, "bankAccountId": $bank_account_id, "bookTranTypeId": $book_tran_type_id, "customFields": $custom_fields, "detailCollection": $detail_collection, "discount": $discount, "entryDate": $entry_date, "id": $id, "ledger": $ledger, "lodgement": $lodgement, "note": $note, "plaidTransactionId": $plaid_transaction_id, "procDate": $proc_date, "supplierId": $supplier_id, "timestamp": $timestamp, "total": $total} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Processes a batch of Cash Payments.
#
# PUT /v1/cashPayments/batch
# operationId: CashPayments_ProcessBatch
export def "cash-payments-batch update-process" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/cashPayments/batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes an existing Cash Payment.
#
# DELETE /v1/cashPayments/{id}
# operationId: CashPayments_Delete
export def "cash-payments delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Cash Receipt to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/cashPayments/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"timestamp": $timestamp} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acCode: string, acEntries: table<accountCode: string, analysisCategoryId: int, description: string, id: int, value: float>, bankAccountCode: string, bankAccountId: int, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, detailCollection: list<string>, discount: float, entryDate: string, id: int, ledger: float, lodgement: float, note: string, plaidTransactionId: string, procDate: string, supplierId: int, timestamp: string, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/cashPayments/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing Cash Payment.
#
# PUT /v1/cashPayments/{id}
# operationId: CashPayments_Put
# --acEntries item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
export def "cash-payments update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --ac-entries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --bank-account-code: string
  --bank-account-id: int # format: int64
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --detail-collection: list<string>
  --discount: float # format: double
  --entry-date: string # format: date-time
  --body-id: int # format: int64
  --ledger: float # format: double
  --lodgement: float # format: double
  --note: string
  --plaid-transaction-id: string
  --proc-date: string # format: date-time
  --supplier-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/cashPayments/{id}") $auth.query)
  let req_body = {"acCode": $ac_code, "acEntries": $ac_entries, "bankAccountCode": $bank_account_code, "bankAccountId": $bank_account_id, "bookTranTypeId": $book_tran_type_id, "customFields": $custom_fields, "detailCollection": $detail_collection, "discount": $discount, "entryDate": $entry_date, "id": $body_id, "ledger": $ledger, "lodgement": $lodgement, "note": $note, "plaidTransactionId": $plaid_transaction_id, "procDate": $proc_date, "supplierId": $supplier_id, "timestamp": $timestamp, "total": $total} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of company's Cash Receipts. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/cashReceipts
# operationId: CashReceipts_Get
export def "cash-receipts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<acCode: string, acEntries: list, bookTranTypeId: int, customFields: list, customerId: int, detailCollection: list, discount: float, entryDate: string, id: int, ledger: float, note: string, plaidTransactionId: string, procDate: string, timestamp: string, total: float, unallocated: float, vatEntries: list, vatTypeId: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/cashReceipts" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Cash Receipt.
#
# POST /v1/cashReceipts
# operationId: CashReceipts_Post
# --acEntries item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --vatEntries item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
export def "cash-receipts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --ac-entries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-id: int # format: int64
  --detail-collection: list<string>
  --discount: float # format: double
  --entry-date: string # format: date-time
  --id: int # format: int64
  --ledger: float # format: double
  --note: string
  --plaid-transaction-id: string
  --proc-date: string # format: date-time
  --timestamp: string # format: byte
  --total: float # format: double
  --unallocated: float # format: double
  --vat-entries: list # item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
  --vat-type-id: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/cashReceipts" $auth.query)
  let req_body = {"acCode": $ac_code, "acEntries": $ac_entries, "bookTranTypeId": $book_tran_type_id, "customFields": $custom_fields, "customerId": $customer_id, "detailCollection": $detail_collection, "discount": $discount, "entryDate": $entry_date, "id": $id, "ledger": $ledger, "note": $note, "plaidTransactionId": $plaid_transaction_id, "procDate": $proc_date, "timestamp": $timestamp, "total": $total, "unallocated": $unallocated, "vatEntries": $vat_entries, "vatTypeId": $vat_type_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Processes a batch of Cash Receipts.
#
# PUT /v1/cashReceipts/batch
# operationId: CashReceipts_ProcessBatch
export def "cash-receipts-batch update-process" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/cashReceipts/batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes an existing Cash Receipt.
#
# DELETE /v1/cashReceipts/{id}
# operationId: CashReceipts_Delete
export def "cash-receipts delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Cash Receipt to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/cashReceipts/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"timestamp": $timestamp} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acCode: string, acEntries: table<accountCode: string, analysisCategoryId: int, description: string, id: int, value: float>, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, customerId: int, detailCollection: list<string>, discount: float, entryDate: string, id: int, ledger: float, note: string, plaidTransactionId: string, procDate: string, timestamp: string, total: float, unallocated: float, vatEntries: table<amount: float, id: int, percentage: float, vatRateId: int>, vatTypeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/cashReceipts/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing Cash Receipt.
#
# PUT /v1/cashReceipts/{id}
# operationId: CashReceipts_Put
# --acEntries item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --vatEntries item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
export def "cash-receipts update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --ac-entries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-id: int # format: int64
  --detail-collection: list<string>
  --discount: float # format: double
  --entry-date: string # format: date-time
  --body-id: int # format: int64
  --ledger: float # format: double
  --note: string
  --plaid-transaction-id: string
  --proc-date: string # format: date-time
  --timestamp: string # format: byte
  --total: float # format: double
  --unallocated: float # format: double
  --vat-entries: list # item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
  --vat-type-id: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/cashReceipts/{id}") $auth.query)
  let req_body = {"acCode": $ac_code, "acEntries": $ac_entries, "bookTranTypeId": $book_tran_type_id, "customFields": $custom_fields, "customerId": $customer_id, "detailCollection": $detail_collection, "discount": $discount, "entryDate": $entry_date, "id": $body_id, "ledger": $ledger, "note": $note, "plaidTransactionId": $plaid_transaction_id, "procDate": $proc_date, "timestamp": $timestamp, "total": $total, "unallocated": $unallocated, "vatEntries": $vat_entries, "vatTypeId": $vat_type_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of company's Category Types. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/categoryTypes
# operationId: CategoryTypes_Get
export def "category-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<description: string, id: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/categoryTypes" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of company settings. Supports OData querying protocol. Filtering is forbidden.
#
# GET /v1/companySettings
# operationId: CompanySettings_Get
export def "company-settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<enableVOCRReporting: bool, id: int, useAllocations: bool, value: string, vocrSettingValue: bool>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/companySettings" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the company configuration settings.
#
# GET /v1/companySetupConfig
# operationId: CompanySetupConfig_Get
export def "company-setup-config get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<financialYear: record<firstMonth: int, startMonth: int, startYear: int>, generalDetails: record<companyAddresses: list<string>, companyName: string, currencyCode: string, currencyDescription: string, currencyId: int, currentcySymbol: string, emails: list<string>, faxes: list<string>, phones: list<string>, regionDescription: string, regionId: int, vatReg: string>, options: record<allowEntryOfGrossPriceInInvoicing: bool, creditInputForReverseChargeVAT: bool, creditNoteJournalAgeingName: string, creditNoteJournalAgeingValue: int, discrepancyAllowed: float, enableVOCRReporting: bool, marginVatScheme: bool, printOSItemsOnly: bool, purchasesVatAnalysisType: int, salesVatAnalysisType: int, useAllocations: bool, useNominal: bool, useNominalCode: bool, vocrSettingValue: bool>, referenceSettings: record<creditorsJournal: bool, debtorsJournal: bool, purchases: bool, sales: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/companySetupConfig" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the company option setting.
#
# GET /v1/companySetupConfig/getCompanyOptions
# operationId: CompanySetupConfig_GetCompanyOptions
export def "company-setup-config-get-company-options get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allowEntryOfGrossPriceInInvoicing: bool, creditInputForReverseChargeVAT: bool, creditNoteJournalAgeingName: string, creditNoteJournalAgeingValue: int, discrepancyAllowed: float, enableVOCRReporting: bool, marginVatScheme: bool, printOSItemsOnly: bool, purchasesVatAnalysisType: int, salesVatAnalysisType: int, useAllocations: bool, useNominal: bool, useNominalCode: bool, vocrSettingValue: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/companySetupConfig/getCompanyOptions" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the financial year.
#
# GET /v1/companySetupConfig/getFinancialYear
# operationId: CompanySetupConfig_GetFinancialYear
export def "company-setup-config-get-financial-year get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<firstMonth: int, startMonth: int, startYear: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/companySetupConfig/getFinancialYear" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of company's Customers. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" and "code" fields.
#
# GET /v1/customers
# operationId: Customers_Get
export def "customers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<accountName: string, accountNumber: string, additionalEmails: list, address: list, authCode: string, bank: record, businessIdentifierCode: string, code: string, contact: string, delivery: list, eFTReference: string, email: string, fax: string, id: int, internationalBankAccountNumber: string, mobile: string, name: string, ourCode: string, ownerTypeId: int, phone: string, timestamp: string, vatAnalysisTypeId: int, vatReg: string, vatType: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/customers" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Customer.
#
# POST /v1/customers
# operationId: Customers_Post
# --bank shape: {branch?: string, id?: int, name?: string, sortCode?: string}
# --openingBalance shape: {currentMonth?: float, oneMonthOld?: float, threeMonthsOld?: float, twoMonthsOld?: float}
# --openingBalances item shape: {entryDate?: string, id?: int, isChanged?: bool, procDate?: string, reference?: string, timestamp?: string, total?: float, totalVAT?: float, unpaid?: float, vatEntries?: list}
export def "customers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string
  --account-number: string
  --additional-emails: list<string>
  --address: list<string>
  --auth-code: string
  --bank: record # shape: {branch?: string, id?: int, name?: string, sortCode?: string}
  --business-identifier-code: string
  --code: string
  --contact: string
  --delivery: list<string>
  --e-ft-reference: string
  --email: string
  --fax: string
  --id: int # format: int64
  --international-bank-account-number: string
  --ledger-balance: float # format: double
  --mobile: string
  --name: string
  --opening-balance: record # shape: {currentMonth?: float, oneMonthOld?: float, threeMonthsOld?: float, twoMonthsOld?: float}
  --opening-balances: list # item shape: {entryDate?: string, id?: int, isChanged?: bool, procDate?: string, reference?: string, timestamp?: string, total?: float, totalVAT?: float, unpaid?: float, vatEntries?: list}
  --our-code: string
  --owner-type-id: int # format: int64
  --phone: string
  --timestamp: string # format: byte
  --vat-analysis-type-id: int # format: int64
  --vat-reg: string
  --vat-type: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/customers" $auth.query)
  let req_body = {"accountName": $account_name, "accountNumber": $account_number, "additionalEmails": $additional_emails, "address": $address, "authCode": $auth_code, "bank": $bank, "businessIdentifierCode": $business_identifier_code, "code": $code, "contact": $contact, "delivery": $delivery, "eFTReference": $e_ft_reference, "email": $email, "fax": $fax, "id": $id, "internationalBankAccountNumber": $international_bank_account_number, "ledgerBalance": $ledger_balance, "mobile": $mobile, "name": $name, "openingBalance": $opening_balance, "openingBalances": $opening_balances, "ourCode": $our_code, "ownerTypeId": $owner_type_id, "phone": $phone, "timestamp": $timestamp, "vatAnalysisTypeId": $vat_analysis_type_id, "vatReg": $vat_reg, "vatType": $vat_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Processes a batch of Customers.
#
# PUT /v1/customers/batch
# operationId: Customers_ProcessBatch
export def "customers-batch update-process" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/customers/batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes an existing Customer.
#
# DELETE /v1/customers/{id}
# operationId: Customers_Delete
export def "customers delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Customer to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/customers/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"timestamp": $timestamp} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --need-balance: oneof<nothing, bool> # If "true" then Customer's ledger balance will be calculated; otherwise balance will be returned as 0.
]: nothing -> record<accountName: string, accountNumber: string, additionalEmails: list<string>, address: list<string>, authCode: string, bank: record<branch: string, id: int, name: string, sortCode: string>, businessIdentifierCode: string, code: string, contact: string, delivery: list<string>, eFTReference: string, email: string, fax: string, id: int, internationalBankAccountNumber: string, ledgerBalance: float, mobile: string, name: string, openingBalance: record<currentMonth: float, oneMonthOld: float, threeMonthsOld: float, twoMonthsOld: float>, openingBalances: table<entryDate: string, id: int, isChanged: bool, procDate: string, reference: string, timestamp: string, total: float, totalVAT: float, unpaid: float, vatEntries: list>, ourCode: string, ownerTypeId: int, phone: string, timestamp: string, vatAnalysisTypeId: int, vatReg: string, vatType: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "needBalance" $need_balance "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/customers/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"needBalance": $need_balance} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing Customer.
#
# PUT /v1/customers/{id}
# operationId: Customers_Put
# --bank shape: {branch?: string, id?: int, name?: string, sortCode?: string}
# --openingBalance shape: {currentMonth?: float, oneMonthOld?: float, threeMonthsOld?: float, twoMonthsOld?: float}
# --openingBalances item shape: {entryDate?: string, id?: int, isChanged?: bool, procDate?: string, reference?: string, timestamp?: string, total?: float, totalVAT?: float, unpaid?: float, vatEntries?: list}
export def "customers update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string
  --account-number: string
  --additional-emails: list<string>
  --address: list<string>
  --auth-code: string
  --bank: record # shape: {branch?: string, id?: int, name?: string, sortCode?: string}
  --business-identifier-code: string
  --code: string
  --contact: string
  --delivery: list<string>
  --e-ft-reference: string
  --email: string
  --fax: string
  --body-id: int # format: int64
  --international-bank-account-number: string
  --ledger-balance: float # format: double
  --mobile: string
  --name: string
  --opening-balance: record # shape: {currentMonth?: float, oneMonthOld?: float, threeMonthsOld?: float, twoMonthsOld?: float}
  --opening-balances: list # item shape: {entryDate?: string, id?: int, isChanged?: bool, procDate?: string, reference?: string, timestamp?: string, total?: float, totalVAT?: float, unpaid?: float, vatEntries?: list}
  --our-code: string
  --owner-type-id: int # format: int64
  --phone: string
  --timestamp: string # format: byte
  --vat-analysis-type-id: int # format: int64
  --vat-reg: string
  --vat-type: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/customers/{id}") $auth.query)
  let req_body = {"accountName": $account_name, "accountNumber": $account_number, "additionalEmails": $additional_emails, "address": $address, "authCode": $auth_code, "bank": $bank, "businessIdentifierCode": $business_identifier_code, "code": $code, "contact": $contact, "delivery": $delivery, "eFTReference": $e_ft_reference, "email": $email, "fax": $fax, "id": $body_id, "internationalBankAccountNumber": $international_bank_account_number, "ledgerBalance": $ledger_balance, "mobile": $mobile, "name": $name, "openingBalance": $opening_balance, "openingBalances": $opening_balances, "ourCode": $our_code, "ownerTypeId": $owner_type_id, "phone": $phone, "timestamp": $timestamp, "vatAnalysisTypeId": $vat_analysis_type_id, "vatReg": $vat_reg, "vatType": $vat_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of Customer's account transactions.
#
# GET /v1/customers/{itemId}/accountTrans
# operationId: Customers_GetAccountTrans
export def "customers-account-trans get" [
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<bookTranId: int, bookTranTypeId: int, bookTransactionReference: string, bookTypeDesc: string, credit: float, debit: float, id: int, procDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/v1/customers/{item_id}/accountTrans") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a Customer's opening balances, calculated for the next periods: current month, one month old, two months old, three and more months old.
#
# GET /v1/customers/{itemId}/openingBalance
# operationId: Customers_GetOpeningBalance
export def "customers-opening-balance get" [
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<currentMonth: float, oneMonthOld: float, threeMonthsOld: float, twoMonthsOld: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/v1/customers/{item_id}/openingBalance") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of Customer's opening balance transactions.
#
# GET /v1/customers/{itemId}/openingBalanceList
# operationId: Customers_GetOpeningBalanceList
export def "customers-opening-balance-list get" [
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<entryDate: string, id: int, isChanged: bool, procDate: string, reference: string, timestamp: string, total: float, totalVAT: float, unpaid: float, vatEntries: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/v1/customers/{item_id}/openingBalanceList") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of Customer's quotes.
#
# GET /v1/customers/{itemId}/quotes
# operationId: Customers_GetQuotes
export def "customers-quotes get" [
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<acCode: string, closedDate: string, comments: string, companyId: int, customFields: list<record>, customerOwnerId: int, customerOwnerName: string, ddNumber: string, deliveryList: string, deliveryTo: list<string>, entryDate: string, id: int, layoutType: int, note: string, poNumber: string, procDate: string, productTrans: list<record>, reference: string, saleInvoiceId: int, saleRepCode: string, saleRepId: int, timeStamp: string, total: float, totalNet: float, totalVat: float, vatTypeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/v1/customers/{item_id}/quotes") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Sends a Statement email. If "toAddress" is not empty then email will be sent to this address. Otherwise email will be sent to Statement Customer's address.
#
# POST /v1/email/sendEmailStatement
# operationId: Email_SendEmailStatement
export def "email-send-email-statement send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bcc-addresses: list<string>
  --customer-id: int # format: int64
  --from-period: string # format: date-time
  --message-body: string
  --minimum-balance: float # format: double
  --to-address: string
  --to-period: string # format: date-time
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/email/sendEmailStatement" $auth.query)
  let req_body = {"bccAddresses": $bcc_addresses, "customerId": $customer_id, "fromPeriod": $from_period, "messageBody": $message_body, "minimumBalance": $minimum_balance, "toAddress": $to_address, "toPeriod": $to_period} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Sends a Quote email. If "toAddress" is not empty then email will be sent to this address. Otherwise email will be sent to Statement Customer's address.
#
# POST /v1/email/sendQuote
# operationId: Email_SendQuote
export def "email-send-quote send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bcc-addresses: list<string>
  --message-body: string
  --quote-id: int # format: int64
  --to-address: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/email/sendQuote" $auth.query)
  let req_body = {"bccAddresses": $bcc_addresses, "messageBody": $message_body, "quoteId": $quote_id, "toAddress": $to_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Sends a Sales Invoice email. If "toAddress" is not empty then email will be sent to this address. Otherwise email will be sent to Sales Invoice Customer's address.
#
# POST /v1/email/sendSalesInvoice
# operationId: Email_SendSalesInvoice
export def "email-send-sales-invoice send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bcc-addresses: list<string>
  --message-body: string
  --sales-invoice-id: int # format: int64
  --to-address: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/email/sendSalesInvoice" $auth.query)
  let req_body = {"bccAddresses": $bcc_addresses, "messageBody": $message_body, "salesInvoiceId": $sales_invoice_id, "toAddress": $to_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of global Owner Type Groups. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/ownerTypeGroups
# operationId: OwnerTypeGroups_Get
export def "owner-type-groups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<description: string, id: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ownerTypeGroups" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of global Owner Types. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/ownerTypes
# operationId: OwnerTypes_Get
export def "owner-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<description: string, id: int, recordTypeGroupId: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/ownerTypes" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of company's Payments. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/payments
# operationId: Payments_Get
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
]: nothing -> record<Count: int, Items: table<acCode: string, acEntries: list, bankAccountCode: string, bankAccountId: int, bookTranTypeId: int, customFields: list, detailCollection: list, discount: float, entryDate: string, id: int, note: string, plaidTransactionId: string, procDate: string, reference: string, supplierId: int, timestamp: string, total: float, transferBankCode: string, transferBankId: int, unallocated: float>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/payments" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Payment.
#
# POST /v1/payments
# operationId: Payments_Post
# --acEntries item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
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
  --ac-code: string
  --ac-entries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --bank-account-code: string
  --bank-account-id: int # format: int64
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --detail-collection: list<string>
  --discount: float # format: double
  --entry-date: string # format: date-time
  --id: int # format: int64
  --note: string
  --plaid-transaction-id: string
  --proc-date: string # format: date-time
  --reference: string
  --supplier-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --transfer-bank-code: string
  --transfer-bank-id: int # format: int64
  --unallocated: float # format: double
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/payments" $auth.query)
  let req_body = {"acCode": $ac_code, "acEntries": $ac_entries, "bankAccountCode": $bank_account_code, "bankAccountId": $bank_account_id, "bookTranTypeId": $book_tran_type_id, "customFields": $custom_fields, "detailCollection": $detail_collection, "discount": $discount, "entryDate": $entry_date, "id": $id, "note": $note, "plaidTransactionId": $plaid_transaction_id, "procDate": $proc_date, "reference": $reference, "supplierId": $supplier_id, "timestamp": $timestamp, "total": $total, "transferBankCode": $transfer_bank_code, "transferBankId": $transfer_bank_id, "unallocated": $unallocated} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Processes a batch of Payments.
#
# PUT /v1/payments/batch
# operationId: Payments_ProcessBatch
export def "payments-batch update-process" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/payments/batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes an existing Payment.
#
# DELETE /v1/payments/{id}
# operationId: Payments_Delete
export def "payments delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Payment to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/payments/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"timestamp": $timestamp} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acCode: string, acEntries: table<accountCode: string, analysisCategoryId: int, description: string, id: int, value: float>, bankAccountCode: string, bankAccountId: int, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, detailCollection: list<string>, discount: float, entryDate: string, id: int, note: string, plaidTransactionId: string, procDate: string, reference: string, supplierId: int, timestamp: string, total: float, transferBankCode: string, transferBankId: int, unallocated: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/payments/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing Payment.
#
# PUT /v1/payments/{id}
# operationId: Payments_Put
# --acEntries item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
export def "payments update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --ac-entries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --bank-account-code: string
  --bank-account-id: int # format: int64
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --detail-collection: list<string>
  --discount: float # format: double
  --entry-date: string # format: date-time
  --body-id: int # format: int64
  --note: string
  --plaid-transaction-id: string
  --proc-date: string # format: date-time
  --reference: string
  --supplier-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --transfer-bank-code: string
  --transfer-bank-id: int # format: int64
  --unallocated: float # format: double
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/payments/{id}") $auth.query)
  let req_body = {"acCode": $ac_code, "acEntries": $ac_entries, "bankAccountCode": $bank_account_code, "bankAccountId": $bank_account_id, "bookTranTypeId": $book_tran_type_id, "customFields": $custom_fields, "detailCollection": $detail_collection, "discount": $discount, "entryDate": $entry_date, "id": $body_id, "note": $note, "plaidTransactionId": $plaid_transaction_id, "procDate": $proc_date, "reference": $reference, "supplierId": $supplier_id, "timestamp": $timestamp, "total": $total, "transferBankCode": $transfer_bank_code, "transferBankId": $transfer_bank_id, "unallocated": $unallocated} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of global Product Types. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/productTypes
# operationId: ProductTypes_Get
export def "product-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<description: string, id: int, recordTypeGroupId: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/productTypes" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of company's Products. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" and "stockCode" fields.
#
# GET /v1/products
# operationId: Products_Get
export def "products list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<details: list, grossUnitPrice: bool, hasDefaultVatRate: bool, id: int, productTypeId: int, stockCode: string, timestamp: string, unitPrice: float, vatAnalysisTypeId: int, vatRateId: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/products" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Product.
#
# POST /v1/products
# operationId: Products_Post
export def "products create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --details: list<string>
  --gross-unit-price: oneof<nothing, bool>
  --has-default-vat-rate: oneof<nothing, bool>
  --id: int # format: int64
  --product-type-id: int # format: int64
  --stock-code: string
  --timestamp: string # format: byte
  --unit-price: float # format: double
  --vat-analysis-type-id: int # format: int64
  --vat-rate-id: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/products" $auth.query)
  let req_body = {"details": $details, "grossUnitPrice": $gross_unit_price, "hasDefaultVatRate": $has_default_vat_rate, "id": $id, "productTypeId": $product_type_id, "stockCode": $stock_code, "timestamp": $timestamp, "unitPrice": $unit_price, "vatAnalysisTypeId": $vat_analysis_type_id, "vatRateId": $vat_rate_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Processes a batch of Products.
#
# PUT /v1/products/batch
# operationId: Products_ProcessBatch
export def "products-batch update-process" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/products/batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes an existing Product.
#
# DELETE /v1/products/{id}
# operationId: Products_Delete
export def "products delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Product to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/products/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"timestamp": $timestamp} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<details: list<string>, grossUnitPrice: bool, hasDefaultVatRate: bool, id: int, productTypeId: int, stockCode: string, timestamp: string, unitPrice: float, vatAnalysisTypeId: int, vatRateId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/products/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing Product.
#
# PUT /v1/products/{id}
# operationId: Products_Put
export def "products update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --details: list<string>
  --gross-unit-price: oneof<nothing, bool>
  --has-default-vat-rate: oneof<nothing, bool>
  --body-id: int # format: int64
  --product-type-id: int # format: int64
  --stock-code: string
  --timestamp: string # format: byte
  --unit-price: float # format: double
  --vat-analysis-type-id: int # format: int64
  --vat-rate-id: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/products/{id}") $auth.query)
  let req_body = {"details": $details, "grossUnitPrice": $gross_unit_price, "hasDefaultVatRate": $has_default_vat_rate, "id": $body_id, "productTypeId": $product_type_id, "stockCode": $stock_code, "timestamp": $timestamp, "unitPrice": $unit_price, "vatAnalysisTypeId": $vat_analysis_type_id, "vatRateId": $vat_rate_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of company's Purchases. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/purchases
# operationId: Purchases_Get
export def "purchases list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<acCode: string, acEntries: list, bookTranTypeId: int, customFields: list, detailCollection: list, entryDate: string, id: int, netGoods: float, netServices: float, note: string, postponedAccounting: bool, procDate: string, reference: string, supplierId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unallocated: float, unpaid: float, vatEntries: list, vatTypeId: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/purchases" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Purchase.
#
# POST /v1/purchases
# operationId: Purchases_Post
# --acEntries item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --vatEntries item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
export def "purchases create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --ac-entries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --detail-collection: list<string>
  --entry-date: string # format: date-time
  --id: int # format: int64
  --is-discrepancy-accepted: oneof<nothing, bool>
  --net-goods: float # format: double
  --net-services: float # format: double
  --note: string
  --postponed-accounting: oneof<nothing, bool>
  --proc-date: string # format: date-time
  --reference: string
  --supplier-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --unallocated: float # format: double
  --unpaid: float # format: double
  --vat-entries: list # item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
  --vat-type-id: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/purchases" $auth.query)
  let req_body = {"acCode": $ac_code, "acEntries": $ac_entries, "bookTranTypeId": $book_tran_type_id, "customFields": $custom_fields, "detailCollection": $detail_collection, "entryDate": $entry_date, "id": $id, "isDiscrepancyAccepted": $is_discrepancy_accepted, "netGoods": $net_goods, "netServices": $net_services, "note": $note, "postponedAccounting": $postponed_accounting, "procDate": $proc_date, "reference": $reference, "supplierId": $supplier_id, "timestamp": $timestamp, "total": $total, "totalNet": $total_net, "totalVAT": $total_vat, "unallocated": $unallocated, "unpaid": $unpaid, "vatEntries": $vat_entries, "vatTypeId": $vat_type_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Processes a batch of Purchases.
#
# PUT /v1/purchases/batch
# operationId: Purchases_ProcessBatch
export def "purchases-batch update-process" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/purchases/batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes an existing Purchase.
#
# DELETE /v1/purchases/{id}
# operationId: Purchases_Delete
export def "purchases delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Purchase to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/purchases/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"timestamp": $timestamp} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acCode: string, acEntries: table<accountCode: string, analysisCategoryId: int, description: string, id: int, value: float>, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, detailCollection: list<string>, entryDate: string, id: int, isDiscrepancyAccepted: bool, netGoods: float, netServices: float, note: string, postponedAccounting: bool, procDate: string, reference: string, supplierId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unallocated: float, unpaid: float, vatEntries: table<amount: float, id: int, percentage: float, vatRateId: int>, vatTypeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/purchases/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing Purchase.
#
# PUT /v1/purchases/{id}
# operationId: Purchases_Put
# --acEntries item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --vatEntries item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
export def "purchases update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --ac-entries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --detail-collection: list<string>
  --entry-date: string # format: date-time
  --body-id: int # format: int64
  --is-discrepancy-accepted: oneof<nothing, bool>
  --net-goods: float # format: double
  --net-services: float # format: double
  --note: string
  --postponed-accounting: oneof<nothing, bool>
  --proc-date: string # format: date-time
  --reference: string
  --supplier-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --unallocated: float # format: double
  --unpaid: float # format: double
  --vat-entries: list # item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
  --vat-type-id: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/purchases/{id}") $auth.query)
  let req_body = {"acCode": $ac_code, "acEntries": $ac_entries, "bookTranTypeId": $book_tran_type_id, "customFields": $custom_fields, "detailCollection": $detail_collection, "entryDate": $entry_date, "id": $body_id, "isDiscrepancyAccepted": $is_discrepancy_accepted, "netGoods": $net_goods, "netServices": $net_services, "note": $note, "postponedAccounting": $postponed_accounting, "procDate": $proc_date, "reference": $reference, "supplierId": $supplier_id, "timestamp": $timestamp, "total": $total, "totalNet": $total_net, "totalVAT": $total_vat, "unallocated": $unallocated, "unpaid": $unpaid, "vatEntries": $vat_entries, "vatTypeId": $vat_type_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of company's Quotes. Filtering is forbidden. Ordering is allowed by "id".
#
# GET /v1/quotes
# operationId: Quote_Get
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
]: nothing -> record<Count: int, Items: table<acCode: string, closedDate: string, comments: string, companyId: int, customFields: list, customerOwnerId: int, customerOwnerName: string, ddNumber: string, deliveryList: string, deliveryTo: list, entryDate: string, id: int, layoutType: int, note: string, poNumber: string, procDate: string, productTrans: list, reference: string, saleInvoiceId: int, saleRepCode: string, saleRepId: int, timeStamp: string, total: float, totalNet: float, totalVat: float, vatTypeId: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/quotes" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Quote.
#
# POST /v1/quotes
# operationId: Quote_Post
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --productTrans item shape: {acEntries?: list, amount?: float, companyId?: int, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vatAmount?: float, vatAnalysisTypeId?: int, vatRateId?: int}
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
  --ac-code: string
  --closed-date: string # format: date-time
  --comments: string
  --company-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-owner-id: int # format: int64
  --customer-owner-name: string
  --dd-number: string
  --delivery-list: string
  --delivery-to: list<string>
  --entry-date: string # format: date-time
  --id: int # format: int64
  --layout-type: int # format: int32
  --note: string
  --po-number: string
  --proc-date: string # format: date-time
  --product-trans: list # item shape: {acEntries?: list, amount?: float, companyId?: int, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vatAmount?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --reference: string
  --sale-invoice-id: int # format: int64
  --sale-rep-code: string
  --sale-rep-id: int # format: int64
  --time-stamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --vat-type-id: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/quotes" $auth.query)
  let req_body = {"acCode": $ac_code, "closedDate": $closed_date, "comments": $comments, "companyId": $company_id, "customFields": $custom_fields, "customerOwnerId": $customer_owner_id, "customerOwnerName": $customer_owner_name, "ddNumber": $dd_number, "deliveryList": $delivery_list, "deliveryTo": $delivery_to, "entryDate": $entry_date, "id": $id, "layoutType": $layout_type, "note": $note, "poNumber": $po_number, "procDate": $proc_date, "productTrans": $product_trans, "reference": $reference, "saleInvoiceId": $sale_invoice_id, "saleRepCode": $sale_rep_code, "saleRepId": $sale_rep_id, "timeStamp": $time_stamp, "total": $total, "totalNet": $total_net, "totalVat": $total_vat, "vatTypeId": $vat_type_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Processes a batch of Quote.
#
# PUT /v1/quotes/batch
# operationId: Quote_ProcessBatch
export def "quotes-batch update-process" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/quotes/batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Close a Quote.
#
# PUT /v1/quotes/close/{id}
# operationId: Quote_Close
export def "quotes-close close" [
  id: int
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/quotes/close/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Creates a new Quote with auto generating reference.
#
# POST /v1/quotes/createQuoteWithGeneratingReference
# operationId: Quote_Post_CreateQuoteWithGeneratingReference
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --productTrans item shape: {acEntries?: list, amount?: float, companyId?: int, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vatAmount?: float, vatAnalysisTypeId?: int, vatRateId?: int}
export def "quotes-create-quote-with-generating-reference create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --closed-date: string # format: date-time
  --comments: string
  --company-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-owner-id: int # format: int64
  --customer-owner-name: string
  --dd-number: string
  --delivery-list: string
  --delivery-to: list<string>
  --entry-date: string # format: date-time
  --id: int # format: int64
  --layout-type: int # format: int32
  --note: string
  --po-number: string
  --proc-date: string # format: date-time
  --product-trans: list # item shape: {acEntries?: list, amount?: float, companyId?: int, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vatAmount?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --reference: string
  --sale-invoice-id: int # format: int64
  --sale-rep-code: string
  --sale-rep-id: int # format: int64
  --time-stamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --vat-type-id: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/quotes/createQuoteWithGeneratingReference" $auth.query)
  let req_body = {"acCode": $ac_code, "closedDate": $closed_date, "comments": $comments, "companyId": $company_id, "customFields": $custom_fields, "customerOwnerId": $customer_owner_id, "customerOwnerName": $customer_owner_name, "ddNumber": $dd_number, "deliveryList": $delivery_list, "deliveryTo": $delivery_to, "entryDate": $entry_date, "id": $id, "layoutType": $layout_type, "note": $note, "poNumber": $po_number, "procDate": $proc_date, "productTrans": $product_trans, "reference": $reference, "saleInvoiceId": $sale_invoice_id, "saleRepCode": $sale_rep_code, "saleRepId": $sale_rep_id, "timeStamp": $time_stamp, "total": $total, "totalNet": $total_net, "totalVat": $total_vat, "vatTypeId": $vat_type_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Generate a sale invoice from a Quote. When sale invoice is empty, new sale invoice will be generated from Quote.
#
# POST /v1/quotes/generateSaleInvoice
# operationId: Quote_Post_GenerateSaleInvoice
# --saleInvoice shape: {acCode?: string, bookTranTypeId?: int, customFields?: list, customerId?: int, deliveryTo?: list<string>, details?: string, entryDate?: string, id?: int, loType?: string, netGoods?: float, netServices?: float, note?: string, ourReference?: string, procDate?: string, productTrans?: list, quoteId?: int, reference?: string, saleRepCode?: string, saleRepId?: int, timestamp?: string, total?: float, totalNet?: float, totalVAT?: float, unpaid?: float, vatTypeId?: int, yourReference?: string}
export def "quotes-generate-sale-invoice create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --quote-id: int # format: int64
  --sale-invoice: record # e.g. {acCode: CUS3, bookTranTypeId: 7, customFields: [{description: acudf_1, id: 1, userDefinedFieldId: 1, value: acudfv_1}, {description: acudf_2, id: 2, userDefinedFieldId: 1, value: acudfv_2}], customerId: 70585, deliveryTo: [dt_1, dt_2], details: detail_1, entryDate: 2016-06-01T00:00:00, id: 75813, loType: 1, note: Customer 3, ourReference: ddNumber_1, procDate: 2016-06-24T00:00:00, productTrans: [{acEntries: [{accountCode: SA02, analysisCategoryId: 40889, description: AnCat1, id: 73455, value: -200}], amount: -220, amountNet: -200, id: 51820, percentage: 10, productCode: PRO2, productId: 20108, quantity: -1, tranNotes: [tn_1, tn_2], unitPrice: 200, vat: -20, vatAnalysisTypeId: 0, vatRateId: 30657}], saleRepId: 33110, timestamp: oq6NcBIe2wg=, total: -220, totalNet: -200, totalVAT: -20, unpaid: -220, vatTypeId: 1, yourReference: poNumber_1} — shape: {acCode?: string, bookTranTypeId?: int, customFields?: list, customerId?: int, deliveryTo?: list<string>, details?: string, entryDate?: string, id?: int, loType?: string, netGoods?: float, netServices?: float, note?: string, ourReference?: string, procDate?: string, productTrans?: list, quoteId?: int, reference?: string, saleRepCode?: string, saleRepId?: int, timestamp?: string, total?: float, totalNet?: float, totalVAT?: float, unpaid?: float, vatTypeId?: int, yourReference?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/quotes/generateSaleInvoice" $auth.query)
  let req_body = {"quoteId": $quote_id, "saleInvoice": $sale_invoice} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Reopen a Quote.
#
# PUT /v1/quotes/reopen/{id}
# operationId: Quote_Reopen
export def "quotes-reopen update" [
  id: int
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/quotes/reopen/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Removes an existing Quote.
#
# DELETE /v1/quotes/{id}
# operationId: Quote_Delete
export def "quotes delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Quote to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/quotes/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"timestamp": $timestamp} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acCode: string, closedDate: string, comments: string, companyId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, customerOwnerId: int, customerOwnerName: string, ddNumber: string, deliveryList: string, deliveryTo: list<string>, entryDate: string, id: int, layoutType: int, note: string, poNumber: string, procDate: string, productTrans: table<acEntries: list, amount: float, companyId: int, id: int, percentage: float, productCode: string, productId: int, quantity: float, tranNotes: list, unitPrice: float, vatAmount: float, vatAnalysisTypeId: int, vatRateId: int>, reference: string, saleInvoiceId: int, saleRepCode: string, saleRepId: int, timeStamp: string, total: float, totalNet: float, totalVat: float, vatTypeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/quotes/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing Quote.
#
# PUT /v1/quotes/{id}
# operationId: Quote_Put
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --productTrans item shape: {acEntries?: list, amount?: float, companyId?: int, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vatAmount?: float, vatAnalysisTypeId?: int, vatRateId?: int}
export def "quotes update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --closed-date: string # format: date-time
  --comments: string
  --company-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-owner-id: int # format: int64
  --customer-owner-name: string
  --dd-number: string
  --delivery-list: string
  --delivery-to: list<string>
  --entry-date: string # format: date-time
  --body-id: int # format: int64
  --layout-type: int # format: int32
  --note: string
  --po-number: string
  --proc-date: string # format: date-time
  --product-trans: list # item shape: {acEntries?: list, amount?: float, companyId?: int, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vatAmount?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --reference: string
  --sale-invoice-id: int # format: int64
  --sale-rep-code: string
  --sale-rep-id: int # format: int64
  --time-stamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --vat-type-id: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/quotes/{id}") $auth.query)
  let req_body = {"acCode": $ac_code, "closedDate": $closed_date, "comments": $comments, "companyId": $company_id, "customFields": $custom_fields, "customerOwnerId": $customer_owner_id, "customerOwnerName": $customer_owner_name, "ddNumber": $dd_number, "deliveryList": $delivery_list, "deliveryTo": $delivery_to, "entryDate": $entry_date, "id": $body_id, "layoutType": $layout_type, "note": $note, "poNumber": $po_number, "procDate": $proc_date, "productTrans": $product_trans, "reference": $reference, "saleInvoiceId": $sale_invoice_id, "saleRepCode": $sale_rep_code, "saleRepId": $sale_rep_id, "timeStamp": $time_stamp, "total": $total, "totalNet": $total_net, "totalVat": $total_vat, "vatTypeId": $vat_type_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of company's Sales Entries, Sales Invoices and Sales Credit Notes. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/sales
# operationId: Sales_Get
export def "sales get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<acCode: string, acEntries: list, bookTranTypeId: int, customFields: list, customerId: int, details: string, entryDate: string, id: int, loType: string, note: string, procDate: string, reference: string, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatEntries: list, vatTypeId: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sales" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of company's Sales Credit Notes. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/salesCreditNotes
# operationId: SalesCreditNotes_Get
export def "sales-credit-notes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<acCode: string, bookTranTypeId: int, customFields: list, customerId: int, deliveryTo: list, details: string, entryDate: string, id: int, loType: string, netGoods: float, netServices: float, note: string, ourReference: string, procDate: string, productTrans: list, quoteId: int, reference: string, saleRepCode: string, saleRepId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatTypeId: int, yourReference: string>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesCreditNotes" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Sales Credit Note.
#
# POST /v1/salesCreditNotes
# operationId: SalesCreditNotes_Post
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --productTrans item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
export def "sales-credit-notes create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-id: int # format: int64
  --delivery-to: list<string>
  --details: string
  --entry-date: string # format: date-time
  --id: int # format: int64
  --lo-type: string
  --net-goods: float # format: double
  --net-services: float # format: double
  --note: string
  --our-reference: string
  --proc-date: string # format: date-time
  --product-trans: list # item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --quote-id: int # format: int64
  --reference: string
  --sale-rep-code: string
  --sale-rep-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --unpaid: float # format: double
  --vat-type-id: int # format: int64
  --your-reference: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesCreditNotes" $auth.query)
  let req_body = {"acCode": $ac_code, "bookTranTypeId": $book_tran_type_id, "customFields": $custom_fields, "customerId": $customer_id, "deliveryTo": $delivery_to, "details": $details, "entryDate": $entry_date, "id": $id, "loType": $lo_type, "netGoods": $net_goods, "netServices": $net_services, "note": $note, "ourReference": $our_reference, "procDate": $proc_date, "productTrans": $product_trans, "quoteId": $quote_id, "reference": $reference, "saleRepCode": $sale_rep_code, "saleRepId": $sale_rep_id, "timestamp": $timestamp, "total": $total, "totalNet": $total_net, "totalVAT": $total_vat, "unpaid": $unpaid, "vatTypeId": $vat_type_id, "yourReference": $your_reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Processes a batch of Sales Credit Notes.
#
# PUT /v1/salesCreditNotes/batch
# operationId: SalesCreditNotes_ProcessBatch
export def "sales-credit-notes-batch update-process" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesCreditNotes/batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes an existing Sales Credit Note.
#
# DELETE /v1/salesCreditNotes/{id}
# operationId: SalesCreditNotes_Delete
export def "sales-credit-notes delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Sales Credit Note to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/salesCreditNotes/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"timestamp": $timestamp} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acCode: string, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, customerId: int, deliveryTo: list<string>, details: string, entryDate: string, id: int, loType: string, netGoods: float, netServices: float, note: string, ourReference: string, procDate: string, productTrans: table<acEntries: list, amount: float, amountNet: float, id: int, percentage: float, productCode: string, productId: int, quantity: float, tranNotes: list, unitPrice: float, vat: float, vatAnalysisTypeId: int, vatRateId: int>, quoteId: int, reference: string, saleRepCode: string, saleRepId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatTypeId: int, yourReference: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/salesCreditNotes/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing Sales Credit Note.
#
# PUT /v1/salesCreditNotes/{id}
# operationId: SalesCreditNotes_Put
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --productTrans item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
export def "sales-credit-notes update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-id: int # format: int64
  --delivery-to: list<string>
  --details: string
  --entry-date: string # format: date-time
  --body-id: int # format: int64
  --lo-type: string
  --net-goods: float # format: double
  --net-services: float # format: double
  --note: string
  --our-reference: string
  --proc-date: string # format: date-time
  --product-trans: list # item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --quote-id: int # format: int64
  --reference: string
  --sale-rep-code: string
  --sale-rep-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --unpaid: float # format: double
  --vat-type-id: int # format: int64
  --your-reference: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/salesCreditNotes/{id}") $auth.query)
  let req_body = {"acCode": $ac_code, "bookTranTypeId": $book_tran_type_id, "customFields": $custom_fields, "customerId": $customer_id, "deliveryTo": $delivery_to, "details": $details, "entryDate": $entry_date, "id": $body_id, "loType": $lo_type, "netGoods": $net_goods, "netServices": $net_services, "note": $note, "ourReference": $our_reference, "procDate": $proc_date, "productTrans": $product_trans, "quoteId": $quote_id, "reference": $reference, "saleRepCode": $sale_rep_code, "saleRepId": $sale_rep_id, "timestamp": $timestamp, "total": $total, "totalNet": $total_net, "totalVAT": $total_vat, "unpaid": $unpaid, "vatTypeId": $vat_type_id, "yourReference": $your_reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of company's Sales Entries. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/salesEntries
# operationId: SalesEntries_Get
export def "sales-entries list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<acCode: string, acEntries: list, bookTranTypeId: int, customFields: list, customerId: int, detailCollection: list, details: string, entryDate: string, id: int, netGoods: float, netServices: float, note: string, procDate: string, reference: string, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatEntries: list, vatTypeId: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesEntries" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Sales Entry.
#
# POST /v1/salesEntries
# operationId: SalesEntries_Post
# --acEntries item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --vatEntries item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
export def "sales-entries create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --ac-entries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-id: int # format: int64
  --detail-collection: list<string>
  --details: string
  --entry-date: string # format: date-time
  --id: int # format: int64
  --net-goods: float # format: double
  --net-services: float # format: double
  --note: string
  --proc-date: string # format: date-time
  --reference: string
  --timestamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --unpaid: float # format: double
  --vat-entries: list # item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
  --vat-type-id: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesEntries" $auth.query)
  let req_body = {"acCode": $ac_code, "acEntries": $ac_entries, "bookTranTypeId": $book_tran_type_id, "customFields": $custom_fields, "customerId": $customer_id, "detailCollection": $detail_collection, "details": $details, "entryDate": $entry_date, "id": $id, "netGoods": $net_goods, "netServices": $net_services, "note": $note, "procDate": $proc_date, "reference": $reference, "timestamp": $timestamp, "total": $total, "totalNet": $total_net, "totalVAT": $total_vat, "unpaid": $unpaid, "vatEntries": $vat_entries, "vatTypeId": $vat_type_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Processes a batch of Sales Entries.
#
# PUT /v1/salesEntries/batch
# operationId: SalesEntries_ProcessBatch
export def "sales-entries-batch update-process" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesEntries/batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes an existing Sales Entry.
#
# DELETE /v1/salesEntries/{id}
# operationId: SalesEntries_Delete
export def "sales-entries delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Sales Entry to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/salesEntries/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"timestamp": $timestamp} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acCode: string, acEntries: table<accountCode: string, analysisCategoryId: int, description: string, id: int, value: float>, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, customerId: int, detailCollection: list<string>, details: string, entryDate: string, id: int, netGoods: float, netServices: float, note: string, procDate: string, reference: string, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatEntries: table<amount: float, id: int, percentage: float, vatRateId: int>, vatTypeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/salesEntries/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing Sales Entry.
#
# PUT /v1/salesEntries/{id}
# operationId: SalesEntries_Put
# --acEntries item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --vatEntries item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
export def "sales-entries update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --ac-entries: list # item shape: {accountCode?: string, analysisCategoryId?: int, description?: string, id?: int, value?: float}
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-id: int # format: int64
  --detail-collection: list<string>
  --details: string
  --entry-date: string # format: date-time
  --body-id: int # format: int64
  --net-goods: float # format: double
  --net-services: float # format: double
  --note: string
  --proc-date: string # format: date-time
  --reference: string
  --timestamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --unpaid: float # format: double
  --vat-entries: list # item shape: {amount?: float, id?: int, percentage?: float, vatRateId?: int}
  --vat-type-id: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/salesEntries/{id}") $auth.query)
  let req_body = {"acCode": $ac_code, "acEntries": $ac_entries, "bookTranTypeId": $book_tran_type_id, "customFields": $custom_fields, "customerId": $customer_id, "detailCollection": $detail_collection, "details": $details, "entryDate": $entry_date, "id": $body_id, "netGoods": $net_goods, "netServices": $net_services, "note": $note, "procDate": $proc_date, "reference": $reference, "timestamp": $timestamp, "total": $total, "totalNet": $total_net, "totalVAT": $total_vat, "unpaid": $unpaid, "vatEntries": $vat_entries, "vatTypeId": $vat_type_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of company's Sales Invoices. Supports OData querying protocol. Filtering is allowed by "entryDate" field. Ordering is allowed by "id" field.
#
# GET /v1/salesInvoices
# operationId: SalesInvoices_Get
export def "sales-invoices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<acCode: string, bookTranTypeId: int, customFields: list, customerId: int, deliveryTo: list, details: string, entryDate: string, id: int, loType: string, netGoods: float, netServices: float, note: string, ourReference: string, procDate: string, productTrans: list, quoteId: int, reference: string, saleRepCode: string, saleRepId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatTypeId: int, yourReference: string>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesInvoices" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Sales Invoice.
#
# POST /v1/salesInvoices
# operationId: SalesInvoices_Post
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --productTrans item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
export def "sales-invoices create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-id: int # format: int64
  --delivery-to: list<string>
  --details: string
  --entry-date: string # format: date-time
  --id: int # format: int64
  --lo-type: string
  --net-goods: float # format: double
  --net-services: float # format: double
  --note: string
  --our-reference: string
  --proc-date: string # format: date-time
  --product-trans: list # item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --quote-id: int # format: int64
  --reference: string
  --sale-rep-code: string
  --sale-rep-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --unpaid: float # format: double
  --vat-type-id: int # format: int64
  --your-reference: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesInvoices" $auth.query)
  let req_body = {"acCode": $ac_code, "bookTranTypeId": $book_tran_type_id, "customFields": $custom_fields, "customerId": $customer_id, "deliveryTo": $delivery_to, "details": $details, "entryDate": $entry_date, "id": $id, "loType": $lo_type, "netGoods": $net_goods, "netServices": $net_services, "note": $note, "ourReference": $our_reference, "procDate": $proc_date, "productTrans": $product_trans, "quoteId": $quote_id, "reference": $reference, "saleRepCode": $sale_rep_code, "saleRepId": $sale_rep_id, "timestamp": $timestamp, "total": $total, "totalNet": $total_net, "totalVAT": $total_vat, "unpaid": $unpaid, "vatTypeId": $vat_type_id, "yourReference": $your_reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Processes a batch of Sales Invoices.
#
# PUT /v1/salesInvoices/batch
# operationId: SalesInvoices_ProcessBatch
export def "sales-invoices-batch update-process" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesInvoices/batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a new Sale Invoice with auto generating reference.
#
# POST /v1/salesInvoices/createSaleInvoiceWithGeneratingReference
# operationId: SalesInvoices_Post_CreateSaleInvoiceWithGeneratingReference
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --productTrans item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
export def "sales-invoices-create-sale-invoice-with-generating-reference create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-id: int # format: int64
  --delivery-to: list<string>
  --details: string
  --entry-date: string # format: date-time
  --id: int # format: int64
  --lo-type: string
  --net-goods: float # format: double
  --net-services: float # format: double
  --note: string
  --our-reference: string
  --proc-date: string # format: date-time
  --product-trans: list # item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --quote-id: int # format: int64
  --reference: string
  --sale-rep-code: string
  --sale-rep-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --unpaid: float # format: double
  --vat-type-id: int # format: int64
  --your-reference: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesInvoices/createSaleInvoiceWithGeneratingReference" $auth.query)
  let req_body = {"acCode": $ac_code, "bookTranTypeId": $book_tran_type_id, "customFields": $custom_fields, "customerId": $customer_id, "deliveryTo": $delivery_to, "details": $details, "entryDate": $entry_date, "id": $id, "loType": $lo_type, "netGoods": $net_goods, "netServices": $net_services, "note": $note, "ourReference": $our_reference, "procDate": $proc_date, "productTrans": $product_trans, "quoteId": $quote_id, "reference": $reference, "saleRepCode": $sale_rep_code, "saleRepId": $sale_rep_id, "timestamp": $timestamp, "total": $total, "totalNet": $total_net, "totalVAT": $total_vat, "unpaid": $unpaid, "vatTypeId": $vat_type_id, "yourReference": $your_reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes an existing Sales Invoice.
#
# DELETE /v1/salesInvoices/{id}
# operationId: SalesInvoices_Delete
export def "sales-invoices delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Sales Invoice to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/salesInvoices/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"timestamp": $timestamp} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acCode: string, bookTranTypeId: int, customFields: table<description: string, id: int, userDefinedFieldId: int, value: string>, customerId: int, deliveryTo: list<string>, details: string, entryDate: string, id: int, loType: string, netGoods: float, netServices: float, note: string, ourReference: string, procDate: string, productTrans: table<acEntries: list, amount: float, amountNet: float, id: int, percentage: float, productCode: string, productId: int, quantity: float, tranNotes: list, unitPrice: float, vat: float, vatAnalysisTypeId: int, vatRateId: int>, quoteId: int, reference: string, saleRepCode: string, saleRepId: int, timestamp: string, total: float, totalNet: float, totalVAT: float, unpaid: float, vatTypeId: int, yourReference: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/salesInvoices/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing Sales Invoice.
#
# PUT /v1/salesInvoices/{id}
# operationId: SalesInvoices_Put
# --customFields item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
# --productTrans item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
export def "sales-invoices update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ac-code: string
  --book-tran-type-id: int # format: int64
  --custom-fields: list # item shape: {description?: string, id?: int, userDefinedFieldId?: int, value?: string}
  --customer-id: int # format: int64
  --delivery-to: list<string>
  --details: string
  --entry-date: string # format: date-time
  --body-id: int # format: int64
  --lo-type: string
  --net-goods: float # format: double
  --net-services: float # format: double
  --note: string
  --our-reference: string
  --proc-date: string # format: date-time
  --product-trans: list # item shape: {acEntries?: list, amount?: float, amountNet: float, id?: int, percentage?: float, productCode?: string, productId?: int, quantity?: float, tranNotes?: list<string>, unitPrice?: float, vat?: float, vatAnalysisTypeId?: int, vatRateId?: int}
  --quote-id: int # format: int64
  --reference: string
  --sale-rep-code: string
  --sale-rep-id: int # format: int64
  --timestamp: string # format: byte
  --total: float # format: double
  --total-net: float # format: double
  --total-vat: float # format: double
  --unpaid: float # format: double
  --vat-type-id: int # format: int64
  --your-reference: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/salesInvoices/{id}") $auth.query)
  let req_body = {"acCode": $ac_code, "bookTranTypeId": $book_tran_type_id, "customFields": $custom_fields, "customerId": $customer_id, "deliveryTo": $delivery_to, "details": $details, "entryDate": $entry_date, "id": $body_id, "loType": $lo_type, "netGoods": $net_goods, "netServices": $net_services, "note": $note, "ourReference": $our_reference, "procDate": $proc_date, "productTrans": $product_trans, "quoteId": $quote_id, "reference": $reference, "saleRepCode": $sale_rep_code, "saleRepId": $sale_rep_id, "timestamp": $timestamp, "total": $total, "totalNet": $total_net, "totalVAT": $total_vat, "unpaid": $unpaid, "vatTypeId": $vat_type_id, "yourReference": $your_reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of company's SaleRep. Filtering is forbidden. Ordering is allowed by "id".
#
# GET /v1/salesReps
# operationId: SalesRep_Get
export def "sales-reps list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<code: string, companyId: int, email: string, id: int, name: string, phone: string, timeStamp: string>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesReps" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new SaleRep.
#
# POST /v1/salesReps
# operationId: SalesRep_Post
export def "sales-reps create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string
  --company-id: int # format: int64
  --email: string
  --id: int # format: int64
  --name: string
  --phone: string
  --time-stamp: string # format: byte
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesReps" $auth.query)
  let req_body = {"code": $code, "companyId": $company_id, "email": $email, "id": $id, "name": $name, "phone": $phone, "timeStamp": $time_stamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Processes a batch of Sale Rep.
#
# PUT /v1/salesReps/batch
# operationId: SalesRep_ProcessBatch
export def "sales-reps-batch update-process" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/salesReps/batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes an existing Sale Rep.
#
# DELETE /v1/salesReps/{id}
# operationId: SalesRep_Delete
export def "sales-reps delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Sale Rep to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/salesReps/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"timestamp": $timestamp} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string, companyId: int, email: string, id: int, name: string, phone: string, timeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/salesReps/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing Sale Rep.
#
# PUT /v1/salesReps/{id}
# operationId: SalesRep_Put
export def "sales-reps update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string
  --company-id: int # format: int64
  --email: string
  --body-id: int # format: int64
  --name: string
  --phone: string
  --time-stamp: string # format: byte
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/salesReps/{id}") $auth.query)
  let req_body = {"code": $code, "companyId": $company_id, "email": $email, "id": $body_id, "name": $name, "phone": $phone, "timeStamp": $time_stamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of company's Suppliers. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" and "code" fields.
#
# GET /v1/suppliers
# operationId: Suppliers_Get
export def "suppliers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<accountName: string, accountNumber: string, additionalEmails: list, address: list, authCode: string, bank: record, businessIdentifierCode: string, code: string, contact: string, eFTReference: string, email: string, fax: string, id: int, internationalBankAccountNumber: string, mobile: string, name: string, ourCode: string, ownerTypeId: int, phone: string, postponedAccounting: bool, timestamp: string, vatAnalysisTypeId: int, vatReg: string, vatType: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/suppliers" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Supplier.
#
# POST /v1/suppliers
# operationId: Suppliers_Post
# --bank shape: {branch?: string, id?: int, name?: string, sortCode?: string}
# --openingBalance shape: {currentMonth?: float, oneMonthOld?: float, threeMonthsOld?: float, twoMonthsOld?: float}
# --openingBalances item shape: {entryDate?: string, id?: int, isChanged?: bool, procDate?: string, reference?: string, timestamp?: string, total?: float, totalVAT?: float, unpaid?: float, vatEntries?: list}
export def "suppliers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string
  --account-number: string
  --additional-emails: list<string>
  --address: list<string>
  --auth-code: string
  --bank: record # shape: {branch?: string, id?: int, name?: string, sortCode?: string}
  --business-identifier-code: string
  --code: string
  --contact: string
  --e-ft-reference: string
  --email: string
  --fax: string
  --id: int # format: int64
  --international-bank-account-number: string
  --ledger-balance: float # format: double
  --mobile: string
  --name: string
  --opening-balance: record # shape: {currentMonth?: float, oneMonthOld?: float, threeMonthsOld?: float, twoMonthsOld?: float}
  --opening-balances: list # item shape: {entryDate?: string, id?: int, isChanged?: bool, procDate?: string, reference?: string, timestamp?: string, total?: float, totalVAT?: float, unpaid?: float, vatEntries?: list}
  --our-code: string
  --owner-type-id: int # format: int64
  --phone: string
  --postponed-accounting: oneof<nothing, bool>
  --timestamp: string # format: byte
  --vat-analysis-type-id: int # format: int64
  --vat-reg: string
  --vat-type: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/suppliers" $auth.query)
  let req_body = {"accountName": $account_name, "accountNumber": $account_number, "additionalEmails": $additional_emails, "address": $address, "authCode": $auth_code, "bank": $bank, "businessIdentifierCode": $business_identifier_code, "code": $code, "contact": $contact, "eFTReference": $e_ft_reference, "email": $email, "fax": $fax, "id": $id, "internationalBankAccountNumber": $international_bank_account_number, "ledgerBalance": $ledger_balance, "mobile": $mobile, "name": $name, "openingBalance": $opening_balance, "openingBalances": $opening_balances, "ourCode": $our_code, "ownerTypeId": $owner_type_id, "phone": $phone, "postponedAccounting": $postponed_accounting, "timestamp": $timestamp, "vatAnalysisTypeId": $vat_analysis_type_id, "vatReg": $vat_reg, "vatType": $vat_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Processes a batch of Suppliers.
#
# PUT /v1/suppliers/batch
# operationId: Suppliers_ProcessBatch
export def "suppliers-batch update-process" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/suppliers/batch" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes an existing Supplier.
#
# DELETE /v1/suppliers/{id}
# operationId: Suppliers_Delete
export def "suppliers delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp of Supplier to remove. Should be encoded in Base64.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/suppliers/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"timestamp": $timestamp} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --need-balance: oneof<nothing, bool> # If "true" then Supplier's ledger balance will be calculated; otherwise balance will be returned as 0.
]: nothing -> record<accountName: string, accountNumber: string, additionalEmails: list<string>, address: list<string>, authCode: string, bank: record<branch: string, id: int, name: string, sortCode: string>, businessIdentifierCode: string, code: string, contact: string, eFTReference: string, email: string, fax: string, id: int, internationalBankAccountNumber: string, ledgerBalance: float, mobile: string, name: string, openingBalance: record<currentMonth: float, oneMonthOld: float, threeMonthsOld: float, twoMonthsOld: float>, openingBalances: table<entryDate: string, id: int, isChanged: bool, procDate: string, reference: string, timestamp: string, total: float, totalVAT: float, unpaid: float, vatEntries: list>, ourCode: string, ownerTypeId: int, phone: string, postponedAccounting: bool, timestamp: string, vatAnalysisTypeId: int, vatReg: string, vatType: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "needBalance" $need_balance "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/suppliers/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"needBalance": $need_balance} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates an existing Supplier.
#
# PUT /v1/suppliers/{id}
# operationId: Suppliers_Put
# --bank shape: {branch?: string, id?: int, name?: string, sortCode?: string}
# --openingBalance shape: {currentMonth?: float, oneMonthOld?: float, threeMonthsOld?: float, twoMonthsOld?: float}
# --openingBalances item shape: {entryDate?: string, id?: int, isChanged?: bool, procDate?: string, reference?: string, timestamp?: string, total?: float, totalVAT?: float, unpaid?: float, vatEntries?: list}
export def "suppliers update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string
  --account-number: string
  --additional-emails: list<string>
  --address: list<string>
  --auth-code: string
  --bank: record # shape: {branch?: string, id?: int, name?: string, sortCode?: string}
  --business-identifier-code: string
  --code: string
  --contact: string
  --e-ft-reference: string
  --email: string
  --fax: string
  --body-id: int # format: int64
  --international-bank-account-number: string
  --ledger-balance: float # format: double
  --mobile: string
  --name: string
  --opening-balance: record # shape: {currentMonth?: float, oneMonthOld?: float, threeMonthsOld?: float, twoMonthsOld?: float}
  --opening-balances: list # item shape: {entryDate?: string, id?: int, isChanged?: bool, procDate?: string, reference?: string, timestamp?: string, total?: float, totalVAT?: float, unpaid?: float, vatEntries?: list}
  --our-code: string
  --owner-type-id: int # format: int64
  --phone: string
  --postponed-accounting: oneof<nothing, bool>
  --timestamp: string # format: byte
  --vat-analysis-type-id: int # format: int64
  --vat-reg: string
  --vat-type: int # format: int64
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v1/suppliers/{id}") $auth.query)
  let req_body = {"accountName": $account_name, "accountNumber": $account_number, "additionalEmails": $additional_emails, "address": $address, "authCode": $auth_code, "bank": $bank, "businessIdentifierCode": $business_identifier_code, "code": $code, "contact": $contact, "eFTReference": $e_ft_reference, "email": $email, "fax": $fax, "id": $body_id, "internationalBankAccountNumber": $international_bank_account_number, "ledgerBalance": $ledger_balance, "mobile": $mobile, "name": $name, "openingBalance": $opening_balance, "openingBalances": $opening_balances, "ourCode": $our_code, "ownerTypeId": $owner_type_id, "phone": $phone, "postponedAccounting": $postponed_accounting, "timestamp": $timestamp, "vatAnalysisTypeId": $vat_analysis_type_id, "vatReg": $vat_reg, "vatType": $vat_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of Supplier's account transactions.
#
# GET /v1/suppliers/{itemId}/accountTrans
# operationId: Suppliers_GetAccountTrans
export def "suppliers-account-trans get" [
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<bookTranId: int, bookTranTypeId: int, bookTransactionReference: string, bookTypeDesc: string, credit: float, debit: float, id: int, procDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/v1/suppliers/{item_id}/accountTrans") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a Supplier's opening balances, calculated for the next periods: current month, one month old, two months old, three and more months old.
#
# GET /v1/suppliers/{itemId}/openingBalance
# operationId: Suppliers_GetOpeningBalance
export def "suppliers-opening-balance get" [
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<currentMonth: float, oneMonthOld: float, threeMonthsOld: float, twoMonthsOld: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/v1/suppliers/{item_id}/openingBalance") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of Supplier's opening balance transactions.
#
# GET /v1/suppliers/{itemId}/openingBalanceList
# operationId: Suppliers_GetOpeningBalanceList
export def "suppliers-opening-balance-list get" [
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<entryDate: string, id: int, isChanged: bool, procDate: string, reference: string, timestamp: string, total: float, totalVAT: float, unpaid: float, vatEntries: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/v1/suppliers/{item_id}/openingBalanceList") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of company's User Defined Fields. Supports OData querying protocol. Filtering is allowed by "categoryTypeId" field. Ordering is allowed by "id" and "orderIndex" fields.
#
# GET /v1/userDefinedFields
# operationId: UserDefinedFields_Get
export def "user-defined-fields get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<categoryTypeId: int, description: string, id: int, orderIndex: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/userDefinedFields" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of global Vat Analysis Types. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/vatAnalysisTypes
# operationId: VatAnalysisTypes_Get
export def "vat-analysis-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<description: string, id: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/vatAnalysisTypes" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of global Vat Categories. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/vatCategories
# operationId: VatCategories_Get
export def "vat-categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<description: string, id: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/vatCategories" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Process Vat Rates
#
# POST /v1/vatCategories/vatRates
# operationId: VatCategories_ProcessVatRates
export def "vat-categories-vat-rates create-process" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/vatCategories/vatRates" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of company's Vat Rates. Supports OData querying protocol. Filtering is allowed by "vatCategoryId" field. Ordering is allowed by "id" and "orderIndex" fields.
#
# GET /v1/vatRates
# operationId: VatRates_Get
export def "vat-rates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<id: int, isActive: bool, isDefault: bool, orderIndex: int, percentage: float, timestamp: string, vatCategoryId: int>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/vatRates" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of global Vat Types. Supports OData querying protocol. Filtering is forbidden. Ordering is allowed by "id" field.
#
# GET /v1/vatTypes
# operationId: VatTypes_Get
export def "vat-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Count: int, Items: table<code: string, description: string, id: int, isNotApplicable: bool, isOnlyZero: bool>, NextPageLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/vatTypes" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
