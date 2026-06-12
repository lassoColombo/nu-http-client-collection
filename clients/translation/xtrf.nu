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

def base-url-completer [] { ["https://presentation.s.xtrf.eu/home-api"] }
def auth-scheme-completer [] { ["x-auth-access-token"] }

# Completers for enum parameters
def status-completer [] { ["BILL_CREATED" "CONFIRMED" "POSTPONED" "SENT" "TO_BE_SENT"] }
def status-completer-1 [] { ["ACTIVE" "INACTIVE" "POTENTIAL"] }
def type-completer [] { ["CHECKBOX" "DATE" "DATE_AND_TIME" "MULTI_SELECTION" "NUMBER" "SELECTION" "TEXT"] }
def rateOrigin-completer [] { ["AUTOCALCULATED" "FILLED_MANUALLY" "PRICE_LIST" "PRICE_PROFILE"] }
def type-completer-1 [] { ["CAT" "SIMPLE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounting-customers-invoices list" } } | get name | first)
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
export def "accounting-customers-invoices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updatedSince: int # only client invoices modified since this timestamp (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updatedSince "scalar")] | flatten | str join "&"
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
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Generates client invoices' documents.
#
# POST /accounting/customers/invoices/documents
# operationId: downloadDocuments
export def "accounting-customers-invoices-documents downloadDocuments" [
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
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Returns client invoices' internal identifiers.
#
# GET /accounting/customers/invoices/ids
# operationId: getAllIds
export def "accounting-customers-invoices-ids get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updatedSince: int # only client invoices modified since this timestamp (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updatedSince "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/customers/invoices/ids" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sends reminders. Returns number of sent e-mails.
#
# POST /accounting/customers/invoices/sendReminders
# operationId: sendReminders
export def "accounting-customers-invoices-send-reminders sendReminders" [
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
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Removes a client invoice.
#
# DELETE /accounting/customers/invoices/{invoiceId}
# operationId: delete_1
export def "accounting-customers-invoices delete-by-invoiceId" [
  invoiceId: int
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
  let full_url = (build-url $base $"/accounting/customers/invoices/($invoiceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns client invoice details.
#
# GET /accounting/customers/invoices/{invoiceId}
# operationId: getById
export def "accounting-customers-invoices get" [
  invoiceId: int
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
  let full_url = (build-url $base $"/accounting/customers/invoices/($invoiceId)" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns dates of a given client invoice.
#
# GET /accounting/customers/invoices/{invoiceId}/dates
# operationId: getDates
export def "accounting-customers-invoices-dates get" [
  invoiceId: int
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
  let full_url = (build-url $base $"/accounting/customers/invoices/($invoiceId)/dates")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generates client invoice document (PDF).
#
# GET /accounting/customers/invoices/{invoiceId}/document
# operationId: getDocument
export def "accounting-customers-invoices-document get" [
  invoiceId: int
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
  let full_url = (build-url $base $"/accounting/customers/invoices/($invoiceId)/document")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Duplicate client invoice.
#
# POST /accounting/customers/invoices/{invoiceId}/duplicate
# operationId: duplicate
export def "accounting-customers-invoices-duplicate duplicate" [
  invoiceId: int
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
  let full_url = (build-url $base $"/accounting/customers/invoices/($invoiceId)/duplicate")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Duplicate client invoice as pro forma.
#
# POST /accounting/customers/invoices/{invoiceId}/duplicate/proForma
# operationId: duplicateAsProForma
export def "accounting-customers-invoices-duplicate-pro-forma duplicateAsProForma" [
  invoiceId: int
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
  let full_url = (build-url $base $"/accounting/customers/invoices/($invoiceId)/duplicate/proForma")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns payment terms of a given client invoice.
#
# GET /accounting/customers/invoices/{invoiceId}/paymentTerms
# operationId: getPaymentTerms
export def "accounting-customers-invoices-payment-terms get" [
  invoiceId: int
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
  let full_url = (build-url $base $"/accounting/customers/invoices/($invoiceId)/paymentTerms")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all payments for the client invoice.
#
# GET /accounting/customers/invoices/{invoiceId}/payments
# operationId: getPayments
export def "accounting-customers-invoices-payments get" [
  invoiceId: int
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
  let full_url = (build-url $base $"/accounting/customers/invoices/($invoiceId)/payments")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a new payment to the client invoice. The invoice payment status (Not Paid, Partially Paid, Fully Paid) is automatically recalculated.
#
# POST /accounting/customers/invoices/{invoiceId}/payments
# operationId: createPayment
export def "accounting-customers-invoices-payments createPayment" [
  invoiceId: int
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
  let full_url = (build-url $base $"/accounting/customers/invoices/($invoiceId)/payments")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Sends reminder.
#
# POST /accounting/customers/invoices/{invoiceId}/sendReminder
# operationId: sendReminder
export def "accounting-customers-invoices-send-reminder sendReminder" [
  invoiceId: int
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
  let full_url = (build-url $base $"/accounting/customers/invoices/($invoiceId)/sendReminder")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a customer payment.
#
# DELETE /accounting/customers/payments/{paymentId}
# operationId: delete_2
export def "accounting-customers-payments delete-by-paymentId" [
  paymentId: int
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
  let full_url = (build-url $base $"/accounting/customers/payments/($paymentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all vendor invoices in all statuses (including not ready and drafts) that have been updated since a specific date.
#
# GET /accounting/providers/invoices
# operationId: getAll_2
export def "accounting-providers-invoices get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updatedSince: int # only vendor invoices modified since this timestamp (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updatedSince "scalar")] | flatten | str join "&"
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
  --jobsIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounting/providers/invoices")
  let body = {jobsIds: $jobsIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns vendor invoices' internal identifiers.
#
# GET /accounting/providers/invoices/ids
# operationId: getAllIds_3
export def "accounting-providers-invoices-ids get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updatedSince: int # only vendor invoices modified since this timestamp (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updatedSince "scalar")] | flatten | str join "&"
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
  invoiceId: int
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
  let full_url = (build-url $base $"/accounting/providers/invoices/($invoiceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns provider invoice details.
#
# GET /accounting/providers/invoices/{invoiceId}
# operationId: getById_3
export def "accounting-providers-invoices get-by-invoiceId" [
  invoiceId: int
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
  let full_url = (build-url $base $"/accounting/providers/invoices/($invoiceId)")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generates provider invoice document (PDF).
#
# GET /accounting/providers/invoices/{invoiceId}/document
# operationId: getDocument_1
export def "accounting-providers-invoices-document get-by-invoiceId" [
  invoiceId: int
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
  let full_url = (build-url $base $"/accounting/providers/invoices/($invoiceId)/document")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all payments for the vendor invoice.
#
# GET /accounting/providers/invoices/{invoiceId}/payments
# operationId: getPayments_1
export def "accounting-providers-invoices-payments get-by-invoiceId" [
  invoiceId: int
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
  let full_url = (build-url $base $"/accounting/providers/invoices/($invoiceId)/payments")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new payment on the vendor account and assigns the payment to the invoice.
#
# POST /accounting/providers/invoices/{invoiceId}/payments
# operationId: createPayment_1
export def "accounting-providers-invoices-payments createPayment-by-invoiceId" [
  invoiceId: int
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
  let full_url = (build-url $base $"/accounting/providers/invoices/($invoiceId)/payments")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Sends a provider invoice.
#
# POST /accounting/providers/invoices/{invoiceId}/send
# operationId: send
export def "accounting-providers-invoices-send send" [
  invoiceId: int
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
  let full_url = (build-url $base $"/accounting/providers/invoices/($invoiceId)/send")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Changes invoice status to given status.
#
# POST /accounting/providers/invoices/{invoiceId}/status
# operationId: setStatus
export def "accounting-providers-invoices-status setStatus" [
  invoiceId: int
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
  let full_url = (build-url $base $"/accounting/providers/invoices/($invoiceId)/status")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Removes a provider payment.
#
# DELETE /accounting/providers/payments/{paymentId}
# operationId: delete_7
export def "accounting-providers-payments delete-by-paymentId" [
  paymentId: int
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
  let full_url = (build-url $base $"/accounting/providers/payments/($paymentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Searches for data (ie. customer, task, etc) and returns it in a tabular form.
#
# GET /browser
# operationId: browseJSON
export def "browser browseJSON" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --viewId: int # view's identifier (format: int64)
  --page: int # format: int32, default: 0
  --additionalOrder: string
  --useDeferredColumns: string
  --maxRows: int # overrides view's default rows limit, supported values 10 to 1000 (format: int32, default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "viewId" $viewId "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "additionalOrder" $additionalOrder "scalar") (serialize-qp "useDeferredColumns" $useDeferredColumns "scalar") (serialize-qp "maxRows" $maxRows "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/browser" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Searches for data (ie. customer, task, etc) and returns it in a CSV form.
#
# GET /browser/csv
# operationId: browseCSV
export def "browser-csv browseCSV" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --viewId: int # view's identifier (format: int64)
  --separator: string # csv field separator
  --secondarySeparator: string # secondary csv field separator
  --additionalOrder: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "viewId" $viewId "scalar") (serialize-qp "separator" $separator "scalar") (serialize-qp "secondarySeparator" $secondarySeparator "scalar") (serialize-qp "additionalOrder" $additionalOrder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/browser/csv" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns current view's detailed information, suitable for browser.
#
# GET /browser/views/details/for/{className}
# operationId: getCurrentViewDetails
export def "browser-views-details-for list" [
  className: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --placeName: string # place name (denotes specific place in system with the table) (default: default)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "placeName" $placeName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/browser/views/details/for/($className)" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns view's detailed information, suitable for browser.
#
# GET /browser/views/details/for/{className}/{viewId}
# operationId: getViewDetails
export def "browser-views-details-for get" [
  className: string
  viewId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --placeName: string # place name (denotes specific place in system with the table) (default: default)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "placeName" $placeName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/browser/views/details/for/($className)/($viewId)" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Selects given view as current and returns its detailed information, suitable for browser.
#
# POST /browser/views/details/for/{className}/{viewId}
# operationId: selectViewAndGetItsDetails
export def "browser-views-details-for selectViewAndGetItsDetails" [
  className: string
  viewId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --place name denotes specific place in system with the table: string # default: default
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "place name (denotes specific place in system with the table)" $place name denotes specific place in system with the table "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/browser/views/details/for/($className)/($viewId)" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns views' brief.
#
# GET /browser/views/for/{className}
# operationId: getViewsBrief
export def "browser-views-for get" [
  className: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --placeName: string # place name (denotes specific place in system with the table) (default: default)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "placeName" $placeName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/browser/views/for/($className)" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates view for given class.
#
# POST /browser/views/for/{className}
# operationId: create
export def "browser-views-for create" [
  className: string
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
  let full_url = (build-url $base $"/browser/views/for/($className)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Removes a view.
#
# DELETE /browser/views/{viewId}
# operationId: delete
export def "browser-views delete" [
  viewId: int
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
  let full_url = (build-url $base $"/browser/views/($viewId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all view's information.
#
# GET /browser/views/{viewId}
# operationId: get
export def "browser-views get" [
  viewId: int
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
  let full_url = (build-url $base $"/browser/views/($viewId)")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates all view's information.
#
# PUT /browser/views/{viewId}
# operationId: update
export def "browser-views update" [
  viewId: int
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
  let full_url = (build-url $base $"/browser/views/($viewId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Returns columns defined in view.
#
# GET /browser/views/{viewId}/columns
# operationId: getColumns
export def "browser-views-columns get" [
  viewId: int
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
  let full_url = (build-url $base $"/browser/views/($viewId)/columns")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates columns in view.
#
# PUT /browser/views/{viewId}/columns
# operationId: updateColumns
export def "browser-views-columns updateColumns" [
  viewId: int
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
  let full_url = (build-url $base $"/browser/views/($viewId)/columns")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Deletes a single column from view.
#
# DELETE /browser/views/{viewId}/columns/{columnName}
# operationId: deleteColumn
export def "browser-views-columns delete" [
  viewId: int
  columnName: string
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
  let full_url = (build-url $base $"/browser/views/($viewId)/columns/($columnName)")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns column's specific settings.
#
# GET /browser/views/{viewId}/columns/{columnName}/settings
# operationId: getColumnSettings
export def "browser-views-columns-settings get" [
  viewId: int
  columnName: string
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
  let full_url = (build-url $base $"/browser/views/($viewId)/columns/($columnName)/settings")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates column's specific settings.
#
# PUT /browser/views/{viewId}/columns/{columnName}/settings
# operationId: updateColumnSettings
export def "browser-views-columns-settings updateColumnSettings" [
  viewId: int
  columnName: string
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
  let full_url = (build-url $base $"/browser/views/($viewId)/columns/($columnName)/settings")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns view's filter.
#
# GET /browser/views/{viewId}/filter
# operationId: getFilter
export def "browser-views-filter get" [
  viewId: int
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
  let full_url = (build-url $base $"/browser/views/($viewId)/filter")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates view's filter.
#
# PUT /browser/views/{viewId}/filter
# operationId: updateFilter
export def "browser-views-filter updateFilter" [
  viewId: int
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
  let full_url = (build-url $base $"/browser/views/($viewId)/filter")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Updates view's filter property.
#
# PUT /browser/views/{viewId}/filter/{filterProperty}
# operationId: updateFilterProperty
export def "browser-views-filter updateFilterProperty" [
  viewId: int
  filterProperty: string
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
  --settingsPresent: oneof<nothing, bool>
  --type: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/browser/views/($viewId)/filter/($filterProperty)")
  let body = {name: $name, settings: $settings, settingsPresent: $settingsPresent, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns view's order settings.
#
# GET /browser/views/{viewId}/order
# operationId: getOrder
export def "browser-views-order get" [
  viewId: int
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
  let full_url = (build-url $base $"/browser/views/($viewId)/order")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates view's order settings.
#
# PUT /browser/views/{viewId}/order
# operationId: updateOrder
export def "browser-views-order updateOrder" [
  viewId: int
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
  let full_url = (build-url $base $"/browser/views/($viewId)/order")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Returns view's permissions.
#
# GET /browser/views/{viewId}/permissions
# operationId: getPermissions
export def "browser-views-permissions get" [
  viewId: int
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
  let full_url = (build-url $base $"/browser/views/($viewId)/permissions")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates view's permissions.
#
# PUT /browser/views/{viewId}/permissions
# operationId: updatePermissions
export def "browser-views-permissions updatePermissions" [
  viewId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sharedGroups: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/browser/views/($viewId)/permissions")
  let body = {sharedGroups: $sharedGroups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns view's settings.
#
# GET /browser/views/{viewId}/settings
# operationId: getSettings
export def "browser-views-settings get" [
  viewId: int
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
  let full_url = (build-url $base $"/browser/views/($viewId)/settings")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates view's settings.
#
# PUT /browser/views/{viewId}/settings
# operationId: updateSettings
# --local shape: {maxLinesInRow?: int, maxRows?: int}
export def "browser-views-settings updateSettings" [
  viewId: int
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
  let full_url = (build-url $base $"/browser/views/($viewId)/settings")
  let body = {local: $local, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns view's local settings (for current user).
#
# GET /browser/views/{viewId}/settings/local
# operationId: getLocalSettings
export def "browser-views-settings-local get" [
  viewId: int
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
  let full_url = (build-url $base $"/browser/views/($viewId)/settings/local")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates view's local settings (for current user).
#
# PUT /browser/views/{viewId}/settings/local
# operationId: updateLocalSettings
export def "browser-views-settings-local updateLocalSettings" [
  viewId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxLinesInRow: int # format: int32
  --maxRows: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/browser/views/($viewId)/settings/local")
  let body = {maxLinesInRow: $maxLinesInRow, maxRows: $maxRows} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns list of simple clients representations
#
# GET /customers
# operationId: getAllNamesWithIds
export def "customers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updatedSince: int # only clients modified since this timestamp (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updatedSince "scalar")] | flatten | str join "&"
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
# --contact shape: {emails?: record, fax?: string, phones?: list, sms?: string, websites?: list}
# --correspondenceAddress shape: {addressLine1?: string, addressLine2?: string, city?: string, countryId?: int, postalCode?: string, provinceId?: int, sameAsBillingAddress?: bool}
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
# --persons item shape: {active?: bool, contact?: record, customFields?: list, customerId?: int, firstProjectDate?: string, firstQuoteDate?: string, gender?: "FEMALE"|"MALE", id?: int, lastName?: string, lastProjectDate?: string, lastQuoteDate?: string, motherTonguesIds?: list, name?: string, numberOfProjects?: int, numberOfQuotes?: int, positionId?: int}
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
  --accountOnCustomerServer: string
  --accounting: record # shape: {taxNumbers?: list}
  --billingAddress: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, countryId?: int, postalCode?: string, provinceId?: int, sameAsBillingAddress?: bool}
  --branchId: int # format: int64
  --categoriesIds: list
  --clientFirstProjectDate: string # format: date-time
  --clientFirstQuoteDate: string # format: date-time
  --clientLastProjectDate: string # format: date-time
  --clientLastQuoteDate: string # format: date-time
  --clientNumberOfProjects: int # format: int32
  --clientNumberOfQuotes: int # format: int32
  --contact: record # shape: {emails?: record, fax?: string, phones?: list, sms?: string, websites?: list}
  --contractNumber: string
  --correspondenceAddress: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, countryId?: int, postalCode?: string, provinceId?: int, sameAsBillingAddress?: bool}
  --customFields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --fullName: string
  --id: int # format: int64
  --idNumber: string
  --industriesIds: list
  --leadSourceId: int # format: int64
  --limitAccessToPeopleResponsible: oneof<nothing, bool>
  --name: string
  --notes: string
  --persons: list # item shape: {active?: bool, contact?: record, customFields?: list, customerId?: int, firstProjectDate?: string, firstQuoteDate?: string, gender?: "FEMALE"|"MALE", id?: int, lastName?: string, lastProjectDate?: string, lastQuoteDate?: string, motherTonguesIds?: list, name?: string, numberOfProjects?: int, numberOfQuotes?: int, positionId?: int}
  --responsiblePersons: record # shape: {accountManagerId?: int, projectCoordinatorId?: int, projectManagerId: int, salesPersonId: int}
  --salesNotes: string
  --status: string@status-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customers")
  let body = {accountOnCustomerServer: $accountOnCustomerServer, accounting: $accounting, billingAddress: $billingAddress, branchId: $branchId, categoriesIds: $categoriesIds, clientFirstProjectDate: $clientFirstProjectDate, clientFirstQuoteDate: $clientFirstQuoteDate, clientLastProjectDate: $clientLastProjectDate, clientLastQuoteDate: $clientLastQuoteDate, clientNumberOfProjects: $clientNumberOfProjects, clientNumberOfQuotes: $clientNumberOfQuotes, contact: $contact, contractNumber: $contractNumber, correspondenceAddress: $correspondenceAddress, customFields: $customFields, fullName: $fullName, id: $id, idNumber: $idNumber, industriesIds: $industriesIds, leadSourceId: $leadSourceId, limitAccessToPeopleResponsible: $limitAccessToPeopleResponsible, name: $name, notes: $notes, persons: $persons, responsiblePersons: $responsiblePersons, salesNotes: $salesNotes, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns clients' internal identifiers.
#
# GET /customers/ids
# operationId: getAllIds_2
export def "customers-ids get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updatedSince: int # only clients modified since this timestamp (format: int64)
  --nameEquals: string # exact name of client
  --emailEquals: string # exact email of client
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updatedSince "scalar") (serialize-qp "nameEquals" $nameEquals "scalar") (serialize-qp "emailEquals" $emailEquals "scalar")] | flatten | str join "&"
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
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Generates a single use sign-in token.
#
# POST /customers/persons/accessToken
# operationId: generateSingleUseSignInToken
export def "customers-persons-access-token generateSingleUseSignInToken" [
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
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Returns persons' internal identifiers.
#
# GET /customers/persons/ids
# operationId: getAllIds_1
export def "customers-persons-ids get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updatedSince: int # only persons modified since this timestamp (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updatedSince "scalar")] | flatten | str join "&"
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
  personId: int
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
  let full_url = (build-url $base $"/customers/persons/($personId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns person details.
#
# GET /customers/persons/{personId}
# operationId: getById_1
export def "customers-persons get-by-personId" [
  personId: int
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
  let full_url = (build-url $base $"/customers/persons/($personId)")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing person.
#
# PUT /customers/persons/{personId}
# operationId: update_1
export def "customers-persons update-by-personId" [
  personId: int
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
  let full_url = (build-url $base $"/customers/persons/($personId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Returns contact of a given person.
#
# GET /customers/persons/{personId}/contact
# operationId: getContact
export def "customers-persons-contact get" [
  personId: int
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
  let full_url = (build-url $base $"/customers/persons/($personId)/contact")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates contact of a given person.
#
# PUT /customers/persons/{personId}/contact
# operationId: updateContact
export def "customers-persons-contact updateContact" [
  personId: int
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
  let full_url = (build-url $base $"/customers/persons/($personId)/contact")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Returns custom fields of a given person.
#
# GET /customers/persons/{personId}/customFields
# operationId: getCustomFields
export def "customers-persons-custom-fields get" [
  personId: int
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
  let full_url = (build-url $base $"/customers/persons/($personId)/customFields")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates custom fields of a given person.
#
# PUT /customers/persons/{personId}/customFields
# operationId: updateCustomFields
export def "customers-persons-custom-fields updateCustomFields" [
  personId: int
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
  let full_url = (build-url $base $"/customers/persons/($personId)/customFields")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Removes a customer price list.
#
# DELETE /customers/priceLists/{priceListId}
# operationId: delete_4
export def "customers-price-lists delete-by-priceListId" [
  priceListId: int
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
  let full_url = (build-url $base $"/customers/priceLists/($priceListId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a client.
#
# DELETE /customers/{customerId}
# operationId: delete_5
export def "customers delete-by-customerId" [
  customerId: int
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
  let full_url = (build-url $base $"/customers/($customerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns client details.
#
# GET /customers/{customerId}
# operationId: getById_2
export def "customers get-by-customerId" [
  customerId: int
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
  let full_url = (build-url $base $"/customers/($customerId)" $qp)
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
# --contact shape: {emails?: record, fax?: string, phones?: list, sms?: string, websites?: list}
# --correspondenceAddress shape: {addressLine1?: string, addressLine2?: string, city?: string, countryId?: int, postalCode?: string, provinceId?: int, sameAsBillingAddress?: bool}
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
# --persons item shape: {active?: bool, contact?: record, customFields?: list, customerId?: int, firstProjectDate?: string, firstQuoteDate?: string, gender?: "FEMALE"|"MALE", id?: int, lastName?: string, lastProjectDate?: string, lastQuoteDate?: string, motherTonguesIds?: list, name?: string, numberOfProjects?: int, numberOfQuotes?: int, positionId?: int}
# --responsiblePersons shape: {accountManagerId?: int, projectCoordinatorId?: int, projectManagerId: int, salesPersonId: int}
export def "customers update-by-customerId" [
  customerId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountOnCustomerServer: string
  --accounting: record # shape: {taxNumbers?: list}
  --billingAddress: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, countryId?: int, postalCode?: string, provinceId?: int, sameAsBillingAddress?: bool}
  --branchId: int # format: int64
  --categoriesIds: list
  --clientFirstProjectDate: string # format: date-time
  --clientFirstQuoteDate: string # format: date-time
  --clientLastProjectDate: string # format: date-time
  --clientLastQuoteDate: string # format: date-time
  --clientNumberOfProjects: int # format: int32
  --clientNumberOfQuotes: int # format: int32
  --contact: record # shape: {emails?: record, fax?: string, phones?: list, sms?: string, websites?: list}
  --contractNumber: string
  --correspondenceAddress: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, countryId?: int, postalCode?: string, provinceId?: int, sameAsBillingAddress?: bool}
  --customFields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --fullName: string
  --id: int # format: int64
  --idNumber: string
  --industriesIds: list
  --leadSourceId: int # format: int64
  --limitAccessToPeopleResponsible: oneof<nothing, bool>
  --name: string
  --notes: string
  --persons: list # item shape: {active?: bool, contact?: record, customFields?: list, customerId?: int, firstProjectDate?: string, firstQuoteDate?: string, gender?: "FEMALE"|"MALE", id?: int, lastName?: string, lastProjectDate?: string, lastQuoteDate?: string, motherTonguesIds?: list, name?: string, numberOfProjects?: int, numberOfQuotes?: int, positionId?: int}
  --responsiblePersons: record # shape: {accountManagerId?: int, projectCoordinatorId?: int, projectManagerId: int, salesPersonId: int}
  --salesNotes: string
  --status: string@status-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($customerId)")
  let body = {accountOnCustomerServer: $accountOnCustomerServer, accounting: $accounting, billingAddress: $billingAddress, branchId: $branchId, categoriesIds: $categoriesIds, clientFirstProjectDate: $clientFirstProjectDate, clientFirstQuoteDate: $clientFirstQuoteDate, clientLastProjectDate: $clientLastProjectDate, clientLastQuoteDate: $clientLastQuoteDate, clientNumberOfProjects: $clientNumberOfProjects, clientNumberOfQuotes: $clientNumberOfQuotes, contact: $contact, contractNumber: $contractNumber, correspondenceAddress: $correspondenceAddress, customFields: $customFields, fullName: $fullName, id: $id, idNumber: $idNumber, industriesIds: $industriesIds, leadSourceId: $leadSourceId, limitAccessToPeopleResponsible: $limitAccessToPeopleResponsible, name: $name, notes: $notes, persons: $persons, responsiblePersons: $responsiblePersons, salesNotes: $salesNotes, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns address of a given client.
#
# GET /customers/{customerId}/address
# operationId: getAddress
export def "customers-address get" [
  customerId: int
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
  let full_url = (build-url $base $"/customers/($customerId)/address")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates address of a given client.
#
# PUT /customers/{customerId}/address
# operationId: updateAddress
export def "customers-address updateAddress" [
  customerId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --addressLine1: string # first line of address
  --addressLine2: string # second line of address
  --city: string # city
  --countryId: int # country (format: int64)
  --postalCode: string # postal code
  --provinceId: int # province (format: int64)
  --sameAsBillingAddress: oneof<nothing, bool> # should billing address be used instead of this one
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($customerId)/address")
  let body = {addressLine1: $addressLine1, addressLine2: $addressLine2, city: $city, countryId: $countryId, postalCode: $postalCode, provinceId: $provinceId, sameAsBillingAddress: $sameAsBillingAddress} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns categories of a given client.
#
# GET /customers/{customerId}/categories
# operationId: getCategories
export def "customers-categories get" [
  customerId: int
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
  let full_url = (build-url $base $"/customers/($customerId)/categories")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates categories of a given client.
#
# PUT /customers/{customerId}/categories
# operationId: updateCategories
export def "customers-categories updateCategories" [
  customerId: int
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
  let full_url = (build-url $base $"/customers/($customerId)/categories")
  let body = {empty: $empty} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns contact of a given client.
#
# GET /customers/{customerId}/contact
# operationId: getContact_1
export def "customers-contact get-by-customerId" [
  customerId: int
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
  let full_url = (build-url $base $"/customers/($customerId)/contact")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates contact of a given client.
#
# PUT /customers/{customerId}/contact
# operationId: updateContact_1
# --emails shape: {additional?: list, cc?: list, primary: string}
export def "customers-contact updateContact-by-customerId" [
  customerId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --emails: record # emails — shape: {additional?: list, cc?: list, primary: string}
  --fax: string # fax number
  --phones: list # phones' numbers
  --sms: string # mobile phone for which SMS notifications will be sent (if configured)
  --websites: list # websites
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($customerId)/contact")
  let body = {emails: $emails, fax: $fax, phones: $phones, sms: $sms, websites: $websites} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns correspondence address of a given client.
#
# GET /customers/{customerId}/correspondenceAddress
# operationId: getCorrespondenceAddress
export def "customers-correspondence-address get" [
  customerId: int
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
  let full_url = (build-url $base $"/customers/($customerId)/correspondenceAddress")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates correspondence address of a given client.
#
# PUT /customers/{customerId}/correspondenceAddress
# operationId: updateCorrespondenceAddress
export def "customers-correspondence-address updateCorrespondenceAddress" [
  customerId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --addressLine1: string # first line of address
  --addressLine2: string # second line of address
  --city: string # city
  --countryId: int # country (format: int64)
  --postalCode: string # postal code
  --provinceId: int # province (format: int64)
  --sameAsBillingAddress: oneof<nothing, bool> # should billing address be used instead of this one
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($customerId)/correspondenceAddress")
  let body = {addressLine1: $addressLine1, addressLine2: $addressLine2, city: $city, countryId: $countryId, postalCode: $postalCode, provinceId: $provinceId, sameAsBillingAddress: $sameAsBillingAddress} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns custom fields of a given client.
#
# GET /customers/{customerId}/customFields
# operationId: getCustomFields_1
export def "customers-custom-fields get-by-customerId" [
  customerId: int
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
  let full_url = (build-url $base $"/customers/($customerId)/customFields")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates custom fields of a given client.
#
# PUT /customers/{customerId}/customFields
# operationId: updateCustomFields_1
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
export def "customers-custom-fields updateCustomFields-by-customerId" [
  customerId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customFields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/customers/($customerId)/customFields")
  let body = {customFields: $customFields, empty: $empty} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns custom field of a given client.
#
# GET /customers/{customerId}/customFields/{customFieldKey}
# operationId: getCustomField
export def "customers-custom-fields get" [
  customerId: int
  customFieldKey: string
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
  let full_url = (build-url $base $"/customers/($customerId)/customFields/($customFieldKey)")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates given custom field of a given client.
#
# PUT /customers/{customerId}/customFields/{customFieldKey}
# operationId: updateCustomField
export def "customers-custom-fields updateCustomField" [
  customerId: int
  customFieldKey: string
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
  let full_url = (build-url $base $"/customers/($customerId)/customFields/($customFieldKey)")
  let body = {key: $key, name: $name, type: $type, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns industries of a given client.
#
# GET /customers/{customerId}/industries
# operationId: getIndustries
export def "customers-industries get" [
  customerId: int
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
  let full_url = (build-url $base $"/customers/($customerId)/industries")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates industries of a given client.
#
# PUT /customers/{customerId}/industries
# operationId: updateIndustries
export def "customers-industries updateIndustries" [
  customerId: int
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
  let full_url = (build-url $base $"/customers/($customerId)/industries")
  let body = {empty: $empty} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
export def "dictionaries-currency-exchange-rate get" [
  isoCode: string
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
  let full_url = (build-url $base $"/dictionaries/currency/($isoCode)/exchangeRate")
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
export def "dictionaries-currency-exchange-rate createExchangeRate" [
  isoCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dateFrom: record # shape: {value?: int}
  --exchangeRate: string
  --lastModification: record # shape: {value?: int}
  --originDetails: string
  --publicationDate: record # shape: {value?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dictionaries/currency/($isoCode)/exchangeRate")
  let body = {dateFrom: $dateFrom, exchangeRate: $exchangeRate, lastModification: $lastModification, originDetails: $originDetails, publicationDate: $publicationDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --nameEquals: string # exact name of entity
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nameEquals" $nameEquals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dictionaries/($type)/active" $qp)
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
  --nameEquals: string # exact name of entity
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nameEquals" $nameEquals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dictionaries/($type)/all" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns specific value from a given dictionary.
#
# GET /dictionaries/{type}/{id}
# operationId: getByTypeAndId
export def "dictionaries get" [
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
  let full_url = (build-url $base $"/dictionaries/($type)/($id)")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Uploads a temporary file (ie. for XML import). Returns token which can be used in other API calls.
#
# POST /files
# operationId: uploadFile
export def "files uploadFile" [
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
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Returns job details by jobId.
#
# GET /jobs/{jobId}
# operationId: getJobDetails
export def "jobs get" [
  jobId: string
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
  let full_url = (build-url $base $"/jobs/($jobId)")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates dates of a given job.
#
# PUT /jobs/{jobId}/dates
# operationId: updateDates
export def "jobs-dates updateDates" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actualEndDate: int # format: int64
  --actualStartDate: int # format: int64
  --deadline: int # format: int64
  --startDate: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/jobs/($jobId)/dates")
  let body = {actualEndDate: $actualEndDate, actualStartDate: $actualStartDate, deadline: $deadline, startDate: $startDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns list of input and output files of a job.
#
# GET /jobs/{jobId}/files
# operationId: getJobFiles
export def "jobs-files get" [
  jobId: string
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
  let full_url = (build-url $base $"/jobs/($jobId)/files")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /jobs/{jobId}/files/output
#
# operationId: assignFileToJobOutput
export def "jobs-files-output assignFileToJobOutput" [
  jobId: string
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
  let full_url = (build-url $base $"/jobs/($jobId)/files/output")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Returns file metadata.
#
# GET /jobs/{jobId}/files/{fileId}
# operationId: getJobFiles_1
export def "jobs-files get-by-jobId-fileId" [
  jobId: string
  fileId: int
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
  let full_url = (build-url $base $"/jobs/($jobId)/files/($fileId)")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates instructions for a job.
#
# PUT /jobs/{jobId}/instructions
# operationId: updateInstructions
export def "jobs-instructions updateInstructions" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forProvider: string
  --fromCustomer: string
  --internal: string
  --notes: string
  --paymentNoteForCustomer: string
  --paymentNoteForVendor: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/jobs/($jobId)/instructions")
  let body = {forProvider: $forProvider, fromCustomer: $fromCustomer, internal: $internal, notes: $notes, paymentNoteForCustomer: $paymentNoteForCustomer, paymentNoteForVendor: $paymentNoteForVendor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Changes job status if possible (400 Bad Request is returned otherwise).
#
# PUT /jobs/{jobId}/status
# operationId: changeStatus
export def "jobs-status changeStatus" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --externalId: string
  --status: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/jobs/($jobId)/status")
  let body = {externalId: $externalId, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Assigns vendor to a job in a project.
#
# PUT /jobs/{jobId}/vendor
# operationId: assignVendor
export def "jobs-vendor assignVendor" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --recalculateRates: oneof<nothing, bool>
  --vendorPriceProfileId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/jobs/($jobId)/vendor")
  let body = {recalculateRates: $recalculateRates, vendorPriceProfileId: $vendorPriceProfileId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
export def "macros-run run" [
  macroId: int
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
  let full_url = (build-url $base $"/macros/($macroId)/run")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
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
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Downloads a file.
#
# GET /projects/files/{fileId}/download
# operationId: getFileById
export def "projects-files-download list" [
  fileId: string
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
  let full_url = (build-url $base $"/projects/files/($fileId)/download")
  let accept_val = "multipart/form-data"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns projects' internal identifiers.
#
# GET /projects/ids
# operationId: getAllIds_6
export def "projects-ids get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updatedSince: int # only projects modified since this timestamp (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updatedSince "scalar")] | flatten | str join "&"
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
  projectId: string
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
  let full_url = (build-url $base $"/projects/($projectId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns project details.
#
# GET /projects/{projectId}
# operationId: getById_7
export def "projects get-by-projectId-by-projectId" [
  projectId: string
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
  let full_url = (build-url $base $"/projects/($projectId)" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns contacts of a given project.
#
# GET /projects/{projectId}/contacts
# operationId: getContacts
export def "projects-contacts get" [
  projectId: string
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
  let full_url = (build-url $base $"/projects/($projectId)/contacts")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates contacts of a given project.
#
# PUT /projects/{projectId}/contacts
# operationId: updateContacts
export def "projects-contacts updateContacts" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additionalIds: list
  --primaryId: int # format: int64
  --sendBackToId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/contacts")
  let body = {additionalIds: $additionalIds, primaryId: $primaryId, sendBackToId: $sendBackToId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns custom fields of a given project.
#
# GET /projects/{projectId}/customFields
# operationId: getCustomFields_5
export def "projects-custom-fields get-by-projectId-by-projectId" [
  projectId: string
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
  let full_url = (build-url $base $"/projects/($projectId)/customFields")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates custom fields of a given project.
#
# PUT /projects/{projectId}/customFields
# operationId: updateCustomFields_3
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
export def "projects-custom-fields updateCustomFields-by-projectId" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customFields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/customFields")
  let body = {customFields: $customFields, empty: $empty} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns dates of a given project.
#
# GET /projects/{projectId}/dates
# operationId: getDates_1
export def "projects-dates get-by-projectId" [
  projectId: string
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
  let full_url = (build-url $base $"/projects/($projectId)/dates")
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
export def "projects-dates updateDates-by-projectId" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actualDeliveryDate: record # shape: {value?: int}
  --actualStartDate: record # shape: {value?: int}
  --deadline: record # shape: {value?: int}
  --startDate: record # shape: {value?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/dates")
  let body = {actualDeliveryDate: $actualDeliveryDate, actualStartDate: $actualStartDate, deadline: $deadline, startDate: $startDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns finance of a given project.
#
# GET /projects/{projectId}/finance
# operationId: getFinance
export def "projects-finance get" [
  projectId: string
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
  let full_url = (build-url $base $"/projects/($projectId)/finance")
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
export def "projects-finance-payables createPayable" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculationUnitId: int # format: int64
  --catLogFile: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currencyId: int # format: int64
  --description: string
  --id: int # format: int64
  --ignoreMinimumCharge: oneof<nothing, bool>
  --invoiceId: string
  --jobId: record
  --jobTypeId: int # format: int64
  --languageCombination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --languageCombinationIdNumber: string
  --minimumCharge: float
  --quantity: float
  --rate: float
  --rateOrigin: string@rateOrigin-completer
  --total: float
  --type: string@type-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/finance/payables")
  let body = {calculationUnitId: $calculationUnitId, catLogFile: $catLogFile, currencyId: $currencyId, description: $description, id: $id, ignoreMinimumCharge: $ignoreMinimumCharge, invoiceId: $invoiceId, jobId: $jobId, jobTypeId: $jobTypeId, languageCombination: $languageCombination, languageCombinationIdNumber: $languageCombinationIdNumber, minimumCharge: $minimumCharge, quantity: $quantity, rate: $rate, rateOrigin: $rateOrigin, total: $total, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a payable.
#
# DELETE /projects/{projectId}/finance/payables/{payableId}
# operationId: deletePayable
export def "projects-finance-payables delete" [
  projectId: string
  payableId: int
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
  let full_url = (build-url $base $"/projects/($projectId)/finance/payables/($payableId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a payable.
#
# PUT /projects/{projectId}/finance/payables/{payableId}
# operationId: updatePayable
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "projects-finance-payables updatePayable" [
  projectId: string
  payableId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculationUnitId: int # format: int64
  --currencyId: int # format: int64
  --description: string
  --id: int # format: int64
  --ignoreMinimumCharge: oneof<nothing, bool>
  --invoiceId: string
  --jobId: record
  --jobTypeId: int # format: int64
  --languageCombination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --languageCombinationIdNumber: string
  --minimumCharge: float
  --quantity: float
  --rate: float
  --rateOrigin: string@rateOrigin-completer
  --total: float
  --type: string@type-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/finance/payables/($payableId)")
  let body = {calculationUnitId: $calculationUnitId, currencyId: $currencyId, description: $description, id: $id, ignoreMinimumCharge: $ignoreMinimumCharge, invoiceId: $invoiceId, jobId: $jobId, jobTypeId: $jobTypeId, languageCombination: $languageCombination, languageCombinationIdNumber: $languageCombinationIdNumber, minimumCharge: $minimumCharge, quantity: $quantity, rate: $rate, rateOrigin: $rateOrigin, total: $total, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds a receivable to a project.
#
# POST /projects/{projectId}/finance/receivables
# operationId: createReceivable
# --catLogFile shape: {content?: string, name?: string, token?: string, url?: string}
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "projects-finance-receivables createReceivable" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculationUnitId: int # format: int64
  --catLogFile: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currencyId: int # format: int64
  --description: string
  --id: int # format: int64
  --ignoreMinimumCharge: oneof<nothing, bool>
  --invoiceId: string
  --jobTypeId: int # format: int64
  --languageCombination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --languageCombinationIdNumber: string
  --minimumCharge: float
  --quantity: float
  --rate: float
  --rateOrigin: string@rateOrigin-completer
  --taskId: int # format: int64
  --total: float
  --type: string@type-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/finance/receivables")
  let body = {calculationUnitId: $calculationUnitId, catLogFile: $catLogFile, currencyId: $currencyId, description: $description, id: $id, ignoreMinimumCharge: $ignoreMinimumCharge, invoiceId: $invoiceId, jobTypeId: $jobTypeId, languageCombination: $languageCombination, languageCombinationIdNumber: $languageCombinationIdNumber, minimumCharge: $minimumCharge, quantity: $quantity, rate: $rate, rateOrigin: $rateOrigin, taskId: $taskId, total: $total, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a receivable.
#
# DELETE /projects/{projectId}/finance/receivables/{receivableId}
# operationId: deleteReceivable
export def "projects-finance-receivables delete" [
  projectId: string
  receivableId: int
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
  let full_url = (build-url $base $"/projects/($projectId)/finance/receivables/($receivableId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a receivable.
#
# PUT /projects/{projectId}/finance/receivables/{receivableId}
# operationId: updateReceivable
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "projects-finance-receivables updateReceivable" [
  projectId: string
  receivableId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculationUnitId: int # format: int64
  --currencyId: int # format: int64
  --description: string
  --id: int # format: int64
  --ignoreMinimumCharge: oneof<nothing, bool>
  --invoiceId: string
  --jobTypeId: int # format: int64
  --languageCombination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --languageCombinationIdNumber: string
  --minimumCharge: float
  --quantity: float
  --rate: float
  --rateOrigin: string@rateOrigin-completer
  --taskId: int # format: int64
  --total: float
  --type: string@type-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/finance/receivables/($receivableId)")
  let body = {calculationUnitId: $calculationUnitId, currencyId: $currencyId, description: $description, id: $id, ignoreMinimumCharge: $ignoreMinimumCharge, invoiceId: $invoiceId, jobTypeId: $jobTypeId, languageCombination: $languageCombination, languageCombinationIdNumber: $languageCombinationIdNumber, minimumCharge: $minimumCharge, quantity: $quantity, rate: $rate, rateOrigin: $rateOrigin, taskId: $taskId, total: $total, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns instructions of a given project.
#
# GET /projects/{projectId}/instructions
# operationId: getInstructions
export def "projects-instructions get" [
  projectId: string
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
  let full_url = (build-url $base $"/projects/($projectId)/instructions")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates instructions of a given project.
#
# PUT /projects/{projectId}/instructions
# operationId: updateInstructions_1
export def "projects-instructions updateInstructions-by-projectId" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forProvider: string
  --fromCustomer: string
  --internal: string
  --notes: string
  --paymentNoteForCustomer: string
  --paymentNoteForVendor: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/instructions")
  let body = {forProvider: $forProvider, fromCustomer: $fromCustomer, internal: $internal, notes: $notes, paymentNoteForCustomer: $paymentNoteForCustomer, paymentNoteForVendor: $paymentNoteForVendor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new language combination for a given project without creating a task.
#
# POST /projects/{projectId}/languageCombinations
# operationId: createLanguageCombination
export def "projects-language-combinations createLanguageCombination" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sourceLanguageId: int # format: int64
  --targetLanguageId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/languageCombinations")
  let body = {sourceLanguageId: $sourceLanguageId, targetLanguageId: $targetLanguageId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
export def "projects-tasks createTask" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientTaskPONumber: string # client task PO number
  --dates: record # shape: {actualDeliveryDate?: record, actualStartDate?: record, deadline?: record, startDate?: record}
  --files: list # files — item shape: {category?: "WORKFILE"|"TM"|"DICTIONARY"|"REF"|"LOG_FILE", content?: string, name?: string, token?: string, url?: string}
  --instructions: record # shape: {forProvider?: string, fromCustomer?: string, internal?: string, notes?: string, paymentNoteForCustomer?: string, paymentNoteForVendor?: string}
  --languageCombination: record # language combination (ie. PL -> EN) — shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --name: string # name
  --people: record # people — shape: {customerContacts?: record, responsiblePersons?: record}
  --specializationId: int # specialization (format: int64)
  --workflowId: int # workflow (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/tasks")
  let body = {clientTaskPONumber: $clientTaskPONumber, dates: $dates, files: $files, instructions: $instructions, languageCombination: $languageCombination, name: $name, people: $people, specializationId: $specializationId, workflowId: $workflowId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns providers' internal identifiers.
#
# GET /providers/ids
# operationId: getAllIds_5
export def "providers-ids get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updatedSince: int # only providers modified since this timestamp (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updatedSince "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/ids" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns persons' internal identifiers.
#
# GET /providers/persons/ids
# operationId: getAllIds_4
export def "providers-persons-ids get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updatedSince: int # only persons modified since this timestamp (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updatedSince "scalar")] | flatten | str join "&"
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
  personId: int
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
  let full_url = (build-url $base $"/providers/persons/($personId)")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns person details.
#
# GET /providers/persons/{personId}
# operationId: getById_4
export def "providers-persons get-by-personId" [
  personId: int
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
  let full_url = (build-url $base $"/providers/persons/($personId)")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns contact of a given person.
#
# GET /providers/persons/{personId}/contact
# operationId: getContact_2
export def "providers-persons-contact get-by-personId" [
  personId: int
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
  let full_url = (build-url $base $"/providers/persons/($personId)/contact")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns custom fields of a given person.
#
# GET /providers/persons/{personId}/customFields
# operationId: getCustomFields_2
export def "providers-persons-custom-fields get-by-personId" [
  personId: int
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
  let full_url = (build-url $base $"/providers/persons/($personId)/customFields")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sends invitation to Vendor Portal.
#
# POST /providers/persons/{personId}/notification/invitation
# operationId: sendInvitations
export def "providers-persons-notification-invitation sendInvitations" [
  personId: int
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
  let full_url = (build-url $base $"/providers/persons/($personId)/notification/invitation")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a provider price list.
#
# DELETE /providers/priceLists/{priceListId}
# operationId: delete_9
export def "providers-price-lists delete-by-priceListId" [
  priceListId: int
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
  let full_url = (build-url $base $"/providers/priceLists/($priceListId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a provider.
#
# DELETE /providers/{providerId}
# operationId: delete_10
export def "providers delete-by-providerId" [
  providerId: int
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
  let full_url = (build-url $base $"/providers/($providerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns provider details.
#
# GET /providers/{providerId}
# operationId: getById_5
export def "providers get-by-providerId" [
  providerId: int
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
  let full_url = (build-url $base $"/providers/($providerId)" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns address of a given provider.
#
# GET /providers/{providerId}/address
# operationId: getAddress_1
export def "providers-address get-by-providerId" [
  providerId: int
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
  let full_url = (build-url $base $"/providers/($providerId)/address")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns competencies of a given provider.
#
# GET /providers/{providerId}/competencies
# operationId: getCompetencies
export def "providers-competencies get" [
  providerId: int
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
  let full_url = (build-url $base $"/providers/($providerId)/competencies")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns contact of a given provider.
#
# GET /providers/{providerId}/contact
# operationId: getContact_3
export def "providers-contact get-by-providerId" [
  providerId: int
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
  let full_url = (build-url $base $"/providers/($providerId)/contact")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns correspondence address of a given provider.
#
# GET /providers/{providerId}/correspondenceAddress
# operationId: getCorrespondenceAddress_1
export def "providers-correspondence-address get-by-providerId" [
  providerId: int
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
  let full_url = (build-url $base $"/providers/($providerId)/correspondenceAddress")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns custom fields of a given provider.
#
# GET /providers/{providerId}/customFields
# operationId: getCustomFields_3
export def "providers-custom-fields get-by-providerId" [
  providerId: int
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
  let full_url = (build-url $base $"/providers/($providerId)/customFields")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sends invitations to Vendor Portal.
#
# POST /providers/{providerId}/notification/invitation
# operationId: sendInvitations_1
export def "providers-notification-invitation sendInvitations-by-providerId" [
  providerId: int
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
  let full_url = (build-url $base $"/providers/($providerId)/notification/invitation")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns quotes' internal identifiers.
#
# GET /quotes/ids
# operationId: getAllIds_7
export def "quotes-ids get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updatedSince: int # only quotes modified since this timestamp (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updatedSince "scalar")] | flatten | str join "&"
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
  quoteId: string
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
  let full_url = (build-url $base $"/quotes/($quoteId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns quote details.
#
# GET /quotes/{quoteId}
# operationId: getById_8
export def "quotes get-by-quoteId-by-quoteId" [
  quoteId: string
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
  let full_url = (build-url $base $"/quotes/($quoteId)" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sends a quote for customer confirmation.
#
# POST /quotes/{quoteId}/confirmation/send
# operationId: send_1
export def "quotes-confirmation-send send-by-quoteId" [
  quoteId: string
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
  let full_url = (build-url $base $"/quotes/($quoteId)/confirmation/send")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns custom fields of a given quote.
#
# GET /quotes/{quoteId}/customFields
# operationId: getCustomFields_6
export def "quotes-custom-fields get-by-quoteId-by-quoteId" [
  quoteId: string
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
  let full_url = (build-url $base $"/quotes/($quoteId)/customFields")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates custom fields of a given quote.
#
# PUT /quotes/{quoteId}/customFields
# operationId: updateCustomFields_4
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
export def "quotes-custom-fields updateCustomFields-by-quoteId" [
  quoteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customFields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/quotes/($quoteId)/customFields")
  let body = {customFields: $customFields, empty: $empty} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns dates of a given quote.
#
# GET /quotes/{quoteId}/dates
# operationId: getDates_2
export def "quotes-dates get-by-quoteId" [
  quoteId: string
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
  let full_url = (build-url $base $"/quotes/($quoteId)/dates")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns finance of a given quote.
#
# GET /quotes/{quoteId}/finance
# operationId: getFinance_1
export def "quotes-finance get-by-quoteId-by-quoteId" [
  quoteId: string
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
  let full_url = (build-url $base $"/quotes/($quoteId)/finance")
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
export def "quotes-finance-payables createPayable-by-quoteId-by-quoteId" [
  quoteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculationUnitId: int # format: int64
  --catLogFile: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currencyId: int # format: int64
  --description: string
  --id: int # format: int64
  --ignoreMinimumCharge: oneof<nothing, bool>
  --invoiceId: string
  --jobId: record
  --jobTypeId: int # format: int64
  --languageCombination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --languageCombinationIdNumber: string
  --minimumCharge: float
  --quantity: float
  --rate: float
  --rateOrigin: string@rateOrigin-completer
  --total: float
  --type: string@type-completer-1
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/quotes/($quoteId)/finance/payables")
  let body = {calculationUnitId: $calculationUnitId, catLogFile: $catLogFile, currencyId: $currencyId, description: $description, id: $id, ignoreMinimumCharge: $ignoreMinimumCharge, invoiceId: $invoiceId, jobId: $jobId, jobTypeId: $jobTypeId, languageCombination: $languageCombination, languageCombinationIdNumber: $languageCombinationIdNumber, minimumCharge: $minimumCharge, quantity: $quantity, rate: $rate, rateOrigin: $rateOrigin, total: $total, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a payable.
#
# DELETE /quotes/{quoteId}/finance/payables/{payableId}
# operationId: deletePayable_1
export def "quotes-finance-payables delete-by-quoteId-payableId-by-quoteId-payableId" [
  quoteId: string
  payableId: int
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
  let full_url = (build-url $base $"/quotes/($quoteId)/finance/payables/($payableId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a payable.
#
# PUT /quotes/{quoteId}/finance/payables/{payableId}
# operationId: updatePayable_1
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-payables updatePayable-by-quoteId-payableId-by-quoteId-payableId" [
  quoteId: string
  payableId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculationUnitId: int # format: int64
  --currencyId: int # format: int64
  --description: string
  --id: int # format: int64
  --ignoreMinimumCharge: oneof<nothing, bool>
  --invoiceId: string
  --jobId: record
  --jobTypeId: int # format: int64
  --languageCombination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --languageCombinationIdNumber: string
  --minimumCharge: float
  --quantity: float
  --rate: float
  --rateOrigin: string@rateOrigin-completer
  --total: float
  --type: string@type-completer-1
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/quotes/($quoteId)/finance/payables/($payableId)")
  let body = {calculationUnitId: $calculationUnitId, currencyId: $currencyId, description: $description, id: $id, ignoreMinimumCharge: $ignoreMinimumCharge, invoiceId: $invoiceId, jobId: $jobId, jobTypeId: $jobTypeId, languageCombination: $languageCombination, languageCombinationIdNumber: $languageCombinationIdNumber, minimumCharge: $minimumCharge, quantity: $quantity, rate: $rate, rateOrigin: $rateOrigin, total: $total, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds a receivable.
#
# POST /quotes/{quoteId}/finance/receivables
# operationId: createReceivable_1
# --catLogFile shape: {content?: string, name?: string, token?: string, url?: string}
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-receivables createReceivable-by-quoteId-by-quoteId" [
  quoteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculationUnitId: int # format: int64
  --catLogFile: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currencyId: int # format: int64
  --description: string
  --id: int # format: int64
  --ignoreMinimumCharge: oneof<nothing, bool>
  --invoiceId: string
  --jobTypeId: int # format: int64
  --languageCombination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --languageCombinationIdNumber: string
  --minimumCharge: float
  --quantity: float
  --rate: float
  --rateOrigin: string@rateOrigin-completer
  --taskId: int # format: int64
  --total: float
  --type: string@type-completer-1
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/quotes/($quoteId)/finance/receivables")
  let body = {calculationUnitId: $calculationUnitId, catLogFile: $catLogFile, currencyId: $currencyId, description: $description, id: $id, ignoreMinimumCharge: $ignoreMinimumCharge, invoiceId: $invoiceId, jobTypeId: $jobTypeId, languageCombination: $languageCombination, languageCombinationIdNumber: $languageCombinationIdNumber, minimumCharge: $minimumCharge, quantity: $quantity, rate: $rate, rateOrigin: $rateOrigin, taskId: $taskId, total: $total, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a receivable.
#
# DELETE /quotes/{quoteId}/finance/receivables/{receivableId}
# operationId: deleteReceivable_1
export def "quotes-finance-receivables delete-by-quoteId-receivableId-by-quoteId-receivableId" [
  quoteId: string
  receivableId: int
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
  let full_url = (build-url $base $"/quotes/($quoteId)/finance/receivables/($receivableId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a receivable.
#
# PUT /quotes/{quoteId}/finance/receivables/{receivableId}
# operationId: updateReceivable_1
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-receivables updateReceivable-by-quoteId-receivableId-by-quoteId-receivableId" [
  quoteId: string
  receivableId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculationUnitId: int # format: int64
  --currencyId: int # format: int64
  --description: string
  --id: int # format: int64
  --ignoreMinimumCharge: oneof<nothing, bool>
  --invoiceId: string
  --jobTypeId: int # format: int64
  --languageCombination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --languageCombinationIdNumber: string
  --minimumCharge: float
  --quantity: float
  --rate: float
  --rateOrigin: string@rateOrigin-completer
  --taskId: int # format: int64
  --total: float
  --type: string@type-completer-1
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/quotes/($quoteId)/finance/receivables/($receivableId)")
  let body = {calculationUnitId: $calculationUnitId, currencyId: $currencyId, description: $description, id: $id, ignoreMinimumCharge: $ignoreMinimumCharge, invoiceId: $invoiceId, jobTypeId: $jobTypeId, languageCombination: $languageCombination, languageCombinationIdNumber: $languageCombinationIdNumber, minimumCharge: $minimumCharge, quantity: $quantity, rate: $rate, rateOrigin: $rateOrigin, taskId: $taskId, total: $total, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns instructions of a given quote.
#
# GET /quotes/{quoteId}/instructions
# operationId: getInstructions_1
export def "quotes-instructions get-by-quoteId" [
  quoteId: string
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
  let full_url = (build-url $base $"/quotes/($quoteId)/instructions")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates instructions of a given quote.
#
# PUT /quotes/{quoteId}/instructions
# operationId: updateInstructions_2
export def "quotes-instructions updateInstructions-by-quoteId" [
  quoteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forProvider: string
  --fromCustomer: string
  --internal: string
  --notes: string
  --paymentNoteForCustomer: string
  --paymentNoteForVendor: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/quotes/($quoteId)/instructions")
  let body = {forProvider: $forProvider, fromCustomer: $fromCustomer, internal: $internal, notes: $notes, paymentNoteForCustomer: $paymentNoteForCustomer, paymentNoteForVendor: $paymentNoteForVendor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new language combination for a given quote without creating a task.
#
# POST /quotes/{quoteId}/languageCombinations
# operationId: createLanguageCombination_1
export def "quotes-language-combinations createLanguageCombination-by-quoteId" [
  quoteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sourceLanguageId: int # format: int64
  --targetLanguageId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/quotes/($quoteId)/languageCombinations")
  let body = {sourceLanguageId: $sourceLanguageId, targetLanguageId: $targetLanguageId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Starts a quote.
#
# POST /quotes/{quoteId}/start
# operationId: start
export def "quotes-start start" [
  quoteId: string
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
  let full_url = (build-url $base $"/quotes/($quoteId)/start")
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
# --jobs shape: {jobCount?: int, jobIds?: list}
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
# --people shape: {customerContacts?: record, responsiblePersons?: record}
export def "quotes-tasks createTask-by-quoteId" [
  quoteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientTaskPONumber: string # client task PO number
  --customFields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --dates: record # shape: {actualDeliveryDate?: record, actualStartDate?: record, deadline?: record, startDate?: record}
  --finance: record # finance — shape: {invoiceable?: bool}
  --id: int # internal identifier (format: int64)
  --idNumber: string # identifier
  --instructions: record # shape: {forProvider?: string, fromCustomer?: string, internal?: string, notes?: string, paymentNoteForCustomer?: string, paymentNoteForVendor?: string}
  --jobs: record # shape: {jobCount?: int, jobIds?: list}
  --languageCombination: record # language combination (ie. PL -> EN) — shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --name: string # name
  --people: record # people — shape: {customerContacts?: record, responsiblePersons?: record}
  --projectId: int # project's internal identifier (format: int64)
  --body-quoteId: int # quote's internal identifier (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/quotes/($quoteId)/tasks")
  let body = {clientTaskPONumber: $clientTaskPONumber, customFields: $customFields, dates: $dates, finance: $finance, id: $id, idNumber: $idNumber, instructions: $instructions, jobs: $jobs, languageCombination: $languageCombination, name: $name, people: $people, projectId: $projectId, quoteId: $body_quoteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Exports reports definition to XML.
#
# POST /reports/export/xml
# operationId: exportToXML
export def "reports-export-xml exportToXML" [
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
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Imports reports definition from XML.
#
# POST /reports/import/xml
# operationId: importFromXML
export def "reports-import-xml importFromXML" [
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
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Removes a report.
#
# DELETE /reports/{reportId}
# operationId: delete_11
export def "reports delete-by-reportId" [
  reportId: int
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
  let full_url = (build-url $base $"/reports/($reportId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Duplicates a report.
#
# POST /reports/{reportId}/duplicate
# operationId: duplicate_1
export def "reports-duplicate duplicate-by-reportId" [
  reportId: int
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
  let full_url = (build-url $base $"/reports/($reportId)/duplicate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Marks report as preferred or not.
#
# PUT /reports/{reportId}/preferred
# operationId: setPreferred
export def "reports-preferred setPreferred" [
  reportId: int
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
  let full_url = (build-url $base $"/reports/($reportId)/preferred")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Generates CSV content for a report.
#
# GET /reports/{reportId}/result/csv
# operationId: generateCSV
export def "reports-result-csv generateCSV" [
  reportId: int
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
  let full_url = (build-url $base $"/reports/($reportId)/result/csv")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generates printer friendly content for a report.
#
# GET /reports/{reportId}/result/printerFriendly
# operationId: generatePrinterFriendly
export def "reports-result-printer-friendly generatePrinterFriendly" [
  reportId: int
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
  let full_url = (build-url $base $"/reports/($reportId)/result/printerFriendly")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns active services list
#
# GET /services/active
# operationId: getAllActive
export def "services-active get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --nameEquals: string # exact name of entity
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nameEquals" $nameEquals "scalar")] | flatten | str join "&"
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
  --nameEquals: string # exact name of entity
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nameEquals" $nameEquals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/services/all" $qp)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns all subscriptions
#
# GET /subscription
# operationId: getAll_4
export def "subscription get-by-" [
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
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# This method can be used to determine if hooks are supported.
#
# GET /subscription/supports
# operationId: areHooksSupported
export def "subscription-supports areHooksSupported" [
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
  subscriptionId: string
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
  let full_url = (build-url $base $"/subscription/($subscriptionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a task.
#
# DELETE /tasks/{taskId}
# operationId: delete_14
export def "tasks delete-by-taskId" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --removeFilesFromDisc: oneof<nothing, bool> # remove files from disc
  --removeExternalProjects: oneof<nothing, bool> # remove external projects (ie. from CAT Tool)
  --forceJobsRemoval: oneof<nothing, bool> # force jobs removal (ie. started or ready)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "removeFilesFromDisc" $removeFilesFromDisc "scalar") (serialize-qp "removeExternalProjects" $removeExternalProjects "scalar") (serialize-qp "forceJobsRemoval" $forceJobsRemoval "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tasks/($taskId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates Client Task PO Number of a given task.
#
# PUT /tasks/{taskId}/clientTaskPONumber
# operationId: updateClientTaskPONumber
export def "tasks-client-task-po-number updateClientTaskPONumber" [
  taskId: string
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
  let full_url = (build-url $base $"/tasks/($taskId)/clientTaskPONumber")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns contacts of a given task.
#
# GET /tasks/{taskId}/contacts
# operationId: getContacts_1
export def "tasks-contacts get-by-taskId" [
  taskId: string
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
  let full_url = (build-url $base $"/tasks/($taskId)/contacts")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates contacts of a given task.
#
# PUT /tasks/{taskId}/contacts
# operationId: updateContacts_1
export def "tasks-contacts updateContacts-by-taskId" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additionalIds: list
  --primaryId: int # format: int64
  --sendBackToId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskId)/contacts")
  let body = {additionalIds: $additionalIds, primaryId: $primaryId, sendBackToId: $sendBackToId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns custom fields of a given task.
#
# GET /tasks/{taskId}/customFields
# operationId: getCustomFields_7
export def "tasks-custom-fields get-by-taskId" [
  taskId: string
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
  let full_url = (build-url $base $"/tasks/($taskId)/customFields")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates custom fields of a given task.
#
# PUT /tasks/{taskId}/customFields
# operationId: updateCustomFields_5
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
export def "tasks-custom-fields updateCustomFields-by-taskId" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customFields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskId)/customFields")
  let body = {customFields: $customFields, empty: $empty} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns dates of a given task.
#
# GET /tasks/{taskId}/dates
# operationId: getDates_3
export def "tasks-dates get-by-taskId" [
  taskId: string
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
  let full_url = (build-url $base $"/tasks/($taskId)/dates")
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
export def "tasks-dates updateDates-by-taskId" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actualDeliveryDate: record # shape: {value?: int}
  --actualStartDate: record # shape: {value?: int}
  --deadline: record # shape: {value?: int}
  --startDate: record # shape: {value?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskId)/dates")
  let body = {actualDeliveryDate: $actualDeliveryDate, actualStartDate: $actualStartDate, deadline: $deadline, startDate: $startDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns lists of files of a given task.
#
# GET /tasks/{taskId}/files
# operationId: getTaskFiles
export def "tasks-files get" [
  taskId: string
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
  let full_url = (build-url $base $"/tasks/($taskId)/files")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds files to a given task.
#
# POST /tasks/{taskId}/files/input
# operationId: addFile
export def "tasks-files-input addFile" [
  taskId: string
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
  --body-url: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskId)/files/input")
  let body = {content: $content, name: $name, token: $body_token, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns instructions of a given task.
#
# GET /tasks/{taskId}/instructions
# operationId: getInstructions_2
export def "tasks-instructions get-by-taskId" [
  taskId: string
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
  let full_url = (build-url $base $"/tasks/($taskId)/instructions")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates instructions of a given task.
#
# PUT /tasks/{taskId}/instructions
# operationId: updateInstructions_3
export def "tasks-instructions updateInstructions-by-taskId" [
  taskId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forProvider: string
  --fromCustomer: string
  --internal: string
  --notes: string
  --paymentNoteForCustomer: string
  --paymentNoteForVendor: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tasks/($taskId)/instructions")
  let body = {forProvider: $forProvider, fromCustomer: $fromCustomer, internal: $internal, notes: $notes, paymentNoteForCustomer: $paymentNoteForCustomer, paymentNoteForVendor: $paymentNoteForVendor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates name of a given task.
#
# PUT /tasks/{taskId}/name
# operationId: updateName
export def "tasks-name updateName" [
  taskId: string
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
  let full_url = (build-url $base $"/tasks/($taskId)/name")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns progress of a given task.
#
# GET /tasks/{taskId}/progress
# operationId: getProgress
export def "tasks-progress get" [
  taskId: string
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
  let full_url = (build-url $base $"/tasks/($taskId)/progress")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Starts a task.
#
# POST /tasks/{taskId}/start
# operationId: start_1
export def "tasks-start start-by-taskId" [
  taskId: string
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
  let full_url = (build-url $base $"/tasks/($taskId)/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns list of simple users representations
#
# GET /users
# operationId: getAllNamesWithIds_1
export def "users get-by-" [
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
  userId: int
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
  let full_url = (build-url $base $"/users/($userId)")
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
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customFields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --email: string
  --firstName: string
  --gender: string
  --id: int # format: int64
  --lastName: string
  --login: string
  --mobilePhone: string
  --phone: string
  --positionName: string
  --timeZoneId: string
  --userGroupName: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userId)")
  let body = {customFields: $customFields, email: $email, firstName: $firstName, gender: $gender, id: $id, lastName: $lastName, login: $login, mobilePhone: $mobilePhone, phone: $phone, positionName: $positionName, timeZoneId: $timeZoneId, userGroupName: $userGroupName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns custom fields of a given user.
#
# GET /users/{userId}/customFields
# operationId: getCustomFields_4
export def "users-custom-fields get-by-userId" [
  userId: int
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
  let full_url = (build-url $base $"/users/($userId)/customFields")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates custom fields of a given user.
#
# PUT /users/{userId}/customFields
# operationId: updateCustomFields_2
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
export def "users-custom-fields updateCustomFields-by-userId" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customFields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userId)/customFields")
  let body = {customFields: $customFields, empty: $empty} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns custom field of a given user.
#
# GET /users/{userId}/customFields/{customFieldKey}
# operationId: getCustomField_1
export def "users-custom-fields get-by-userId-customFieldKey" [
  userId: int
  customFieldKey: string
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
  let full_url = (build-url $base $"/users/($userId)/customFields/($customFieldKey)")
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates given custom field of a given user.
#
# PUT /users/{userId}/customFields/{customFieldKey}
# operationId: updateCustomField_1
export def "users-custom-fields updateCustomField-by-userId-customFieldKey" [
  userId: int
  customFieldKey: string
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
  let full_url = (build-url $base $"/users/($userId)/customFields/($customFieldKey)")
  let body = {key: $key, name: $name, type: $type, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sets user's password to a new value.
#
# PUT /users/{userId}/password
# operationId: changePassword
export def "users-password changePassword" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --newPassword: string # new password
  --oldPassword: string # old password
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($userId)/password")
  let body = {newPassword: $newPassword, oldPassword: $oldPassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
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
  --externalProjectId: string # job's externalProjectId
  --externalId: string # job's external identifier
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalProjectId" $externalProjectId "scalar") (serialize-qp "externalId" $externalId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/jobs/for-external-id" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns details for a job.
#
# GET /v2/jobs/{jobId}
# operationId: getFileById_1
export def "jobs get-by-jobId" [
  jobId: string
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
  let full_url = (build-url $base $"/v2/jobs/($jobId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates dates of a given job.
#
# PUT /v2/jobs/{jobId}/dates
# operationId: changeDates
export def "jobs-dates changeDates" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --actualEndDate: int # format: int64
  --actualStartDate: int # format: int64
  --deadline: int # format: int64
  --startDate: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/jobs/($jobId)/dates")
  let body = {actualEndDate: $actualEndDate, actualStartDate: $actualStartDate, deadline: $deadline, startDate: $startDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v2/jobs/{jobId}/files/addExternalLink
#
# operationId: addExternalFileLink
# --languageCombinationIds item shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "jobs-files-add-external-link addExternalFileLink" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string
  --externalInfo: record
  --filename: string
  --languageCombinationIds: list # item shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --languageIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/jobs/($jobId)/files/addExternalLink")
  let body = {category: $category, externalInfo: $externalInfo, filename: $filename, languageCombinationIds: $languageCombinationIds, languageIds: $languageIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns list of files delivered in the job.
#
# GET /v2/jobs/{jobId}/files/delivered
# operationId: getDeliveredFiles
export def "jobs-files-delivered get" [
  jobId: string
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
  let full_url = (build-url $base $"/v2/jobs/($jobId)/files/delivered")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds files to the project as delivered in the job.
#
# PUT /v2/jobs/{jobId}/files/delivered/add
# operationId: addFiles
# --files item shape: {category?: string, fileId?: string, languageCombinationIds?: list, languageIds?: list}
export def "jobs-files-delivered-add addFiles" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --files: list # item shape: {category?: string, fileId?: string, languageCombinationIds?: list, languageIds?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/jobs/($jobId)/files/delivered/add")
  let body = {files: $files} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds file link to the project as a link delivered in the job.
#
# POST /v2/jobs/{jobId}/files/delivered/addLink
# operationId: addFileLinks
# --fileLinks item shape: {category?: string, externalInfo?: record, filename?: string, languageCombinationIds?: list, languageIds?: list, toBeGenerated?: bool, url?: string}
export def "jobs-files-delivered-add-link addFileLinks" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fileLinks: list # item shape: {category?: string, externalInfo?: record, filename?: string, languageCombinationIds?: list, languageIds?: list, toBeGenerated?: bool, url?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/jobs/($jobId)/files/delivered/addLink")
  let body = {fileLinks: $fileLinks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Uploads file to the project as a file delivered in the job.
#
# POST /v2/jobs/{jobId}/files/delivered/upload
# operationId: uploadFile_1
export def "jobs-files-delivered-upload uploadFile-by-jobId" [
  jobId: string
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
  let full_url = (build-url $base $"/v2/jobs/($jobId)/files/delivered/upload")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Returns list of files shared with the job as Reference Files.
#
# GET /v2/jobs/{jobId}/files/sharedReferenceFiles
# operationId: getSharedReferenceFiles
export def "jobs-files-shared-reference-files get" [
  jobId: string
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
  let full_url = (build-url $base $"/v2/jobs/($jobId)/files/sharedReferenceFiles")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Shares selected files as Reference Files with a job in a project.
#
# PUT /v2/jobs/{jobId}/files/sharedReferenceFiles/share
# operationId: shareAsReferenceFiles
export def "jobs-files-shared-reference-files-share shareAsReferenceFiles" [
  jobId: string
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
  let full_url = (build-url $base $"/v2/jobs/($jobId)/files/sharedReferenceFiles/share")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Returns list of files shared with the job as Work Files.
#
# GET /v2/jobs/{jobId}/files/sharedWorkFiles
# operationId: getSharedWorkFiles
export def "jobs-files-shared-work-files get" [
  jobId: string
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
  let full_url = (build-url $base $"/v2/jobs/($jobId)/files/sharedWorkFiles")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Shares selected files as Work Files with a job in a project.
#
# PUT /v2/jobs/{jobId}/files/sharedWorkFiles/share
# operationId: shareAsWorkFiles
export def "jobs-files-shared-work-files-share shareAsWorkFiles" [
  jobId: string
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
  let full_url = (build-url $base $"/v2/jobs/($jobId)/files/sharedWorkFiles/share")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Stops sharing selected files with a job in a project.
#
# PUT /v2/jobs/{jobId}/files/stopSharing
# operationId: stopSharing
export def "jobs-files-stop-sharing stopSharing" [
  jobId: string
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
  let full_url = (build-url $base $"/v2/jobs/($jobId)/files/stopSharing")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Updates instructions for a job.
#
# PUT /v2/jobs/{jobId}/instructions
# operationId: updateInstructions_4
export def "jobs-instructions updateInstructions-by-jobId" [
  jobId: string
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
  let full_url = (build-url $base $"/v2/jobs/($jobId)/instructions")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Changes job status if possible (400 Bad Request is returned otherwise).
#
# PUT /v2/jobs/{jobId}/status
# operationId: changeStatus_1
export def "jobs-status changeStatus-by-jobId" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --externalId: string
  --status: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/jobs/($jobId)/status")
  let body = {externalId: $externalId, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Assigns vendor to a job in a project.
#
# PUT /v2/jobs/{jobId}/vendor
# operationId: assignVendor_1
export def "jobs-vendor assignVendor-by-jobId" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --vendorPriceProfileId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/jobs/($jobId)/vendor")
  let body = {vendorPriceProfileId: $vendorPriceProfileId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --clientId: int # format: int64
  --externalId: string
  --name: string
  --serviceId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects")
  let body = {clientId: $clientId, externalId: $externalId, name: $name, serviceId: $serviceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --files: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/files/archive")
  let body = {files: $files} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns details of a file.
#
# GET /v2/projects/files/{fileId}
# operationId: getFileById_2
export def "projects-files get-by-fileId" [
  fileId: string
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
  let full_url = (build-url $base $"/v2/projects/files/($fileId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Downloads a file content.
#
# GET /v2/projects/files/{fileId}/download/{fileName}
# operationId: getFileContentById
export def "projects-files-download get" [
  fileId: string
  fileName: string
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
  let full_url = (build-url $base $"/v2/projects/files/($fileId)/download/($fileName)")
  let accept_val = "multipart/form-data"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns project details.
#
# GET /v2/projects/for-external-id/{externalProjectId}
# operationId: getByExternalId_1
export def "projects-for-external-id get-by-externalProjectId" [
  externalProjectId: string
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
  let full_url = (build-url $base $"/v2/projects/for-external-id/($externalProjectId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns project details.
#
# GET /v2/projects/{projectId}
# operationId: getById_9
export def "projects get-by-projectId-by-projectId-1" [
  projectId: string
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
  let full_url = (build-url $base $"/v2/projects/($projectId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns process id.
#
# POST /v2/projects/{projectId}/addJob
# operationId: addJobToProcess
export def "projects-add-job addJobToProcess" [
  projectId: string
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/addJob")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns if cat tool project is created or queued.
#
# GET /v2/projects/{projectId}/catToolProject
# operationId: getCATToolProjectInfo
export def "projects-cat-tool-project get" [
  projectId: string
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/catToolProject")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns Client Contacts information for a project.
#
# GET /v2/projects/{projectId}/clientContacts
# operationId: getContacts_2
export def "projects-client-contacts get-by-projectId" [
  projectId: string
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/clientContacts")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates Client Contacts for a project.
#
# PUT /v2/projects/{projectId}/clientContacts
# operationId: updateContacts_2
export def "projects-client-contacts updateContacts-by-projectId" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additionalIds: list
  --primaryId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/clientContacts")
  let body = {additionalIds: $additionalIds, primaryId: $primaryId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates Client Deadline for a project.
#
# PUT /v2/projects/{projectId}/clientDeadline
# operationId: updateClientDeadline
export def "projects-client-deadline updateClientDeadline" [
  projectId: string
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/clientDeadline")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates Client Notes for a project.
#
# PUT /v2/projects/{projectId}/clientNotes
# operationId: updateClientNotes
export def "projects-client-notes updateClientNotes" [
  projectId: string
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/clientNotes")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates Client Reference Number for a project.
#
# PUT /v2/projects/{projectId}/clientReferenceNumber
# operationId: updateClientReferenceNumber
export def "projects-client-reference-number updateClientReferenceNumber" [
  projectId: string
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/clientReferenceNumber")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of custom field keys and values for a project.
#
# GET /v2/projects/{projectId}/customFields
# operationId: getCustomFields_8
export def "projects-custom-fields get-by-projectId-by-projectId-1" [
  projectId: string
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/customFields")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a custom field with a specified key in a project
#
# PUT /v2/projects/{projectId}/customFields/{key}
# operationId: updateCustomField_2
export def "projects-custom-fields updateCustomField-by-projectId-key" [
  projectId: string
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/customFields/($key)")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns list of files in a project.
#
# GET /v2/projects/{projectId}/files
# operationId: getFiles
export def "projects-files get" [
  projectId: string
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/files")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds files to the project as added by PM.
#
# PUT /v2/projects/{projectId}/files/add
# operationId: addFiles_1
# --files item shape: {category?: string, fileId?: string, languageCombinationIds?: list, languageIds?: list}
export def "projects-files-add addFiles-by-projectId" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --files: list # item shape: {category?: string, fileId?: string, languageCombinationIds?: list, languageIds?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/files/add")
  let body = {files: $files} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v2/projects/{projectId}/files/addExternalLink
#
# operationId: addExternalFileLinks
# --languageCombinationIds item shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "projects-files-add-external-link addExternalFileLinks" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string
  --externalInfo: record
  --filename: string
  --languageCombinationIds: list # item shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --languageIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/files/addExternalLink")
  let body = {category: $category, externalInfo: $externalInfo, filename: $filename, languageCombinationIds: $languageCombinationIds, languageIds: $languageIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds file links to the project as added by PM.
#
# POST /v2/projects/{projectId}/files/addLink
# operationId: addFileLinks_1
# --fileLinks item shape: {category?: string, externalInfo?: record, filename?: string, languageCombinationIds?: list, languageIds?: list, toBeGenerated?: bool, url?: string}
export def "projects-files-add-link addFileLinks-by-projectId" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fileLinks: list # item shape: {category?: string, externalInfo?: record, filename?: string, languageCombinationIds?: list, languageIds?: list, toBeGenerated?: bool, url?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/files/addLink")
  let body = {fileLinks: $fileLinks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns list of files in a project, that are ready to be delivered to client.
#
# GET /v2/projects/{projectId}/files/deliverable
# operationId: getDeliverableFiles
export def "projects-files-deliverable get" [
  projectId: string
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/files/deliverable")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Uploads file to the project as a file uploaded by PM.
#
# POST /v2/projects/{projectId}/files/upload
# operationId: uploadFile_2
export def "projects-files-upload uploadFile-by-projectId" [
  projectId: string
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/files/upload")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Returns finance information for a project.
#
# GET /v2/projects/{projectId}/finance
# operationId: getFinance_2
export def "projects-finance get-by-projectId" [
  projectId: string
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/finance")
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
export def "projects-finance-payables createPayable-by-projectId" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculationUnitId: int # format: int64
  --catLogFile: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currencyId: int # format: int64
  --description: string
  --id: int # format: int64
  --ignoreMinimumCharge: oneof<nothing, bool>
  --invoiceId: string
  --jobId: record
  --jobTypeId: int # format: int64
  --languageCombination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --languageCombinationIdNumber: string
  --minimumCharge: float
  --quantity: float
  --rate: float
  --rateOrigin: string@rateOrigin-completer
  --total: float
  --type: string@type-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/finance/payables")
  let body = {calculationUnitId: $calculationUnitId, catLogFile: $catLogFile, currencyId: $currencyId, description: $description, id: $id, ignoreMinimumCharge: $ignoreMinimumCharge, invoiceId: $invoiceId, jobId: $jobId, jobTypeId: $jobTypeId, languageCombination: $languageCombination, languageCombinationIdNumber: $languageCombinationIdNumber, minimumCharge: $minimumCharge, quantity: $quantity, rate: $rate, rateOrigin: $rateOrigin, total: $total, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a payable.
#
# DELETE /v2/projects/{projectId}/finance/payables/{payableId}
# operationId: deletePayable_2
export def "projects-finance-payables delete-by-projectId-payableId" [
  projectId: string
  payableId: int
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/finance/payables/($payableId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a payable.
#
# PUT /v2/projects/{projectId}/finance/payables/{payableId}
# operationId: updatePayable_2
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "projects-finance-payables updatePayable-by-projectId-payableId" [
  projectId: string
  payableId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculationUnitId: int # format: int64
  --currencyId: int # format: int64
  --description: string
  --id: int # format: int64
  --ignoreMinimumCharge: oneof<nothing, bool>
  --invoiceId: string
  --jobId: record
  --jobTypeId: int # format: int64
  --languageCombination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --languageCombinationIdNumber: string
  --minimumCharge: float
  --quantity: float
  --rate: float
  --rateOrigin: string@rateOrigin-completer
  --total: float
  --type: string@type-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/finance/payables/($payableId)")
  let body = {calculationUnitId: $calculationUnitId, currencyId: $currencyId, description: $description, id: $id, ignoreMinimumCharge: $ignoreMinimumCharge, invoiceId: $invoiceId, jobId: $jobId, jobTypeId: $jobTypeId, languageCombination: $languageCombination, languageCombinationIdNumber: $languageCombinationIdNumber, minimumCharge: $minimumCharge, quantity: $quantity, rate: $rate, rateOrigin: $rateOrigin, total: $total, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds a receivable to a project.
#
# POST /v2/projects/{projectId}/finance/receivables
# operationId: createReceivable_2
# --catLogFile shape: {content?: string, name?: string, token?: string, url?: string}
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "projects-finance-receivables createReceivable-by-projectId" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculationUnitId: int # format: int64
  --catLogFile: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currencyId: int # format: int64
  --description: string
  --id: int # format: int64
  --ignoreMinimumCharge: oneof<nothing, bool>
  --invoiceId: string
  --jobTypeId: int # format: int64
  --languageCombination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --languageCombinationIdNumber: string
  --minimumCharge: float
  --quantity: float
  --rate: float
  --rateOrigin: string@rateOrigin-completer
  --taskId: int # format: int64
  --total: float
  --type: string@type-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/finance/receivables")
  let body = {calculationUnitId: $calculationUnitId, catLogFile: $catLogFile, currencyId: $currencyId, description: $description, id: $id, ignoreMinimumCharge: $ignoreMinimumCharge, invoiceId: $invoiceId, jobTypeId: $jobTypeId, languageCombination: $languageCombination, languageCombinationIdNumber: $languageCombinationIdNumber, minimumCharge: $minimumCharge, quantity: $quantity, rate: $rate, rateOrigin: $rateOrigin, taskId: $taskId, total: $total, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a receivable.
#
# DELETE /v2/projects/{projectId}/finance/receivables/{receivableId}
# operationId: deleteReceivable_2
export def "projects-finance-receivables delete-by-projectId-receivableId" [
  projectId: string
  receivableId: int
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/finance/receivables/($receivableId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a receivable.
#
# PUT /v2/projects/{projectId}/finance/receivables/{receivableId}
# operationId: updateReceivable_2
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "projects-finance-receivables updateReceivable-by-projectId-receivableId" [
  projectId: string
  receivableId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculationUnitId: int # format: int64
  --currencyId: int # format: int64
  --description: string
  --id: int # format: int64
  --ignoreMinimumCharge: oneof<nothing, bool>
  --invoiceId: string
  --jobTypeId: int # format: int64
  --languageCombination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --languageCombinationIdNumber: string
  --minimumCharge: float
  --quantity: float
  --rate: float
  --rateOrigin: string@rateOrigin-completer
  --taskId: int # format: int64
  --total: float
  --type: string@type-completer-1
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/finance/receivables/($receivableId)")
  let body = {calculationUnitId: $calculationUnitId, currencyId: $currencyId, description: $description, id: $id, ignoreMinimumCharge: $ignoreMinimumCharge, invoiceId: $invoiceId, jobTypeId: $jobTypeId, languageCombination: $languageCombination, languageCombinationIdNumber: $languageCombinationIdNumber, minimumCharge: $minimumCharge, quantity: $quantity, rate: $rate, rateOrigin: $rateOrigin, taskId: $taskId, total: $total, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates Internal Notes for a project.
#
# PUT /v2/projects/{projectId}/internalNotes
# operationId: updateInternalNotes
export def "projects-internal-notes updateInternalNotes" [
  projectId: string
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/internalNotes")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns list of jobs in a project.
#
# GET /v2/projects/{projectId}/jobs
# operationId: getJobs
export def "projects-jobs get" [
  projectId: string
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/jobs")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates Order Date for a project.
#
# PUT /v2/projects/{projectId}/orderDate
# operationId: updateOrderedOn
export def "projects-order-date updateOrderedOn" [
  projectId: string
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/orderDate")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns process id.
#
# GET /v2/projects/{projectId}/process
# operationId: getProcessId
export def "projects-process get" [
  projectId: string
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/process")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates source language for a project.
#
# PUT /v2/projects/{projectId}/sourceLanguage
# operationId: updateSourceLanguage
export def "projects-source-language updateSourceLanguage" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sourceLanguageId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/sourceLanguage")
  let body = {sourceLanguageId: $sourceLanguageId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates specialization for a project.
#
# PUT /v2/projects/{projectId}/specialization
# operationId: updateSpecialization
export def "projects-specialization updateSpecialization" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --specializationId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/specialization")
  let body = {specializationId: $specializationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Changes project status if possible (400 Bad Request is returned otherwise).
#
# PUT /v2/projects/{projectId}/status
# operationId: changeStatus_2
export def "projects-status changeStatus-by-projectId" [
  projectId: string
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/status")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates target languages for a project.
#
# PUT /v2/projects/{projectId}/targetLanguages
# operationId: updateTargetLanguages
export def "projects-target-languages updateTargetLanguages" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --targetLanguageIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/projects/($projectId)/targetLanguages")
  let body = {targetLanguageIds: $targetLanguageIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates instructions for all vendors performing the jobs in a project.
#
# PUT /v2/projects/{projectId}/vendorInstructions
# operationId: updateVendorInstructions
export def "projects-vendor-instructions updateVendorInstructions" [
  projectId: string
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/vendorInstructions")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates volume for a project.
#
# PUT /v2/projects/{projectId}/volume
# operationId: updateVolume
export def "projects-volume updateVolume" [
  projectId: string
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
  let full_url = (build-url $base $"/v2/projects/($projectId)/volume")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --clientId: int # format: int64
  --name: string
  --opportunityOfferId: int # format: int64
  --serviceId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/quotes")
  let body = {clientId: $clientId, name: $name, opportunityOfferId: $opportunityOfferId, serviceId: $serviceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Returns details of a file.
#
# GET /v2/quotes/files/{fileId}
# operationId: getFileById_3
export def "quotes-files get-by-fileId" [
  fileId: string
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
  let full_url = (build-url $base $"/v2/quotes/files/($fileId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Downloads a file content.
#
# GET /v2/quotes/files/{fileId}/download/{fileName}
# operationId: getFileContentById_1
export def "quotes-files-download get-by-fileId-fileName" [
  fileId: string
  fileName: string
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
  let full_url = (build-url $base $"/v2/quotes/files/($fileId)/download/($fileName)")
  let accept_val = "multipart/form-data"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns quote details.
#
# GET /v2/quotes/{quoteId}
# operationId: getById_10
export def "quotes get-by-quoteId-by-quoteId-1" [
  quoteId: string
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
  let full_url = (build-url $base $"/v2/quotes/($quoteId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates Business Days for a quote.
#
# PUT /v2/quotes/{quoteId}/businessDays
# operationId: updateBusinessDays
export def "quotes-business-days updateBusinessDays" [
  quoteId: string
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
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/businessDays")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns Client Contacts information for a quote.
#
# GET /v2/quotes/{quoteId}/clientContacts
# operationId: getContacts_3
export def "quotes-client-contacts get-by-quoteId" [
  quoteId: string
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
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/clientContacts")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates Client Contacts for a quote.
#
# PUT /v2/quotes/{quoteId}/clientContacts
# operationId: updateContacts_3
export def "quotes-client-contacts updateContacts-by-quoteId" [
  quoteId: string
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
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/clientContacts")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json;charset=UTF-8" $body
}

# Updates Client Notes for a quote.
#
# PUT /v2/quotes/{quoteId}/clientNotes
# operationId: updateClientNotes_1
export def "quotes-client-notes updateClientNotes-by-quoteId" [
  quoteId: string
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
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/clientNotes")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates Client Reference Number for a quote.
#
# PUT /v2/quotes/{quoteId}/clientReferenceNumber
# operationId: updateClientReferenceNumber_1
export def "quotes-client-reference-number updateClientReferenceNumber-by-quoteId" [
  quoteId: string
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
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/clientReferenceNumber")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of custom field keys and values for a project.
#
# GET /v2/quotes/{quoteId}/customFields
# operationId: getCustomFields_9
export def "quotes-custom-fields get-by-quoteId-by-quoteId-1" [
  quoteId: string
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
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/customFields")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a custom field with a specified key in a quote.
#
# PUT /v2/quotes/{quoteId}/customFields/{key}
# operationId: updateCustomField_3
export def "quotes-custom-fields updateCustomField-by-quoteId-key" [
  quoteId: string
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
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/customFields/($key)")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates Expected Delivery Date for a quote.
#
# PUT /v2/quotes/{quoteId}/expectedDeliveryDate
# operationId: updateExpectedDeliveryDate
export def "quotes-expected-delivery-date updateExpectedDeliveryDate" [
  quoteId: string
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
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/expectedDeliveryDate")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns list of files in a quote.
#
# GET /v2/quotes/{quoteId}/files
# operationId: getFiles_1
export def "quotes-files get-by-quoteId" [
  quoteId: string
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
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/files")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds files to the quote as added by PM.
#
# PUT /v2/quotes/{quoteId}/files/add
# operationId: addFiles_2
export def "quotes-files-add addFiles-by-quoteId" [
  quoteId: string
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
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/files/add")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Uploads file to the quote as a file uploaded by PM.
#
# POST /v2/quotes/{quoteId}/files/upload
# operationId: uploadFile_3
export def "quotes-files-upload uploadFile-by-quoteId" [
  quoteId: string
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
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/files/upload")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Returns finance information for a quote.
#
# GET /v2/quotes/{quoteId}/finance
# operationId: getFinance_3
export def "quotes-finance get-by-quoteId-by-quoteId-1" [
  quoteId: string
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
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/finance")
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
export def "quotes-finance-payables createPayable-by-quoteId-by-quoteId-1" [
  quoteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculationUnitId: int # format: int64
  --catLogFile: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currencyId: int # format: int64
  --description: string
  --id: int # format: int64
  --ignoreMinimumCharge: oneof<nothing, bool>
  --invoiceId: string
  --jobId: record
  --jobTypeId: int # format: int64
  --languageCombination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --languageCombinationIdNumber: string
  --minimumCharge: float
  --quantity: float
  --rate: float
  --rateOrigin: string@rateOrigin-completer
  --total: float
  --type: string@type-completer-1
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/finance/payables")
  let body = {calculationUnitId: $calculationUnitId, catLogFile: $catLogFile, currencyId: $currencyId, description: $description, id: $id, ignoreMinimumCharge: $ignoreMinimumCharge, invoiceId: $invoiceId, jobId: $jobId, jobTypeId: $jobTypeId, languageCombination: $languageCombination, languageCombinationIdNumber: $languageCombinationIdNumber, minimumCharge: $minimumCharge, quantity: $quantity, rate: $rate, rateOrigin: $rateOrigin, total: $total, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a payable.
#
# DELETE /v2/quotes/{quoteId}/finance/payables/{payableId}
# operationId: deletePayable_3
export def "quotes-finance-payables delete-by-quoteId-payableId-by-quoteId-payableId-1" [
  quoteId: string
  payableId: int
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
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/finance/payables/($payableId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a payable.
#
# PUT /v2/quotes/{quoteId}/finance/payables/{payableId}
# operationId: updatePayable_3
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-payables updatePayable-by-quoteId-payableId-by-quoteId-payableId-1" [
  quoteId: string
  payableId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculationUnitId: int # format: int64
  --currencyId: int # format: int64
  --description: string
  --id: int # format: int64
  --ignoreMinimumCharge: oneof<nothing, bool>
  --invoiceId: string
  --jobId: record
  --jobTypeId: int # format: int64
  --languageCombination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --languageCombinationIdNumber: string
  --minimumCharge: float
  --quantity: float
  --rate: float
  --rateOrigin: string@rateOrigin-completer
  --total: float
  --type: string@type-completer-1
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/finance/payables/($payableId)")
  let body = {calculationUnitId: $calculationUnitId, currencyId: $currencyId, description: $description, id: $id, ignoreMinimumCharge: $ignoreMinimumCharge, invoiceId: $invoiceId, jobId: $jobId, jobTypeId: $jobTypeId, languageCombination: $languageCombination, languageCombinationIdNumber: $languageCombinationIdNumber, minimumCharge: $minimumCharge, quantity: $quantity, rate: $rate, rateOrigin: $rateOrigin, total: $total, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Adds a receivable to a quote.
#
# POST /v2/quotes/{quoteId}/finance/receivables
# operationId: createReceivable_3
# --catLogFile shape: {content?: string, name?: string, token?: string, url?: string}
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-receivables createReceivable-by-quoteId-by-quoteId-1" [
  quoteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculationUnitId: int # format: int64
  --catLogFile: record # shape: {content?: string, name?: string, token?: string, url?: string}
  --currencyId: int # format: int64
  --description: string
  --id: int # format: int64
  --ignoreMinimumCharge: oneof<nothing, bool>
  --invoiceId: string
  --jobTypeId: int # format: int64
  --languageCombination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --languageCombinationIdNumber: string
  --minimumCharge: float
  --quantity: float
  --rate: float
  --rateOrigin: string@rateOrigin-completer
  --taskId: int # format: int64
  --total: float
  --type: string@type-completer-1
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/finance/receivables")
  let body = {calculationUnitId: $calculationUnitId, catLogFile: $catLogFile, currencyId: $currencyId, description: $description, id: $id, ignoreMinimumCharge: $ignoreMinimumCharge, invoiceId: $invoiceId, jobTypeId: $jobTypeId, languageCombination: $languageCombination, languageCombinationIdNumber: $languageCombinationIdNumber, minimumCharge: $minimumCharge, quantity: $quantity, rate: $rate, rateOrigin: $rateOrigin, taskId: $taskId, total: $total, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a receivable.
#
# DELETE /v2/quotes/{quoteId}/finance/receivables/{receivableId}
# operationId: deleteReceivable_3
export def "quotes-finance-receivables delete-by-quoteId-receivableId-by-quoteId-receivableId-1" [
  quoteId: string
  receivableId: int
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
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/finance/receivables/($receivableId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a receivable.
#
# PUT /v2/quotes/{quoteId}/finance/receivables/{receivableId}
# operationId: updateReceivable_3
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-receivables updateReceivable-by-quoteId-receivableId-by-quoteId-receivableId-1" [
  quoteId: string
  receivableId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --calculationUnitId: int # format: int64
  --currencyId: int # format: int64
  --description: string
  --id: int # format: int64
  --ignoreMinimumCharge: oneof<nothing, bool>
  --invoiceId: string
  --jobTypeId: int # format: int64
  --languageCombination: record # shape: {sourceLanguageId?: int, targetLanguageId?: int}
  --languageCombinationIdNumber: string
  --minimumCharge: float
  --quantity: float
  --rate: float
  --rateOrigin: string@rateOrigin-completer
  --taskId: int # format: int64
  --total: float
  --type: string@type-completer-1
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/finance/receivables/($receivableId)")
  let body = {calculationUnitId: $calculationUnitId, currencyId: $currencyId, description: $description, id: $id, ignoreMinimumCharge: $ignoreMinimumCharge, invoiceId: $invoiceId, jobTypeId: $jobTypeId, languageCombination: $languageCombination, languageCombinationIdNumber: $languageCombinationIdNumber, minimumCharge: $minimumCharge, quantity: $quantity, rate: $rate, rateOrigin: $rateOrigin, taskId: $taskId, total: $total, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates Internal Notes for a quote.
#
# PUT /v2/quotes/{quoteId}/internalNotes
# operationId: updateInternalNotes_1
export def "quotes-internal-notes updateInternalNotes-by-quoteId" [
  quoteId: string
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
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/internalNotes")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns list of jobs in a quote.
#
# GET /v2/quotes/{quoteId}/jobs
# operationId: getJobs_1
export def "quotes-jobs get-by-quoteId" [
  quoteId: string
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
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/jobs")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates Quote Expiry Date for a quote.
#
# PUT /v2/quotes/{quoteId}/quoteExpiry
# operationId: updateQuoteExpiry
export def "quotes-quote-expiry updateQuoteExpiry" [
  quoteId: string
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
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/quoteExpiry")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates source language for a quote.
#
# PUT /v2/quotes/{quoteId}/sourceLanguage
# operationId: updateSourceLanguage_1
export def "quotes-source-language updateSourceLanguage-by-quoteId" [
  quoteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sourceLanguageId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/sourceLanguage")
  let body = {sourceLanguageId: $sourceLanguageId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates specialization for a quote.
#
# PUT /v2/quotes/{quoteId}/specialization
# operationId: updateSpecialization_1
export def "quotes-specialization updateSpecialization-by-quoteId" [
  quoteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --specializationId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/specialization")
  let body = {specializationId: $specializationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Changes quote status if possible (400 Bad Request is returned otherwise).
#
# PUT /v2/quotes/{quoteId}/status
# operationId: changeStatus_3
export def "quotes-status changeStatus-by-quoteId" [
  quoteId: string
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
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/status")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates target languages for a quote.
#
# PUT /v2/quotes/{quoteId}/targetLanguages
# operationId: updateTargetLanguages_1
export def "quotes-target-languages updateTargetLanguages-by-quoteId" [
  quoteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --targetLanguageIds: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/targetLanguages")
  let body = {targetLanguageIds: $targetLanguageIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates instructions for all vendors performing the jobs in a quote.
#
# PUT /v2/quotes/{quoteId}/vendorInstructions
# operationId: updateVendorInstructions_1
export def "quotes-vendor-instructions updateVendorInstructions-by-quoteId" [
  quoteId: string
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
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/vendorInstructions")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates volume for a quote.
#
# PUT /v2/quotes/{quoteId}/volume
# operationId: updateVolume_1
export def "quotes-volume updateVolume-by-quoteId" [
  quoteId: string
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
  let full_url = (build-url $base $"/v2/quotes/($quoteId)/volume")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
