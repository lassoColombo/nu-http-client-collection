# Auto-generated client for Accounting API v2.1.0
# Source: https://api.apis.guru/v2/specs/codat.io/accounting/2.1.0/openapi.json
# Auth: --token flag or $env.ACCOUNTING_API_TOKEN

const BASE_URL = "https://api.codat.io"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o ACCOUNTING_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
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

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body}.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk.
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
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["list-account-transactions" "get-account-transaction" "list-bank-accounts" "get-bank-account" "list-bank-account-transactions" "get-bill-attachments" "get-bill-attachment" "download-bill-attachment" "get-customer-attachments" "get-customer-attachment" "download-customer-attachment" "get-direct-costs" "get-direct-cost" "list-direct-cost-attachments" "get-direct-cost-attachment" "download-direct-cost-attachment" "get-direct-incomes" "get-direct-income" "list-direct-income-attachments" "get-direct-income-attachment" "download-direct-income-attachment" "get-invoice-attachments" "get-invoice-attachment" "download-invoice-attachment" "list-supplier-attachments" "get-supplier-attachment" "download-supplier-attachment" "list-transfers" "get-transfer" "get-create-update-bank-accounts-model" "get-create-bank-account-model" "get-create-update-bill-credit-notes-model" "get-create-bill-payments-model" "get-create-update-bills-model" "get-create-chart-of-accounts-model" "get-create-update-credit-notes-model" "get-create-update-customers-model" "get-create-direct-costs-model" "get-create-direct-incomes-model" "get-create-update-invoices-model" "get-create-items-model" "get-create-journal-entries-model" "get-create-journals-model" "get-create-payments-model" "get-create-update-purchase-orders-model" "get-create-update-suppliers-model" "get-create-transfers-model" "create-account" "create-bank-account" "create-bank-transactions" "update-bank-account" "create-bill-credit-note" "update-bill-credit-note" "create-bill-payment" "delete-bill-payment" "create-bill" "delete-bill" "update-bill" "upload-bill-attachments" "create-credit-note" "update-credit-note" "create-customer" "update-customer" "create-direct-cost" "upload-direct-cost-attachment" "create-direct-income" "upload-direct-income-attachment" "create-invoice" "delete-invoice" "update-invoice" "upload-invoice-attachment" "create-item" "create-journal-entry" "delete-journal-entry" "push-journal" "create-payment" "create-purchase-order" "update-purchase-order" "create-supplier" "put-supplier" "create-transfer" "list-accounts" "get-account" "get-all-bank-account" "list-bank-transactions" "list-bill-credit-notes" "get-bill-credit-note" "list-bill-payments" "get-bill-payments" "list-bills" "get-bill" "list-credit-notes" "get-credit-note" "get-customers" "get-customer" "get-balance-sheet" "get-cash-flow-statement" "get-profit-and-loss" "get-company-info" "post-sync-info" "list-invoices" "get-invoice" "download-invoice-pdf" "list-items" "get-item" "list-journal-entries" "get-journal-entry" "list-journals" "get-journal" "list-payment-methods" "get-payment-method" "list-payments" "get-payment" "list-purchase-orders" "get-purchase-order" "list-sales-orders" "get-sales-order" "list-suppliers" "get-supplier" "list-tax-rates" "get-tax-rate" "list-tracking-categories" "get-tracking-category" "get-aged-creditors-report" "is-aged-creditors-report-available" "get-aged-debtors-report" "is-aged-debtor-report-available" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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
export def "list-account-transactions" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<bankAccountRef: record, currency: string, currencyRate: float, date: string, id: string, lines: list, metadata: record, note: string, status: string, totalAmount: float, transactionId: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/accountTransactions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get account transaction
#
# GET /companies/{companyId}/connections/{connectionId}/data/accountTransactions/{accountTransactionId}
# operationId: get-account-transaction
export def "get-account-transaction" [
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
]: nothing -> oneof<record<bankAccountRef: record<id: string, name: string>, currency: string, currencyRate: float, date: string, id: string, lines: table<amount: float, description: string, recordRef: record>, metadata: record<isDeleted: bool>, note: string, status: string, totalAmount: float, transactionId: string, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($account_transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'accountTransactionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), account_transaction_id: (encode-path-segment $account_transaction_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/accountTransactions/{account_transaction_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List bank accounts
#
# GET /companies/{companyId}/connections/{connectionId}/data/bankAccounts
# operationId: list-bank-accounts
export def "list-bank-accounts" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<accountName: string, accountNumber: string, accountType: string, availableBalance: float, balance: float, currency: string, iBan: string, id: string, institution: string, metadata: record, nominalCode: string, overdraftLimit: float, sortCode: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/bankAccounts") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get bank account
#
# GET /companies/{companyId}/connections/{connectionId}/data/bankAccounts/{accountId}
# DEPRECATED
# operationId: get-bank-account
@deprecated
export def "get-bank-account" [
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
]: nothing -> oneof<record<accountName: string, accountNumber: string, accountType: string, availableBalance: float, balance: float, currency: string, iBan: string, id: string, institution: string, metadata: record<isDeleted: bool>, nominalCode: string, overdraftLimit: float, sortCode: string, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), account_id: (encode-path-segment $account_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/bankAccounts/{account_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List bank transactions for bank account
#
# GET /companies/{companyId}/connections/{connectionId}/data/bankAccounts/{accountId}/bankTransactions
# operationId: list-bank-account-transactions
export def "list-bank-account-transactions" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<accountId: string, transactions: list>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), account_id: (encode-path-segment $account_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/bankAccounts/{account_id}/bankTransactions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List bill attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/bills/{billId}/attachments
# operationId: get-bill-attachments
export def "get-bill-attachments" [
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
]: nothing -> oneof<record<attachments: table<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($bill_id | is-empty) { error make --unspanned { msg: "path parameter 'billId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), bill_id: (encode-path-segment $bill_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/bills/{bill_id}/attachments") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get bill attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/bills/{billId}/attachments/{attachmentId}
# operationId: get-bill-attachment
export def "get-bill-attachment" [
  company_id: string
  connection_id: string
  bill_id: string
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
]: nothing -> oneof<record<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($bill_id | is-empty) { error make --unspanned { msg: "path parameter 'billId' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachmentId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), bill_id: (encode-path-segment $bill_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/bills/{bill_id}/attachments/{attachment_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Download bill attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/bills/{billId}/attachments/{attachmentId}/download
# operationId: download-bill-attachment
export def "download-bill-attachment" [
  company_id: string
  connection_id: string
  bill_id: string
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
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($bill_id | is-empty) { error make --unspanned { msg: "path parameter 'billId' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachmentId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), bill_id: (encode-path-segment $bill_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/bills/{bill_id}/attachments/{attachment_id}/download") $auth.query)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List customer attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/customers/{customerId}/attachments
# operationId: get-customer-attachments
export def "get-customer-attachments" [
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
]: nothing -> oneof<record<attachments: table<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), customer_id: (encode-path-segment $customer_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/customers/{customer_id}/attachments") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get customer attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/customers/{customerId}/attachments/{attachmentId}
# operationId: get-customer-attachment
export def "get-customer-attachment" [
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
]: nothing -> oneof<record<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachmentId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), customer_id: (encode-path-segment $customer_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/customers/{customer_id}/attachments/{attachment_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Download customer attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/customers/{customerId}/attachments/{attachmentId}/download
# operationId: download-customer-attachment
export def "download-customer-attachment" [
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
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachmentId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), customer_id: (encode-path-segment $customer_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/customers/{customer_id}/attachments/{attachment_id}/download") $auth.query)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List direct costs
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts
# operationId: get-direct-costs
export def "get-direct-costs" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<contactRef: record, currency: string, currencyRate: float, id: string, issueDate: string, lineItems: list, metadata: record, note: string, paymentAllocations: list, reference: string, subTotal: float, supplementalData: record, taxAmount: float, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directCosts") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get direct cost
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}
# DEPRECATED
# operationId: get-direct-cost
@deprecated
export def "get-direct-cost" [
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
]: nothing -> oneof<record<contactRef: record<dataType: string, id: string>, currency: string, currencyRate: float, id: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, tracking: record, trackingCategoryRefs: list, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: table<allocation: record, payment: record>, reference: string, subTotal: float, supplementalData: record<content: record>, taxAmount: float, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($direct_cost_id | is-empty) { error make --unspanned { msg: "path parameter 'directCostId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), direct_cost_id: (encode-path-segment $direct_cost_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directCosts/{direct_cost_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List direct cost attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}/attachments
# operationId: list-direct-cost-attachments
export def "list-direct-cost-attachments" [
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
]: nothing -> oneof<record<attachments: table<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($direct_cost_id | is-empty) { error make --unspanned { msg: "path parameter 'directCostId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), direct_cost_id: (encode-path-segment $direct_cost_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directCosts/{direct_cost_id}/attachments") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get direct cost attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}/attachments/{attachmentId}
# operationId: get-direct-cost-attachment
export def "get-direct-cost-attachment" [
  company_id: string
  connection_id: string
  direct_cost_id: string
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
]: nothing -> oneof<record<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($direct_cost_id | is-empty) { error make --unspanned { msg: "path parameter 'directCostId' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachmentId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), direct_cost_id: (encode-path-segment $direct_cost_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directCosts/{direct_cost_id}/attachments/{attachment_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Download direct cost attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/directCosts/{directCostId}/attachments/{attachmentId}/download
# operationId: download-direct-cost-attachment
export def "download-direct-cost-attachment" [
  company_id: string
  connection_id: string
  direct_cost_id: string
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
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($direct_cost_id | is-empty) { error make --unspanned { msg: "path parameter 'directCostId' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachmentId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), direct_cost_id: (encode-path-segment $direct_cost_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directCosts/{direct_cost_id}/attachments/{attachment_id}/download") $auth.query)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get direct incomes
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes
# operationId: get-direct-incomes
export def "get-direct-incomes" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<contactRef: record, currency: string, currencyRate: float, id: string, issueDate: string, lineItems: list, metadata: record, note: string, paymentAllocations: list, reference: string, subTotal: float, supplementalData: record, taxAmount: float, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directIncomes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get direct income
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}
# DEPRECATED
# operationId: get-direct-income
@deprecated
export def "get-direct-income" [
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
]: nothing -> oneof<record<contactRef: record<dataType: string, id: string>, currency: string, currencyRate: float, id: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, trackingCategoryRefs: list, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: table<allocation: record, payment: record>, reference: string, subTotal: float, supplementalData: record<content: record>, taxAmount: float, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($direct_income_id | is-empty) { error make --unspanned { msg: "path parameter 'directIncomeId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), direct_income_id: (encode-path-segment $direct_income_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directIncomes/{direct_income_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List direct income attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}/attachments
# operationId: list-direct-income-attachments
export def "list-direct-income-attachments" [
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
]: nothing -> oneof<record<attachments: table<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($direct_income_id | is-empty) { error make --unspanned { msg: "path parameter 'directIncomeId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), direct_income_id: (encode-path-segment $direct_income_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directIncomes/{direct_income_id}/attachments") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get direct income attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}/attachments/{attachmentId}
# operationId: get-direct-income-attachment
export def "get-direct-income-attachment" [
  company_id: string
  connection_id: string
  direct_income_id: string
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
  --timeout-in-minutes: int # format: int32
]: nothing -> oneof<record<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($direct_income_id | is-empty) { error make --unspanned { msg: "path parameter 'directIncomeId' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachmentId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), direct_income_id: (encode-path-segment $direct_income_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directIncomes/{direct_income_id}/attachments/{attachment_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Download direct income attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/directIncomes/{directIncomeId}/attachments/{attachmentId}/download
# operationId: download-direct-income-attachment
export def "download-direct-income-attachment" [
  company_id: string
  connection_id: string
  direct_income_id: string
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
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($direct_income_id | is-empty) { error make --unspanned { msg: "path parameter 'directIncomeId' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachmentId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), direct_income_id: (encode-path-segment $direct_income_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/directIncomes/{direct_income_id}/attachments/{attachment_id}/download") $auth.query)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get invoice attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/invoices/{invoiceId}/attachments
# operationId: get-invoice-attachments
export def "get-invoice-attachments" [
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
]: nothing -> oneof<record<attachments: table<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/invoices/{invoice_id}/attachments") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get invoice attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/invoices/{invoiceId}/attachments/{attachmentId}
# operationId: get-invoice-attachment
export def "get-invoice-attachment" [
  company_id: string
  connection_id: string
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
]: nothing -> oneof<record<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachmentId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), invoice_id: (encode-path-segment $invoice_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/invoices/{invoice_id}/attachments/{attachment_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Download invoice attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/invoices/{invoiceId}/attachments/{attachmentId}/download
# operationId: download-invoice-attachment
export def "download-invoice-attachment" [
  company_id: string
  connection_id: string
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
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachmentId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), invoice_id: (encode-path-segment $invoice_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/invoices/{invoice_id}/attachments/{attachment_id}/download") $auth.query)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List supplier attachments
#
# GET /companies/{companyId}/connections/{connectionId}/data/suppliers/{supplierId}/attachments
# operationId: list-supplier-attachments
export def "list-supplier-attachments" [
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
]: nothing -> oneof<record<attachments: table<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($supplier_id | is-empty) { error make --unspanned { msg: "path parameter 'supplierId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), supplier_id: (encode-path-segment $supplier_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/suppliers/{supplier_id}/attachments") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get supplier attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/suppliers/{supplierId}/attachments/{attachmentId}
# operationId: get-supplier-attachment
export def "get-supplier-attachment" [
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
]: nothing -> oneof<record<contentType: string, dateCreated: string, fileSize: int, id: string, includeWhenSent: bool, name: string, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($supplier_id | is-empty) { error make --unspanned { msg: "path parameter 'supplierId' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachmentId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), supplier_id: (encode-path-segment $supplier_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/suppliers/{supplier_id}/attachments/{attachment_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Download supplier attachment
#
# GET /companies/{companyId}/connections/{connectionId}/data/suppliers/{supplierId}/attachments/{attachmentId}/download
# operationId: download-supplier-attachment
export def "download-supplier-attachment" [
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
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($supplier_id | is-empty) { error make --unspanned { msg: "path parameter 'supplierId' must be non-empty" } }
  if ($attachment_id | is-empty) { error make --unspanned { msg: "path parameter 'attachmentId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), supplier_id: (encode-path-segment $supplier_id), attachment_id: (encode-path-segment $attachment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/suppliers/{supplier_id}/attachments/{attachment_id}/download") $auth.query)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List transfers
#
# GET /companies/{companyId}/connections/{connectionId}/data/transfers
# operationId: list-transfers
export def "list-transfers" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<contactRef: record, date: string, depositedRecordRefs: list, description: string, from: record, id: string, metadata: record, supplementalData: record, to: record, trackingCategoryRefs: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/transfers") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get transfer
#
# GET /companies/{companyId}/connections/{connectionId}/data/transfers/{transferId}
# DEPRECATED
# operationId: get-transfer
@deprecated
export def "get-transfer" [
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
]: nothing -> oneof<record<contactRef: record<dataType: string, id: string>, date: string, depositedRecordRefs: list<string>, description: string, from: record<accountRef: record<id: string, name: string>, amount: float, currency: string>, id: string, metadata: record<isDeleted: bool>, supplementalData: record<content: record>, to: record<accountRef: record<id: string, name: string>, amount: float, currency: string>, trackingCategoryRefs: table<id: string, name: string>, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($transfer_id | is-empty) { error make --unspanned { msg: "path parameter 'transferId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), transfer_id: (encode-path-segment $transfer_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/data/transfers/{transfer_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get create/update bank account model
#
# GET /companies/{companyId}/connections/{connectionId}/options/bankAccounts
# operationId: get-create-update-bankAccounts-model
export def "get-create-update-bank-accounts-model" [
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
]: nothing -> oneof<record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/bankAccounts") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List push options for bank account bank transactions
#
# GET /companies/{companyId}/connections/{connectionId}/options/bankAccounts/{accountId}/bankTransactions
# operationId: get-create-bank-account-model
export def "get-create-bank-account-model" [
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
]: nothing -> oneof<record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), account_id: (encode-path-segment $account_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/bankAccounts/{account_id}/bankTransactions") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get create/update bill credit note model
#
# GET /companies/{companyId}/connections/{connectionId}/options/billCreditNotes
# operationId: get-create-update-billCreditNotes-model
export def "get-create-update-bill-credit-notes-model" [
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
]: nothing -> oneof<record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/billCreditNotes") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get create bill payment model
#
# GET /companies/{companyId}/connections/{connectionId}/options/billPayments
# operationId: get-create-billPayments-model
export def "get-create-bill-payments-model" [
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
]: nothing -> oneof<record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/billPayments") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get create/update bill model
#
# GET /companies/{companyId}/connections/{connectionId}/options/bills
# operationId: get-create-update-bills-model
export def "get-create-update-bills-model" [
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
]: nothing -> oneof<record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/bills") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get create account model
#
# GET /companies/{companyId}/connections/{connectionId}/options/chartOfAccounts
# operationId: get-create-chartOfAccounts-model
export def "get-create-chart-of-accounts-model" [
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
]: nothing -> oneof<record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/chartOfAccounts") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get create/update credit note model
#
# GET /companies/{companyId}/connections/{connectionId}/options/creditNotes
# operationId: get-create-update-creditNotes-model
export def "get-create-update-credit-notes-model" [
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
]: nothing -> oneof<record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/creditNotes") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get create/update customer model
#
# GET /companies/{companyId}/connections/{connectionId}/options/customers
# operationId: get-create-update-customers-model
export def "get-create-update-customers-model" [
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
]: nothing -> oneof<record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/customers") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get create direct cost model
#
# GET /companies/{companyId}/connections/{connectionId}/options/directCosts
# operationId: get-create-directCosts-model
export def "get-create-direct-costs-model" [
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
]: nothing -> oneof<record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/directCosts") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get create direct income model
#
# GET /companies/{companyId}/connections/{connectionId}/options/directIncomes
# operationId: get-create-directIncomes-model
export def "get-create-direct-incomes-model" [
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
]: nothing -> oneof<record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/directIncomes") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get create/update invoice model
#
# GET /companies/{companyId}/connections/{connectionId}/options/invoices
# operationId: get-create-update-invoices-model
export def "get-create-update-invoices-model" [
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
]: nothing -> oneof<record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/invoices") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get create item model
#
# GET /companies/{companyId}/connections/{connectionId}/options/items
# operationId: get-create-items-model
export def "get-create-items-model" [
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
]: nothing -> oneof<record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/items") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get create journal entry model
#
# GET /companies/{companyId}/connections/{connectionId}/options/journalEntries
# operationId: get-create-journalEntries-model
export def "get-create-journal-entries-model" [
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
]: nothing -> oneof<record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/journalEntries") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get create journal model
#
# GET /companies/{companyId}/connections/{connectionId}/options/journals
# operationId: get-create-journals-model
export def "get-create-journals-model" [
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
]: nothing -> oneof<record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/journals") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get create payment model
#
# GET /companies/{companyId}/connections/{connectionId}/options/payments
# operationId: get-create-payments-model
export def "get-create-payments-model" [
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
]: nothing -> oneof<record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/payments") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get create/update purchase order model
#
# GET /companies/{companyId}/connections/{connectionId}/options/purchaseOrders
# operationId: get-create-update-purchaseOrders-model
export def "get-create-update-purchase-orders-model" [
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
]: nothing -> oneof<record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/purchaseOrders") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get create/update supplier model
#
# GET /companies/{companyId}/connections/{connectionId}/options/suppliers
# operationId: get-create-update-suppliers-model
export def "get-create-update-suppliers-model" [
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
]: nothing -> oneof<record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/suppliers") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get create transfer model
#
# GET /companies/{companyId}/connections/{connectionId}/options/transfers
# operationId: get-create-transfers-model
export def "get-create-transfers-model" [
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
]: nothing -> oneof<record<description: string, displayName: string, options: table<description: string, displayName: string, required: bool, type: string, value: string>, properties: record, required: bool, type: string, validation: record<information: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/options/transfers") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Create account
#
# POST /companies/{companyId}/connections/{connectionId}/push/accounts
# operationId: create-account
export def "create-account" [
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<currency: string, currentBalance: float, description: string, fullyQualifiedCategory: string, fullyQualifiedName: string, id: string, isBankAccount: bool, metadata: record<isDeleted: bool>, name: string, nominalCode: string, status: string, type: string, validDatatypeLinks: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/accounts") $qp $auth.query)
  let req_body = {"currency": $currency, "currentBalance": $current_balance, "description": $description, "fullyQualifiedCategory": $fully_qualified_category, "fullyQualifiedName": $fully_qualified_name, "id": $id, "isBankAccount": $is_bank_account, "metadata": $metadata, "name": $name, "nominalCode": $nominal_code, "status": $status, "type": $type, "validDatatypeLinks": $valid_datatype_links, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "isBankAccount") == null) { error make --unspanned { msg: "required body field 'isBankAccount' missing: pass --is-bank-account or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create bank account
#
# POST /companies/{companyId}/connections/{connectionId}/push/bankAccounts
# operationId: create-bank-account
export def "create-bank-account" [
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<currency: string, currentBalance: float, description: string, fullyQualifiedCategory: string, fullyQualifiedName: string, id: string, isBankAccount: bool, metadata: record<isDeleted: bool>, name: string, nominalCode: string, status: string, type: string, validDatatypeLinks: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "allowSyncOnPushComplete" $allow_sync_on_push_complete "scalar") (serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/bankAccounts") $qp $auth.query)
  let req_body = {"accountName": $account_name, "accountNumber": $account_number, "accountType": $account_type, "availableBalance": $available_balance, "balance": $balance, "currency": $currency, "iBan": $i_ban, "id": $id, "institution": $institution, "metadata": $metadata, "nominalCode": $nominal_code, "overdraftLimit": $overdraft_limit, "sortCode": $sort_code, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"allowSyncOnPushComplete": $allow_sync_on_push_complete, "timeoutInMinutes": $timeout_in_minutes} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create bank transactions
#
# POST /companies/{companyId}/connections/{connectionId}/push/bankAccounts/{accountId}/bankTransactions
# operationId: create-bank-transactions
export def "create-bank-transactions" [
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
  --allow-sync-on-push-complete: oneof<nothing, bool> # default: true
  --timeout-in-minutes: int # format: int32
  --body-account-id: string # nullable (spec name: accountId)
  --transactions: list # nullable — item shape: {amount: float, balance: float, clearedOnDate?: string, counterparty?: string, description?: string, id?: string, reconciled: bool, reference?: string, transactionType: "Unknown"|"Credit"|"Debit"|"Int"|"Div"|"Fee"|"SerChg"|"Dep"|"Atm"|"Pos"|"Xfer"|"Check"|"Payment"|"Cash"|"DirectDep"|"DirectDebit"|"RepeatPmt"|"Other", modifiedDate?: string, sourceModifiedDate?: string}
]: any -> oneof<record<data: record<accountId: string, transactions: list<record>>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "allowSyncOnPushComplete" $allow_sync_on_push_complete "scalar") (serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), account_id: (encode-path-segment $account_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/bankAccounts/{account_id}/bankTransactions") $qp $auth.query)
  let req_body = {"accountId": $body_account_id, "transactions": $transactions} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"allowSyncOnPushComplete": $allow_sync_on_push_complete, "timeoutInMinutes": $timeout_in_minutes} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update bank account
#
# PUT /companies/{companyId}/connections/{connectionId}/push/bankAccounts/{bankAccountId}
# operationId: update-bank-account
export def "update-bank-account" [
  company_id: string
  connection_id: string
  bank_account_id: string
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<accountName: string, accountNumber: string, accountType: string, availableBalance: float, balance: float, currency: string, iBan: string, id: string, institution: string, metadata: record<isDeleted: bool>, nominalCode: string, overdraftLimit: float, sortCode: string, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($bank_account_id | is-empty) { error make --unspanned { msg: "path parameter 'bankAccountId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), bank_account_id: (encode-path-segment $bank_account_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/bankAccounts/{bank_account_id}") $qp $auth.query)
  let req_body = {"accountName": $account_name, "accountNumber": $account_number, "accountType": $account_type, "availableBalance": $available_balance, "balance": $balance, "currency": $currency, "iBan": $i_ban, "id": $id, "institution": $institution, "metadata": $metadata, "nominalCode": $nominal_code, "overdraftLimit": $overdraft_limit, "sortCode": $sort_code, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes, "forceUpdate": $force_update} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create bill credit note
#
# POST /companies/{companyId}/connections/{connectionId}/push/billCreditNotes
# operationId: create-bill-credit-note
export def "create-bill-credit-note" [
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<allocatedOnDate: string, billCreditNoteNumber: string, currency: string, currencyRate: float, discountPercentage: float, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, remainingCredit: float, status: string, subTotal: float, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/billCreditNotes") $qp $auth.query)
  let req_body = {"allocatedOnDate": $allocated_on_date, "billCreditNoteNumber": $bill_credit_note_number, "currency": $currency, "currencyRate": $currency_rate, "discountPercentage": $discount_percentage, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "remainingCredit": $remaining_credit, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "supplierRef": $supplier_ref, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount, "withholdingTax": $withholding_tax, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update bill credit note
#
# PUT /companies/{companyId}/connections/{connectionId}/push/billCreditNotes/{billCreditNoteId}
# operationId: update-bill-credit-note
export def "update-bill-credit-note" [
  company_id: string
  connection_id: string
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<allocatedOnDate: string, billCreditNoteNumber: string, currency: string, currencyRate: float, discountPercentage: float, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, remainingCredit: float, status: string, subTotal: float, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($bill_credit_note_id | is-empty) { error make --unspanned { msg: "path parameter 'billCreditNoteId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), bill_credit_note_id: (encode-path-segment $bill_credit_note_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/billCreditNotes/{bill_credit_note_id}") $qp $auth.query)
  let req_body = {"allocatedOnDate": $allocated_on_date, "billCreditNoteNumber": $bill_credit_note_number, "currency": $currency, "currencyRate": $currency_rate, "discountPercentage": $discount_percentage, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "remainingCredit": $remaining_credit, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "supplierRef": $supplier_ref, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount, "withholdingTax": $withholding_tax, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes, "forceUpdate": $force_update} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create bill payments
#
# POST /companies/{companyId}/connections/{connectionId}/push/billPayments
# operationId: create-bill-payment
export def "create-bill-payment" [
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<accountRef: record<id: string, name: string>, currency: string, currencyRate: float, date: string, id: string, lines: list<record>, metadata: record<isDeleted: bool>, note: string, paymentMethodRef: record<id: string, name: string>, reference: string, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/billPayments") $qp $auth.query)
  let req_body = {"accountRef": $account_ref, "currency": $currency, "currencyRate": $currency_rate, "date": $date, "id": $id, "lines": $lines, "metadata": $metadata, "note": $note, "paymentMethodRef": $payment_method_ref, "reference": $reference, "supplementalData": $supplemental_data, "supplierRef": $supplier_ref, "totalAmount": $total_amount, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete bill payment
#
# DELETE /companies/{companyId}/connections/{connectionId}/push/billPayments/{billPaymentId}
# operationId: delete-billPayment
export def "delete-bill-payment" [
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
]: nothing -> oneof<record<changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($bill_payment_id | is-empty) { error make --unspanned { msg: "path parameter 'billPaymentId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), bill_payment_id: (encode-path-segment $bill_payment_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/billPayments/{bill_payment_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Create bill
#
# POST /companies/{companyId}/connections/{connectionId}/push/bills
# operationId: create-bill
export def "create-bill" [
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
  --timeout-in-minutes: int # format: int32
  --amount-due: float # Amount outstanding on the bill. (nullable)
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --due-date: string # Date the supplier is due to be paid.
  --id: string # Identifier for the bill, unique for the company in the accounting platform.
  issue_date: string # Date of the bill as recorded in the accounting platform.
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<amountDue: float, currency: string, currencyRate: float, dueDate: string, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, purchaseOrderRefs: list<record>, reference: string, status: string, subTotal: float, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, taxAmount: float, totalAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/bills") $qp $auth.query)
  let req_body = {"amountDue": $amount_due, "currency": $currency, "currencyRate": $currency_rate, "dueDate": $due_date, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "purchaseOrderRefs": $purchase_order_refs, "reference": $reference, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "supplierRef": $supplier_ref, "taxAmount": $tax_amount, "totalAmount": $total_amount, "withholdingTax": $withholding_tax, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete bill
#
# DELETE /companies/{companyId}/connections/{connectionId}/push/bills/{billId}
# operationId: delete-bill
export def "delete-bill" [
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
]: nothing -> oneof<record<changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($bill_id | is-empty) { error make --unspanned { msg: "path parameter 'billId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), bill_id: (encode-path-segment $bill_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/bills/{bill_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Update bill
#
# PUT /companies/{companyId}/connections/{connectionId}/push/bills/{billId}
# operationId: update-bill
export def "update-bill" [
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
  --timeout-in-minutes: int # format: int32
  --force-update: oneof<nothing, bool> # default: false
  --amount-due: float # Amount outstanding on the bill. (nullable)
  --currency: string # The currency data type in Codat is the [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency code, e.g. _GBP_. ## Unknown currencies In line with the ISO 4217 specification, the code _XXX_ is used when the data source does not return a currency for a transaction. There are only a very small number of edge cases where this currency code is returned by the Codat system. (format: ISO4217)
  --currency-rate: float # Rate to convert the total amount of the payment into the base currency for the company at the time of the payment. Currency rates in Codat are implemented as the multiple of foreign currency units to each base currency unit. Where the currency rate is provided by the underlying accounting platform, it will be available from Codat with the same precision (up to a maximum of 9 decimal places). For accounting platforms which do not provide an explicit currency rate, it is calculated as `baseCurrency / foreignCurrency` and will be returned to 9 decimal places. ## Examples with base currency of GBP | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (GBP) | | :--------------- | :------------- | :------------ | :------------------------- | | **USD** | $20 | 0.781 | £15.62 | | **EUR** | €20 | 0.885 | £17.70 | | **RUB** | ₽20 | 0.011 | £0.22 | ## Examples with base currency of USD | Foreign Currency | Foreign Amount | Currency Rate | Base Currency Amount (USD) | | :--------------- | :------------- | :------------ | :------------------------- | | **GBP** | £20 | 1.277 | $25.54 | | **EUR** | €20 | 1.134 | $22.68 | | **RUB** | ₽20 | 0.015 | $0.30 | (nullable)
  --due-date: string # Date the supplier is due to be paid.
  --id: string # Identifier for the bill, unique for the company in the accounting platform.
  issue_date: string # Date of the bill as recorded in the accounting platform.
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<amountDue: float, currency: string, currencyRate: float, dueDate: string, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, purchaseOrderRefs: list<record>, reference: string, status: string, subTotal: float, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, taxAmount: float, totalAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($bill_id | is-empty) { error make --unspanned { msg: "path parameter 'billId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), bill_id: (encode-path-segment $bill_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/bills/{bill_id}") $qp $auth.query)
  let req_body = {"amountDue": $amount_due, "currency": $currency, "currencyRate": $currency_rate, "dueDate": $due_date, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "purchaseOrderRefs": $purchase_order_refs, "reference": $reference, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "supplierRef": $supplier_ref, "taxAmount": $tax_amount, "totalAmount": $total_amount, "withholdingTax": $withholding_tax, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes, "forceUpdate": $force_update} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Upload bill attachments
#
# POST /companies/{companyId}/connections/{connectionId}/push/bills/{billId}/attachments
# operationId: upload-bill-attachments
export def "upload-bill-attachments" [
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
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($bill_id | is-empty) { error make --unspanned { msg: "path parameter 'billId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), bill_id: (encode-path-segment $bill_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/bills/{bill_id}/attachments") $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body = ($req_body | default {})
  let mp = if ($req_body | describe | str starts-with "record") { build-multipart-body $req_body [] $dry_run } else { {body: $req_body, content_type: "multipart/form-data"} }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Create credit note
#
# POST /companies/{companyId}/connections/{connectionId}/push/creditNotes
# operationId: create-credit-note
export def "create-credit-note" [
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<additionalTaxAmount: float, additionalTaxPercentage: float, allocatedOnDate: string, creditNoteNumber: string, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, discountPercentage: float, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, remainingCredit: float, status: string, subTotal: float, supplementalData: record<content: record>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/creditNotes") $qp $auth.query)
  let req_body = {"additionalTaxAmount": $additional_tax_amount, "additionalTaxPercentage": $additional_tax_percentage, "allocatedOnDate": $allocated_on_date, "creditNoteNumber": $credit_note_number, "currency": $currency, "currencyRate": $currency_rate, "customerRef": $customer_ref, "discountPercentage": $discount_percentage, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "remainingCredit": $remaining_credit, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount, "withholdingTax": $withholding_tax, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update creditNote
#
# PUT /companies/{companyId}/connections/{connectionId}/push/creditNotes/{creditNoteId}
# operationId: update-credit-note
export def "update-credit-note" [
  company_id: string
  connection_id: string
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<additionalTaxAmount: float, additionalTaxPercentage: float, allocatedOnDate: string, creditNoteNumber: string, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, discountPercentage: float, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, remainingCredit: float, status: string, subTotal: float, supplementalData: record<content: record>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($credit_note_id | is-empty) { error make --unspanned { msg: "path parameter 'creditNoteId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), credit_note_id: (encode-path-segment $credit_note_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/creditNotes/{credit_note_id}") $qp $auth.query)
  let req_body = {"additionalTaxAmount": $additional_tax_amount, "additionalTaxPercentage": $additional_tax_percentage, "allocatedOnDate": $allocated_on_date, "creditNoteNumber": $credit_note_number, "currency": $currency, "currencyRate": $currency_rate, "customerRef": $customer_ref, "discountPercentage": $discount_percentage, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "remainingCredit": $remaining_credit, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount, "withholdingTax": $withholding_tax, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes, "forceUpdate": $force_update} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create customer
#
# POST /companies/{companyId}/connections/{connectionId}/push/customers
# operationId: create-customer
export def "create-customer" [
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<addresses: list<record>, contactName: string, contacts: list<record>, customerName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record<isDeleted: bool>, phone: string, registrationNumber: string, status: string, supplementalData: record<content: record>, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/customers") $qp $auth.query)
  let req_body = {"addresses": $addresses, "contactName": $contact_name, "contacts": $contacts, "customerName": $customer_name, "defaultCurrency": $default_currency, "emailAddress": $email_address, "id": $id, "metadata": $metadata, "phone": $phone, "registrationNumber": $registration_number, "status": $status, "supplementalData": $supplemental_data, "taxNumber": $tax_number, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update customer
#
# PUT /companies/{companyId}/connections/{connectionId}/push/customers/{customerId}
# operationId: update-customer
export def "update-customer" [
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<addresses: list<record>, contactName: string, contacts: list<record>, customerName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record<isDeleted: bool>, phone: string, registrationNumber: string, status: string, supplementalData: record<content: record>, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), customer_id: (encode-path-segment $customer_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/customers/{customer_id}") $qp $auth.query)
  let req_body = {"addresses": $addresses, "contactName": $contact_name, "contacts": $contacts, "customerName": $customer_name, "defaultCurrency": $default_currency, "emailAddress": $email_address, "id": $id, "metadata": $metadata, "phone": $phone, "registrationNumber": $registration_number, "status": $status, "supplementalData": $supplemental_data, "taxNumber": $tax_number, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes, "forceUpdate": $force_update} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create direct cost
#
# POST /companies/{companyId}/connections/{connectionId}/push/directCosts
# operationId: create-direct-cost
export def "create-direct-cost" [
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<contactRef: record<dataType: string, id: string>, currency: string, currencyRate: float, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, reference: string, subTotal: float, supplementalData: record<content: record>, taxAmount: float, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/directCosts") $qp $auth.query)
  let req_body = {"contactRef": $contact_ref, "currency": $currency, "currencyRate": $currency_rate, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "reference": $reference, "subTotal": $sub_total, "supplementalData": $supplemental_data, "taxAmount": $tax_amount, "totalAmount": $total_amount, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Upload direct cost attachment
#
# POST /companies/{companyId}/connections/{connectionId}/push/directCosts/{directCostId}/attachment
# operationId: upload-direct-cost-attachment
export def "upload-direct-cost-attachment" [
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
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($direct_cost_id | is-empty) { error make --unspanned { msg: "path parameter 'directCostId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), direct_cost_id: (encode-path-segment $direct_cost_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/directCosts/{direct_cost_id}/attachment") $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body = ($req_body | default {})
  let mp = if ($req_body | describe | str starts-with "record") { build-multipart-body $req_body [] $dry_run } else { {body: $req_body, content_type: "multipart/form-data"} }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Create direct income
#
# POST /companies/{companyId}/connections/{connectionId}/push/directIncomes
# operationId: create-direct-income
export def "create-direct-income" [
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<contactRef: record<dataType: string, id: string>, currency: string, currencyRate: float, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: list<record>, reference: string, subTotal: float, supplementalData: record<content: record>, taxAmount: float, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/directIncomes") $qp $auth.query)
  let req_body = {"contactRef": $contact_ref, "currency": $currency, "currencyRate": $currency_rate, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentAllocations": $payment_allocations, "reference": $reference, "subTotal": $sub_total, "supplementalData": $supplemental_data, "taxAmount": $tax_amount, "totalAmount": $total_amount, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create direct income attachment
#
# POST /companies/{companyId}/connections/{connectionId}/push/directIncomes/{directIncomeId}/attachment
# operationId: upload-direct-income-attachment
export def "upload-direct-income-attachment" [
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
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($direct_income_id | is-empty) { error make --unspanned { msg: "path parameter 'directIncomeId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), direct_income_id: (encode-path-segment $direct_income_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/directIncomes/{direct_income_id}/attachment") $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body = ($req_body | default {})
  let mp = if ($req_body | describe | str starts-with "record") { build-multipart-body $req_body [] $dry_run } else { {body: $req_body, content_type: "multipart/form-data"} }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Create invoice
#
# POST /companies/{companyId}/connections/{connectionId}/push/invoices
# operationId: create-invoice
export def "create-invoice" [
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<additionalTaxAmount: float, additionalTaxPercentage: float, amountDue: float, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, discountPercentage: float, dueDate: string, id: string, invoiceNumber: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paidOnDate: string, paymentAllocations: list<record>, salesOrderRefs: list<string>, status: string, subTotal: float, supplementalData: record<content: record>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/invoices") $qp $auth.query)
  let req_body = {"additionalTaxAmount": $additional_tax_amount, "additionalTaxPercentage": $additional_tax_percentage, "amountDue": $amount_due, "currency": $currency, "currencyRate": $currency_rate, "customerRef": $customer_ref, "discountPercentage": $discount_percentage, "dueDate": $due_date, "id": $id, "invoiceNumber": $invoice_number, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paidOnDate": $paid_on_date, "paymentAllocations": $payment_allocations, "salesOrderRefs": $sales_order_refs, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount, "withholdingTax": $withholding_tax, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete invoice
#
# DELETE /companies/{companyId}/connections/{connectionId}/push/invoices/{invoiceId}
# operationId: delete-invoice
export def "delete-invoice" [
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
]: nothing -> oneof<record<changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/invoices/{invoice_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Update invoice
#
# PUT /companies/{companyId}/connections/{connectionId}/push/invoices/{invoiceId}
# operationId: update-invoice
export def "update-invoice" [
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<additionalTaxAmount: float, additionalTaxPercentage: float, amountDue: float, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, discountPercentage: float, dueDate: string, id: string, invoiceNumber: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paidOnDate: string, paymentAllocations: list<record>, salesOrderRefs: list<string>, status: string, subTotal: float, supplementalData: record<content: record>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/invoices/{invoice_id}") $qp $auth.query)
  let req_body = {"additionalTaxAmount": $additional_tax_amount, "additionalTaxPercentage": $additional_tax_percentage, "amountDue": $amount_due, "currency": $currency, "currencyRate": $currency_rate, "customerRef": $customer_ref, "discountPercentage": $discount_percentage, "dueDate": $due_date, "id": $id, "invoiceNumber": $invoice_number, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paidOnDate": $paid_on_date, "paymentAllocations": $payment_allocations, "salesOrderRefs": $sales_order_refs, "status": $status, "subTotal": $sub_total, "supplementalData": $supplemental_data, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount, "withholdingTax": $withholding_tax, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes, "forceUpdate": $force_update} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Push invoice attachment
#
# POST /companies/{companyId}/connections/{connectionId}/push/invoices/{invoiceId}/attachment
# operationId: upload-invoice-attachment
export def "upload-invoice-attachment" [
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
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/invoices/{invoice_id}/attachment") $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req_body = ($req_body | default {})
  let mp = if ($req_body | describe | str starts-with "record") { build-multipart-body $req_body [] $dry_run } else { {body: $req_body, content_type: "multipart/form-data"} }
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: $mp.content_type
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $mp.body $insecure $raw $allow_errors $full [200]
}

# Create item
#
# POST /companies/{companyId}/connections/{connectionId}/push/items
# operationId: create-item
export def "create-item" [
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<billItem: record<accountRef: record, description: string, taxRateRef: record, unitPrice: float>, code: string, id: string, invoiceItem: record<accountRef: record, description: string, taxRateRef: record, unitPrice: float>, isBillItem: bool, isInvoiceItem: bool, itemStatus: string, metadata: record<isDeleted: bool>, name: string, type: any, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/items") $qp $auth.query)
  let req_body = {"billItem": $bill_item, "code": $code, "id": $id, "invoiceItem": $invoice_item, "isBillItem": $is_bill_item, "isInvoiceItem": $is_invoice_item, "itemStatus": $item_status, "metadata": $metadata, "name": $name, "type": $type, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "isBillItem") == null) { error make --unspanned { msg: "required body field 'isBillItem' missing: pass --is-bill-item or pipe a record" } }
  if (($req_body | get -o "isInvoiceItem") == null) { error make --unspanned { msg: "required body field 'isInvoiceItem' missing: pass --is-invoice-item or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create journal entry
#
# POST /companies/{companyId}/connections/{connectionId}/push/journalEntries
# operationId: create-journal-entry
export def "create-journal-entry" [
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<createdOn: string, description: string, id: string, journalLines: list<record>, journalRef: record<id: string, name: string>, metadata: record<isDeleted: bool>, postedOn: string, recordRef: record<dataType: string, id: string>, supplementalData: record<content: record>, updatedOn: string, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/journalEntries") $qp $auth.query)
  let req_body = {"createdOn": $created_on, "description": $description, "id": $id, "journalLines": $journal_lines, "journalRef": $journal_ref, "metadata": $metadata, "postedOn": $posted_on, "recordRef": $record_ref, "supplementalData": $supplemental_data, "updatedOn": $updated_on, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete journal entry
#
# DELETE /companies/{companyId}/connections/{connectionId}/push/journalEntries/{journalEntryId}
# operationId: delete-journal-entry
export def "delete-journal-entry" [
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
]: nothing -> oneof<record<changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($journal_entry_id | is-empty) { error make --unspanned { msg: "path parameter 'journalEntryId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), journal_entry_id: (encode-path-segment $journal_entry_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/journalEntries/{journal_entry_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Create journal
#
# POST /companies/{companyId}/connections/{connectionId}/push/journals
# operationId: push-journal
export def "push-journal" [
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<createdOn: string, hasChildren: bool, id: string, journalCode: string, metadata: record<isDeleted: bool>, name: string, parentId: string, status: string, type: string, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/journals") $qp $auth.query)
  let req_body = {"createdOn": $created_on, "hasChildren": $has_children, "id": $id, "journalCode": $journal_code, "metadata": $metadata, "name": $name, "parentId": $parent_id, "status": $status, "type": $type, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create payment
#
# POST /companies/{companyId}/connections/{connectionId}/push/payments
# operationId: create-payment
export def "create-payment" [
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<accountRef: record<id: string, name: string>, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, date: string, id: string, lines: list<record>, metadata: record<isDeleted: bool>, note: string, paymentMethodRef: record<id: string, name: string>, reference: string, supplementalData: record<content: record>, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/payments") $qp $auth.query)
  let req_body = {"accountRef": $account_ref, "currency": $currency, "currencyRate": $currency_rate, "customerRef": $customer_ref, "date": $date, "id": $id, "lines": $lines, "metadata": $metadata, "note": $note, "paymentMethodRef": $payment_method_ref, "reference": $reference, "supplementalData": $supplemental_data, "totalAmount": $total_amount, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create purchase order
#
# POST /companies/{companyId}/connections/{connectionId}/push/purchaseOrders
# operationId: create-purchase-order
export def "create-purchase-order" [
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<currency: string, currencyRate: float, deliveryDate: string, expectedDeliveryDate: string, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentDueDate: string, purchaseOrderNumber: string, shipTo: record<address: record, contact: record>, status: string, subTotal: float, supplierRef: record<id: string, supplierName: string>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/purchaseOrders") $qp $auth.query)
  let req_body = {"currency": $currency, "currencyRate": $currency_rate, "deliveryDate": $delivery_date, "expectedDeliveryDate": $expected_delivery_date, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentDueDate": $payment_due_date, "purchaseOrderNumber": $purchase_order_number, "shipTo": $ship_to, "status": $status, "subTotal": $sub_total, "supplierRef": $supplier_ref, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update purchase order
#
# PUT /companies/{companyId}/connections/{connectionId}/push/purchaseOrders/{purchaseOrderId}
# operationId: update-purchase-order
export def "update-purchase-order" [
  company_id: string
  connection_id: string
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<currency: string, currencyRate: float, deliveryDate: string, expectedDeliveryDate: string, id: string, issueDate: string, lineItems: list<record>, metadata: record<isDeleted: bool>, note: string, paymentDueDate: string, purchaseOrderNumber: string, shipTo: record<address: record, contact: record>, status: string, subTotal: float, supplierRef: record<id: string, supplierName: string>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($purchase_order_id | is-empty) { error make --unspanned { msg: "path parameter 'purchaseOrderId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), purchase_order_id: (encode-path-segment $purchase_order_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/purchaseOrders/{purchase_order_id}") $qp $auth.query)
  let req_body = {"currency": $currency, "currencyRate": $currency_rate, "deliveryDate": $delivery_date, "expectedDeliveryDate": $expected_delivery_date, "id": $id, "issueDate": $issue_date, "lineItems": $line_items, "metadata": $metadata, "note": $note, "paymentDueDate": $payment_due_date, "purchaseOrderNumber": $purchase_order_number, "shipTo": $ship_to, "status": $status, "subTotal": $sub_total, "supplierRef": $supplier_ref, "totalAmount": $total_amount, "totalDiscount": $total_discount, "totalTaxAmount": $total_tax_amount, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes, "forceUpdate": $force_update} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create suppliers
#
# POST /companies/{companyId}/connections/{connectionId}/push/suppliers
# operationId: create-supplier
export def "create-supplier" [
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<addresses: list<record>, contactName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record<isDeleted: bool>, phone: string, registrationNumber: string, status: string, supplementalData: record<content: record>, supplierName: string, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/suppliers") $qp $auth.query)
  let req_body = {"addresses": $addresses, "contactName": $contact_name, "defaultCurrency": $default_currency, "emailAddress": $email_address, "id": $id, "metadata": $metadata, "phone": $phone, "registrationNumber": $registration_number, "status": $status, "supplementalData": $supplemental_data, "supplierName": $supplier_name, "taxNumber": $tax_number, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update supplier
#
# PUT /companies/{companyId}/connections/{connectionId}/push/suppliers/{supplierId}
# operationId: put-supplier
export def "put-supplier" [
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
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<addresses: list<record>, contactName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record<isDeleted: bool>, phone: string, registrationNumber: string, status: string, supplementalData: record<content: record>, supplierName: string, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  if ($supplier_id | is-empty) { error make --unspanned { msg: "path parameter 'supplierId' must be non-empty" } }
  let qp = [(serialize-qp "timeoutInMinutes" $timeout_in_minutes "scalar") (serialize-qp "forceUpdate" $force_update "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id), supplier_id: (encode-path-segment $supplier_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/suppliers/{supplier_id}") $qp $auth.query)
  let req_body = {"addresses": $addresses, "contactName": $contact_name, "defaultCurrency": $default_currency, "emailAddress": $email_address, "id": $id, "metadata": $metadata, "phone": $phone, "registrationNumber": $registration_number, "status": $status, "supplementalData": $supplemental_data, "supplierName": $supplier_name, "taxNumber": $tax_number, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"timeoutInMinutes": $timeout_in_minutes, "forceUpdate": $force_update} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create transfer
#
# POST /companies/{companyId}/connections/{connectionId}/push/transfers
# operationId: create-transfer
export def "create-transfer" [
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
  --from: record # shape: {accountRef?: record, amount?: float, currency?: string}
  --id: string # Unique identifier for the transfer.
  --metadata: record # shape: {isDeleted?: bool}
  --supplemental-data: record # Reference to a configured dynamic key value pair that is unique to the accounting platform. This feature is in private beta, contact us if you would like to learn more. — shape: {content?: record}
  --to: record # shape: {accountRef?: record, amount?: float, currency?: string}
  --tracking-category-refs: list # Reference to the tracking categories this transfer is being tracked against. (nullable) — item shape: {id: string, name?: string}
  --modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
  --source-modified-date: string # In Codat's data model, dates and times are represented using the ISO 8601 standard (https://en.wikipedia.org/wiki/ISO_8601). Date and time fields are formatted as strings; for example: ``` 2020-10-08T22:40:50Z 2021-01-01T00:00:00 ``` When syncing data that contains `DateTime` fields from Codat, make sure you support the following cases when reading time information: - Coordinated Universal Time (UTC): `2021-11-15T06:00:00Z` - Unqualified local time: `2021-11-15T01:00:00` - UTC time offsets: `2021-11-15T01:00:00-05:00` > Time zones > > Not all dates from Codat will contain information about time zones. > Where it is not available from the underlying platform, Codat will return these as times local to the business whose data has been synced.
]: any -> oneof<record<data: record<contactRef: record<dataType: string, id: string>, date: string, depositedRecordRefs: list<string>, description: string, from: record<accountRef: record, amount: float, currency: string>, id: string, metadata: record<isDeleted: bool>, supplementalData: record<content: record>, to: record<accountRef: record, amount: float, currency: string>, trackingCategoryRefs: list<record>, modifiedDate: string, sourceModifiedDate: string>, changes: table<attachmentId: string, recordRef: record, type: string>, companyId: string, completedOnUtc: string, dataConnectionKey: string, dataType: string, errorMessage: string, pushOperationKey: string, requestedOnUtc: string, status: string, statusCode: int, timeoutInMinutes: int, timeoutInSeconds: int, validation: record<errors: list<record>, warnings: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($connection_id | is-empty) { error make --unspanned { msg: "path parameter 'connectionId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), connection_id: (encode-path-segment $connection_id)} | format pattern "/companies/{company_id}/connections/{connection_id}/push/transfers") $auth.query)
  let req_body = {"contactRef": $contact_ref, "date": $date, "depositedRecordRefs": $deposited_record_refs, "description": $description, "from": $from, "id": $id, "metadata": $metadata, "supplementalData": $supplemental_data, "to": $to, "trackingCategoryRefs": $tracking_category_refs, "modifiedDate": $modified_date, "sourceModifiedDate": $source_modified_date} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List accounts
#
# GET /companies/{companyId}/data/accounts
# operationId: list-accounts
export def "list-accounts" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<currency: string, currentBalance: float, description: string, fullyQualifiedCategory: string, fullyQualifiedName: string, id: string, isBankAccount: bool, metadata: record, name: string, nominalCode: string, status: string, type: string, validDatatypeLinks: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/accounts") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get account
#
# GET /companies/{companyId}/data/accounts/{accountId}
# DEPRECATED
# operationId: get-account
@deprecated
export def "get-account" [
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
]: nothing -> oneof<record<currency: string, currentBalance: float, description: string, fullyQualifiedCategory: string, fullyQualifiedName: string, id: string, isBankAccount: bool, metadata: record<isDeleted: bool>, name: string, nominalCode: string, status: string, type: string, validDatatypeLinks: table<links: list, property: string>, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), account_id: (encode-path-segment $account_id)} | format pattern "/companies/{company_id}/data/accounts/{account_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get bank account
#
# GET /companies/{companyId}/data/bankAccounts/{accountId}
# DEPRECATED
# operationId: get-all-bank-account
@deprecated
export def "get-all-bank-account" [
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
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
]: nothing -> oneof<record<accountName: string, accountNumber: string, availableBalance: float, balance: float, currency: string, fromDate: string, iban: string, id: string, institution: string, modifiedDate: record<modifiedDate: string>, nominalCode: string, overdraftLimit: float, sortCode: string, sourceModifiedDate: record<sourceModifiedDate: string>, toDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), account_id: (encode-path-segment $account_id)} | format pattern "/companies/{company_id}/data/bankAccounts/{account_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List all bank transactions
#
# GET /companies/{companyId}/data/bankAccounts/{accountId}/transactions
# operationId: list-bank-transactions
export def "list-bank-transactions" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<amount: float, balance: float, clearedOnDate: string, counterparty: string, description: string, id: string, reconciled: bool, reference: string, transactionType: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), account_id: (encode-path-segment $account_id)} | format pattern "/companies/{company_id}/data/bankAccounts/{account_id}/transactions") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List bill credit notes
#
# GET /companies/{companyId}/data/billCreditNotes
# operationId: list-bill-credit-notes
export def "list-bill-credit-notes" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<allocatedOnDate: string, billCreditNoteNumber: string, currency: string, currencyRate: float, discountPercentage: float, id: string, issueDate: string, lineItems: list, metadata: record, note: string, paymentAllocations: list, remainingCredit: float, status: string, subTotal: float, supplementalData: record, supplierRef: record, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/billCreditNotes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get bill credit note
#
# GET /companies/{companyId}/data/billCreditNotes/{billCreditNoteId}
# DEPRECATED
# operationId: get-bill-credit-note
@deprecated
export def "get-bill-credit-note" [
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
]: nothing -> oneof<record<allocatedOnDate: string, billCreditNoteNumber: string, currency: string, currencyRate: float, discountPercentage: float, id: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, tracking: record, trackingCategoryRefs: list, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: table<allocation: record, payment: record>, remainingCredit: float, status: string, subTotal: float, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: table<amount: float, name: string>, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($bill_credit_note_id | is-empty) { error make --unspanned { msg: "path parameter 'billCreditNoteId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), bill_credit_note_id: (encode-path-segment $bill_credit_note_id)} | format pattern "/companies/{company_id}/data/billCreditNotes/{bill_credit_note_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List bill payments
#
# GET /companies/{companyId}/data/billPayments
# operationId: list-bill-payments
export def "list-bill-payments" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<accountRef: record, currency: string, currencyRate: float, date: string, id: string, lines: list, metadata: record, note: string, paymentMethodRef: record, reference: string, supplementalData: record, supplierRef: record, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/billPayments") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get bill payment
#
# GET /companies/{companyId}/data/billPayments/{billPaymentId}
# DEPRECATED
# operationId: get-bill-payments
@deprecated
export def "get-bill-payments" [
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
]: nothing -> oneof<record<accountRef: record<id: string, name: string>, currency: string, currencyRate: float, date: string, id: string, lines: table<allocatedOnDate: string, amount: float, links: list>, metadata: record<isDeleted: bool>, note: string, paymentMethodRef: record<id: string, name: string>, reference: string, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($bill_payment_id | is-empty) { error make --unspanned { msg: "path parameter 'billPaymentId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), bill_payment_id: (encode-path-segment $bill_payment_id)} | format pattern "/companies/{company_id}/data/billPayments/{bill_payment_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List bills
#
# GET /companies/{companyId}/data/bills
# operationId: list-bills
export def "list-bills" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<amountDue: float, currency: string, currencyRate: float, dueDate: string, id: string, issueDate: string, lineItems: list, metadata: record, note: string, paymentAllocations: list, purchaseOrderRefs: list, reference: string, status: string, subTotal: float, supplementalData: record, supplierRef: record, taxAmount: float, totalAmount: float, withholdingTax: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/bills") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get bill
#
# GET /companies/{companyId}/data/bills/{billId}
# operationId: get-bill
export def "get-bill" [
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
]: nothing -> oneof<record<amountDue: float, currency: string, currencyRate: float, dueDate: string, id: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, isDirectCost: bool, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, tracking: record, trackingCategoryRefs: list, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: table<allocation: record, payment: record>, purchaseOrderRefs: table<id: string, purchaseOrderNumber: string>, reference: string, status: string, subTotal: float, supplementalData: record<content: record>, supplierRef: record<id: string, supplierName: string>, taxAmount: float, totalAmount: float, withholdingTax: table<amount: float, name: string>, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($bill_id | is-empty) { error make --unspanned { msg: "path parameter 'billId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), bill_id: (encode-path-segment $bill_id)} | format pattern "/companies/{company_id}/data/bills/{bill_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List credit notes
#
# GET /companies/{companyId}/data/creditNotes
# operationId: list-credit-notes
export def "list-credit-notes" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<additionalTaxAmount: float, additionalTaxPercentage: float, allocatedOnDate: string, creditNoteNumber: string, currency: string, currencyRate: float, customerRef: record, discountPercentage: float, id: string, issueDate: string, lineItems: list, metadata: record, note: string, paymentAllocations: list, remainingCredit: float, status: string, subTotal: float, supplementalData: record, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/creditNotes") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get credit note
#
# GET /companies/{companyId}/data/creditNotes/{creditNoteId}
# DEPRECATED
# operationId: get-credit-note
@deprecated
export def "get-credit-note" [
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
]: nothing -> oneof<record<additionalTaxAmount: float, additionalTaxPercentage: float, allocatedOnDate: string, creditNoteNumber: string, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, discountPercentage: float, id: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, isDirectIncome: bool, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, tracking: record, trackingCategoryRefs: list, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, paymentAllocations: table<allocation: record, payment: record>, remainingCredit: float, status: string, subTotal: float, supplementalData: record<content: record>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: table<amount: float, name: string>, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($credit_note_id | is-empty) { error make --unspanned { msg: "path parameter 'creditNoteId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), credit_note_id: (encode-path-segment $credit_note_id)} | format pattern "/companies/{company_id}/data/creditNotes/{credit_note_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List customers
#
# GET /companies/{companyId}/data/customers
# operationId: get-customers
export def "get-customers" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<addresses: list, contactName: string, contacts: list, customerName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record, phone: string, registrationNumber: string, status: string, supplementalData: record, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/customers") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get customer
#
# GET /companies/{companyId}/data/customers/{customerId}
# DEPRECATED
# operationId: get-customer
@deprecated
export def "get-customer" [
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
]: nothing -> oneof<record<addresses: table<city: string, country: string, line1: string, line2: string, postalCode: string, region: string, type: string>, contactName: string, contacts: table<address: record, email: string, modifiedDate: string, name: string, phone: list, status: string>, customerName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record<isDeleted: bool>, phone: string, registrationNumber: string, status: string, supplementalData: record<content: record>, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), customer_id: (encode-path-segment $customer_id)} | format pattern "/companies/{company_id}/data/customers/{customer_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get balance sheet
#
# GET /companies/{companyId}/data/financials/balanceSheet
# operationId: get-balance-sheet
export def "get-balance-sheet" [
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
  --period-length: int # required, format: int32
  --periods-to-compare: int # required, format: int32
  --start-month: string
]: nothing -> oneof<record<currency: string, earliestAvailableMonth: string, mostRecentAvailableMonth: string, reports: table<assets: record, date: string, equity: record, liabilities: record, netAssets: float>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($period_length == null) { error make --unspanned { msg: "required query parameter 'periodLength' missing: pass --period-length" } }
  if ($periods_to_compare == null) { error make --unspanned { msg: "required query parameter 'periodsToCompare' missing: pass --periods-to-compare" } }
  let qp = [(serialize-qp "periodLength" $period_length "scalar") (serialize-qp "periodsToCompare" $periods_to_compare "scalar") (serialize-qp "startMonth" $start_month "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/financials/balanceSheet") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"periodLength": $period_length, "periodsToCompare": $periods_to_compare, "startMonth": $start_month} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get cash flow statement
#
# GET /companies/{companyId}/data/financials/cashFlowStatement
# operationId: get-cash-flow-statement
export def "get-cash-flow-statement" [
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
  --period-length: int # required, format: int32
  --periods-to-compare: int # required, format: int32
  --start-month: string
]: nothing -> oneof<record<currency: string, earliestAvailableMonth: string, mostRecentAvailableMonth: string, reportBasis: string, reportInput: string, reports: table<cashPayments: record, cashReceipts: record, fromDate: string, toDate: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($period_length == null) { error make --unspanned { msg: "required query parameter 'periodLength' missing: pass --period-length" } }
  if ($periods_to_compare == null) { error make --unspanned { msg: "required query parameter 'periodsToCompare' missing: pass --periods-to-compare" } }
  let qp = [(serialize-qp "periodLength" $period_length "scalar") (serialize-qp "periodsToCompare" $periods_to_compare "scalar") (serialize-qp "startMonth" $start_month "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/financials/cashFlowStatement") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"periodLength": $period_length, "periodsToCompare": $periods_to_compare, "startMonth": $start_month} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get profit and loss
#
# GET /companies/{companyId}/data/financials/profitAndLoss
# operationId: get-profit-and-loss
export def "get-profit-and-loss" [
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
  --period-length: int # required, format: int32
  --periods-to-compare: int # required, format: int32
  --start-month: string
]: nothing -> oneof<record<currency: string, earliestAvailableMonth: string, mostRecentAvailableMonth: string, reportBasis: string, reports: table<costOfSales: record, expenses: record, fromDate: string, grossProfit: float, income: record, netOperatingProfit: float, netOtherIncome: float, netProfit: float, otherExpenses: record, otherIncome: record, toDate: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($period_length == null) { error make --unspanned { msg: "required query parameter 'periodLength' missing: pass --period-length" } }
  if ($periods_to_compare == null) { error make --unspanned { msg: "required query parameter 'periodsToCompare' missing: pass --periods-to-compare" } }
  let qp = [(serialize-qp "periodLength" $period_length "scalar") (serialize-qp "periodsToCompare" $periods_to_compare "scalar") (serialize-qp "startMonth" $start_month "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/financials/profitAndLoss") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"periodLength": $period_length, "periodsToCompare": $periods_to_compare, "startMonth": $start_month} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get company info
#
# GET /companies/{companyId}/data/info
# operationId: get-company-info
export def "get-company-info" [
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
]: nothing -> oneof<record<accountingPlatformRef: string, addresses: table<city: string, country: string, line1: string, line2: string, postalCode: string, region: string, type: string>, baseCurrency: string, companyLegalName: string, companyName: string, createdDate: string, financialYearStartDate: string, ledgerLockDate: string, phoneNumbers: table<number: string, type: string>, registrationNumber: string, sourceUrls: record, taxNumber: string, webLinks: table<type: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/info") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Refresh company info
#
# POST /companies/{companyId}/data/info
# operationId: post-sync-info
export def "post-sync-info" [
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
]: nothing -> oneof<record<companyId: string, completed: string, connectionId: string, dataType: string, datasetLogsUrl: string, errorMessage: string, id: string, isCompleted: bool, isErrored: bool, progress: int, requested: string, status: string, validationInformationUrl: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/info") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# List invoices
#
# GET /companies/{companyId}/data/invoices
# operationId: list-invoices
export def "list-invoices" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<additionalTaxAmount: float, additionalTaxPercentage: float, amountDue: float, currency: string, currencyRate: float, customerRef: record, discountPercentage: float, dueDate: string, id: string, invoiceNumber: string, issueDate: string, lineItems: list, metadata: record, note: string, paidOnDate: string, paymentAllocations: list, salesOrderRefs: list, status: string, subTotal: float, supplementalData: record, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/invoices") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get invoice
#
# GET /companies/{companyId}/data/invoices/{invoiceId}
# DEPRECATED
# operationId: get-invoice
@deprecated
export def "get-invoice" [
  company_id: string
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
]: nothing -> oneof<record<additionalTaxAmount: float, additionalTaxPercentage: float, amountDue: float, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, discountPercentage: float, dueDate: string, id: string, invoiceNumber: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, isDirectIncome: bool, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, tracking: record, trackingCategoryRefs: list, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, paidOnDate: string, paymentAllocations: table<allocation: record, payment: record>, salesOrderRefs: list<string>, status: string, subTotal: float, supplementalData: record<content: record>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, withholdingTax: table<amount: float, name: string>, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/companies/{company_id}/data/invoices/{invoice_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Get invoice as PDF
#
# GET /companies/{companyId}/data/invoices/{invoiceId}/pdf
# operationId: Download-invoice-pdf
export def "download-invoice-pdf" [
  company_id: string
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
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), invoice_id: (encode-path-segment $invoice_id)} | format pattern "/companies/{company_id}/data/invoices/{invoice_id}/pdf") $auth.query)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List items
#
# GET /companies/{companyId}/data/items
# operationId: list-items
export def "list-items" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<billItem: record, code: string, id: string, invoiceItem: record, isBillItem: bool, isInvoiceItem: bool, itemStatus: string, metadata: record, name: string, type: any, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/items") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get item
#
# GET /companies/{companyId}/data/items/{itemId}
# DEPRECATED
# operationId: get-item
@deprecated
export def "get-item" [
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
]: nothing -> oneof<record<billItem: record<accountRef: record<id: string, name: string>, description: string, taxRateRef: record<effectiveTaxRate: float, id: string, name: string>, unitPrice: float>, code: string, id: string, invoiceItem: record<accountRef: record<id: string, name: string>, description: string, taxRateRef: record<effectiveTaxRate: float, id: string, name: string>, unitPrice: float>, isBillItem: bool, isInvoiceItem: bool, itemStatus: string, metadata: record<isDeleted: bool>, name: string, type: any, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), item_id: (encode-path-segment $item_id)} | format pattern "/companies/{company_id}/data/items/{item_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List journal entries
#
# GET /companies/{companyId}/data/journalEntries
# operationId: list-journal-entries
export def "list-journal-entries" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<createdOn: string, description: string, id: string, journalLines: list, journalRef: record, metadata: record, postedOn: string, recordRef: record, supplementalData: record, updatedOn: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/journalEntries") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get journal entry
#
# GET /companies/{companyId}/data/journalEntries/{journalEntryId}
# DEPRECATED
# operationId: get-journal-entry
@deprecated
export def "get-journal-entry" [
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
]: nothing -> oneof<record<createdOn: string, description: string, id: string, journalLines: table<accountRef: record, currency: string, description: string, netAmount: float, tracking: record>, journalRef: record<id: string, name: string>, metadata: record<isDeleted: bool>, postedOn: string, recordRef: record<dataType: string, id: string>, supplementalData: record<content: record>, updatedOn: string, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($journal_entry_id | is-empty) { error make --unspanned { msg: "path parameter 'journalEntryId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), journal_entry_id: (encode-path-segment $journal_entry_id)} | format pattern "/companies/{company_id}/data/journalEntries/{journal_entry_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List journals
#
# GET /companies/{companyId}/data/journals
# operationId: list-journals
export def "list-journals" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<createdOn: string, hasChildren: bool, id: string, journalCode: string, metadata: record, name: string, parentId: string, status: string, type: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/journals") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get journal
#
# GET /companies/{companyId}/data/journals/{journalId}
# DEPRECATED
# operationId: get-journal
@deprecated
export def "get-journal" [
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
]: nothing -> oneof<record<createdOn: string, hasChildren: bool, id: string, journalCode: string, metadata: record<isDeleted: bool>, name: string, parentId: string, status: string, type: string, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($journal_id | is-empty) { error make --unspanned { msg: "path parameter 'journalId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), journal_id: (encode-path-segment $journal_id)} | format pattern "/companies/{company_id}/data/journals/{journal_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List all payment methods
#
# GET /companies/{companyId}/data/paymentMethods
# DEPRECATED
# operationId: list-payment-methods
@deprecated
export def "list-payment-methods" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<amountDue: float, currency: string, currencyRate: float, dueDate: string, id: string, issueDate: string, lineItems: list, metadata: record, note: string, paymentAllocations: list, purchaseOrderRefs: list, reference: string, status: string, subTotal: float, supplementalData: record, supplierRef: record, taxAmount: float, totalAmount: float, withholdingTax: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/paymentMethods") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get payment method
#
# GET /companies/{companyId}/data/paymentMethods/{paymentMethodId}
# DEPRECATED
# operationId: get-payment-method
@deprecated
export def "get-payment-method" [
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
]: nothing -> oneof<record<id: string, metadata: record<isDeleted: bool>, name: string, status: string, type: string, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($payment_method_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentMethodId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), payment_method_id: (encode-path-segment $payment_method_id)} | format pattern "/companies/{company_id}/data/paymentMethods/{payment_method_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List payments
#
# GET /companies/{companyId}/data/payments
# operationId: list-payments
export def "list-payments" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: list<any>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/payments") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get payment
#
# GET /companies/{companyId}/data/payments/{paymentId}
# DEPRECATED
# operationId: get-payment
@deprecated
export def "get-payment" [
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
]: nothing -> oneof<record<accountRef: record<id: string, name: string>, currency: string, currencyRate: float, customerRef: record<companyName: string, id: string>, date: string, id: string, lines: table<allocatedOnDate: string, amount: float, links: list>, metadata: record<isDeleted: bool>, note: string, paymentMethodRef: record<id: string, name: string>, reference: string, supplementalData: record<content: record>, totalAmount: float, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), payment_id: (encode-path-segment $payment_id)} | format pattern "/companies/{company_id}/data/payments/{payment_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List purchase orders
#
# GET /companies/{companyId}/data/purchaseOrders
# operationId: list-purchase-orders
export def "list-purchase-orders" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<currency: string, currencyRate: float, deliveryDate: string, expectedDeliveryDate: string, id: string, issueDate: string, lineItems: list, metadata: record, note: string, paymentDueDate: string, purchaseOrderNumber: string, shipTo: record, status: string, subTotal: float, supplierRef: record, totalAmount: float, totalDiscount: float, totalTaxAmount: float, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/purchaseOrders") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get purchase order
#
# GET /companies/{companyId}/data/purchaseOrders/{purchaseOrderId}
# DEPRECATED
# operationId: get-purchase-order
@deprecated
export def "get-purchase-order" [
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
]: nothing -> oneof<record<currency: string, currencyRate: float, deliveryDate: string, expectedDeliveryDate: string, id: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, trackingCategoryRefs: list, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, paymentDueDate: string, purchaseOrderNumber: string, shipTo: record<address: record<city: string, country: string, line1: string, line2: string, postalCode: string, region: string, type: string>, contact: record<email: string, name: string, phone: string>>, status: string, subTotal: float, supplierRef: record<id: string, supplierName: string>, totalAmount: float, totalDiscount: float, totalTaxAmount: float, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($purchase_order_id | is-empty) { error make --unspanned { msg: "path parameter 'purchaseOrderId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), purchase_order_id: (encode-path-segment $purchase_order_id)} | format pattern "/companies/{company_id}/data/purchaseOrders/{purchase_order_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List sales orders
#
# GET /companies/{companyId}/data/salesOrders
# operationId: list-sales-orders
export def "list-sales-orders" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<currency: string, currencyRate: float, customerPurchaseOrderNumber: string, customerRef: record, expectedDeliveryDate: string, id: string, invoicingStatus: string, issueDate: string, lineItems: list, metadata: record, note: string, salesOrderNumber: string, shipTo: record, status: string, subTotal: float, totalAmount: float, totalDiscount: float, totalTaxAmount: float, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/salesOrders") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get sales order
#
# GET /companies/{companyId}/data/salesOrders/{salesOrderId}
# DEPRECATED
# operationId: get-sales-order
@deprecated
export def "get-sales-order" [
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
]: nothing -> oneof<record<currency: string, currencyRate: float, customerPurchaseOrderNumber: string, customerRef: record<companyName: string, id: string>, expectedDeliveryDate: string, id: string, invoicingStatus: string, issueDate: string, lineItems: table<accountRef: record, description: string, discountAmount: float, discountPercentage: float, itemRef: record, quantity: float, subTotal: float, taxAmount: float, taxRateRef: record, totalAmount: float, tracking: record, unitAmount: float>, metadata: record<isDeleted: bool>, note: string, salesOrderNumber: string, shipTo: record<address: record<city: string, country: string, line1: string, line2: string, postalCode: string, region: string, type: string>, contact: record<email: string, name: string, phone: string>>, status: string, subTotal: float, totalAmount: float, totalDiscount: float, totalTaxAmount: float, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($sales_order_id | is-empty) { error make --unspanned { msg: "path parameter 'salesOrderId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), sales_order_id: (encode-path-segment $sales_order_id)} | format pattern "/companies/{company_id}/data/salesOrders/{sales_order_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List suppliers
#
# GET /companies/{companyId}/data/suppliers
# operationId: list-suppliers
export def "list-suppliers" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<addresses: list, contactName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record, phone: string, registrationNumber: string, status: string, supplementalData: record, supplierName: string, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/suppliers") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get supplier
#
# GET /companies/{companyId}/data/suppliers/{supplierId}
# DEPRECATED
# operationId: get-supplier
@deprecated
export def "get-supplier" [
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
]: nothing -> oneof<record<addresses: table<city: string, country: string, line1: string, line2: string, postalCode: string, region: string, type: string>, contactName: string, defaultCurrency: string, emailAddress: string, id: string, metadata: record<isDeleted: bool>, phone: string, registrationNumber: string, status: string, supplementalData: record<content: record>, supplierName: string, taxNumber: string, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($supplier_id | is-empty) { error make --unspanned { msg: "path parameter 'supplierId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), supplier_id: (encode-path-segment $supplier_id)} | format pattern "/companies/{company_id}/data/suppliers/{supplier_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List all tax rates
#
# GET /companies/{companyId}/data/taxRates
# operationId: list-tax-rates
export def "list-tax-rates" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<code: string, components: list, effectiveTaxRate: float, id: string, metadata: record, name: string, status: string, totalTaxRate: float, validDatatypeLinks: list, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/taxRates") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get tax rate
#
# GET /companies/{companyId}/data/taxRates/{taxRateId}
# DEPRECATED
# operationId: get-tax-rate
@deprecated
export def "get-tax-rate" [
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
]: nothing -> oneof<record<code: string, components: table<isCompound: bool, name: string, rate: float>, effectiveTaxRate: float, id: string, metadata: record<isDeleted: bool>, name: string, status: string, totalTaxRate: float, validDatatypeLinks: table<links: list, property: string>, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($tax_rate_id | is-empty) { error make --unspanned { msg: "path parameter 'taxRateId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), tax_rate_id: (encode-path-segment $tax_rate_id)} | format pattern "/companies/{company_id}/data/taxRates/{tax_rate_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# List tracking categories
#
# GET /companies/{companyId}/data/trackingCategories
# operationId: list-tracking-categories
export def "list-tracking-categories" [
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
  --page: int # Page number. [Read more](https://docs.codat.io/using-the-api/paging). (required, format: int32, default: 1)
  --page-size: int # Number of records to return in a page. [Read more](https://docs.codat.io/using-the-api/paging). (format: int32, default: 100)
  --query: string # Codat query string. [Read more](https://docs.codat.io/using-the-api/querying).
  --order-by: string # Field to order results by. [Read more](https://docs.codat.io/using-the-api/ordering-results).
]: nothing -> oneof<record<results: table<hasChildren: bool, id: string, name: string, parentId: string, status: string, modifiedDate: string, sourceModifiedDate: string>, _links: record<current: record<href: string>, next: record<href: string>, previous: record<href: string>, self: record<href: string>>, pageNumber: int, pageSize: int, totalResults: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let page = ($page | default 1)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "orderBy" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/data/trackingCategories") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "query": $query, "orderBy": $order_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get tracking categories
#
# GET /companies/{companyId}/data/trackingCategories/{trackingCategoryId}
# DEPRECATED
# operationId: get-tracking-category
@deprecated
export def "get-tracking-category" [
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
]: nothing -> oneof<record<hasChildren: bool, id: string, name: string, parentId: string, status: string, subCategories: list<any>, modifiedDate: string, sourceModifiedDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($tracking_category_id | is-empty) { error make --unspanned { msg: "path parameter 'trackingCategoryId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), tracking_category_id: (encode-path-segment $tracking_category_id)} | format pattern "/companies/{company_id}/data/trackingCategories/{tracking_category_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Aged creditors report
#
# GET /companies/{companyId}/reports/agedCreditor
# operationId: get-aged-creditors-report
export def "get-aged-creditors-report" [
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
  --report-date: string # Date the report is generated up to. (format: date)
  --number-of-periods: int # Number of periods to include in the report. (format: int32)
  --period-length-days: int # The length of period in days. (format: int32)
]: nothing -> oneof<record<data: table<agedCurrencyOutstanding: list, supplierId: string, supplierName: string>, generated: string, reportDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let qp = [(serialize-qp "reportDate" $report_date "scalar") (serialize-qp "numberOfPeriods" $number_of_periods "scalar") (serialize-qp "periodLengthDays" $period_length_days "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/reports/agedCreditor") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"reportDate": $report_date, "numberOfPeriods": $number_of_periods, "periodLengthDays": $period_length_days} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Aged creditors report available
#
# GET /companies/{companyId}/reports/agedCreditor/available
# operationId: is-aged-creditors-report-available
export def "is-aged-creditors-report-available" [
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
]: nothing -> oneof<bool, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/reports/agedCreditor/available") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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

# Aged debtors report
#
# GET /companies/{companyId}/reports/agedDebtor
# operationId: get-aged-debtors-report
export def "get-aged-debtors-report" [
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
  --report-date: string # Date the report is generated up to. (format: date)
  --number-of-periods: int # Number of periods to include in the report. (format: int32)
  --period-length-days: int # The length of period in days. (format: int32)
]: nothing -> oneof<record<data: table<agedCurrencyOutstanding: list, customerId: string, customerName: string>, generated: string, reportDate: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let qp = [(serialize-qp "reportDate" $report_date "scalar") (serialize-qp "numberOfPeriods" $number_of_periods "scalar") (serialize-qp "periodLengthDays" $period_length_days "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/reports/agedDebtor") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"reportDate": $report_date, "numberOfPeriods": $number_of_periods, "periodLengthDays": $period_length_days} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Aged debtors report available
#
# GET /companies/{companyId}/reports/agedDebtor/available
# operationId: is-aged-debtor-report-available
export def "is-aged-debtor-report-available" [
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
]: nothing -> oneof<bool, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/companies/{company_id}/reports/agedDebtor/available") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
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
