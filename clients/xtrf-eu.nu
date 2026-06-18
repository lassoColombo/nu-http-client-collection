# Auto-generated client for XTRF Home Portal API v2.0
# Source: https://api.apis.guru/v2/specs/xtrf.eu/2.0/openapi.json
# Auth: --token flag or $env.XTRF_HOME_PORTAL_API_TOKEN

const BASE_URL = "https://presentation.s.xtrf.eu/home-api"
const DEFAULT_AUTH = "x-auth-access-token"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o XTRF_HOME_PORTAL_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-auth-access-token" => { {headers: {X-AUTH-ACCESS-TOKEN: $token_val}, query: ""} }
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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
def build-multipart-body [parts: record, file_fields: list<string>]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | transpose k v | where {|p| $p.v != null} | each {|p|
    let name = $p.k
    let val = $p.v
    if $name in $file_fields {
      let filename = ($val | path basename)
      let bytes = (open --raw $val | into binary | collect)
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  })
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://presentation.s.xtrf.eu/home-api"] }
def auth-scheme-completer [] { ["x-auth-access-token"] }

# Completers for enum parameters
def status-completer [] { ["BILL_CREATED" "CONFIRMED" "POSTPONED" "SENT" "TO_BE_SENT"] }
def status-completer-1 [] { ["ACTIVE" "INACTIVE" "POTENTIAL"] }
def type-completer [] { ["CHECKBOX" "DATE" "DATE_AND_TIME" "MULTI_SELECTION" "NUMBER" "SELECTION" "TEXT"] }
def rate-origin-completer [] { ["AUTOCALCULATED" "FILLED_MANUALLY" "PRICE_LIST" "PRICE_PROFILE"] }
def type-completer-1 [] { ["CAT" "SIMPLE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounting-customers-invoices get-list" } } | get name | first)
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

# Lists all client invoices in all statuses (including not ready and drafts) that have been updated since a specific date.
#
# GET /accounting/customers/invoices
# operationId: getAll
export def "accounting-customers-invoices get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only client invoices modified since this timestamp (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/customers/invoices" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new invoice.
#
# POST /accounting/customers/invoices
# operationId: create_1
export def "accounting-customers-invoices create-by-" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounting/customers/invoices")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Generates client invoices' documents.
#
# POST /accounting/customers/invoices/documents
# operationId: downloadDocuments
export def "accounting-customers-invoices-documents download" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounting/customers/invoices/documents")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Returns client invoices' internal identifiers.
#
# GET /accounting/customers/invoices/ids
# operationId: getAllIds
export def "accounting-customers-invoices-ids get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only client invoices modified since this timestamp (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/customers/invoices/ids" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sends reminders. Returns number of sent e-mails.
#
# POST /accounting/customers/invoices/sendReminders
# operationId: sendReminders
export def "accounting-customers-invoices-send-reminders send" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounting/customers/invoices/sendReminders")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Removes a client invoice.
#
# DELETE /accounting/customers/invoices/{invoiceId}
# operationId: delete_1
export def "accounting-customers-invoices delete-by-invoiceId" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/customers/invoices/{invoice_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns client invoice details.
#
# GET /accounting/customers/invoices/{invoiceId}
# operationId: getById
export def "accounting-customers-invoices get" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: string # list of adittional fields which should be embedded in the response (ie. tasks)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "embed" $embed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/customers/invoices/{invoice_id}") $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns dates of a given client invoice.
#
# GET /accounting/customers/invoices/{invoiceId}/dates
# operationId: getDates
export def "accounting-customers-invoices-dates get" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/customers/invoices/{invoice_id}/dates"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generates client invoice document (PDF).
#
# GET /accounting/customers/invoices/{invoiceId}/document
# operationId: getDocument
export def "accounting-customers-invoices-document get" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/customers/invoices/{invoice_id}/document"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Duplicate client invoice.
#
# POST /accounting/customers/invoices/{invoiceId}/duplicate
# operationId: duplicate
export def "accounting-customers-invoices-duplicate create" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/customers/invoices/{invoice_id}/duplicate"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Duplicate client invoice as pro forma.
#
# POST /accounting/customers/invoices/{invoiceId}/duplicate/proForma
# operationId: duplicateAsProForma
export def "accounting-customers-invoices-duplicate-pro-forma create" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/customers/invoices/{invoice_id}/duplicate/proForma"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns payment terms of a given client invoice.
#
# GET /accounting/customers/invoices/{invoiceId}/paymentTerms
# operationId: getPaymentTerms
export def "accounting-customers-invoices-payment-terms get" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/customers/invoices/{invoice_id}/paymentTerms"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all payments for the client invoice.
#
# GET /accounting/customers/invoices/{invoiceId}/payments
# operationId: getPayments
export def "accounting-customers-invoices-payments get" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/customers/invoices/{invoice_id}/payments"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a new payment to the client invoice. The invoice payment status (Not Paid, Partially Paid, Fully Paid) is automatically recalculated.
#
# POST /accounting/customers/invoices/{invoiceId}/payments
# operationId: createPayment
export def "accounting-customers-invoices-payments create" [
  invoice_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/customers/invoices/{invoice_id}/payments"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Sends reminder.
#
# POST /accounting/customers/invoices/{invoiceId}/sendReminder
# operationId: sendReminder
export def "accounting-customers-invoices-send-reminder send" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/customers/invoices/{invoice_id}/sendReminder"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a customer payment.
#
# DELETE /accounting/customers/payments/{paymentId}
# operationId: delete_2
export def "accounting-customers-payments delete-by-paymentId" [
  payment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id)} | format pattern "/accounting/customers/payments/{payment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all vendor invoices in all statuses (including not ready and drafts) that have been updated since a specific date.
#
# GET /accounting/providers/invoices
# operationId: getAll_2
export def "accounting-providers-invoices get-list-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only vendor invoices modified since this timestamp (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/providers/invoices" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new invoice.
#
# POST /accounting/providers/invoices
# operationId: create_4
export def "accounting-providers-invoices create-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --jobs-ids: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounting/providers/invoices")
  let req_body = {"jobsIds": $jobs_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns vendor invoices' internal identifiers.
#
# GET /accounting/providers/invoices/ids
# operationId: getAllIds_3
export def "accounting-providers-invoices-ids get-list-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only vendor invoices modified since this timestamp (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/providers/invoices/ids" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a provider invoice.
#
# DELETE /accounting/providers/invoices/{invoiceId}
# operationId: delete_6
export def "accounting-providers-invoices delete-by-invoiceId" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/providers/invoices/{invoice_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns provider invoice details.
#
# GET /accounting/providers/invoices/{invoiceId}
# operationId: getById_3
export def "accounting-providers-invoices get-by-invoiceId" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/providers/invoices/{invoice_id}"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generates provider invoice document (PDF).
#
# GET /accounting/providers/invoices/{invoiceId}/document
# operationId: getDocument_1
export def "accounting-providers-invoices-document get-by-invoiceId" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/providers/invoices/{invoice_id}/document"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all payments for the vendor invoice.
#
# GET /accounting/providers/invoices/{invoiceId}/payments
# operationId: getPayments_1
export def "accounting-providers-invoices-payments get-by-invoiceId" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/providers/invoices/{invoice_id}/payments"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new payment on the vendor account and assigns the payment to the invoice.
#
# POST /accounting/providers/invoices/{invoiceId}/payments
# operationId: createPayment_1
export def "accounting-providers-invoices-payments create-by-invoiceId" [
  invoice_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/providers/invoices/{invoice_id}/payments"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Sends a provider invoice.
#
# POST /accounting/providers/invoices/{invoiceId}/send
# operationId: send
export def "accounting-providers-invoices-send send" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/providers/invoices/{invoice_id}/send"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Changes invoice status to given status.
#
# POST /accounting/providers/invoices/{invoiceId}/status
# operationId: setStatus
export def "accounting-providers-invoices-status update" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/providers/invoices/{invoice_id}/status"))
  let req_body = {"status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes a provider payment.
#
# DELETE /accounting/providers/payments/{paymentId}
# operationId: delete_7
export def "accounting-providers-payments delete-by-paymentId" [
  payment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id)} | format pattern "/accounting/providers/payments/{payment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Searches for data (ie. customer, task, etc) and returns it in a tabular form.
#
# GET /browser
# operationId: browseJSON
export def "browser get-browse-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --view-id: int # view's identifier (format: int64)
  --page: int # format: int32, default: 0
  --additional-order: string
  --use-deferred-columns: string
  --max-rows: int # overrides view's default rows limit, supported values 10 to 1000 (format: int32, default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "viewId" $view_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "additionalOrder" $additional_order "scalar") (serialize-qp "useDeferredColumns" $use_deferred_columns "scalar") (serialize-qp "maxRows" $max_rows "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/browser" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Searches for data (ie. customer, task, etc) and returns it in a CSV form.
#
# GET /browser/csv
# operationId: browseCSV
export def "browser-csv get-browse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --view-id: int # view's identifier (format: int64)
  --separator: string # csv field separator
  --secondary-separator: string # secondary csv field separator
  --additional-order: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "viewId" $view_id "scalar") (serialize-qp "separator" $separator "scalar") (serialize-qp "secondarySeparator" $secondary_separator "scalar") (serialize-qp "additionalOrder" $additional_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/browser/csv" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns current view's detailed information, suitable for browser.
#
# GET /browser/views/details/for/{className}
# operationId: getCurrentViewDetails
export def "browser-views-details-for get-get" [
  class_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --place-name: string # place name (denotes specific place in system with the table) (default: default)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "placeName" $place_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({class_name: (encode-path-segment $class_name)} | format pattern "/browser/views/details/for/{class_name}") $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns view's detailed information, suitable for browser.
#
# GET /browser/views/details/for/{className}/{viewId}
# operationId: getViewDetails
export def "browser-views-details-for get" [
  class_name: string
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --place-name: string # place name (denotes specific place in system with the table) (default: default)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "placeName" $place_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({class_name: (encode-path-segment $class_name), view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/details/for/{class_name}/{view_id}") $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Selects given view as current and returns its detailed information, suitable for browser.
#
# POST /browser/views/details/for/{className}/{viewId}
# operationId: selectViewAndGetItsDetails
export def "browser-views-details-for get-select-and-its" [
  class_name: string
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --place-name-denotes-specific-place-in-system-with-the-table: string # default: default
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "place name (denotes specific place in system with the table)" $place_name_denotes_specific_place_in_system_with_the_table "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({class_name: (encode-path-segment $class_name), view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/details/for/{class_name}/{view_id}") $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns views' brief.
#
# GET /browser/views/for/{className}
# operationId: getViewsBrief
export def "browser-views-for get-brief" [
  class_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --place-name: string # place name (denotes specific place in system with the table) (default: default)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "placeName" $place_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({class_name: (encode-path-segment $class_name)} | format pattern "/browser/views/for/{class_name}") $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates view for given class.
#
# POST /browser/views/for/{className}
# operationId: create
export def "browser-views-for create" [
  class_name: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({class_name: (encode-path-segment $class_name)} | format pattern "/browser/views/for/{class_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Removes a view.
#
# DELETE /browser/views/{viewId}
# operationId: delete
export def "browser-views delete" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all view's information.
#
# GET /browser/views/{viewId}
# operationId: get
export def "browser-views get" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates all view's information.
#
# PUT /browser/views/{viewId}
# operationId: update
export def "browser-views update" [
  view_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Returns columns defined in view.
#
# GET /browser/views/{viewId}/columns
# operationId: getColumns
export def "browser-views-columns get" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/columns"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates columns in view.
#
# PUT /browser/views/{viewId}/columns
# operationId: updateColumns
export def "browser-views-columns update" [
  view_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/columns"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Deletes a single column from view.
#
# DELETE /browser/views/{viewId}/columns/{columnName}
# operationId: deleteColumn
export def "browser-views-columns delete" [
  view_id: int
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id), column_name: (encode-path-segment $column_name)} | format pattern "/browser/views/{view_id}/columns/{column_name}"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns column's specific settings.
#
# GET /browser/views/{viewId}/columns/{columnName}/settings
# operationId: getColumnSettings
export def "browser-views-columns-settings get" [
  view_id: int
  column_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id), column_name: (encode-path-segment $column_name)} | format pattern "/browser/views/{view_id}/columns/{column_name}/settings"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates column's specific settings.
#
# PUT /browser/views/{viewId}/columns/{columnName}/settings
# operationId: updateColumnSettings
export def "browser-views-columns-settings update" [
  view_id: int
  column_name: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id), column_name: (encode-path-segment $column_name)} | format pattern "/browser/views/{view_id}/columns/{column_name}/settings"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns view's filter.
#
# GET /browser/views/{viewId}/filter
# operationId: getFilter
export def "browser-views-filter get" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/filter"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates view's filter.
#
# PUT /browser/views/{viewId}/filter
# operationId: updateFilter
export def "browser-views-filter update" [
  view_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/filter"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Updates view's filter property.
#
# PUT /browser/views/{viewId}/filter/{filterProperty}
# operationId: updateFilterProperty
export def "browser-views-filter update-property" [
  view_id: int
  filter_property: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --settings: record
  --settings-present: oneof<nothing, bool>
  --type: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id), filter_property: (encode-path-segment $filter_property)} | format pattern "/browser/views/{view_id}/filter/{filter_property}"))
  let req_body = {"name": $name, "settings": $settings, "settingsPresent": $settings_present, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns view's order settings.
#
# GET /browser/views/{viewId}/order
# operationId: getOrder
export def "browser-views-order get" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/order"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates view's order settings.
#
# PUT /browser/views/{viewId}/order
# operationId: updateOrder
export def "browser-views-order update" [
  view_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/order"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Returns view's permissions.
#
# GET /browser/views/{viewId}/permissions
# operationId: getPermissions
export def "browser-views-permissions get" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/permissions"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates view's permissions.
#
# PUT /browser/views/{viewId}/permissions
# operationId: updatePermissions
export def "browser-views-permissions update" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --shared-groups: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/permissions"))
  let req_body = {"sharedGroups": $shared_groups} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns view's settings.
#
# GET /browser/views/{viewId}/settings
# operationId: getSettings
export def "browser-views-settings get" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/settings"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates view's settings.
#
# PUT /browser/views/{viewId}/settings
# operationId: updateSettings
# --local shape: {maxLinesInRow?: int, maxRows?: int}
export def "browser-views-settings update" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --local: record # shape: {maxLinesInRow?: int, maxRows?: int}
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/settings"))
  let req_body = {"local": $local, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns view's local settings (for current user).
#
# GET /browser/views/{viewId}/settings/local
# operationId: getLocalSettings
export def "browser-views-settings-local get" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/settings/local"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates view's local settings (for current user).
#
# PUT /browser/views/{viewId}/settings/local
# operationId: updateLocalSettings
export def "browser-views-settings-local update" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-lines-in-row: int # format: int32
  --max-rows: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/settings/local"))
  let req_body = {"maxLinesInRow": $max_lines_in_row, "maxRows": $max_rows} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns list of simple clients representations
#
# GET /customers
# operationId: getAllNamesWithIds
export def "customers get-list-names" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only clients modified since this timestamp (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customers" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new client.
#
# POST /customers
# operationId: create_3
# --accounting shape: {taxNumbers?: list}
# --billingAddress shape: {addressLine1?: string, addressLine2?: string, city?: string, countryId?: int, postalCode?: string, provinceId?: int, sameAsBillingAddress?: bool}
# --contact shape: {emails?: record, fax?: string, phones?: list<string>, sms?: string, websites?: list<string>}
# --correspondenceAddress shape: {addressLine1?: string, addressLine2?: string, city?: string, countryId?: int, postalCode?: string, provinceId?: int, sameAsBillingAddress?: bool}
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
# --persons item shape: {active?: bool, contact?: record, customFields?: list, customerId?: int, firstProjectDate?: string, firstQuoteDate?: string, gender?: "FEMALE"|"MALE", id?: int, lastName?: string, lastProjectDate?: string, lastQuoteDate?: string, motherTonguesIds?: list<int>, name?: string, numberOfProjects?: int, numberOfQuotes?: int, positionId?: int}
# --responsiblePersons shape: {accountManagerId?: int, projectCoordinatorId?: int, projectManagerId: int, salesPersonId: int}
export def "customers create-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-on-customer-server: string
  --accounting: record # shape: {taxNumbers?: list}
  --billing-address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, countryId?: int, postalCode?: string, provinceId?: int, sameAsBillingAddress?: bool}
  --branch-id: int # format: int64
  --categories-ids: list<int>
  --client-first-project-date: string # format: date-time
  --client-first-quote-date: string # format: date-time
  --client-last-project-date: string # format: date-time
  --client-last-quote-date: string # format: date-time
  --client-number-of-projects: int # format: int32
  --client-number-of-quotes: int # format: int32
  --contact: record # shape: {emails?: record, fax?: string, phones?: list<string>, sms?: string, websites?: list<string>}
  --contract-number: string
  --correspondence-address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, countryId?: int, postalCode?: string, provinceId?: int, sameAsBillingAddress?: bool}
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --full-name: string
  --id: int # format: int64
  --id-number: string
  --industries-ids: list<int>
  --lead-source-id: int # format: int64
  --limit-access-to-people-responsible: oneof<nothing, bool>
  --name: string
  --notes: string
  --persons: list # item shape: {active?: bool, contact?: record, customFields?: list, customerId?: int, firstProjectDate?: string, firstQuoteDate?: string, gender?: "FEMALE"|"MALE", id?: int, lastName?: string, lastProjectDate?: string, lastQuoteDate?: string, motherTonguesIds?: list<int>, name?: string, numberOfProjects?: int, numberOfQuotes?: int, positionId?: int}
  --responsible-persons: record # shape: {accountManagerId?: int, projectCoordinatorId?: int, projectManagerId: int, salesPersonId: int}
  --sales-notes: string
  --status: string@status-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customers")
  let req_body = {"accountOnCustomerServer": $account_on_customer_server, "accounting": $accounting, "billingAddress": $billing_address, "branchId": $branch_id, "categoriesIds": $categories_ids, "clientFirstProjectDate": $client_first_project_date, "clientFirstQuoteDate": $client_first_quote_date, "clientLastProjectDate": $client_last_project_date, "clientLastQuoteDate": $client_last_quote_date, "clientNumberOfProjects": $client_number_of_projects, "clientNumberOfQuotes": $client_number_of_quotes, "contact": $contact, "contractNumber": $contract_number, "correspondenceAddress": $correspondence_address, "customFields": $custom_fields, "fullName": $full_name, "id": $id, "idNumber": $id_number, "industriesIds": $industries_ids, "leadSourceId": $lead_source_id, "limitAccessToPeopleResponsible": $limit_access_to_people_responsible, "name": $name, "notes": $notes, "persons": $persons, "responsiblePersons": $responsible_persons, "salesNotes": $sales_notes, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns clients' internal identifiers.
#
# GET /customers/ids
# operationId: getAllIds_2
export def "customers-ids get-list-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only clients modified since this timestamp (format: int64)
  --name-equals: string # exact name of client
  --email-equals: string # exact email of client
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar") (serialize-qp "nameEquals" $name_equals "scalar") (serialize-qp "emailEquals" $email_equals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customers/ids" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new person.
#
# POST /customers/persons
# operationId: create_2
export def "customers-persons create-by-" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customers/persons")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Generates a single use sign-in token.
#
# POST /customers/persons/accessToken
# operationId: generateSingleUseSignInToken
export def "customers-persons-access-token generate-single-use-sign" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customers/persons/accessToken")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Returns persons' internal identifiers.
#
# GET /customers/persons/ids
# operationId: getAllIds_1
export def "customers-persons-ids get-list-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only persons modified since this timestamp (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customers/persons/ids" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a person.
#
# DELETE /customers/persons/{personId}
# operationId: delete_3
export def "customers-persons delete-by-personId" [
  person_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/customers/persons/{person_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns person details.
#
# GET /customers/persons/{personId}
# operationId: getById_1
export def "customers-persons get-by-personId" [
  person_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/customers/persons/{person_id}"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing person.
#
# PUT /customers/persons/{personId}
# operationId: update_1
export def "customers-persons update-by-personId" [
  person_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/customers/persons/{person_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Returns contact of a given person.
#
# GET /customers/persons/{personId}/contact
# operationId: getContact
export def "customers-persons-contact get" [
  person_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/customers/persons/{person_id}/contact"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates contact of a given person.
#
# PUT /customers/persons/{personId}/contact
# operationId: updateContact
export def "customers-persons-contact update" [
  person_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/customers/persons/{person_id}/contact"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Returns custom fields of a given person.
#
# GET /customers/persons/{personId}/customFields
# operationId: getCustomFields
export def "customers-persons-custom-fields get" [
  person_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/customers/persons/{person_id}/customFields"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates custom fields of a given person.
#
# PUT /customers/persons/{personId}/customFields
# operationId: updateCustomFields
export def "customers-persons-custom-fields update" [
  person_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/customers/persons/{person_id}/customFields"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Removes a customer price list.
#
# DELETE /customers/priceLists/{priceListId}
# operationId: delete_4
export def "customers-price-lists delete-by-priceListId" [
  price_list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({price_list_id: (encode-path-segment $price_list_id)} | format pattern "/customers/priceLists/{price_list_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a client.
#
# DELETE /customers/{customerId}
# operationId: delete_5
export def "customers delete-by-customerId" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns client details.
#
# GET /customers/{customerId}
# operationId: getById_2
export def "customers get-by-customerId" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: string # list of additional fields which should be embedded in the response (available options: persons)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "embed" $embed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}") $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing client.
#
# PUT /customers/{customerId}
# operationId: update_2
# --accounting shape: {taxNumbers?: list}
# --billingAddress shape: {addressLine1?: string, addressLine2?: string, city?: string, countryId?: int, postalCode?: string, provinceId?: int, sameAsBillingAddress?: bool}
# --contact shape: {emails?: record, fax?: string, phones?: list<string>, sms?: string, websites?: list<string>}
# --correspondenceAddress shape: {addressLine1?: string, addressLine2?: string, city?: string, countryId?: int, postalCode?: string, provinceId?: int, sameAsBillingAddress?: bool}
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
# --persons item shape: {active?: bool, contact?: record, customFields?: list, customerId?: int, firstProjectDate?: string, firstQuoteDate?: string, gender?: "FEMALE"|"MALE", id?: int, lastName?: string, lastProjectDate?: string, lastQuoteDate?: string, motherTonguesIds?: list<int>, name?: string, numberOfProjects?: int, numberOfQuotes?: int, positionId?: int}
# --responsiblePersons shape: {accountManagerId?: int, projectCoordinatorId?: int, projectManagerId: int, salesPersonId: int}
export def "customers update-by-customerId" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-on-customer-server: string
  --accounting: record # shape: {taxNumbers?: list}
  --billing-address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, countryId?: int, postalCode?: string, provinceId?: int, sameAsBillingAddress?: bool}
  --branch-id: int # format: int64
  --categories-ids: list<int>
  --client-first-project-date: string # format: date-time
  --client-first-quote-date: string # format: date-time
  --client-last-project-date: string # format: date-time
  --client-last-quote-date: string # format: date-time
  --client-number-of-projects: int # format: int32
  --client-number-of-quotes: int # format: int32
  --contact: record # shape: {emails?: record, fax?: string, phones?: list<string>, sms?: string, websites?: list<string>}
  --contract-number: string
  --correspondence-address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, countryId?: int, postalCode?: string, provinceId?: int, sameAsBillingAddress?: bool}
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --full-name: string
  --id: int # format: int64
  --id-number: string
  --industries-ids: list<int>
  --lead-source-id: int # format: int64
  --limit-access-to-people-responsible: oneof<nothing, bool>
  --name: string
  --notes: string
  --persons: list # item shape: {active?: bool, contact?: record, customFields?: list, customerId?: int, firstProjectDate?: string, firstQuoteDate?: string, gender?: "FEMALE"|"MALE", id?: int, lastName?: string, lastProjectDate?: string, lastQuoteDate?: string, motherTonguesIds?: list<int>, name?: string, numberOfProjects?: int, numberOfQuotes?: int, positionId?: int}
  --responsible-persons: record # shape: {accountManagerId?: int, projectCoordinatorId?: int, projectManagerId: int, salesPersonId: int}
  --sales-notes: string
  --status: string@status-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}"))
  let req_body = {"accountOnCustomerServer": $account_on_customer_server, "accounting": $accounting, "billingAddress": $billing_address, "branchId": $branch_id, "categoriesIds": $categories_ids, "clientFirstProjectDate": $client_first_project_date, "clientFirstQuoteDate": $client_first_quote_date, "clientLastProjectDate": $client_last_project_date, "clientLastQuoteDate": $client_last_quote_date, "clientNumberOfProjects": $client_number_of_projects, "clientNumberOfQuotes": $client_number_of_quotes, "contact": $contact, "contractNumber": $contract_number, "correspondenceAddress": $correspondence_address, "customFields": $custom_fields, "fullName": $full_name, "id": $id, "idNumber": $id_number, "industriesIds": $industries_ids, "leadSourceId": $lead_source_id, "limitAccessToPeopleResponsible": $limit_access_to_people_responsible, "name": $name, "notes": $notes, "persons": $persons, "responsiblePersons": $responsible_persons, "salesNotes": $sales_notes, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns address of a given client.
#
# GET /customers/{customerId}/address
# operationId: getAddress
export def "customers-address get" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/address"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates address of a given client.
#
# PUT /customers/{customerId}/address
# operationId: updateAddress
export def "customers-address update" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-line1: string # first line of address
  --address-line2: string # second line of address
  --city: string # city
  --country-id: int # country (format: int64)
  --postal-code: string # postal code
  --province-id: int # province (format: int64)
  --same-as-billing-address: oneof<nothing, bool> # should billing address be used instead of this one
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/address"))
  let req_body = {"addressLine1": $address_line1, "addressLine2": $address_line2, "city": $city, "countryId": $country_id, "postalCode": $postal_code, "provinceId": $province_id, "sameAsBillingAddress": $same_as_billing_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns categories of a given client.
#
# GET /customers/{customerId}/categories
# operationId: getCategories
export def "customers-categories get" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/categories"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates categories of a given client.
#
# PUT /customers/{customerId}/categories
# operationId: updateCategories
export def "customers-categories update" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --empty: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/categories"))
  let req_body = {"empty": $empty} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns contact of a given client.
#
# GET /customers/{customerId}/contact
# operationId: getContact_1
export def "customers-contact get-by-customerId" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/contact"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates contact of a given client.
#
# PUT /customers/{customerId}/contact
# operationId: updateContact_1
# --emails shape: {additional?: list<string>, cc?: list<string>, primary: string}
export def "customers-contact update-by-customerId" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --emails: record # emails — shape: {additional?: list<string>, cc?: list<string>, primary: string}
  --fax: string # fax number
  --phones: list<string> # phones' numbers
  --sms: string # mobile phone for which SMS notifications will be sent (if configured)
  --websites: list<string> # websites
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/contact"))
  let req_body = {"emails": $emails, "fax": $fax, "phones": $phones, "sms": $sms, "websites": $websites} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns correspondence address of a given client.
#
# GET /customers/{customerId}/correspondenceAddress
# operationId: getCorrespondenceAddress
export def "customers-correspondence-address get" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/correspondenceAddress"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates correspondence address of a given client.
#
# PUT /customers/{customerId}/correspondenceAddress
# operationId: updateCorrespondenceAddress
export def "customers-correspondence-address update" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-line1: string # first line of address
  --address-line2: string # second line of address
  --city: string # city
  --country-id: int # country (format: int64)
  --postal-code: string # postal code
  --province-id: int # province (format: int64)
  --same-as-billing-address: oneof<nothing, bool> # should billing address be used instead of this one
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/correspondenceAddress"))
  let req_body = {"addressLine1": $address_line1, "addressLine2": $address_line2, "city": $city, "countryId": $country_id, "postalCode": $postal_code, "provinceId": $province_id, "sameAsBillingAddress": $same_as_billing_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns custom fields of a given client.
#
# GET /customers/{customerId}/customFields
# operationId: getCustomFields_1
export def "customers-custom-fields get-by-customerId" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/customFields"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates custom fields of a given client.
#
# PUT /customers/{customerId}/customFields
# operationId: updateCustomFields_1
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
export def "customers-custom-fields update-by-customerId" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/customFields"))
  let req_body = {"customFields": $custom_fields, "empty": $empty} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns custom field of a given client.
#
# GET /customers/{customerId}/customFields/{customFieldKey}
# operationId: getCustomField
export def "customers-custom-fields get" [
  customer_id: int
  custom_field_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), custom_field_key: (encode-path-segment $custom_field_key)} | format pattern "/customers/{customer_id}/customFields/{custom_field_key}"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates given custom field of a given client.
#
# PUT /customers/{customerId}/customFields/{customFieldKey}
# operationId: updateCustomField
export def "customers-custom-fields update" [
  customer_id: int
  custom_field_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --name: string
  --type: string@type-completer
  --value: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), custom_field_key: (encode-path-segment $custom_field_key)} | format pattern "/customers/{customer_id}/customFields/{custom_field_key}"))
  let req_body = {"key": $key, "name": $name, "type": $type, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns industries of a given client.
#
# GET /customers/{customerId}/industries
# operationId: getIndustries
export def "customers-industries get" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/industries"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates industries of a given client.
#
# PUT /customers/{customerId}/industries
# operationId: updateIndustries
export def "customers-industries update" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --empty: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/industries"))
  let req_body = {"empty": $empty} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns active dictionary entities for all types.
#
# GET /dictionaries/active
# operationId: getActive
export def "dictionaries-active list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dictionaries/active")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns dictionary entities for all types. Both active and not active ones.
#
# GET /dictionaries/all
# operationId: getAll_1
export def "dictionaries-all get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dictionaries/all")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns currency exchange rates.
#
# GET /dictionaries/currency/{isoCode}/exchangeRate
# operationId: getByIsoCode
export def "dictionaries-currency-exchange-rate get-by-iso-code" [
  iso_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({iso_code: (encode-path-segment $iso_code)} | format pattern "/dictionaries/currency/{iso_code}/exchangeRate"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adding currency exchange rates.
#
# POST /dictionaries/currency/{isoCode}/exchangeRate
# operationId: createExchangeRate
# --dateFrom shape: {value?: int}
# --lastModification shape: {value?: int}
# --publicationDate shape: {value?: int}
export def "dictionaries-currency-exchange-rate create" [
  iso_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: record # shape: {value?: int}
  --exchange-rate: string
  --last-modification: record # shape: {value?: int}
  --origin-details: string
  --publication-date: record # shape: {value?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({iso_code: (encode-path-segment $iso_code)} | format pattern "/dictionaries/currency/{iso_code}/exchangeRate"))
  let req_body = {"dateFrom": $date_from, "exchangeRate": $exchange_rate, "lastModification": $last_modification, "originDetails": $origin_details, "publicationDate": $publication_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns active values from a given dictionary.
#
# GET /dictionaries/{type}/active
# operationId: getActiveByType
export def "dictionaries-active get" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name-equals: string # exact name of entity
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nameEquals" $name_equals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type)} | format pattern "/dictionaries/{type}/active") $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all values (both active and not active) from a given dictionary.
#
# GET /dictionaries/{type}/all
# operationId: getAllByType
export def "dictionaries-all get" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name-equals: string # exact name of entity
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nameEquals" $name_equals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type)} | format pattern "/dictionaries/{type}/all") $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns specific value from a given dictionary.
#
# GET /dictionaries/{type}/{id}
# operationId: getByTypeAndId
export def "dictionaries get-by-and" [
  type: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/dictionaries/{type}/{id}"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Uploads a temporary file (ie. for XML import). Returns token which can be used in other API calls.
#
# POST /files
# operationId: uploadFile
export def "files upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files")
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body ["file"])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Returns job details by jobId.
#
# GET /jobs/{jobId}
# operationId: getJobDetails
export def "jobs get-details" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates dates of a given job.
#
# PUT /jobs/{jobId}/dates
# operationId: updateDates
export def "jobs-dates update" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actual-end-date: int # format: int64
  --actual-start-date: int # format: int64
  --deadline: int # format: int64
  --start-date: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}/dates"))
  let req_body = {"actualEndDate": $actual_end_date, "actualStartDate": $actual_start_date, "deadline": $deadline, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns list of input and output files of a job.
#
# GET /jobs/{jobId}/files
# operationId: getJobFiles
export def "jobs-files get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}/files"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /jobs/{jobId}/files/output
#
# operationId: assignFileToJobOutput
export def "jobs-files-output assign" [
  job_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}/files/output"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Returns file metadata.
#
# GET /jobs/{jobId}/files/{fileId}
# operationId: getJobFiles_1
export def "jobs-files get-by-jobId-fileId" [
  job_id: string
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id), file_id: (encode-path-segment $file_id)} | format pattern "/jobs/{job_id}/files/{file_id}"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates instructions for a job.
#
# PUT /jobs/{jobId}/instructions
# operationId: updateInstructions
export def "jobs-instructions update" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --for-provider: string
  --from-customer: string
  --internal: string
  --notes: string
  --payment-note-for-customer: string
  --payment-note-for-vendor: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}/instructions"))
  let req_body = {"forProvider": $for_provider, "fromCustomer": $from_customer, "internal": $internal, "notes": $notes, "paymentNoteForCustomer": $payment_note_for_customer, "paymentNoteForVendor": $payment_note_for_vendor} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Changes job status if possible (400 Bad Request is returned otherwise).
#
# PUT /jobs/{jobId}/status
# operationId: changeStatus
export def "jobs-status update-change" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-id: string
  --status: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}/status"))
  let req_body = {"externalId": $external_id, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Assigns vendor to a job in a project.
#
# PUT /jobs/{jobId}/vendor
# operationId: assignVendor
export def "jobs-vendor assign" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --recalculate-rates: oneof<nothing, bool>
  --vendor-price-profile-id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}/vendor"))
  let req_body = {"recalculateRates": $recalculate_rates, "vendorPriceProfileId": $vendor_price_profile_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns license content.
#
# GET /license
# operationId: getLicense
export def "license get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/license")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Refreshes license content.
#
# POST /license/refresh
# operationId: refresh
export def "license-refresh refresh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/license/refresh")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Executes a macro.
#
# POST /macros/{macroId}/run
# operationId: run
export def "macros-run create" [
  macro_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({macro_id: (encode-path-segment $macro_id)} | format pattern "/macros/{macro_id}/run"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Creates a new Classic Project.
#
# POST /projects
# operationId: create_5
export def "projects create-by-" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Downloads a file.
#
# GET /projects/files/{fileId}/download
# operationId: getFileById
export def "projects-files-download get" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/projects/files/{file_id}/download"))
  let accept_val = "multipart/form-data"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns projects' internal identifiers.
#
# GET /projects/ids
# operationId: getAllIds_6
export def "projects-ids get-list-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only projects modified since this timestamp (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects/ids" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a project.
#
# DELETE /projects/{projectId}
# operationId: delete_12
export def "projects delete-by-projectId" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns project details.
#
# GET /projects/{projectId}
# operationId: getById_7
export def "projects get-by-projectId-by-projectId" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: string # list of additional fields which should be embedded in the response (available options: tasks)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "embed" $embed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}") $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns contacts of a given project.
#
# GET /projects/{projectId}/contacts
# operationId: getContacts
export def "projects-contacts get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/contacts"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates contacts of a given project.
#
# PUT /projects/{projectId}/contacts
# operationId: updateContacts
export def "projects-contacts update" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-ids: list<int>
  --primary-id: int # format: int64
  --send-back-to-id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/contacts"))
  let req_body = {"additionalIds": $additional_ids, "primaryId": $primary_id, "sendBackToId": $send_back_to_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns custom fields of a given project.
#
# GET /projects/{projectId}/customFields
# operationId: getCustomFields_5
export def "projects-custom-fields get-by-projectId-by-projectId" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/customFields"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates custom fields of a given project.
#
# PUT /projects/{projectId}/customFields
# operationId: updateCustomFields_3
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
export def "projects-custom-fields update-by-projectId" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/customFields"))
  let req_body = {"customFields": $custom_fields, "empty": $empty} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns dates of a given project.
#
# GET /projects/{projectId}/dates
# operationId: getDates_1
export def "projects-dates get-by-projectId" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/dates"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates dates of a given project.
#
# PUT /projects/{projectId}/dates
# operationId: updateDates_1
# --actualDeliveryDate shape: {value?: int}
# --actualStartDate shape: {value?: int}
# --deadline shape: {value?: int}
# --startDate shape: {value?: int}
export def "projects-dates update-by-projectId" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actual-delivery-date: record # shape: {value?: int}
  --actual-start-date: record # shape: {value?: int}
  --deadline: record # shape: {value?: int}
  --start-date: record # shape: {value?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/dates"))
  let req_body = {"actualDeliveryDate": $actual_delivery_date, "actualStartDate": $actual_start_date, "deadline": $deadline, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns finance of a given project.
#
# GET /projects/{projectId}/finance
# operationId: getFinance
export def "projects-finance get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/finance"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a payable to a project.
#
# POST /projects/{projectId}/finance/payables
# operationId: createPayable
# --catLogFile shape: {content?: string, name?: string, token?: string, url?: string}
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "projects-finance-payables create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --cat-log-file: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-id: record
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --total: float
  --type: string@type-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/finance/payables"))
  let req_body = {"calculationUnitId": $calculation_unit_id, "catLogFile": $cat_log_file, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobId": $job_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a payable.
#
# DELETE /projects/{projectId}/finance/payables/{payableId}
# operationId: deletePayable
export def "projects-finance-payables delete" [
  project_id: string
  payable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), payable_id: (encode-path-segment $payable_id)} | format pattern "/projects/{project_id}/finance/payables/{payable_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a payable.
#
# PUT /projects/{projectId}/finance/payables/{payableId}
# operationId: updatePayable
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "projects-finance-payables update" [
  project_id: string
  payable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-id: record
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --total: float
  --type: string@type-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), payable_id: (encode-path-segment $payable_id)} | format pattern "/projects/{project_id}/finance/payables/{payable_id}"))
  let req_body = {"calculationUnitId": $calculation_unit_id, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobId": $job_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Adds a receivable to a project.
#
# POST /projects/{projectId}/finance/receivables
# operationId: createReceivable
# --catLogFile shape: {content?: string, name?: string, token?: string, url?: string}
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "projects-finance-receivables create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --cat-log-file: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --task-id: int # format: int64
  --total: float
  --type: string@type-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/finance/receivables"))
  let req_body = {"calculationUnitId": $calculation_unit_id, "catLogFile": $cat_log_file, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "taskId": $task_id, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a receivable.
#
# DELETE /projects/{projectId}/finance/receivables/{receivableId}
# operationId: deleteReceivable
export def "projects-finance-receivables delete" [
  project_id: string
  receivable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), receivable_id: (encode-path-segment $receivable_id)} | format pattern "/projects/{project_id}/finance/receivables/{receivable_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a receivable.
#
# PUT /projects/{projectId}/finance/receivables/{receivableId}
# operationId: updateReceivable
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "projects-finance-receivables update" [
  project_id: string
  receivable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --task-id: int # format: int64
  --total: float
  --type: string@type-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), receivable_id: (encode-path-segment $receivable_id)} | format pattern "/projects/{project_id}/finance/receivables/{receivable_id}"))
  let req_body = {"calculationUnitId": $calculation_unit_id, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "taskId": $task_id, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns instructions of a given project.
#
# GET /projects/{projectId}/instructions
# operationId: getInstructions
export def "projects-instructions get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/instructions"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates instructions of a given project.
#
# PUT /projects/{projectId}/instructions
# operationId: updateInstructions_1
export def "projects-instructions update-by-projectId" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --for-provider: string
  --from-customer: string
  --internal: string
  --notes: string
  --payment-note-for-customer: string
  --payment-note-for-vendor: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/instructions"))
  let req_body = {"forProvider": $for_provider, "fromCustomer": $from_customer, "internal": $internal, "notes": $notes, "paymentNoteForCustomer": $payment_note_for_customer, "paymentNoteForVendor": $payment_note_for_vendor} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new language combination for a given project without creating a task.
#
# POST /projects/{projectId}/languageCombinations
# operationId: createLanguageCombination
export def "projects-language-combinations create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-language-id: int # format: int64
  --target-language-id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/languageCombinations"))
  let req_body = {"sourceLanguageId": $source_language_id, "targetLanguageId": $target_language_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new task for a given project.
#
# POST /projects/{projectId}/tasks
# operationId: createTask
# --dates shape: {actualDeliveryDate?: record, actualStartDate?: record, deadline?: record, startDate?: record}
# --files item shape: {category?: "WORKFILE"|"TM"|"DICTIONARY"|"REF"|"LOG_FILE", content?: string, name?: string, token?: string, url?: string}
# --instructions shape: {forProvider?: string, fromCustomer?: string, internal?: string, notes?: string, paymentNoteForCustomer?: string, paymentNoteForVendor?: string}
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
# --people shape: {customerContacts?: record, responsiblePersons?: record}
export def "projects-tasks create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-task-po-number: string # client task PO number
  --dates: record # shape: {actualDeliveryDate?: record, actualStartDate?: record, deadline?: record, startDate?: record}
  --files: list # files — item shape: {category?: "WORKFILE"|"TM"|"DICTIONARY"|"REF"|"LOG_FILE", content?: string, name?: string, token?: string, url?: string}
  --instructions: record # shape: {forProvider?: string, fromCustomer?: string, internal?: string, notes?: string, paymentNoteForCustomer?: string, paymentNoteForVendor?: string}
  --language-combination: record # language combination (ie. PL -> EN) — shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --name: string # name
  --people: record # people — shape: {customerContacts?: record, responsiblePersons?: record}
  --specialization-id: int # specialization (format: int64)
  --workflow-id: int # workflow (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/tasks"))
  let req_body = {"clientTaskPONumber": $client_task_po_number, "dates": $dates, "files": $files, "instructions": $instructions, "languageCombination": $language_combination, "name": $name, "people": $people, "specializationId": $specialization_id, "workflowId": $workflow_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns providers' internal identifiers.
#
# GET /providers/ids
# operationId: getAllIds_5
export def "providers-ids get-list-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only providers modified since this timestamp (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/ids" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns persons' internal identifiers.
#
# GET /providers/persons/ids
# operationId: getAllIds_4
export def "providers-persons-ids get-list-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only persons modified since this timestamp (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/persons/ids" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a person.
#
# DELETE /providers/persons/{personId}
# operationId: delete_8
export def "providers-persons delete-by-personId" [
  person_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/providers/persons/{person_id}"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns person details.
#
# GET /providers/persons/{personId}
# operationId: getById_4
export def "providers-persons get-by-personId" [
  person_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/providers/persons/{person_id}"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns contact of a given person.
#
# GET /providers/persons/{personId}/contact
# operationId: getContact_2
export def "providers-persons-contact get-by-personId" [
  person_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/providers/persons/{person_id}/contact"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns custom fields of a given person.
#
# GET /providers/persons/{personId}/customFields
# operationId: getCustomFields_2
export def "providers-persons-custom-fields get-by-personId" [
  person_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/providers/persons/{person_id}/customFields"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sends invitation to Vendor Portal.
#
# POST /providers/persons/{personId}/notification/invitation
# operationId: sendInvitations
export def "providers-persons-notification-invitation send" [
  person_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/providers/persons/{person_id}/notification/invitation"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a provider price list.
#
# DELETE /providers/priceLists/{priceListId}
# operationId: delete_9
export def "providers-price-lists delete-by-priceListId" [
  price_list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({price_list_id: (encode-path-segment $price_list_id)} | format pattern "/providers/priceLists/{price_list_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a provider.
#
# DELETE /providers/{providerId}
# operationId: delete_10
export def "providers delete-by-providerId" [
  provider_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({provider_id: (encode-path-segment $provider_id)} | format pattern "/providers/{provider_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns provider details.
#
# GET /providers/{providerId}
# operationId: getById_5
export def "providers get-by-providerId" [
  provider_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: string # list of adittional fields which should be embedded in the response (ie. persons)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "embed" $embed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({provider_id: (encode-path-segment $provider_id)} | format pattern "/providers/{provider_id}") $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns address of a given provider.
#
# GET /providers/{providerId}/address
# operationId: getAddress_1
export def "providers-address get-by-providerId" [
  provider_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({provider_id: (encode-path-segment $provider_id)} | format pattern "/providers/{provider_id}/address"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns competencies of a given provider.
#
# GET /providers/{providerId}/competencies
# operationId: getCompetencies
export def "providers-competencies get" [
  provider_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({provider_id: (encode-path-segment $provider_id)} | format pattern "/providers/{provider_id}/competencies"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns contact of a given provider.
#
# GET /providers/{providerId}/contact
# operationId: getContact_3
export def "providers-contact get-by-providerId" [
  provider_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({provider_id: (encode-path-segment $provider_id)} | format pattern "/providers/{provider_id}/contact"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns correspondence address of a given provider.
#
# GET /providers/{providerId}/correspondenceAddress
# operationId: getCorrespondenceAddress_1
export def "providers-correspondence-address get-by-providerId" [
  provider_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({provider_id: (encode-path-segment $provider_id)} | format pattern "/providers/{provider_id}/correspondenceAddress"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns custom fields of a given provider.
#
# GET /providers/{providerId}/customFields
# operationId: getCustomFields_3
export def "providers-custom-fields get-by-providerId" [
  provider_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({provider_id: (encode-path-segment $provider_id)} | format pattern "/providers/{provider_id}/customFields"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sends invitations to Vendor Portal.
#
# POST /providers/{providerId}/notification/invitation
# operationId: sendInvitations_1
export def "providers-notification-invitation send-by-providerId" [
  provider_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({provider_id: (encode-path-segment $provider_id)} | format pattern "/providers/{provider_id}/notification/invitation"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns quotes' internal identifiers.
#
# GET /quotes/ids
# operationId: getAllIds_7
export def "quotes-ids get-list-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only quotes modified since this timestamp (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quotes/ids" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a quote.
#
# DELETE /quotes/{quoteId}
# operationId: delete_13
export def "quotes delete-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns quote details.
#
# GET /quotes/{quoteId}
# operationId: getById_8
export def "quotes get-by-quoteId-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: string # list of adittional fields which should be embedded in the response (ie. tasks)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "embed" $embed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}") $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sends a quote for customer confirmation.
#
# POST /quotes/{quoteId}/confirmation/send
# operationId: send_1
export def "quotes-confirmation-send send-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/confirmation/send"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns custom fields of a given quote.
#
# GET /quotes/{quoteId}/customFields
# operationId: getCustomFields_6
export def "quotes-custom-fields get-by-quoteId-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/customFields"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates custom fields of a given quote.
#
# PUT /quotes/{quoteId}/customFields
# operationId: updateCustomFields_4
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
export def "quotes-custom-fields update-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/customFields"))
  let req_body = {"customFields": $custom_fields, "empty": $empty} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns dates of a given quote.
#
# GET /quotes/{quoteId}/dates
# operationId: getDates_2
export def "quotes-dates get-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/dates"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns finance of a given quote.
#
# GET /quotes/{quoteId}/finance
# operationId: getFinance_1
export def "quotes-finance get-by-quoteId-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/finance"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a payable.
#
# POST /quotes/{quoteId}/finance/payables
# operationId: createPayable_1
# --catLogFile shape: {content?: string, name?: string, token?: string, url?: string}
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-payables create-by-quoteId-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --cat-log-file: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-id: record
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --total: float
  --type: string@type-completer-1
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/finance/payables"))
  let req_body = {"calculationUnitId": $calculation_unit_id, "catLogFile": $cat_log_file, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobId": $job_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a payable.
#
# DELETE /quotes/{quoteId}/finance/payables/{payableId}
# operationId: deletePayable_1
export def "quotes-finance-payables delete-by-quoteId-payableId-by-quoteId-payableId" [
  quote_id: string
  payable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), payable_id: (encode-path-segment $payable_id)} | format pattern "/quotes/{quote_id}/finance/payables/{payable_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a payable.
#
# PUT /quotes/{quoteId}/finance/payables/{payableId}
# operationId: updatePayable_1
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-payables update-by-quoteId-payableId-by-quoteId-payableId" [
  quote_id: string
  payable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-id: record
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --total: float
  --type: string@type-completer-1
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), payable_id: (encode-path-segment $payable_id)} | format pattern "/quotes/{quote_id}/finance/payables/{payable_id}"))
  let req_body = {"calculationUnitId": $calculation_unit_id, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobId": $job_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Adds a receivable.
#
# POST /quotes/{quoteId}/finance/receivables
# operationId: createReceivable_1
# --catLogFile shape: {content?: string, name?: string, token?: string, url?: string}
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-receivables create-by-quoteId-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --cat-log-file: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --task-id: int # format: int64
  --total: float
  --type: string@type-completer-1
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/finance/receivables"))
  let req_body = {"calculationUnitId": $calculation_unit_id, "catLogFile": $cat_log_file, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "taskId": $task_id, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a receivable.
#
# DELETE /quotes/{quoteId}/finance/receivables/{receivableId}
# operationId: deleteReceivable_1
export def "quotes-finance-receivables delete-by-quoteId-receivableId-by-quoteId-receivableId" [
  quote_id: string
  receivable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), receivable_id: (encode-path-segment $receivable_id)} | format pattern "/quotes/{quote_id}/finance/receivables/{receivable_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a receivable.
#
# PUT /quotes/{quoteId}/finance/receivables/{receivableId}
# operationId: updateReceivable_1
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-receivables update-by-quoteId-receivableId-by-quoteId-receivableId" [
  quote_id: string
  receivable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --task-id: int # format: int64
  --total: float
  --type: string@type-completer-1
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), receivable_id: (encode-path-segment $receivable_id)} | format pattern "/quotes/{quote_id}/finance/receivables/{receivable_id}"))
  let req_body = {"calculationUnitId": $calculation_unit_id, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "taskId": $task_id, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns instructions of a given quote.
#
# GET /quotes/{quoteId}/instructions
# operationId: getInstructions_1
export def "quotes-instructions get-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/instructions"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates instructions of a given quote.
#
# PUT /quotes/{quoteId}/instructions
# operationId: updateInstructions_2
export def "quotes-instructions update-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --for-provider: string
  --from-customer: string
  --internal: string
  --notes: string
  --payment-note-for-customer: string
  --payment-note-for-vendor: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/instructions"))
  let req_body = {"forProvider": $for_provider, "fromCustomer": $from_customer, "internal": $internal, "notes": $notes, "paymentNoteForCustomer": $payment_note_for_customer, "paymentNoteForVendor": $payment_note_for_vendor} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new language combination for a given quote without creating a task.
#
# POST /quotes/{quoteId}/languageCombinations
# operationId: createLanguageCombination_1
export def "quotes-language-combinations create-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-language-id: int # format: int64
  --target-language-id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/languageCombinations"))
  let req_body = {"sourceLanguageId": $source_language_id, "targetLanguageId": $target_language_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Starts a quote.
#
# POST /quotes/{quoteId}/start
# operationId: start
export def "quotes-start start" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/start"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new task for a given quote.
#
# POST /quotes/{quoteId}/tasks
# operationId: createTask_1
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
# --dates shape: {actualDeliveryDate?: record, actualStartDate?: record, deadline?: record, startDate?: record}
# --finance shape: {invoiceable?: bool}
# --instructions shape: {forProvider?: string, fromCustomer?: string, internal?: string, notes?: string, paymentNoteForCustomer?: string, paymentNoteForVendor?: string}
# --jobs shape: {jobCount?: int, jobIds?: list<int>}
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
# --people shape: {customerContacts?: record, responsiblePersons?: record}
export def "quotes-tasks create-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-task-po-number: string # client task PO number
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --dates: record # shape: {actualDeliveryDate?: record, actualStartDate?: record, deadline?: record, startDate?: record}
  --finance: record # finance — shape: {invoiceable?: bool}
  --id: int # internal identifier (format: int64)
  --id-number: string # identifier
  --instructions: record # shape: {forProvider?: string, fromCustomer?: string, internal?: string, notes?: string, paymentNoteForCustomer?: string, paymentNoteForVendor?: string}
  --jobs: record # shape: {jobCount?: int, jobIds?: list<int>}
  --language-combination: record # language combination (ie. PL -> EN) — shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --name: string # name
  --people: record # people — shape: {customerContacts?: record, responsiblePersons?: record}
  --project-id: int # project's internal identifier (format: int64)
  --body-quote-id: int # quote's internal identifier (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/tasks"))
  let req_body = {"clientTaskPONumber": $client_task_po_number, "customFields": $custom_fields, "dates": $dates, "finance": $finance, "id": $id, "idNumber": $id_number, "instructions": $instructions, "jobs": $jobs, "languageCombination": $language_combination, "name": $name, "people": $people, "projectId": $project_id, "quoteId": $body_quote_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Exports reports definition to XML.
#
# POST /reports/export/xml
# operationId: exportToXML
export def "reports-export-xml export" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/export/xml")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Imports reports definition from XML.
#
# POST /reports/import/xml
# operationId: importFromXML
export def "reports-import-xml import" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/import/xml")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Removes a report.
#
# DELETE /reports/{reportId}
# operationId: delete_11
export def "reports delete-by-reportId" [
  report_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id)} | format pattern "/reports/{report_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Duplicates a report.
#
# POST /reports/{reportId}/duplicate
# operationId: duplicate_1
export def "reports-duplicate create-by-reportId" [
  report_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id)} | format pattern "/reports/{report_id}/duplicate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Marks report as preferred or not.
#
# PUT /reports/{reportId}/preferred
# operationId: setPreferred
export def "reports-preferred update" [
  report_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id)} | format pattern "/reports/{report_id}/preferred"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Generates CSV content for a report.
#
# GET /reports/{reportId}/result/csv
# operationId: generateCSV
export def "reports-result-csv generate" [
  report_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id)} | format pattern "/reports/{report_id}/result/csv"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generates printer friendly content for a report.
#
# GET /reports/{reportId}/result/printerFriendly
# operationId: generatePrinterFriendly
export def "reports-result-printer-friendly generate" [
  report_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id)} | format pattern "/reports/{report_id}/result/printerFriendly"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns active services list
#
# GET /services/active
# operationId: getAllActive
export def "services-active get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name-equals: string # exact name of entity
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nameEquals" $name_equals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/services/active" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns services list
#
# GET /services/all
# operationId: getAll_3
export def "services-all get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name-equals: string # exact name of entity
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nameEquals" $name_equals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/services/all" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all subscriptions
#
# GET /subscription
# operationId: getAll_4
export def "subscription get-list-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscription")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe to event
#
# POST /subscription
# operationId: subscribe
export def "subscription subscribe" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscription")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# This method can be used to determine if hooks are supported.
#
# GET /subscription/supports
# operationId: areHooksSupported
export def "subscription-supports get-are-hooks-supported" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscription/supports")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unsubscribe from event
#
# DELETE /subscription/{subscriptionId}
# operationId: unsubscribe
export def "subscription unsubscribe" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscription/{subscription_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a task.
#
# DELETE /tasks/{taskId}
# operationId: delete_14
export def "tasks delete-by-taskId" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --remove-files-from-disc: oneof<nothing, bool> # remove files from disc
  --remove-external-projects: oneof<nothing, bool> # remove external projects (ie. from CAT Tool)
  --force-jobs-removal: oneof<nothing, bool> # force jobs removal (ie. started or ready)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "removeFilesFromDisc" $remove_files_from_disc "scalar") (serialize-qp "removeExternalProjects" $remove_external_projects "scalar") (serialize-qp "forceJobsRemoval" $force_jobs_removal "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates Client Task PO Number of a given task.
#
# PUT /tasks/{taskId}/clientTaskPONumber
# operationId: updateClientTaskPONumber
export def "tasks-client-task-po-number update" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/clientTaskPONumber"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns contacts of a given task.
#
# GET /tasks/{taskId}/contacts
# operationId: getContacts_1
export def "tasks-contacts get-by-taskId" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/contacts"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates contacts of a given task.
#
# PUT /tasks/{taskId}/contacts
# operationId: updateContacts_1
export def "tasks-contacts update-by-taskId" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-ids: list<int>
  --primary-id: int # format: int64
  --send-back-to-id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/contacts"))
  let req_body = {"additionalIds": $additional_ids, "primaryId": $primary_id, "sendBackToId": $send_back_to_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns custom fields of a given task.
#
# GET /tasks/{taskId}/customFields
# operationId: getCustomFields_7
export def "tasks-custom-fields get-by-taskId" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/customFields"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates custom fields of a given task.
#
# PUT /tasks/{taskId}/customFields
# operationId: updateCustomFields_5
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
export def "tasks-custom-fields update-by-taskId" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/customFields"))
  let req_body = {"customFields": $custom_fields, "empty": $empty} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns dates of a given task.
#
# GET /tasks/{taskId}/dates
# operationId: getDates_3
export def "tasks-dates get-by-taskId" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/dates"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates dates of a given task.
#
# PUT /tasks/{taskId}/dates
# operationId: updateDates_2
# --actualDeliveryDate shape: {value?: int}
# --actualStartDate shape: {value?: int}
# --deadline shape: {value?: int}
# --startDate shape: {value?: int}
export def "tasks-dates update-by-taskId" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actual-delivery-date: record # shape: {value?: int}
  --actual-start-date: record # shape: {value?: int}
  --deadline: record # shape: {value?: int}
  --start-date: record # shape: {value?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/dates"))
  let req_body = {"actualDeliveryDate": $actual_delivery_date, "actualStartDate": $actual_start_date, "deadline": $deadline, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns lists of files of a given task.
#
# GET /tasks/{taskId}/files
# operationId: getTaskFiles
export def "tasks-files get" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/files"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds files to a given task.
#
# POST /tasks/{taskId}/files/input
# operationId: addFile
export def "tasks-files-input create" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string
  --name: string
  --body-token: string
  --url: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/files/input"))
  let req_body = {"content": $content, "name": $name, "token": $body_token, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns instructions of a given task.
#
# GET /tasks/{taskId}/instructions
# operationId: getInstructions_2
export def "tasks-instructions get-by-taskId" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/instructions"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates instructions of a given task.
#
# PUT /tasks/{taskId}/instructions
# operationId: updateInstructions_3
export def "tasks-instructions update-by-taskId" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --for-provider: string
  --from-customer: string
  --internal: string
  --notes: string
  --payment-note-for-customer: string
  --payment-note-for-vendor: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/instructions"))
  let req_body = {"forProvider": $for_provider, "fromCustomer": $from_customer, "internal": $internal, "notes": $notes, "paymentNoteForCustomer": $payment_note_for_customer, "paymentNoteForVendor": $payment_note_for_vendor} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates name of a given task.
#
# PUT /tasks/{taskId}/name
# operationId: updateName
export def "tasks-name update" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/name"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns progress of a given task.
#
# GET /tasks/{taskId}/progress
# operationId: getProgress
export def "tasks-progress get" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/progress"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Starts a task.
#
# POST /tasks/{taskId}/start
# operationId: start_1
export def "tasks-start start-by-taskId" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/start"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of simple users representations
#
# GET /users
# operationId: getAllNamesWithIds_1
export def "users get-list-names-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns currently signed in user details.
#
# GET /users/me
# operationId: getMe
export def "users-me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns time zone preferred by user currently signed in.
#
# GET /users/me/timeZone
# operationId: getTimeZone
export def "users-me-time-zone get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/timeZone")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns user details.
#
# GET /users/{userId}
# operationId: getById_6
export def "users get-by-userId" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing user.
#
# PUT /users/{userId}
# operationId: update_3
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
export def "users update-by-userId" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --email: string
  --first-name: string
  --gender: string
  --id: int # format: int64
  --last-name: string
  --login: string
  --mobile-phone: string
  --phone: string
  --position-name: string
  --time-zone-id: string
  --user-group-name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}"))
  let req_body = {"customFields": $custom_fields, "email": $email, "firstName": $first_name, "gender": $gender, "id": $id, "lastName": $last_name, "login": $login, "mobilePhone": $mobile_phone, "phone": $phone, "positionName": $position_name, "timeZoneId": $time_zone_id, "userGroupName": $user_group_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns custom fields of a given user.
#
# GET /users/{userId}/customFields
# operationId: getCustomFields_4
export def "users-custom-fields get-by-userId" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/customFields"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates custom fields of a given user.
#
# PUT /users/{userId}/customFields
# operationId: updateCustomFields_2
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
export def "users-custom-fields update-by-userId" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/customFields"))
  let req_body = {"customFields": $custom_fields, "empty": $empty} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns custom field of a given user.
#
# GET /users/{userId}/customFields/{customFieldKey}
# operationId: getCustomField_1
export def "users-custom-fields get-by-userId-customFieldKey" [
  user_id: int
  custom_field_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), custom_field_key: (encode-path-segment $custom_field_key)} | format pattern "/users/{user_id}/customFields/{custom_field_key}"))
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates given custom field of a given user.
#
# PUT /users/{userId}/customFields/{customFieldKey}
# operationId: updateCustomField_1
export def "users-custom-fields update-by-userId-customFieldKey" [
  user_id: int
  custom_field_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --name: string
  --type: string@type-completer
  --value: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), custom_field_key: (encode-path-segment $custom_field_key)} | format pattern "/users/{user_id}/customFields/{custom_field_key}"))
  let req_body = {"key": $key, "name": $name, "type": $type, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Sets user's password to a new value.
#
# PUT /users/{userId}/password
# operationId: changePassword
export def "users-password update-change" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-password: string # new password
  --old-password: string # old password
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/password"))
  let req_body = {"newPassword": $new_password, "oldPassword": $old_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# GET /v2/jobs/for-external-id
#
# operationId: getByExternalId
export def "jobs-for-external-id get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-project-id: string # job's externalProjectId
  --external-id: string # job's external identifier
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalProjectId" $external_project_id "scalar") (serialize-qp "externalId" $external_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/jobs/for-external-id" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns details for a job.
#
# GET /v2/jobs/{jobId}
# operationId: getFileById_1
export def "jobs get-file-by-jobId" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates dates of a given job.
#
# PUT /v2/jobs/{jobId}/dates
# operationId: changeDates
export def "jobs-dates update-change" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actual-end-date: int # format: int64
  --actual-start-date: int # format: int64
  --deadline: int # format: int64
  --start-date: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/dates"))
  let req_body = {"actualEndDate": $actual_end_date, "actualStartDate": $actual_start_date, "deadline": $deadline, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /v2/jobs/{jobId}/files/addExternalLink
#
# operationId: addExternalFileLink
# --languageCombinationIds item shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "jobs-files-add-external-link create" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string
  --external-info: record
  --filename: string
  --language-combination-ids: list # item shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-ids: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/files/addExternalLink"))
  let req_body = {"category": $category, "externalInfo": $external_info, "filename": $filename, "languageCombinationIds": $language_combination_ids, "languageIds": $language_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns list of files delivered in the job.
#
# GET /v2/jobs/{jobId}/files/delivered
# operationId: getDeliveredFiles
export def "jobs-files-delivered get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/files/delivered"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds files to the project as delivered in the job.
#
# PUT /v2/jobs/{jobId}/files/delivered/add
# operationId: addFiles
# --files item shape: {category?: string, fileId?: string, languageCombinationIds?: list, languageIds?: list<int>}
export def "jobs-files-delivered-add create" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --files: list # item shape: {category?: string, fileId?: string, languageCombinationIds?: list, languageIds?: list<int>}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/files/delivered/add"))
  let req_body = {"files": $files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Adds file link to the project as a link delivered in the job.
#
# POST /v2/jobs/{jobId}/files/delivered/addLink
# operationId: addFileLinks
# --fileLinks item shape: {category?: string, externalInfo?: record, filename?: string, languageCombinationIds?: list, languageIds?: list<int>, toBeGenerated?: bool, url?: string}
export def "jobs-files-delivered-add-link create" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-links: list # item shape: {category?: string, externalInfo?: record, filename?: string, languageCombinationIds?: list, languageIds?: list<int>, toBeGenerated?: bool, url?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/files/delivered/addLink"))
  let req_body = {"fileLinks": $file_links} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Uploads file to the project as a file delivered in the job.
#
# POST /v2/jobs/{jobId}/files/delivered/upload
# operationId: uploadFile_1
export def "jobs-files-delivered-upload upload-by-jobId" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/files/delivered/upload"))
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body ["file"])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Returns list of files shared with the job as Reference Files.
#
# GET /v2/jobs/{jobId}/files/sharedReferenceFiles
# operationId: getSharedReferenceFiles
export def "jobs-files-shared-reference-files get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/files/sharedReferenceFiles"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Shares selected files as Reference Files with a job in a project.
#
# PUT /v2/jobs/{jobId}/files/sharedReferenceFiles/share
# operationId: shareAsReferenceFiles
export def "jobs-files-shared-reference-files-share update" [
  job_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/files/sharedReferenceFiles/share"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Returns list of files shared with the job as Work Files.
#
# GET /v2/jobs/{jobId}/files/sharedWorkFiles
# operationId: getSharedWorkFiles
export def "jobs-files-shared-work-files get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/files/sharedWorkFiles"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Shares selected files as Work Files with a job in a project.
#
# PUT /v2/jobs/{jobId}/files/sharedWorkFiles/share
# operationId: shareAsWorkFiles
export def "jobs-files-shared-work-files-share update" [
  job_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/files/sharedWorkFiles/share"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Stops sharing selected files with a job in a project.
#
# PUT /v2/jobs/{jobId}/files/stopSharing
# operationId: stopSharing
export def "jobs-files-stop-sharing stop" [
  job_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/files/stopSharing"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Updates instructions for a job.
#
# PUT /v2/jobs/{jobId}/instructions
# operationId: updateInstructions_4
export def "jobs-instructions update-by-jobId" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/instructions"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Changes job status if possible (400 Bad Request is returned otherwise).
#
# PUT /v2/jobs/{jobId}/status
# operationId: changeStatus_1
export def "jobs-status update-change-by-jobId" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-id: string
  --status: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/status"))
  let req_body = {"externalId": $external_id, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Assigns vendor to a job in a project.
#
# PUT /v2/jobs/{jobId}/vendor
# operationId: assignVendor_1
export def "jobs-vendor assign-by-jobId" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --vendor-price-profile-id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/vendor"))
  let req_body = {"vendorPriceProfileId": $vendor_price_profile_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new Smart Project.
#
# POST /v2/projects
# operationId: create_6
export def "projects create-by--1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: int # format: int64
  --external-id: string
  --name: string
  --service-id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects")
  let req_body = {"clientId": $client_id, "externalId": $external_id, "name": $name, "serviceId": $service_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Prepares a ZIP archive that contains the specified files.
#
# POST /v2/projects/files/archive
# operationId: archive
export def "projects-files-archive archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --files: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/files/archive")
  let req_body = {"files": $files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns details of a file.
#
# GET /v2/projects/files/{fileId}
# operationId: getFileById_2
export def "projects-files get-by-fileId" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/v2/projects/files/{file_id}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Downloads a file content.
#
# GET /v2/projects/files/{fileId}/download/{fileName}
# operationId: getFileContentById
export def "projects-files-download get-content" [
  file_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id), file_name: (encode-path-segment $file_name)} | format pattern "/v2/projects/files/{file_id}/download/{file_name}"))
  let accept_val = "multipart/form-data"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns project details.
#
# GET /v2/projects/for-external-id/{externalProjectId}
# operationId: getByExternalId_1
export def "projects-for-external-id get-by-externalProjectId" [
  external_project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({external_project_id: (encode-path-segment $external_project_id)} | format pattern "/v2/projects/for-external-id/{external_project_id}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns project details.
#
# GET /v2/projects/{projectId}
# operationId: getById_9
export def "projects get-by-projectId-by-projectId-1" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns process id.
#
# POST /v2/projects/{projectId}/addJob
# operationId: addJobToProcess
export def "projects-add-job create-to-process" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/addJob"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns if cat tool project is created or queued.
#
# GET /v2/projects/{projectId}/catToolProject
# operationId: getCATToolProjectInfo
export def "projects-cat-tool-project get-get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/catToolProject"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns Client Contacts information for a project.
#
# GET /v2/projects/{projectId}/clientContacts
# operationId: getContacts_2
export def "projects-client-contacts get-by-projectId" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/clientContacts"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates Client Contacts for a project.
#
# PUT /v2/projects/{projectId}/clientContacts
# operationId: updateContacts_2
export def "projects-client-contacts update-by-projectId" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-ids: list<int>
  --primary-id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/clientContacts"))
  let req_body = {"additionalIds": $additional_ids, "primaryId": $primary_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates Client Deadline for a project.
#
# PUT /v2/projects/{projectId}/clientDeadline
# operationId: updateClientDeadline
export def "projects-client-deadline update" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/clientDeadline"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates Client Notes for a project.
#
# PUT /v2/projects/{projectId}/clientNotes
# operationId: updateClientNotes
export def "projects-client-notes update" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/clientNotes"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates Client Reference Number for a project.
#
# PUT /v2/projects/{projectId}/clientReferenceNumber
# operationId: updateClientReferenceNumber
export def "projects-client-reference-number update" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/clientReferenceNumber"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a list of custom field keys and values for a project.
#
# GET /v2/projects/{projectId}/customFields
# operationId: getCustomFields_8
export def "projects-custom-fields get-by-projectId-by-projectId-1" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/customFields"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a custom field with a specified key in a project
#
# PUT /v2/projects/{projectId}/customFields/{key}
# operationId: updateCustomField_2
export def "projects-custom-fields update-by-projectId-key" [
  project_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), key: (encode-path-segment $key)} | format pattern "/v2/projects/{project_id}/customFields/{key}"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns list of files in a project.
#
# GET /v2/projects/{projectId}/files
# operationId: getFiles
export def "projects-files get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/files"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds files to the project as added by PM.
#
# PUT /v2/projects/{projectId}/files/add
# operationId: addFiles_1
# --files item shape: {category?: string, fileId?: string, languageCombinationIds?: list, languageIds?: list<int>}
export def "projects-files-add create-by-projectId" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --files: list # item shape: {category?: string, fileId?: string, languageCombinationIds?: list, languageIds?: list<int>}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/files/add"))
  let req_body = {"files": $files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /v2/projects/{projectId}/files/addExternalLink
#
# operationId: addExternalFileLinks
# --languageCombinationIds item shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "projects-files-add-external-link create" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string
  --external-info: record
  --filename: string
  --language-combination-ids: list # item shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-ids: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/files/addExternalLink"))
  let req_body = {"category": $category, "externalInfo": $external_info, "filename": $filename, "languageCombinationIds": $language_combination_ids, "languageIds": $language_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Adds file links to the project as added by PM.
#
# POST /v2/projects/{projectId}/files/addLink
# operationId: addFileLinks_1
# --fileLinks item shape: {category?: string, externalInfo?: record, filename?: string, languageCombinationIds?: list, languageIds?: list<int>, toBeGenerated?: bool, url?: string}
export def "projects-files-add-link create-by-projectId" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-links: list # item shape: {category?: string, externalInfo?: record, filename?: string, languageCombinationIds?: list, languageIds?: list<int>, toBeGenerated?: bool, url?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/files/addLink"))
  let req_body = {"fileLinks": $file_links} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns list of files in a project, that are ready to be delivered to client.
#
# GET /v2/projects/{projectId}/files/deliverable
# operationId: getDeliverableFiles
export def "projects-files-deliverable get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/files/deliverable"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Uploads file to the project as a file uploaded by PM.
#
# POST /v2/projects/{projectId}/files/upload
# operationId: uploadFile_2
export def "projects-files-upload upload-by-projectId" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/files/upload"))
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body ["file"])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Returns finance information for a project.
#
# GET /v2/projects/{projectId}/finance
# operationId: getFinance_2
export def "projects-finance get-by-projectId" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/finance"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a payable to a project.
#
# POST /v2/projects/{projectId}/finance/payables
# operationId: createPayable_2
# --catLogFile shape: {content?: string, name?: string, token?: string, url?: string}
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "projects-finance-payables create-by-projectId" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --cat-log-file: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-id: record
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --total: float
  --type: string@type-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/finance/payables"))
  let req_body = {"calculationUnitId": $calculation_unit_id, "catLogFile": $cat_log_file, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobId": $job_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a payable.
#
# DELETE /v2/projects/{projectId}/finance/payables/{payableId}
# operationId: deletePayable_2
export def "projects-finance-payables delete-by-projectId-payableId" [
  project_id: string
  payable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), payable_id: (encode-path-segment $payable_id)} | format pattern "/v2/projects/{project_id}/finance/payables/{payable_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a payable.
#
# PUT /v2/projects/{projectId}/finance/payables/{payableId}
# operationId: updatePayable_2
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "projects-finance-payables update-by-projectId-payableId" [
  project_id: string
  payable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-id: record
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --total: float
  --type: string@type-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), payable_id: (encode-path-segment $payable_id)} | format pattern "/v2/projects/{project_id}/finance/payables/{payable_id}"))
  let req_body = {"calculationUnitId": $calculation_unit_id, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobId": $job_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Adds a receivable to a project.
#
# POST /v2/projects/{projectId}/finance/receivables
# operationId: createReceivable_2
# --catLogFile shape: {content?: string, name?: string, token?: string, url?: string}
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "projects-finance-receivables create-by-projectId" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --cat-log-file: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --task-id: int # format: int64
  --total: float
  --type: string@type-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/finance/receivables"))
  let req_body = {"calculationUnitId": $calculation_unit_id, "catLogFile": $cat_log_file, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "taskId": $task_id, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a receivable.
#
# DELETE /v2/projects/{projectId}/finance/receivables/{receivableId}
# operationId: deleteReceivable_2
export def "projects-finance-receivables delete-by-projectId-receivableId" [
  project_id: string
  receivable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), receivable_id: (encode-path-segment $receivable_id)} | format pattern "/v2/projects/{project_id}/finance/receivables/{receivable_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a receivable.
#
# PUT /v2/projects/{projectId}/finance/receivables/{receivableId}
# operationId: updateReceivable_2
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "projects-finance-receivables update-by-projectId-receivableId" [
  project_id: string
  receivable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --task-id: int # format: int64
  --total: float
  --type: string@type-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), receivable_id: (encode-path-segment $receivable_id)} | format pattern "/v2/projects/{project_id}/finance/receivables/{receivable_id}"))
  let req_body = {"calculationUnitId": $calculation_unit_id, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "taskId": $task_id, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates Internal Notes for a project.
#
# PUT /v2/projects/{projectId}/internalNotes
# operationId: updateInternalNotes
export def "projects-internal-notes update" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/internalNotes"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns list of jobs in a project.
#
# GET /v2/projects/{projectId}/jobs
# operationId: getJobs
export def "projects-jobs get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/jobs"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates Order Date for a project.
#
# PUT /v2/projects/{projectId}/orderDate
# operationId: updateOrderedOn
export def "projects-order-date update-ordered" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/orderDate"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns process id.
#
# GET /v2/projects/{projectId}/process
# operationId: getProcessId
export def "projects-process get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/process"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates source language for a project.
#
# PUT /v2/projects/{projectId}/sourceLanguage
# operationId: updateSourceLanguage
export def "projects-source-language update" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-language-id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/sourceLanguage"))
  let req_body = {"sourceLanguageId": $source_language_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates specialization for a project.
#
# PUT /v2/projects/{projectId}/specialization
# operationId: updateSpecialization
export def "projects-specialization update" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --specialization-id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/specialization"))
  let req_body = {"specializationId": $specialization_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Changes project status if possible (400 Bad Request is returned otherwise).
#
# PUT /v2/projects/{projectId}/status
# operationId: changeStatus_2
export def "projects-status update-change-by-projectId" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/status"))
  let req_body = {"status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates target languages for a project.
#
# PUT /v2/projects/{projectId}/targetLanguages
# operationId: updateTargetLanguages
export def "projects-target-languages update" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-language-ids: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/targetLanguages"))
  let req_body = {"targetLanguageIds": $target_language_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates instructions for all vendors performing the jobs in a project.
#
# PUT /v2/projects/{projectId}/vendorInstructions
# operationId: updateVendorInstructions
export def "projects-vendor-instructions update" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/vendorInstructions"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates volume for a project.
#
# PUT /v2/projects/{projectId}/volume
# operationId: updateVolume
export def "projects-volume update" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: float
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/volume"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a new Smart Quote.
#
# POST /v2/quotes
# operationId: create_7
export def "quotes create-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: int # format: int64
  --name: string
  --opportunity-offer-id: int # format: int64
  --service-id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/quotes")
  let req_body = {"clientId": $client_id, "name": $name, "opportunityOfferId": $opportunity_offer_id, "serviceId": $service_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Prepares a ZIP archive that contains the specified files.
#
# POST /v2/quotes/files/archive
# operationId: archive_1
export def "quotes-files-archive archive-by-" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/quotes/files/archive")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Returns details of a file.
#
# GET /v2/quotes/files/{fileId}
# operationId: getFileById_3
export def "quotes-files get-by-fileId" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/v2/quotes/files/{file_id}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Downloads a file content.
#
# GET /v2/quotes/files/{fileId}/download/{fileName}
# operationId: getFileContentById_1
export def "quotes-files-download get-content-by-fileId-fileName" [
  file_id: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id), file_name: (encode-path-segment $file_name)} | format pattern "/v2/quotes/files/{file_id}/download/{file_name}"))
  let accept_val = "multipart/form-data"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns quote details.
#
# GET /v2/quotes/{quoteId}
# operationId: getById_10
export def "quotes get-by-quoteId-by-quoteId-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates Business Days for a quote.
#
# PUT /v2/quotes/{quoteId}/businessDays
# operationId: updateBusinessDays
export def "quotes-business-days update" [
  quote_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/businessDays"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns Client Contacts information for a quote.
#
# GET /v2/quotes/{quoteId}/clientContacts
# operationId: getContacts_3
export def "quotes-client-contacts get-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/clientContacts"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates Client Contacts for a quote.
#
# PUT /v2/quotes/{quoteId}/clientContacts
# operationId: updateContacts_3
export def "quotes-client-contacts update-by-quoteId" [
  quote_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/clientContacts"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $req_body
}

# Updates Client Notes for a quote.
#
# PUT /v2/quotes/{quoteId}/clientNotes
# operationId: updateClientNotes_1
export def "quotes-client-notes update-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/clientNotes"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates Client Reference Number for a quote.
#
# PUT /v2/quotes/{quoteId}/clientReferenceNumber
# operationId: updateClientReferenceNumber_1
export def "quotes-client-reference-number update-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/clientReferenceNumber"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns a list of custom field keys and values for a project.
#
# GET /v2/quotes/{quoteId}/customFields
# operationId: getCustomFields_9
export def "quotes-custom-fields get-by-quoteId-by-quoteId-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/customFields"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a custom field with a specified key in a quote.
#
# PUT /v2/quotes/{quoteId}/customFields/{key}
# operationId: updateCustomField_3
export def "quotes-custom-fields update-by-quoteId-key" [
  quote_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), key: (encode-path-segment $key)} | format pattern "/v2/quotes/{quote_id}/customFields/{key}"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates Expected Delivery Date for a quote.
#
# PUT /v2/quotes/{quoteId}/expectedDeliveryDate
# operationId: updateExpectedDeliveryDate
export def "quotes-expected-delivery-date update" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/expectedDeliveryDate"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns list of files in a quote.
#
# GET /v2/quotes/{quoteId}/files
# operationId: getFiles_1
export def "quotes-files get-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/files"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds files to the quote as added by PM.
#
# PUT /v2/quotes/{quoteId}/files/add
# operationId: addFiles_2
export def "quotes-files-add create-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/files/add"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Uploads file to the quote as a file uploaded by PM.
#
# POST /v2/quotes/{quoteId}/files/upload
# operationId: uploadFile_3
export def "quotes-files-upload upload-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/files/upload"))
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body ["file"])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Returns finance information for a quote.
#
# GET /v2/quotes/{quoteId}/finance
# operationId: getFinance_3
export def "quotes-finance get-by-quoteId-by-quoteId-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/finance"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a payable to a quote.
#
# POST /v2/quotes/{quoteId}/finance/payables
# operationId: createPayable_3
# --catLogFile shape: {content?: string, name?: string, token?: string, url?: string}
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-payables create-by-quoteId-by-quoteId-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --cat-log-file: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-id: record
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --total: float
  --type: string@type-completer-1
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/finance/payables"))
  let req_body = {"calculationUnitId": $calculation_unit_id, "catLogFile": $cat_log_file, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobId": $job_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a payable.
#
# DELETE /v2/quotes/{quoteId}/finance/payables/{payableId}
# operationId: deletePayable_3
export def "quotes-finance-payables delete-by-quoteId-payableId-by-quoteId-payableId-1" [
  quote_id: string
  payable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), payable_id: (encode-path-segment $payable_id)} | format pattern "/v2/quotes/{quote_id}/finance/payables/{payable_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a payable.
#
# PUT /v2/quotes/{quoteId}/finance/payables/{payableId}
# operationId: updatePayable_3
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-payables update-by-quoteId-payableId-by-quoteId-payableId-1" [
  quote_id: string
  payable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-id: record
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --total: float
  --type: string@type-completer-1
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), payable_id: (encode-path-segment $payable_id)} | format pattern "/v2/quotes/{quote_id}/finance/payables/{payable_id}"))
  let req_body = {"calculationUnitId": $calculation_unit_id, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobId": $job_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Adds a receivable to a quote.
#
# POST /v2/quotes/{quoteId}/finance/receivables
# operationId: createReceivable_3
# --catLogFile shape: {content?: string, name?: string, token?: string, url?: string}
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-receivables create-by-quoteId-by-quoteId-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --cat-log-file: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --task-id: int # format: int64
  --total: float
  --type: string@type-completer-1
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/finance/receivables"))
  let req_body = {"calculationUnitId": $calculation_unit_id, "catLogFile": $cat_log_file, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "taskId": $task_id, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a receivable.
#
# DELETE /v2/quotes/{quoteId}/finance/receivables/{receivableId}
# operationId: deleteReceivable_3
export def "quotes-finance-receivables delete-by-quoteId-receivableId-by-quoteId-receivableId-1" [
  quote_id: string
  receivable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), receivable_id: (encode-path-segment $receivable_id)} | format pattern "/v2/quotes/{quote_id}/finance/receivables/{receivable_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a receivable.
#
# PUT /v2/quotes/{quoteId}/finance/receivables/{receivableId}
# operationId: updateReceivable_3
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-receivables update-by-quoteId-receivableId-by-quoteId-receivableId-1" [
  quote_id: string
  receivable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculation-unit-id: int # format: int64
  --currency-id: int # format: int64
  --description: string
  --id: int # format: int64
  --ignore-minimum-charge: oneof<nothing, bool>
  --invoice-id: string
  --job-type-id: int # format: int64
  --language-combination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --language-combination-id-number: string
  --minimum-charge: float
  --quantity: float
  --rate: float
  --rate-origin: string@rate-origin-completer
  --task-id: int # format: int64
  --total: float
  --type: string@type-completer-1
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), receivable_id: (encode-path-segment $receivable_id)} | format pattern "/v2/quotes/{quote_id}/finance/receivables/{receivable_id}"))
  let req_body = {"calculationUnitId": $calculation_unit_id, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "taskId": $task_id, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates Internal Notes for a quote.
#
# PUT /v2/quotes/{quoteId}/internalNotes
# operationId: updateInternalNotes_1
export def "quotes-internal-notes update-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/internalNotes"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns list of jobs in a quote.
#
# GET /v2/quotes/{quoteId}/jobs
# operationId: getJobs_1
export def "quotes-jobs get-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/jobs"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates Quote Expiry Date for a quote.
#
# PUT /v2/quotes/{quoteId}/quoteExpiry
# operationId: updateQuoteExpiry
export def "quotes-quote-expiry update" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/quoteExpiry"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates source language for a quote.
#
# PUT /v2/quotes/{quoteId}/sourceLanguage
# operationId: updateSourceLanguage_1
export def "quotes-source-language update-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-language-id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/sourceLanguage"))
  let req_body = {"sourceLanguageId": $source_language_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates specialization for a quote.
#
# PUT /v2/quotes/{quoteId}/specialization
# operationId: updateSpecialization_1
export def "quotes-specialization update-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --specialization-id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/specialization"))
  let req_body = {"specializationId": $specialization_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Changes quote status if possible (400 Bad Request is returned otherwise).
#
# PUT /v2/quotes/{quoteId}/status
# operationId: changeStatus_3
export def "quotes-status update-change-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/status"))
  let req_body = {"status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates target languages for a quote.
#
# PUT /v2/quotes/{quoteId}/targetLanguages
# operationId: updateTargetLanguages_1
export def "quotes-target-languages update-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-language-ids: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/targetLanguages"))
  let req_body = {"targetLanguageIds": $target_language_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates instructions for all vendors performing the jobs in a quote.
#
# PUT /v2/quotes/{quoteId}/vendorInstructions
# operationId: updateVendorInstructions_1
export def "quotes-vendor-instructions update-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/vendorInstructions"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates volume for a quote.
#
# PUT /v2/quotes/{quoteId}/volume
# operationId: updateVolume_1
export def "quotes-volume update-by-quoteId" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: float
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/volume"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
