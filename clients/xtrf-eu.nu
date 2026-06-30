# Auto-generated client for XTRF Home Portal API v2.0
# Source: https://api.apis.guru/v2/specs/xtrf.eu/2.0/openapi.json
# Auth: --token flag or $env.XTRF_HOME_PORTAL_API_TOKEN

const BASE_URL = "https://presentation.s.xtrf.eu/home-api"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o XTRF_HOME_PORTAL_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-auth-access-token" => { {scheme: $scheme, headers: {X-AUTH-ACCESS-TOKEN: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://presentation.s.xtrf.eu/home-api"] }
def auth-scheme-completer [] { ["x-auth-access-token"] }

# Completers for enum parameters
def type-completer [] { ["CREDIT_NOTE" "DRAFT" "FINAL"] }
def status-completer [] { ["BILL_CREATED" "CONFIRMED" "POSTPONED" "SENT" "TO_BE_SENT"] }
def status-completer-1 [] { ["ACTIVE" "INACTIVE" "POTENTIAL"] }
def gender-completer [] { ["FEMALE" "MALE"] }
def type-completer-1 [] { ["CHECKBOX" "DATE" "DATE_AND_TIME" "MULTI_SELECTION" "NUMBER" "SELECTION" "TEXT"] }
def category-completer [] { ["DICTIONARY" "LOG_FILE" "REF" "TM" "WORKFILE"] }
def rate-origin-completer [] { ["AUTOCALCULATED" "FILLED_MANUALLY" "PRICE_LIST" "PRICE_PROFILE"] }
def type-completer-2 [] { ["CAT" "SIMPLE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only client invoices modified since this timestamp (format: int64)
]: nothing -> table<currencyId: int, customerDetails: record<addressLine: string, city: string, country: string, countryId: int, name: string, postalCode: string, vatUE: string>, customerId: int, dates: record<draftDate: record, finalDate: record, invoiceDate: record, paymentDueDate: record>, id: int, invoiceNumber: string, paymentMethodId: int, paymentTerms: record<description: string, name: string>, status: string, tasks: list<record>, tasksValue: float, totalGross: float, totalInWords: string, totalNetto: float, type: string, vatCalculationRule: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/customers/invoices" $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"updatedSince": $updated_since} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
}

# Creates a new invoice.
#
# POST /accounting/customers/invoices
# operationId: create_1
export def "accounting-customers-invoices create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --prepayments-ids: list<int>
  --tasks-ids: list<int>
  --type: string@type-completer
]: any -> record<invoiceUrl: string, invoicesIds: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounting/customers/invoices" $auth.query)
  let req_body = {"prepaymentsIds": $prepayments_ids, "tasksIds": $tasks_ids, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int>
]: any -> record<url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounting/customers/invoices/documents" $auth.query)
  let req_body = {"ids": $ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only client invoices modified since this timestamp (format: int64)
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/customers/invoices/ids" $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"updatedSince": $updated_since} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int>
]: any -> record<numberOfSentEmails: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounting/customers/invoices/sendReminders" $auth.query)
  let req_body = {"ids": $ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full []
}

# Removes a client invoice.
#
# DELETE /accounting/customers/invoices/{invoiceId}
# operationId: delete_1
export def "accounting-customers-invoices delete-by-invoice-id" [
  invoice_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/customers/invoices/{invoice_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: string # list of adittional fields which should be embedded in the response (ie. tasks)
]: nothing -> record<currencyId: int, customerDetails: record<addressLine: string, city: string, country: string, countryId: int, name: string, postalCode: string, vatUE: string>, customerId: int, dates: record<draftDate: record<value: int>, finalDate: record<value: int>, invoiceDate: record<value: int>, paymentDueDate: record<value: int>>, id: int, invoiceNumber: string, paymentMethodId: int, paymentTerms: record<description: string, name: string>, status: string, tasks: table<clientTaskPONumber: string, customFields: list, dates: record, finance: record, id: int, idNumber: string, instructions: record, jobs: record, languageCombination: record, name: string, people: record, projectId: int, quoteId: int>, tasksValue: float, totalGross: float, totalInWords: string, totalNetto: float, type: string, vatCalculationRule: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let qp = [(serialize-qp "embed" $embed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/customers/invoices/{invoice_id}") $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"embed": $embed} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<draftDate: record<value: int>, finalDate: record<value: int>, invoiceDate: record<value: int>, paymentDueDate: record<value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/customers/invoices/{invoice_id}/dates") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/customers/invoices/{invoice_id}/document") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<currencyId: int, customerDetails: record<addressLine: string, city: string, country: string, countryId: int, name: string, postalCode: string, vatUE: string>, customerId: int, dates: record<draftDate: record<value: int>, finalDate: record<value: int>, invoiceDate: record<value: int>, paymentDueDate: record<value: int>>, id: int, invoiceNumber: string, paymentMethodId: int, paymentTerms: record<description: string, name: string>, status: string, tasks: table<clientTaskPONumber: string, customFields: list, dates: record, finance: record, id: int, idNumber: string, instructions: record, jobs: record, languageCombination: record, name: string, people: record, projectId: int, quoteId: int>, tasksValue: float, totalGross: float, totalInWords: string, totalNetto: float, type: string, vatCalculationRule: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/customers/invoices/{invoice_id}/duplicate") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req null $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<currencyId: int, customerDetails: record<addressLine: string, city: string, country: string, countryId: int, name: string, postalCode: string, vatUE: string>, customerId: int, dates: record<draftDate: record<value: int>, finalDate: record<value: int>, invoiceDate: record<value: int>, paymentDueDate: record<value: int>>, id: int, invoiceNumber: string, paymentMethodId: int, paymentTerms: record<description: string, name: string>, status: string, tasks: table<clientTaskPONumber: string, customFields: list, dates: record, finance: record, id: int, idNumber: string, instructions: record, jobs: record, languageCombination: record, name: string, people: record, projectId: int, quoteId: int>, tasksValue: float, totalGross: float, totalInWords: string, totalNetto: float, type: string, vatCalculationRule: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/customers/invoices/{invoice_id}/duplicate/proForma") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req null $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/customers/invoices/{invoice_id}/paymentTerms") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<amount: float, notes: string, paymentDate: record<value: int>, paymentMethodId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/customers/invoices/{invoice_id}/payments") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Adds a new payment to the client invoice. The invoice payment status (Not Paid, Partially Paid, Fully Paid) is automatically recalculated.
#
# POST /accounting/customers/invoices/{invoiceId}/payments
# operationId: createPayment
# --paymentDate shape: {value?: int}
export def "accounting-customers-invoices-payments create" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float
  --notes: string
  --payment-date: record # shape: {value?: int}
  --payment-method-id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/customers/invoices/{invoice_id}/payments") $auth.query)
  let req_body = {"amount": $amount, "notes": $notes, "paymentDate": $payment_date, "paymentMethodId": $payment_method_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/customers/invoices/{invoice_id}/sendReminder") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# Removes a customer payment.
#
# DELETE /accounting/customers/payments/{paymentId}
# operationId: delete_2
export def "accounting-customers-payments delete-by-payment-id" [
  payment_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id)} | format pattern "/accounting/customers/payments/{payment_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Lists all vendor invoices in all statuses (including not ready and drafts) that have been updated since a specific date.
#
# GET /accounting/providers/invoices
# operationId: getAll_2
export def "accounting-providers-invoices get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only vendor invoices modified since this timestamp (format: int64)
]: nothing -> table<currencyId: int, dates: record<draftDate: record, finalDate: record, invoiceUploadedDate: record, paymentDueDate: record>, draftNumber: string, finalNumber: string, id: int, internalNumber: string, jobsNetValue: float, notesFromProvider: string, paymentStatus: string, providerId: int, status: string, totalGross: float, totalGrossInWords: string, totalNetto: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/providers/invoices" $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"updatedSince": $updated_since} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
}

# Creates a new invoice.
#
# POST /accounting/providers/invoices
# operationId: create_4
export def "accounting-providers-invoices create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jobs-ids: list<int>
]: any -> record<invoiceUrl: string, invoicesIds: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounting/providers/invoices" $auth.query)
  let req_body = {"jobsIds": $jobs_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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

# Returns vendor invoices' internal identifiers.
#
# GET /accounting/providers/invoices/ids
# operationId: getAllIds_3
export def "accounting-providers-invoices-ids get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only vendor invoices modified since this timestamp (format: int64)
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting/providers/invoices/ids" $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"updatedSince": $updated_since} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
}

# Removes a provider invoice.
#
# DELETE /accounting/providers/invoices/{invoiceId}
# operationId: delete_6
export def "accounting-providers-invoices delete-by-invoice-id" [
  invoice_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/providers/invoices/{invoice_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Returns provider invoice details.
#
# GET /accounting/providers/invoices/{invoiceId}
# operationId: getById_3
export def "accounting-providers-invoices get-by-invoice-id" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<currencyId: int, dates: record<draftDate: record<value: int>, finalDate: record<value: int>, invoiceUploadedDate: record<value: int>, paymentDueDate: record<value: int>>, draftNumber: string, finalNumber: string, id: int, internalNumber: string, jobsNetValue: float, notesFromProvider: string, paymentStatus: string, providerId: int, status: string, totalGross: float, totalGrossInWords: string, totalNetto: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/providers/invoices/{invoice_id}") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Generates provider invoice document (PDF).
#
# GET /accounting/providers/invoices/{invoiceId}/document
# operationId: getDocument_1
export def "accounting-providers-invoices-document get-by-invoice-id" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/providers/invoices/{invoice_id}/document") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Returns all payments for the vendor invoice.
#
# GET /accounting/providers/invoices/{invoiceId}/payments
# operationId: getPayments_1
export def "accounting-providers-invoices-payments get-by-invoice-id" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<amount: float, notes: string, paymentDate: record<value: int>, paymentMethodId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/providers/invoices/{invoice_id}/payments") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Creates a new payment on the vendor account and assigns the payment to the invoice.
#
# POST /accounting/providers/invoices/{invoiceId}/payments
# operationId: createPayment_1
# --paymentDate shape: {value?: int}
export def "accounting-providers-invoices-payments create-by-invoice-id" [
  invoice_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float
  --notes: string
  --payment-date: record # shape: {value?: int}
  --payment-method-id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/providers/invoices/{invoice_id}/payments") $auth.query)
  let req_body = {"amount": $amount, "notes": $notes, "paymentDate": $payment_date, "paymentMethodId": $payment_method_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/providers/invoices/{invoice_id}/send") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req null $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($invoice_id | is-empty) { error make --unspanned { msg: "path parameter 'invoiceId' must be non-empty" } }
  let full_url = (build-url $base ({invoice_id: (encode-path-segment $invoice_id)} | format pattern "/accounting/providers/invoices/{invoice_id}/status") $auth.query)
  let req_body = {"status": $status} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Removes a provider payment.
#
# DELETE /accounting/providers/payments/{paymentId}
# operationId: delete_7
export def "accounting-providers-payments delete-by-payment-id" [
  payment_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id)} | format pattern "/accounting/providers/payments/{payment_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --view-id: int # view's identifier (format: int64)
  --page: int # format: int32, default: 0
  --additional-order: string
  --use-deferred-columns: string
  --max-rows: int # overrides view's default rows limit, supported values 10 to 1000 (format: int32, default: 0)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "viewId" $view_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "additionalOrder" $additional_order "scalar") (serialize-qp "useDeferredColumns" $use_deferred_columns "scalar") (serialize-qp "maxRows" $max_rows "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/browser" $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"viewId": $view_id, "page": $page, "additionalOrder": $additional_order, "useDeferredColumns": $use_deferred_columns, "maxRows": $max_rows} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --view-id: int # view's identifier (format: int64)
  --separator: string # csv field separator
  --secondary-separator: string # secondary csv field separator
  --additional-order: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "viewId" $view_id "scalar") (serialize-qp "separator" $separator "scalar") (serialize-qp "secondarySeparator" $secondary_separator "scalar") (serialize-qp "additionalOrder" $additional_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/browser/csv" $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"viewId": $view_id, "separator": $separator, "secondarySeparator": $secondary_separator, "additionalOrder": $additional_order} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
}

# Returns current view's detailed information, suitable for browser.
#
# GET /browser/views/details/for/{className}
# operationId: getCurrentViewDetails
export def "browser-views-details-for list" [
  class_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --place-name: string # place name (denotes specific place in system with the table) (default: default)
]: nothing -> record<access: record<change: bool, delete: bool>, actions: table<header: string, name: string>, filter: record<properties: list<record>>, view: record<columns: list<record>, order: record<column: string, type: string>, permissions: record<sharedGroups: list>, settings: record<local: record, name: string>>, viewId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($class_name | is-empty) { error make --unspanned { msg: "path parameter 'className' must be non-empty" } }
  let qp = [(serialize-qp "placeName" $place_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({class_name: (encode-path-segment $class_name)} | format pattern "/browser/views/details/for/{class_name}") $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"placeName": $place_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --place-name: string # place name (denotes specific place in system with the table) (default: default)
]: nothing -> record<access: record<change: bool, delete: bool>, actions: table<header: string, name: string>, filter: record<properties: list<record>>, view: record<columns: list<record>, order: record<column: string, type: string>, permissions: record<sharedGroups: list>, settings: record<local: record, name: string>>, viewId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($class_name | is-empty) { error make --unspanned { msg: "path parameter 'className' must be non-empty" } }
  if ($view_id | is-empty) { error make --unspanned { msg: "path parameter 'viewId' must be non-empty" } }
  let qp = [(serialize-qp "placeName" $place_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({class_name: (encode-path-segment $class_name), view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/details/for/{class_name}/{view_id}") $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"placeName": $place_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --place-name-denotes-specific-place-in-system-with-the-table: string # default: default
]: nothing -> record<access: record<change: bool, delete: bool>, actions: table<header: string, name: string>, filter: record<properties: list<record>>, view: record<columns: list<record>, order: record<column: string, type: string>, permissions: record<sharedGroups: list>, settings: record<local: record, name: string>>, viewId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($class_name | is-empty) { error make --unspanned { msg: "path parameter 'className' must be non-empty" } }
  if ($view_id | is-empty) { error make --unspanned { msg: "path parameter 'viewId' must be non-empty" } }
  let qp = [(serialize-qp "place name (denotes specific place in system with the table)" $place_name_denotes_specific_place_in_system_with_the_table "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({class_name: (encode-path-segment $class_name), view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/details/for/{class_name}/{view_id}") $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"place name (denotes specific place in system with the table)": $place_name_denotes_specific_place_in_system_with_the_table} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --place-name: string # place name (denotes specific place in system with the table) (default: default)
]: nothing -> record<access: record<change: bool, delete: bool>, list: table<access: record, current: bool, id: int, lastModification: record, mine: bool, name: string, owner: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($class_name | is-empty) { error make --unspanned { msg: "path parameter 'className' must be non-empty" } }
  let qp = [(serialize-qp "placeName" $place_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({class_name: (encode-path-segment $class_name)} | format pattern "/browser/views/for/{class_name}") $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"placeName": $place_name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
}

# Creates view for given class.
#
# POST /browser/views/for/{className}
# operationId: create
# --columns item shape: {name?: string, settings?: record}
# --order shape: {column?: string, type?: string}
# --permissions shape: {sharedGroups?: list<int>}
# --settings shape: {local?: record, name?: string}
export def "browser-views-for create" [
  class_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --columns: list # item shape: {name?: string, settings?: record}
  --order: record # shape: {column?: string, type?: string}
  --permissions: record # shape: {sharedGroups?: list<int>}
  --settings: record # shape: {local?: record, name?: string}
]: any -> record<columns: table<name: string, settings: record>, order: record<column: string, type: string>, permissions: record<sharedGroups: list<int>>, settings: record<local: record<maxLinesInRow: int, maxRows: int>, name: string>, viewId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($class_name | is-empty) { error make --unspanned { msg: "path parameter 'className' must be non-empty" } }
  let full_url = (build-url $base ({class_name: (encode-path-segment $class_name)} | format pattern "/browser/views/for/{class_name}") $auth.query)
  let req_body = {"columns": $columns, "order": $order, "permissions": $permissions, "settings": $settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($view_id | is-empty) { error make --unspanned { msg: "path parameter 'viewId' must be non-empty" } }
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<columns: table<name: string, settings: record>, order: record<column: string, type: string>, permissions: record<sharedGroups: list<int>>, settings: record<local: record<maxLinesInRow: int, maxRows: int>, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($view_id | is-empty) { error make --unspanned { msg: "path parameter 'viewId' must be non-empty" } }
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Updates all view's information.
#
# PUT /browser/views/{viewId}
# operationId: update
# --columns item shape: {name?: string, settings?: record}
# --order shape: {column?: string, type?: string}
# --permissions shape: {sharedGroups?: list<int>}
# --settings shape: {local?: record, name?: string}
export def "browser-views update" [
  view_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --columns: list # item shape: {name?: string, settings?: record}
  --order: record # shape: {column?: string, type?: string}
  --permissions: record # shape: {sharedGroups?: list<int>}
  --settings: record # shape: {local?: record, name?: string}
]: any -> record<columns: table<name: string, settings: record>, order: record<column: string, type: string>, permissions: record<sharedGroups: list<int>>, settings: record<local: record<maxLinesInRow: int, maxRows: int>, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($view_id | is-empty) { error make --unspanned { msg: "path parameter 'viewId' must be non-empty" } }
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}") $auth.query)
  let req_body = {"columns": $columns, "order": $order, "permissions": $permissions, "settings": $settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, settings: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($view_id | is-empty) { error make --unspanned { msg: "path parameter 'viewId' must be non-empty" } }
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/columns") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> table<name: string, settings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($view_id | is-empty) { error make --unspanned { msg: "path parameter 'viewId' must be non-empty" } }
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/columns") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string, settings: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($view_id | is-empty) { error make --unspanned { msg: "path parameter 'viewId' must be non-empty" } }
  if ($column_name | is-empty) { error make --unspanned { msg: "path parameter 'columnName' must be non-empty" } }
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id), column_name: (encode-path-segment $column_name)} | format pattern "/browser/views/{view_id}/columns/{column_name}") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($view_id | is-empty) { error make --unspanned { msg: "path parameter 'viewId' must be non-empty" } }
  if ($column_name | is-empty) { error make --unspanned { msg: "path parameter 'columnName' must be non-empty" } }
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id), column_name: (encode-path-segment $column_name)} | format pattern "/browser/views/{view_id}/columns/{column_name}/settings") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($view_id | is-empty) { error make --unspanned { msg: "path parameter 'viewId' must be non-empty" } }
  if ($column_name | is-empty) { error make --unspanned { msg: "path parameter 'columnName' must be non-empty" } }
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id), column_name: (encode-path-segment $column_name)} | format pattern "/browser/views/{view_id}/columns/{column_name}/settings") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<properties: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($view_id | is-empty) { error make --unspanned { msg: "path parameter 'viewId' must be non-empty" } }
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/filter") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> record<properties: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($view_id | is-empty) { error make --unspanned { msg: "path parameter 'viewId' must be non-empty" } }
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/filter") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --settings: record
  --settings-present: oneof<nothing, bool>
  --type: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($view_id | is-empty) { error make --unspanned { msg: "path parameter 'viewId' must be non-empty" } }
  if ($filter_property | is-empty) { error make --unspanned { msg: "path parameter 'filterProperty' must be non-empty" } }
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id), filter_property: (encode-path-segment $filter_property)} | format pattern "/browser/views/{view_id}/filter/{filter_property}") $auth.query)
  let req_body = {"name": $name, "settings": $settings, "settingsPresent": $settings_present, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<column: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($view_id | is-empty) { error make --unspanned { msg: "path parameter 'viewId' must be non-empty" } }
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/order") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --column: string
  --type: string
]: any -> record<column: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($view_id | is-empty) { error make --unspanned { msg: "path parameter 'viewId' must be non-empty" } }
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/order") $auth.query)
  let req_body = {"column": $column, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<sharedGroups: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($view_id | is-empty) { error make --unspanned { msg: "path parameter 'viewId' must be non-empty" } }
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/permissions") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --shared-groups: list<int>
]: any -> record<sharedGroups: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($view_id | is-empty) { error make --unspanned { msg: "path parameter 'viewId' must be non-empty" } }
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/permissions") $auth.query)
  let req_body = {"sharedGroups": $shared_groups} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<local: record<maxLinesInRow: int, maxRows: int>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($view_id | is-empty) { error make --unspanned { msg: "path parameter 'viewId' must be non-empty" } }
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/settings") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --local: record # shape: {maxLinesInRow?: int, maxRows?: int}
  --name: string
]: any -> record<local: record<maxLinesInRow: int, maxRows: int>, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($view_id | is-empty) { error make --unspanned { msg: "path parameter 'viewId' must be non-empty" } }
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/settings") $auth.query)
  let req_body = {"local": $local, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<maxLinesInRow: int, maxRows: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($view_id | is-empty) { error make --unspanned { msg: "path parameter 'viewId' must be non-empty" } }
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/settings/local") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-lines-in-row: int # format: int32
  --max-rows: int # format: int32
]: any -> record<maxLinesInRow: int, maxRows: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($view_id | is-empty) { error make --unspanned { msg: "path parameter 'viewId' must be non-empty" } }
  let full_url = (build-url $base ({view_id: (encode-path-segment $view_id)} | format pattern "/browser/views/{view_id}/settings/local") $auth.query)
  let req_body = {"maxLinesInRow": $max_lines_in_row, "maxRows": $max_rows} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only clients modified since this timestamp (format: int64)
]: nothing -> table<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customers" $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"updatedSince": $updated_since} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
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
]: any -> record<accountOnCustomerServer: string, accounting: record<taxNumbers: list<record>>, billingAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, branchId: int, categoriesIds: list<int>, clientFirstProjectDate: string, clientFirstQuoteDate: string, clientLastProjectDate: string, clientLastQuoteDate: string, clientNumberOfProjects: int, clientNumberOfQuotes: int, contact: record<emails: record<additional: list, cc: list, primary: string>, fax: string, phones: list<string>, sms: string, websites: list<string>>, contractNumber: string, correspondenceAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, customFields: table<key: string, name: string, type: string, value: record>, fullName: string, id: int, idNumber: string, industriesIds: list<int>, leadSourceId: int, limitAccessToPeopleResponsible: bool, name: string, notes: string, persons: table<active: bool, contact: record, customFields: list, customerId: int, firstProjectDate: string, firstQuoteDate: string, gender: string, id: int, lastName: string, lastProjectDate: string, lastQuoteDate: string, motherTonguesIds: list, name: string, numberOfProjects: int, numberOfQuotes: int, positionId: int>, responsiblePersons: record<accountManagerId: int, projectCoordinatorId: int, projectManagerId: int, salesPersonId: int>, salesNotes: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customers" $auth.query)
  let req_body = {"accountOnCustomerServer": $account_on_customer_server, "accounting": $accounting, "billingAddress": $billing_address, "branchId": $branch_id, "categoriesIds": $categories_ids, "clientFirstProjectDate": $client_first_project_date, "clientFirstQuoteDate": $client_first_quote_date, "clientLastProjectDate": $client_last_project_date, "clientLastQuoteDate": $client_last_quote_date, "clientNumberOfProjects": $client_number_of_projects, "clientNumberOfQuotes": $client_number_of_quotes, "contact": $contact, "contractNumber": $contract_number, "correspondenceAddress": $correspondence_address, "customFields": $custom_fields, "fullName": $full_name, "id": $id, "idNumber": $id_number, "industriesIds": $industries_ids, "leadSourceId": $lead_source_id, "limitAccessToPeopleResponsible": $limit_access_to_people_responsible, "name": $name, "notes": $notes, "persons": $persons, "responsiblePersons": $responsible_persons, "salesNotes": $sales_notes, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-post $req $req_body $insecure $raw $allow_errors $full []
}

# Returns clients' internal identifiers.
#
# GET /customers/ids
# operationId: getAllIds_2
export def "customers-ids get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only clients modified since this timestamp (format: int64)
  --name-equals: string # exact name of client
  --email-equals: string # exact email of client
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar") (serialize-qp "nameEquals" $name_equals "scalar") (serialize-qp "emailEquals" $email_equals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customers/ids" $qp $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"updatedSince": $updated_since, "nameEquals": $name_equals, "emailEquals": $email_equals} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
}

# Creates a new person.
#
# POST /customers/persons
# operationId: create_2
# --contact shape: {emails?: record, fax?: string, phones?: list<string>, sms?: string}
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
export def "customers-persons create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --contact: record # shape: {emails?: record, fax?: string, phones?: list<string>, sms?: string}
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --customer-id: int # format: int64
  --first-project-date: string # format: date-time
  --first-quote-date: string # format: date-time
  --gender: string@gender-completer
  --id: int # format: int64
  --last-name: string
  --last-project-date: string # format: date-time
  --last-quote-date: string # format: date-time
  --mother-tongues-ids: list<int>
  --name: string
  --number-of-projects: int # format: int32
  --number-of-quotes: int # format: int32
  --position-id: int # format: int64
]: any -> record<active: bool, contact: record<emails: record<additional: list, primary: string>, fax: string, phones: list<string>, sms: string>, customFields: table<key: string, name: string, type: string, value: record>, customerId: int, firstProjectDate: string, firstQuoteDate: string, gender: string, id: int, lastName: string, lastProjectDate: string, lastQuoteDate: string, motherTonguesIds: list<int>, name: string, numberOfProjects: int, numberOfQuotes: int, positionId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customers/persons" $auth.query)
  let req_body = {"active": $active, "contact": $contact, "customFields": $custom_fields, "customerId": $customer_id, "firstProjectDate": $first_project_date, "firstQuoteDate": $first_quote_date, "gender": $gender, "id": $id, "lastName": $last_name, "lastProjectDate": $last_project_date, "lastQuoteDate": $last_quote_date, "motherTonguesIds": $mother_tongues_ids, "name": $name, "numberOfProjects": $number_of_projects, "numberOfQuotes": $number_of_quotes, "positionId": $position_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --login-or-email: string
]: any -> record<token: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/customers/persons/accessToken" $auth.query)
  let req_body = {"loginOrEmail": $login_or_email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full []
}

# Returns persons' internal identifiers.
#
# GET /customers/persons/ids
# operationId: getAllIds_1
export def "customers-persons-ids get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only persons modified since this timestamp (format: int64)
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/customers/persons/ids" $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"updatedSince": $updated_since} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
}

# Removes a person.
#
# DELETE /customers/persons/{personId}
# operationId: delete_3
export def "customers-persons delete-by-person-id" [
  person_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/customers/persons/{person_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Returns person details.
#
# GET /customers/persons/{personId}
# operationId: getById_1
export def "customers-persons get-by-person-id" [
  person_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: bool, contact: record<emails: record<additional: list, primary: string>, fax: string, phones: list<string>, sms: string>, customFields: table<key: string, name: string, type: string, value: record>, customerId: int, firstProjectDate: string, firstQuoteDate: string, gender: string, id: int, lastName: string, lastProjectDate: string, lastQuoteDate: string, motherTonguesIds: list<int>, name: string, numberOfProjects: int, numberOfQuotes: int, positionId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/customers/persons/{person_id}") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Updates an existing person.
#
# PUT /customers/persons/{personId}
# operationId: update_1
# --contact shape: {emails?: record, fax?: string, phones?: list<string>, sms?: string}
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
export def "customers-persons update-by-person-id" [
  person_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --contact: record # shape: {emails?: record, fax?: string, phones?: list<string>, sms?: string}
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --customer-id: int # format: int64
  --first-project-date: string # format: date-time
  --first-quote-date: string # format: date-time
  --gender: string@gender-completer
  --id: int # format: int64
  --last-name: string
  --last-project-date: string # format: date-time
  --last-quote-date: string # format: date-time
  --mother-tongues-ids: list<int>
  --name: string
  --number-of-projects: int # format: int32
  --number-of-quotes: int # format: int32
  --position-id: int # format: int64
]: any -> record<active: bool, contact: record<emails: record<additional: list, primary: string>, fax: string, phones: list<string>, sms: string>, customFields: table<key: string, name: string, type: string, value: record>, customerId: int, firstProjectDate: string, firstQuoteDate: string, gender: string, id: int, lastName: string, lastProjectDate: string, lastQuoteDate: string, motherTonguesIds: list<int>, name: string, numberOfProjects: int, numberOfQuotes: int, positionId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/customers/persons/{person_id}") $auth.query)
  let req_body = {"active": $active, "contact": $contact, "customFields": $custom_fields, "customerId": $customer_id, "firstProjectDate": $first_project_date, "firstQuoteDate": $first_quote_date, "gender": $gender, "id": $id, "lastName": $last_name, "lastProjectDate": $last_project_date, "lastQuoteDate": $last_quote_date, "motherTonguesIds": $mother_tongues_ids, "name": $name, "numberOfProjects": $number_of_projects, "numberOfQuotes": $number_of_quotes, "positionId": $position_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<emails: record<additional: list<string>, primary: string>, fax: string, phones: list<string>, sms: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/customers/persons/{person_id}/contact") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Updates contact of a given person.
#
# PUT /customers/persons/{personId}/contact
# operationId: updateContact
# --emails shape: {additional?: list<string>, primary: string}
export def "customers-persons-contact update" [
  person_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --emails: record # emails — shape: {additional?: list<string>, primary: string}
  --fax: string # fax number
  --phones: list<string> # phones' numbers
  --sms: string # mobile phone for which SMS notifications will be sent (if configured)
]: any -> record<emails: record<additional: list<string>, primary: string>, fax: string, phones: list<string>, sms: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/customers/persons/{person_id}/contact") $auth.query)
  let req_body = {"emails": $emails, "fax": $fax, "phones": $phones, "sms": $sms} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<key: string, name: string, type: string, value: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/customers/persons/{person_id}/customFields") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Updates custom fields of a given person.
#
# PUT /customers/persons/{personId}/customFields
# operationId: updateCustomFields
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
export def "customers-persons-custom-fields update" [
  person_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> table<key: string, name: string, type: string, value: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/customers/persons/{person_id}/customFields") $auth.query)
  let req_body = {"customFields": $custom_fields, "empty": $empty} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full []
}

# Removes a customer price list.
#
# DELETE /customers/priceLists/{priceListId}
# operationId: delete_4
export def "customers-price-lists delete-by-price-list-id" [
  price_list_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($price_list_id | is-empty) { error make --unspanned { msg: "path parameter 'priceListId' must be non-empty" } }
  let full_url = (build-url $base ({price_list_id: (encode-path-segment $price_list_id)} | format pattern "/customers/priceLists/{price_list_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Removes a client.
#
# DELETE /customers/{customerId}
# operationId: delete_5
export def "customers delete-by-customer-id" [
  customer_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Returns client details.
#
# GET /customers/{customerId}
# operationId: getById_2
export def "customers get-by-customer-id" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: string # list of additional fields which should be embedded in the response (available options: persons)
]: nothing -> record<accountOnCustomerServer: string, accounting: record<taxNumbers: list<record>>, billingAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, branchId: int, categoriesIds: list<int>, clientFirstProjectDate: string, clientFirstQuoteDate: string, clientLastProjectDate: string, clientLastQuoteDate: string, clientNumberOfProjects: int, clientNumberOfQuotes: int, contact: record<emails: record<additional: list, cc: list, primary: string>, fax: string, phones: list<string>, sms: string, websites: list<string>>, contractNumber: string, correspondenceAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, customFields: table<key: string, name: string, type: string, value: record>, fullName: string, id: int, idNumber: string, industriesIds: list<int>, leadSourceId: int, limitAccessToPeopleResponsible: bool, name: string, notes: string, persons: table<active: bool, contact: record, customFields: list, customerId: int, firstProjectDate: string, firstQuoteDate: string, gender: string, id: int, lastName: string, lastProjectDate: string, lastQuoteDate: string, motherTonguesIds: list, name: string, numberOfProjects: int, numberOfQuotes: int, positionId: int>, responsiblePersons: record<accountManagerId: int, projectCoordinatorId: int, projectManagerId: int, salesPersonId: int>, salesNotes: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let qp = [(serialize-qp "embed" $embed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}") $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"embed": $embed} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
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
export def "customers update-by-customer-id" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
]: any -> record<accountOnCustomerServer: string, accounting: record<taxNumbers: list<record>>, billingAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, branchId: int, categoriesIds: list<int>, clientFirstProjectDate: string, clientFirstQuoteDate: string, clientLastProjectDate: string, clientLastQuoteDate: string, clientNumberOfProjects: int, clientNumberOfQuotes: int, contact: record<emails: record<additional: list, cc: list, primary: string>, fax: string, phones: list<string>, sms: string, websites: list<string>>, contractNumber: string, correspondenceAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, customFields: table<key: string, name: string, type: string, value: record>, fullName: string, id: int, idNumber: string, industriesIds: list<int>, leadSourceId: int, limitAccessToPeopleResponsible: bool, name: string, notes: string, persons: table<active: bool, contact: record, customFields: list, customerId: int, firstProjectDate: string, firstQuoteDate: string, gender: string, id: int, lastName: string, lastProjectDate: string, lastQuoteDate: string, motherTonguesIds: list, name: string, numberOfProjects: int, numberOfQuotes: int, positionId: int>, responsiblePersons: record<accountManagerId: int, projectCoordinatorId: int, projectManagerId: int, salesPersonId: int>, salesNotes: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}") $auth.query)
  let req_body = {"accountOnCustomerServer": $account_on_customer_server, "accounting": $accounting, "billingAddress": $billing_address, "branchId": $branch_id, "categoriesIds": $categories_ids, "clientFirstProjectDate": $client_first_project_date, "clientFirstQuoteDate": $client_first_quote_date, "clientLastProjectDate": $client_last_project_date, "clientLastQuoteDate": $client_last_quote_date, "clientNumberOfProjects": $client_number_of_projects, "clientNumberOfQuotes": $client_number_of_quotes, "contact": $contact, "contractNumber": $contract_number, "correspondenceAddress": $correspondence_address, "customFields": $custom_fields, "fullName": $full_name, "id": $id, "idNumber": $id_number, "industriesIds": $industries_ids, "leadSourceId": $lead_source_id, "limitAccessToPeopleResponsible": $limit_access_to_people_responsible, "name": $name, "notes": $notes, "persons": $persons, "responsiblePersons": $responsible_persons, "salesNotes": $sales_notes, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/address") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-line1: string # first line of address
  --address-line2: string # second line of address
  --city: string # city
  --country-id: int # country (format: int64)
  --postal-code: string # postal code
  --province-id: int # province (format: int64)
  --same-as-billing-address: oneof<nothing, bool> # should billing address be used instead of this one
]: any -> record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/address") $auth.query)
  let req_body = {"addressLine1": $address_line1, "addressLine2": $address_line2, "city": $city, "countryId": $country_id, "postalCode": $postal_code, "provinceId": $province_id, "sameAsBillingAddress": $same_as_billing_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/categories") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --empty: oneof<nothing, bool>
]: any -> list<int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/categories") $auth.query)
  let req_body = {"empty": $empty} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
}

# Returns contact of a given client.
#
# GET /customers/{customerId}/contact
# operationId: getContact_1
export def "customers-contact get-by-customer-id" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<emails: record<additional: list<string>, cc: list<string>, primary: string>, fax: string, phones: list<string>, sms: string, websites: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/contact") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Updates contact of a given client.
#
# PUT /customers/{customerId}/contact
# operationId: updateContact_1
# --emails shape: {additional?: list<string>, cc?: list<string>, primary: string}
export def "customers-contact update-by-customer-id" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --emails: record # emails — shape: {additional?: list<string>, cc?: list<string>, primary: string}
  --fax: string # fax number
  --phones: list<string> # phones' numbers
  --sms: string # mobile phone for which SMS notifications will be sent (if configured)
  --websites: list<string> # websites
]: any -> record<emails: record<additional: list<string>, cc: list<string>, primary: string>, fax: string, phones: list<string>, sms: string, websites: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/contact") $auth.query)
  let req_body = {"emails": $emails, "fax": $fax, "phones": $phones, "sms": $sms, "websites": $websites} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/correspondenceAddress") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-line1: string # first line of address
  --address-line2: string # second line of address
  --city: string # city
  --country-id: int # country (format: int64)
  --postal-code: string # postal code
  --province-id: int # province (format: int64)
  --same-as-billing-address: oneof<nothing, bool> # should billing address be used instead of this one
]: any -> record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/correspondenceAddress") $auth.query)
  let req_body = {"addressLine1": $address_line1, "addressLine2": $address_line2, "city": $city, "countryId": $country_id, "postalCode": $postal_code, "provinceId": $province_id, "sameAsBillingAddress": $same_as_billing_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
}

# Returns custom fields of a given client.
#
# GET /customers/{customerId}/customFields
# operationId: getCustomFields_1
export def "customers-custom-fields get-by-customer-id" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<key: string, name: string, type: string, value: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/customFields") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Updates custom fields of a given client.
#
# PUT /customers/{customerId}/customFields
# operationId: updateCustomFields_1
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
export def "customers-custom-fields update-by-customer-id" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> table<key: string, name: string, type: string, value: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/customFields") $auth.query)
  let req_body = {"customFields": $custom_fields, "empty": $empty} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: string, name: string, type: string, value: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($custom_field_key | is-empty) { error make --unspanned { msg: "path parameter 'customFieldKey' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), custom_field_key: (encode-path-segment $custom_field_key)} | format pattern "/customers/{customer_id}/customFields/{custom_field_key}") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --name: string
  --type: string@type-completer-1
  --value: record
]: any -> record<key: string, name: string, type: string, value: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($custom_field_key | is-empty) { error make --unspanned { msg: "path parameter 'customFieldKey' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), custom_field_key: (encode-path-segment $custom_field_key)} | format pattern "/customers/{customer_id}/customFields/{custom_field_key}") $auth.query)
  let req_body = {"key": $key, "name": $name, "type": $type, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/industries") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --empty: oneof<nothing, bool>
]: any -> list<int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/customers/{customer_id}/industries") $auth.query)
  let req_body = {"empty": $empty} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<calculationUnit: table<active: bool, canBeUsedInCatAnalysis: bool, catQuantityConversionExpression: string, default: bool, exchangeRatio: float, fileStatsConversionExpression: string, id: int, jobTypeIds: list, name: string, preferred: bool, symbol: string, timeToQuantityConversionExpression: string, type: string>, category: table<active: bool, default: bool, id: int, name: string, preferred: bool, supportedClasses: list>, country: table<active: bool, default: bool, id: int, name: string, preferred: bool, symbol: string>, currency: table<active: bool, default: bool, id: int, isoCode: string, name: string, preferred: bool, symbol: string>, industry: table<active: bool, default: bool, id: int, name: string, preferred: bool>, jobType: table<active: bool, calculationUnitIds: list, default: bool, filesNeeded: bool, id: int, name: string, preferred: bool, providedByClient: bool, relationToLanguage: string, vendorProductivity: float, vendorProductivityCalculationUnitId: int>, language: table<active: bool, default: bool, id: int, iso6391: string, iso6392: string, name: string, preferred: bool, symbol: string>, leadSource: table<active: bool, availableForCustomer: bool, availableForProvider: bool, default: bool, id: int, name: string, preferred: bool>, personDepartment: table<active: bool, default: bool, id: int, name: string, preferred: bool>, personPosition: table<active: bool, default: bool, id: int, name: string, preferred: bool>, province: table<active: bool, countryId: int, default: bool, id: int, name: string, preferred: bool>, specialization: table<active: bool, default: bool, id: int, name: string, preferred: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dictionaries/active" $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Returns dictionary entities for all types. Both active and not active ones.
#
# GET /dictionaries/all
# operationId: getAll_1
export def "dictionaries-all list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<calculationUnit: table<active: bool, canBeUsedInCatAnalysis: bool, catQuantityConversionExpression: string, default: bool, exchangeRatio: float, fileStatsConversionExpression: string, id: int, jobTypeIds: list, name: string, preferred: bool, symbol: string, timeToQuantityConversionExpression: string, type: string>, category: table<active: bool, default: bool, id: int, name: string, preferred: bool, supportedClasses: list>, country: table<active: bool, default: bool, id: int, name: string, preferred: bool, symbol: string>, currency: table<active: bool, default: bool, id: int, isoCode: string, name: string, preferred: bool, symbol: string>, industry: table<active: bool, default: bool, id: int, name: string, preferred: bool>, jobType: table<active: bool, calculationUnitIds: list, default: bool, filesNeeded: bool, id: int, name: string, preferred: bool, providedByClient: bool, relationToLanguage: string, vendorProductivity: float, vendorProductivityCalculationUnitId: int>, language: table<active: bool, default: bool, id: int, iso6391: string, iso6392: string, name: string, preferred: bool, symbol: string>, leadSource: table<active: bool, availableForCustomer: bool, availableForProvider: bool, default: bool, id: int, name: string, preferred: bool>, personDepartment: table<active: bool, default: bool, id: int, name: string, preferred: bool>, personPosition: table<active: bool, default: bool, id: int, name: string, preferred: bool>, province: table<active: bool, countryId: int, default: bool, id: int, name: string, preferred: bool>, specialization: table<active: bool, default: bool, id: int, name: string, preferred: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dictionaries/all" $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<dateFrom: record<value: int>, exchangeRate: string, lastModification: record<value: int>, originDetails: string, publicationDate: record<value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($iso_code | is-empty) { error make --unspanned { msg: "path parameter 'isoCode' must be non-empty" } }
  let full_url = (build-url $base ({iso_code: (encode-path-segment $iso_code)} | format pattern "/dictionaries/currency/{iso_code}/exchangeRate") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($iso_code | is-empty) { error make --unspanned { msg: "path parameter 'isoCode' must be non-empty" } }
  let full_url = (build-url $base ({iso_code: (encode-path-segment $iso_code)} | format pattern "/dictionaries/currency/{iso_code}/exchangeRate") $auth.query)
  let req_body = {"dateFrom": $date_from, "exchangeRate": $exchange_rate, "lastModification": $last_modification, "originDetails": $origin_details, "publicationDate": $publication_date} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name-equals: string # exact name of entity
]: nothing -> record<active: bool, andClearEventsQueue: record<all: list<record>, empty: bool, readyToBeDispatched: bool>, auditDisplayName: string, auditPath: string, classNameKey: string, classSimpleName: string, compoundId: string, defaultEntity: bool, displayName: string, entityMarkedAsNotSupposedToBePersisted: bool, eventsQueueReadyToBeDispatched: bool, id: int, identifier: record<compoundId: string, id: int>, internalDescription: string, lastModificationDate: string, name: string, packedCompoundId: string, preferedEntity: bool, preferred: bool, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  let qp = [(serialize-qp "nameEquals" $name_equals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type)} | format pattern "/dictionaries/{type}/active") $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"nameEquals": $name_equals} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name-equals: string # exact name of entity
]: nothing -> record<active: bool, andClearEventsQueue: record<all: list<record>, empty: bool, readyToBeDispatched: bool>, auditDisplayName: string, auditPath: string, classNameKey: string, classSimpleName: string, compoundId: string, defaultEntity: bool, displayName: string, entityMarkedAsNotSupposedToBePersisted: bool, eventsQueueReadyToBeDispatched: bool, id: int, identifier: record<compoundId: string, id: int>, internalDescription: string, lastModificationDate: string, name: string, packedCompoundId: string, preferedEntity: bool, preferred: bool, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  let qp = [(serialize-qp "nameEquals" $name_equals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type)} | format pattern "/dictionaries/{type}/all") $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"nameEquals": $name_equals} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: bool, andClearEventsQueue: record<all: list<record>, empty: bool, readyToBeDispatched: bool>, auditDisplayName: string, auditPath: string, classNameKey: string, classSimpleName: string, compoundId: string, defaultEntity: bool, displayName: string, entityMarkedAsNotSupposedToBePersisted: bool, eventsQueueReadyToBeDispatched: bool, id: int, identifier: record<compoundId: string, id: int>, internalDescription: string, lastModificationDate: string, name: string, packedCompoundId: string, preferedEntity: bool, preferred: bool, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/dictionaries/{type}/{id}") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/files" $auth.query)
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
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
  send-post $req $mp.body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<communication: record<instructionsForAllJobs: string, instructionsForJob: string, noteFromVendor: string>, dates: record<actualEndDate: int, actualStartDate: int, deadline: int, startDate: int>, documents: record<purchaseOrderStatus: string>, files: record<deliveredInJobFiles: list<string>, sharedReferenceFiles: list<string>, sharedWorkFiles: list<string>>, id: string, idNumber: string, languages: table<sourceLanguageId: int, specializationId: int, targetLanguageId: int>, name: string, status: string, stepNumber: int, stepType: record<id: string, jobTypeId: int, name: string, semantics: record<canVerifyFiles: bool, isScripted: bool>>, vendorId: int, vendorPriceProfileId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actual-end-date: int # format: int64
  --actual-start-date: int # format: int64
  --deadline: int # format: int64
  --start-date: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}/dates") $auth.query)
  let req_body = {"actualEndDate": $actual_end_date, "actualStartDate": $actual_start_date, "deadline": $deadline, "startDate": $start_date} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<inputFiles: table<content: string, name: string, token: string, url: string>, outputFiles: table<content: string, name: string, token: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}/files") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # file category
  --content: string
  --name: string
  --body-token: string
  --url: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}/files/output") $auth.query)
  let req_body = {"category": $category, "content": $content, "name": $name, "token": $body_token, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full []
}

# Returns file metadata.
#
# GET /jobs/{jobId}/files/{fileId}
# operationId: getJobFiles_1
export def "jobs-files get-by-job-id-file-id" [
  job_id: string
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<categoryKey: string, id: int, lastModifiedOn: int, name: string, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'fileId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id), file_id: (encode-path-segment $file_id)} | format pattern "/jobs/{job_id}/files/{file_id}") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}/instructions") $auth.query)
  let req_body = {"forProvider": $for_provider, "fromCustomer": $from_customer, "internal": $internal, "notes": $notes, "paymentNoteForCustomer": $payment_note_for_customer, "paymentNoteForVendor": $payment_note_for_vendor} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-id: string
  --status: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}/status") $auth.query)
  let req_body = {"externalId": $external_id, "status": $status} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recalculate-rates: oneof<nothing, bool>
  --vendor-price-profile-id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/jobs/{job_id}/vendor") $auth.query)
  let req_body = {"recalculateRates": $recalculate_rates, "vendorPriceProfileId": $vendor_price_profile_id} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<clientId: string, parameters: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/license" $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/license/refresh" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req null $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async: oneof<nothing, bool> # indicates whether the macro should be executed asynchronously or synchronously (default: false)
  --ids: list<int> # list of internal identifiers of elements to be processed by the macro, can be empty for certain macros
  --params: record # map of custom key-value pairs that can optionally parametrize the macro execution
]: any -> record<actionId: string, resultUrl: string, statusUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($macro_id | is-empty) { error make --unspanned { msg: "path parameter 'macroId' must be non-empty" } }
  let full_url = (build-url $base ({macro_id: (encode-path-segment $macro_id)} | format pattern "/macros/{macro_id}/run") $auth.query)
  let req_body = {"async": $async, "ids": $ids, "params": $params} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full []
}

# Creates a new Classic Project.
#
# POST /projects
# operationId: create_5
# --dates shape: {actualDeliveryDate?: record, actualStartDate?: record, deadline?: record, startDate?: record}
# --inputFiles item shape: {category?: "WORKFILE"|"TM"|"DICTIONARY"|"REF"|"LOG_FILE", content?: string, name?: string, token?: string, url?: string}
# --instructions shape: {forProvider?: string, fromCustomer?: string, internal?: string, notes?: string, paymentNoteForCustomer?: string, paymentNoteForVendor?: string}
# --people shape: {customerContacts?: record, responsiblePersons?: record}
export def "projects create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories-ids: list<int> # list of language categories
  customer_id: int # format: int64
  --dates: record # shape: {actualDeliveryDate?: record, actualStartDate?: record, deadline?: record, startDate?: record}
  --input-files: list # input files — item shape: {category?: "WORKFILE"|"TM"|"DICTIONARY"|"REF"|"LOG_FILE", content?: string, name?: string, token?: string, url?: string}
  --instructions: record # shape: {forProvider?: string, fromCustomer?: string, internal?: string, notes?: string, paymentNoteForCustomer?: string, paymentNoteForVendor?: string}
  --name: string
  --people: record # people — shape: {customerContacts?: record, responsiblePersons?: record}
  service_id: int # format: int64
  --source-language-id: int # format: int64
  specialization_id: int # format: int64
  --target-languages-ids: list<int>
]: any -> record<categoriesIds: list<int>, contactPersonId: int, contacts: record<additionalIds: list<int>, primaryId: int, sendBackToId: int>, customFields: table<key: string, name: string, type: string, value: record>, customerId: int, dates: record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>>, finance: record<ROI: float, currencyId: int, margin: float, payables: list<record>, profit: float, receivables: list<record>, totalAgreed: float, totalCost: float>, id: int, idNumber: string, instructions: record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>, isClassicProject: bool, name: string, projectId: string, projectManagerId: int, specializationId: int, status: string, tasks: table<clientTaskPONumber: string, customFields: list, dates: record, finance: record, id: int, idNumber: string, instructions: record, jobs: record, languageCombination: record, name: string, people: record, projectId: int, quoteId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects" $auth.query)
  let req_body = {"categoriesIds": $categories_ids, "customerId": $customer_id, "dates": $dates, "inputFiles": $input_files, "instructions": $instructions, "name": $name, "people": $people, "serviceId": $service_id, "sourceLanguageId": $source_language_id, "specializationId": $specialization_id, "targetLanguagesIds": $target_languages_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'fileId' must be non-empty" } }
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/projects/files/{file_id}/download") $auth.query)
  let accept_val = "multipart/form-data"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Returns projects' internal identifiers.
#
# GET /projects/ids
# operationId: getAllIds_6
export def "projects-ids get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only projects modified since this timestamp (format: int64)
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects/ids" $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"updatedSince": $updated_since} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
}

# Removes a project.
#
# DELETE /projects/{projectId}
# operationId: delete_12
export def "projects delete-by-project-id" [
  project_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Returns project details.
#
# GET /projects/{projectId}
# operationId: getById_7
export def "projects get-by-project-id-by-project-id" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: string # list of additional fields which should be embedded in the response (available options: tasks)
]: nothing -> record<categoriesIds: list<int>, contactPersonId: int, contacts: record<additionalIds: list<int>, primaryId: int, sendBackToId: int>, customFields: table<key: string, name: string, type: string, value: record>, customerId: int, dates: record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>>, finance: record<ROI: float, currencyId: int, margin: float, payables: list<record>, profit: float, receivables: list<record>, totalAgreed: float, totalCost: float>, id: int, idNumber: string, instructions: record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>, isClassicProject: bool, name: string, projectId: string, projectManagerId: int, specializationId: int, status: string, tasks: table<clientTaskPONumber: string, customFields: list, dates: record, finance: record, id: int, idNumber: string, instructions: record, jobs: record, languageCombination: record, name: string, people: record, projectId: int, quoteId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "embed" $embed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}") $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"embed": $embed} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<additionalIds: list<int>, primaryId: int, sendBackToId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/contacts") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-ids: list<int>
  --primary-id: int # format: int64
  --send-back-to-id: int # format: int64
]: any -> record<additionalIds: list<int>, primaryId: int, sendBackToId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/contacts") $auth.query)
  let req_body = {"additionalIds": $additional_ids, "primaryId": $primary_id, "sendBackToId": $send_back_to_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
}

# Returns custom fields of a given project.
#
# GET /projects/{projectId}/customFields
# operationId: getCustomFields_5
export def "projects-custom-fields get-by-project-id-by-project-id" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<key: string, name: string, type: string, value: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/customFields") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Updates custom fields of a given project.
#
# PUT /projects/{projectId}/customFields
# operationId: updateCustomFields_3
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
export def "projects-custom-fields update-by-project-id" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> table<key: string, name: string, type: string, value: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/customFields") $auth.query)
  let req_body = {"customFields": $custom_fields, "empty": $empty} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
}

# Returns dates of a given project.
#
# GET /projects/{projectId}/dates
# operationId: getDates_1
export def "projects-dates get-by-project-id" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/dates") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Updates dates of a given project.
#
# PUT /projects/{projectId}/dates
# operationId: updateDates_1
# --actualDeliveryDate shape: {value?: int}
# --actualStartDate shape: {value?: int}
# --deadline shape: {value?: int}
# --startDate shape: {value?: int}
export def "projects-dates update-by-project-id" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actual-delivery-date: record # shape: {value?: int}
  --actual-start-date: record # shape: {value?: int}
  --deadline: record # shape: {value?: int}
  --start-date: record # shape: {value?: int}
]: any -> record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/dates") $auth.query)
  let req_body = {"actualDeliveryDate": $actual_delivery_date, "actualStartDate": $actual_start_date, "deadline": $deadline, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ROI: float, currencyId: int, margin: float, payables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, profit: float, receivables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, totalAgreed: float, totalCost: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/finance") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --type: string@type-completer-2
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/finance/payables") $auth.query)
  let req_body = {"calculationUnitId": $calculation_unit_id, "catLogFile": $cat_log_file, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobId": $job_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
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
  send-post $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($payable_id | is-empty) { error make --unspanned { msg: "path parameter 'payableId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), payable_id: (encode-path-segment $payable_id)} | format pattern "/projects/{project_id}/finance/payables/{payable_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --type: string@type-completer-2
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($payable_id | is-empty) { error make --unspanned { msg: "path parameter 'payableId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), payable_id: (encode-path-segment $payable_id)} | format pattern "/projects/{project_id}/finance/payables/{payable_id}") $auth.query)
  let req_body = {"calculationUnitId": $calculation_unit_id, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobId": $job_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --type: string@type-completer-2
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/finance/receivables") $auth.query)
  let req_body = {"calculationUnitId": $calculation_unit_id, "catLogFile": $cat_log_file, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "taskId": $task_id, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
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
  send-post $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($receivable_id | is-empty) { error make --unspanned { msg: "path parameter 'receivableId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), receivable_id: (encode-path-segment $receivable_id)} | format pattern "/projects/{project_id}/finance/receivables/{receivable_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --type: string@type-completer-2
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($receivable_id | is-empty) { error make --unspanned { msg: "path parameter 'receivableId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), receivable_id: (encode-path-segment $receivable_id)} | format pattern "/projects/{project_id}/finance/receivables/{receivable_id}") $auth.query)
  let req_body = {"calculationUnitId": $calculation_unit_id, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "taskId": $task_id, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/instructions") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Updates instructions of a given project.
#
# PUT /projects/{projectId}/instructions
# operationId: updateInstructions_1
export def "projects-instructions update-by-project-id" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --for-provider: string
  --from-customer: string
  --internal: string
  --notes: string
  --payment-note-for-customer: string
  --payment-note-for-vendor: string
]: any -> record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/instructions") $auth.query)
  let req_body = {"forProvider": $for_provider, "fromCustomer": $from_customer, "internal": $internal, "notes": $notes, "paymentNoteForCustomer": $payment_note_for_customer, "paymentNoteForVendor": $payment_note_for_vendor} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-language-id: int # format: int64
  --target-language-id: int # format: int64
]: any -> record<sourceLanguageId: int, targetLanguageId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/languageCombinations") $auth.query)
  let req_body = {"sourceLanguageId": $source_language_id, "targetLanguageId": $target_language_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-post $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
]: any -> record<clientTaskPONumber: string, customFields: table<key: string, name: string, type: string, value: record>, dates: record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>>, finance: record<invoiceable: bool>, id: int, idNumber: string, instructions: record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>, jobs: record<jobCount: int, jobIds: list<int>>, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, name: string, people: record<customerContacts: record<additionalIds: list, primaryId: int, sendBackToId: int>, responsiblePersons: record<projectCoordinatorId: int, projectManagerId: int>>, projectId: int, quoteId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/tasks") $auth.query)
  let req_body = {"clientTaskPONumber": $client_task_po_number, "dates": $dates, "files": $files, "instructions": $instructions, "languageCombination": $language_combination, "name": $name, "people": $people, "specializationId": $specialization_id, "workflowId": $workflow_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-post $req $req_body $insecure $raw $allow_errors $full []
}

# Returns providers' internal identifiers.
#
# GET /providers/ids
# operationId: getAllIds_5
export def "providers-ids get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only providers modified since this timestamp (format: int64)
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/ids" $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"updatedSince": $updated_since} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
}

# Returns persons' internal identifiers.
#
# GET /providers/persons/ids
# operationId: getAllIds_4
export def "providers-persons-ids get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only persons modified since this timestamp (format: int64)
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/persons/ids" $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"updatedSince": $updated_since} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
}

# Removes a person.
#
# DELETE /providers/persons/{personId}
# operationId: delete_8
export def "providers-persons delete-by-person-id" [
  person_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/providers/persons/{person_id}") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Returns person details.
#
# GET /providers/persons/{personId}
# operationId: getById_4
export def "providers-persons get-by-person-id" [
  person_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: bool, contact: record<emails: record<additional: list, primary: string>, fax: string, phones: list<string>, sms: string>, customFields: table<key: string, name: string, type: string, value: record>, gender: string, id: int, lastName: string, motherTonguesIds: list<int>, name: string, positionId: int, providerId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/providers/persons/{person_id}") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Returns contact of a given person.
#
# GET /providers/persons/{personId}/contact
# operationId: getContact_2
export def "providers-persons-contact get-by-person-id" [
  person_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<emails: record<additional: list<string>, primary: string>, fax: string, phones: list<string>, sms: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/providers/persons/{person_id}/contact") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Returns custom fields of a given person.
#
# GET /providers/persons/{personId}/customFields
# operationId: getCustomFields_2
export def "providers-persons-custom-fields get-by-person-id" [
  person_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<key: string, name: string, type: string, value: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/providers/persons/{person_id}/customFields") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alreadyRegisteredPersonsCount: int, invitedPersonsCount: int, providersWithAlreadyRegisteredPersonCount: int, providersWithInvitedPersonCount: int, providersWithoutPersonCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($person_id | is-empty) { error make --unspanned { msg: "path parameter 'personId' must be non-empty" } }
  let full_url = (build-url $base ({person_id: (encode-path-segment $person_id)} | format pattern "/providers/persons/{person_id}/notification/invitation") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req null $insecure $raw $allow_errors $full []
}

# Removes a provider price list.
#
# DELETE /providers/priceLists/{priceListId}
# operationId: delete_9
export def "providers-price-lists delete-by-price-list-id" [
  price_list_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($price_list_id | is-empty) { error make --unspanned { msg: "path parameter 'priceListId' must be non-empty" } }
  let full_url = (build-url $base ({price_list_id: (encode-path-segment $price_list_id)} | format pattern "/providers/priceLists/{price_list_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Removes a provider.
#
# DELETE /providers/{providerId}
# operationId: delete_10
export def "providers delete-by-provider-id" [
  provider_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($provider_id | is-empty) { error make --unspanned { msg: "path parameter 'providerId' must be non-empty" } }
  let full_url = (build-url $base ({provider_id: (encode-path-segment $provider_id)} | format pattern "/providers/{provider_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Returns provider details.
#
# GET /providers/{providerId}
# operationId: getById_5
export def "providers get-by-provider-id" [
  provider_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: string # list of adittional fields which should be embedded in the response (ie. persons)
]: nothing -> record<billingAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, branchId: int, competencies: record<languageCombinations: list<record>>, contact: record<emails: record<additional: list, cc: list, primary: string>, fax: string, phones: list<string>, sms: string, websites: list<string>>, correspondenceAddress: record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool>, customFields: table<key: string, name: string, type: string, value: record>, fullName: string, id: int, idNumber: string, leadSourceId: int, name: string, notes: string, persons: table<active: bool, contact: record, customFields: list, gender: string, id: int, lastName: string, motherTonguesIds: list, name: string, positionId: int, providerId: int>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($provider_id | is-empty) { error make --unspanned { msg: "path parameter 'providerId' must be non-empty" } }
  let qp = [(serialize-qp "embed" $embed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({provider_id: (encode-path-segment $provider_id)} | format pattern "/providers/{provider_id}") $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"embed": $embed} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
}

# Returns address of a given provider.
#
# GET /providers/{providerId}/address
# operationId: getAddress_1
export def "providers-address get-by-provider-id" [
  provider_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($provider_id | is-empty) { error make --unspanned { msg: "path parameter 'providerId' must be non-empty" } }
  let full_url = (build-url $base ({provider_id: (encode-path-segment $provider_id)} | format pattern "/providers/{provider_id}/address") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<languageCombinations: table<sourceLanguageId: int, targetLanguageId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($provider_id | is-empty) { error make --unspanned { msg: "path parameter 'providerId' must be non-empty" } }
  let full_url = (build-url $base ({provider_id: (encode-path-segment $provider_id)} | format pattern "/providers/{provider_id}/competencies") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Returns contact of a given provider.
#
# GET /providers/{providerId}/contact
# operationId: getContact_3
export def "providers-contact get-by-provider-id" [
  provider_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<emails: record<additional: list<string>, cc: list<string>, primary: string>, fax: string, phones: list<string>, sms: string, websites: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($provider_id | is-empty) { error make --unspanned { msg: "path parameter 'providerId' must be non-empty" } }
  let full_url = (build-url $base ({provider_id: (encode-path-segment $provider_id)} | format pattern "/providers/{provider_id}/contact") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Returns correspondence address of a given provider.
#
# GET /providers/{providerId}/correspondenceAddress
# operationId: getCorrespondenceAddress_1
export def "providers-correspondence-address get-by-provider-id" [
  provider_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<addressLine1: string, addressLine2: string, city: string, countryId: int, postalCode: string, provinceId: int, sameAsBillingAddress: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($provider_id | is-empty) { error make --unspanned { msg: "path parameter 'providerId' must be non-empty" } }
  let full_url = (build-url $base ({provider_id: (encode-path-segment $provider_id)} | format pattern "/providers/{provider_id}/correspondenceAddress") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Returns custom fields of a given provider.
#
# GET /providers/{providerId}/customFields
# operationId: getCustomFields_3
export def "providers-custom-fields get-by-provider-id" [
  provider_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<key: string, name: string, type: string, value: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($provider_id | is-empty) { error make --unspanned { msg: "path parameter 'providerId' must be non-empty" } }
  let full_url = (build-url $base ({provider_id: (encode-path-segment $provider_id)} | format pattern "/providers/{provider_id}/customFields") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Sends invitations to Vendor Portal.
#
# POST /providers/{providerId}/notification/invitation
# operationId: sendInvitations_1
export def "providers-notification-invitation send-by-provider-id" [
  provider_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alreadyRegisteredPersonsCount: int, invitedPersonsCount: int, providersWithAlreadyRegisteredPersonCount: int, providersWithInvitedPersonCount: int, providersWithoutPersonCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($provider_id | is-empty) { error make --unspanned { msg: "path parameter 'providerId' must be non-empty" } }
  let full_url = (build-url $base ({provider_id: (encode-path-segment $provider_id)} | format pattern "/providers/{provider_id}/notification/invitation") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req null $insecure $raw $allow_errors $full []
}

# Returns quotes' internal identifiers.
#
# GET /quotes/ids
# operationId: getAllIds_7
export def "quotes-ids get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --updated-since: int # only quotes modified since this timestamp (format: int64)
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedSince" $updated_since "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/quotes/ids" $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"updatedSince": $updated_since} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
}

# Removes a quote.
#
# DELETE /quotes/{quoteId}
# operationId: delete_13
export def "quotes delete-by-quote-id" [
  quote_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Returns quote details.
#
# GET /quotes/{quoteId}
# operationId: getById_8
export def "quotes get-by-quote-id-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: string # list of adittional fields which should be embedded in the response (ie. tasks)
]: nothing -> record<automaticallyAcceptSentQuote: bool, categoriesIds: list<int>, contactPersonId: int, customFields: table<key: string, name: string, type: string, value: record>, customerId: int, dates: record<createdOn: record<value: int>, deadline: record<value: int>, offerExpiry: record<value: int>, startDate: record<value: int>>, finance: record<ROI: float, currencyId: int, margin: float, payables: list<record>, profit: float, receivables: list<record>, totalAgreed: float, totalCost: float>, id: int, idNumber: string, instructions: record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>, isClassicQuote: bool, name: string, quoteId: string, salesPersonId: int, status: string, tasks: table<clientTaskPONumber: string, customFields: list, dates: record, finance: record, id: int, idNumber: string, instructions: record, jobs: record, languageCombination: record, name: string, people: record, projectId: int, quoteId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let qp = [(serialize-qp "embed" $embed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}") $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"embed": $embed} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
}

# Sends a quote for customer confirmation.
#
# POST /quotes/{quoteId}/confirmation/send
# operationId: send_1
export def "quotes-confirmation-send send-by-quote-id" [
  quote_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/confirmation/send") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# Returns custom fields of a given quote.
#
# GET /quotes/{quoteId}/customFields
# operationId: getCustomFields_6
export def "quotes-custom-fields get-by-quote-id-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<key: string, name: string, type: string, value: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/customFields") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Updates custom fields of a given quote.
#
# PUT /quotes/{quoteId}/customFields
# operationId: updateCustomFields_4
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
export def "quotes-custom-fields update-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> table<key: string, name: string, type: string, value: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/customFields") $auth.query)
  let req_body = {"customFields": $custom_fields, "empty": $empty} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
}

# Returns dates of a given quote.
#
# GET /quotes/{quoteId}/dates
# operationId: getDates_2
export def "quotes-dates get-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdOn: record<value: int>, deadline: record<value: int>, offerExpiry: record<value: int>, startDate: record<value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/dates") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Returns finance of a given quote.
#
# GET /quotes/{quoteId}/finance
# operationId: getFinance_1
export def "quotes-finance get-by-quote-id-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ROI: float, currencyId: int, margin: float, payables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, profit: float, receivables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, totalAgreed: float, totalCost: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/finance") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Adds a payable.
#
# POST /quotes/{quoteId}/finance/payables
# operationId: createPayable_1
# --catLogFile shape: {content?: string, name?: string, token?: string, url?: string}
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-payables create-by-quote-id-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --type: string@type-completer-2
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/finance/payables") $auth.query)
  let req_body = {"calculationUnitId": $calculation_unit_id, "catLogFile": $cat_log_file, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobId": $job_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "total": $total, "type": $type} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full []
}

# Deletes a payable.
#
# DELETE /quotes/{quoteId}/finance/payables/{payableId}
# operationId: deletePayable_1
export def "quotes-finance-payables delete-by-quote-id-payable-id-by-quote-id-payable-id" [
  quote_id: string
  payable_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  if ($payable_id | is-empty) { error make --unspanned { msg: "path parameter 'payableId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), payable_id: (encode-path-segment $payable_id)} | format pattern "/quotes/{quote_id}/finance/payables/{payable_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Updates a payable.
#
# PUT /quotes/{quoteId}/finance/payables/{payableId}
# operationId: updatePayable_1
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-payables update-by-quote-id-payable-id-by-quote-id-payable-id" [
  quote_id: string
  payable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --type: string@type-completer-2
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  if ($payable_id | is-empty) { error make --unspanned { msg: "path parameter 'payableId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), payable_id: (encode-path-segment $payable_id)} | format pattern "/quotes/{quote_id}/finance/payables/{payable_id}") $auth.query)
  let req_body = {"calculationUnitId": $calculation_unit_id, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobId": $job_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "total": $total, "type": $type} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
}

# Adds a receivable.
#
# POST /quotes/{quoteId}/finance/receivables
# operationId: createReceivable_1
# --catLogFile shape: {content?: string, name?: string, token?: string, url?: string}
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-receivables create-by-quote-id-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --type: string@type-completer-2
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/finance/receivables") $auth.query)
  let req_body = {"calculationUnitId": $calculation_unit_id, "catLogFile": $cat_log_file, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "taskId": $task_id, "total": $total, "type": $type} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full []
}

# Deletes a receivable.
#
# DELETE /quotes/{quoteId}/finance/receivables/{receivableId}
# operationId: deleteReceivable_1
export def "quotes-finance-receivables delete-by-quote-id-receivable-id-by-quote-id-receivable-id" [
  quote_id: string
  receivable_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  if ($receivable_id | is-empty) { error make --unspanned { msg: "path parameter 'receivableId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), receivable_id: (encode-path-segment $receivable_id)} | format pattern "/quotes/{quote_id}/finance/receivables/{receivable_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Updates a receivable.
#
# PUT /quotes/{quoteId}/finance/receivables/{receivableId}
# operationId: updateReceivable_1
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-receivables update-by-quote-id-receivable-id-by-quote-id-receivable-id" [
  quote_id: string
  receivable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --type: string@type-completer-2
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  if ($receivable_id | is-empty) { error make --unspanned { msg: "path parameter 'receivableId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), receivable_id: (encode-path-segment $receivable_id)} | format pattern "/quotes/{quote_id}/finance/receivables/{receivable_id}") $auth.query)
  let req_body = {"calculationUnitId": $calculation_unit_id, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "taskId": $task_id, "total": $total, "type": $type} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
}

# Returns instructions of a given quote.
#
# GET /quotes/{quoteId}/instructions
# operationId: getInstructions_1
export def "quotes-instructions get-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/instructions") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Updates instructions of a given quote.
#
# PUT /quotes/{quoteId}/instructions
# operationId: updateInstructions_2
export def "quotes-instructions update-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --for-provider: string
  --from-customer: string
  --internal: string
  --notes: string
  --payment-note-for-customer: string
  --payment-note-for-vendor: string
]: any -> record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/instructions") $auth.query)
  let req_body = {"forProvider": $for_provider, "fromCustomer": $from_customer, "internal": $internal, "notes": $notes, "paymentNoteForCustomer": $payment_note_for_customer, "paymentNoteForVendor": $payment_note_for_vendor} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
}

# Creates a new language combination for a given quote without creating a task.
#
# POST /quotes/{quoteId}/languageCombinations
# operationId: createLanguageCombination_1
export def "quotes-language-combinations create-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-language-id: int # format: int64
  --target-language-id: int # format: int64
]: any -> record<sourceLanguageId: int, targetLanguageId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/languageCombinations") $auth.query)
  let req_body = {"sourceLanguageId": $source_language_id, "targetLanguageId": $target_language_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-post $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/start") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req null $insecure $raw $allow_errors $full [204]
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
export def "quotes-tasks create-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
]: any -> record<clientTaskPONumber: string, customFields: table<key: string, name: string, type: string, value: record>, dates: record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>>, finance: record<invoiceable: bool>, id: int, idNumber: string, instructions: record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string>, jobs: record<jobCount: int, jobIds: list<int>>, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, name: string, people: record<customerContacts: record<additionalIds: list, primaryId: int, sendBackToId: int>, responsiblePersons: record<projectCoordinatorId: int, projectManagerId: int>>, projectId: int, quoteId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/quotes/{quote_id}/tasks") $auth.query)
  let req_body = {"clientTaskPONumber": $client_task_po_number, "customFields": $custom_fields, "dates": $dates, "finance": $finance, "id": $id, "idNumber": $id_number, "instructions": $instructions, "jobs": $jobs, "languageCombination": $language_combination, "name": $name, "people": $people, "projectId": $project_id, "quoteId": $body_quote_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-post $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<int>
]: any -> record<url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/export/xml" $auth.query)
  let req_body = {"ids": $ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-token: string
]: any -> record<currentSystemVersion: string, importedReportsNames: list<string>, invalidReportsNames: list<string>, targetSystemVersion: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/import/xml" $auth.query)
  let req_body = {"fileToken": $file_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full []
}

# Removes a report.
#
# DELETE /reports/{reportId}
# operationId: delete_11
export def "reports delete-by-report-id" [
  report_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($report_id | is-empty) { error make --unspanned { msg: "path parameter 'reportId' must be non-empty" } }
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id)} | format pattern "/reports/{report_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Duplicates a report.
#
# POST /reports/{reportId}/duplicate
# operationId: duplicate_1
export def "reports-duplicate create-by-report-id" [
  report_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($report_id | is-empty) { error make --unspanned { msg: "path parameter 'reportId' must be non-empty" } }
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id)} | format pattern "/reports/{report_id}/duplicate") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req null $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --preferred: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($report_id | is-empty) { error make --unspanned { msg: "path parameter 'reportId' must be non-empty" } }
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id)} | format pattern "/reports/{report_id}/preferred") $auth.query)
  let req_body = {"preferred": $preferred} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($report_id | is-empty) { error make --unspanned { msg: "path parameter 'reportId' must be non-empty" } }
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id)} | format pattern "/reports/{report_id}/result/csv") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($report_id | is-empty) { error make --unspanned { msg: "path parameter 'reportId' must be non-empty" } }
  let full_url = (build-url $base ({report_id: (encode-path-segment $report_id)} | format pattern "/reports/{report_id}/result/printerFriendly") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name-equals: string # exact name of entity
]: nothing -> record<active: bool, default: bool, id: int, name: string, preferred: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nameEquals" $name_equals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/services/active" $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"nameEquals": $name_equals} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
}

# Returns services list
#
# GET /services/all
# operationId: getAll_3
export def "services-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name-equals: string # exact name of entity
]: nothing -> record<active: bool, default: bool, id: int, name: string, preferred: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nameEquals" $name_equals "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/services/all" $qp $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"nameEquals": $name_equals} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
}

# Returns all subscriptions
#
# GET /subscription
# operationId: getAll_4
export def "subscription get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<embed: string, event: string, filter: string, subscriptionId: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscription" $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: string # additional fields which should be embedded in the event
  --event: string # event to which you want to subscribe
  --filter: string # filter expression in the form 'attribute=value'
  --url: string # url that will be invoked by XTRF on event
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscription" $auth.query)
  let req_body = {"embed": $embed, "event": $event, "filter": $filter, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<bool, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subscription/supports" $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscription/{subscription_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Removes a task.
#
# DELETE /tasks/{taskId}
# operationId: delete_14
export def "tasks delete-by-task-id" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --remove-files-from-disc: oneof<nothing, bool> # remove files from disc
  --remove-external-projects: oneof<nothing, bool> # remove external projects (ie. from CAT Tool)
  --force-jobs-removal: oneof<nothing, bool> # force jobs removal (ie. started or ready)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let qp = [(serialize-qp "removeFilesFromDisc" $remove_files_from_disc "scalar") (serialize-qp "removeExternalProjects" $remove_external_projects "scalar") (serialize-qp "forceJobsRemoval" $force_jobs_removal "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"removeFilesFromDisc": $remove_files_from_disc, "removeExternalProjects": $remove_external_projects, "forceJobsRemoval": $force_jobs_removal} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> record<value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/clientTaskPONumber") $auth.query)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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

# Returns contacts of a given task.
#
# GET /tasks/{taskId}/contacts
# operationId: getContacts_1
export def "tasks-contacts get-by-task-id" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<additionalIds: list<int>, primaryId: int, sendBackToId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/contacts") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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

# Updates contacts of a given task.
#
# PUT /tasks/{taskId}/contacts
# operationId: updateContacts_1
export def "tasks-contacts update-by-task-id" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-ids: list<int>
  --primary-id: int # format: int64
  --send-back-to-id: int # format: int64
]: any -> record<additionalIds: list<int>, primaryId: int, sendBackToId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/contacts") $auth.query)
  let req_body = {"additionalIds": $additional_ids, "primaryId": $primary_id, "sendBackToId": $send_back_to_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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

# Returns custom fields of a given task.
#
# GET /tasks/{taskId}/customFields
# operationId: getCustomFields_7
export def "tasks-custom-fields get-by-task-id" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<key: string, name: string, type: string, value: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/customFields") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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

# Updates custom fields of a given task.
#
# PUT /tasks/{taskId}/customFields
# operationId: updateCustomFields_5
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
export def "tasks-custom-fields update-by-task-id" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> table<key: string, name: string, type: string, value: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/customFields") $auth.query)
  let req_body = {"customFields": $custom_fields, "empty": $empty} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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

# Returns dates of a given task.
#
# GET /tasks/{taskId}/dates
# operationId: getDates_3
export def "tasks-dates get-by-task-id" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/dates") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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

# Updates dates of a given task.
#
# PUT /tasks/{taskId}/dates
# operationId: updateDates_2
# --actualDeliveryDate shape: {value?: int}
# --actualStartDate shape: {value?: int}
# --deadline shape: {value?: int}
# --startDate shape: {value?: int}
export def "tasks-dates update-by-task-id" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actual-delivery-date: record # shape: {value?: int}
  --actual-start-date: record # shape: {value?: int}
  --deadline: record # shape: {value?: int}
  --start-date: record # shape: {value?: int}
]: any -> record<actualDeliveryDate: record<value: int>, actualStartDate: record<value: int>, deadline: record<value: int>, startDate: record<value: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/dates") $auth.query)
  let req_body = {"actualDeliveryDate": $actual_delivery_date, "actualStartDate": $actual_start_date, "deadline": $deadline, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bundles: record, inputFiles: record<logFiles: list<record>, referenceFiles: list<record>, terminology: list<record>, tm: list<record>, workFiles: list<record>>, jobs: table<files: record, id: int, idNumber: string, name: string>, outputFiles: table<content: string, name: string, token: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/files") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string
  --name: string
  --body-token: string
  --url: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/files/input") $auth.query)
  let req_body = {"content": $content, "name": $name, "token": $body_token, "url": $url} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Returns instructions of a given task.
#
# GET /tasks/{taskId}/instructions
# operationId: getInstructions_2
export def "tasks-instructions get-by-task-id" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/instructions") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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

# Updates instructions of a given task.
#
# PUT /tasks/{taskId}/instructions
# operationId: updateInstructions_3
export def "tasks-instructions update-by-task-id" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --for-provider: string
  --from-customer: string
  --internal: string
  --notes: string
  --payment-note-for-customer: string
  --payment-note-for-vendor: string
]: any -> record<forProvider: string, fromCustomer: string, internal: string, notes: string, paymentNoteForCustomer: string, paymentNoteForVendor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/instructions") $auth.query)
  let req_body = {"forProvider": $for_provider, "fromCustomer": $from_customer, "internal": $internal, "notes": $notes, "paymentNoteForCustomer": $payment_note_for_customer, "paymentNoteForVendor": $payment_note_for_vendor} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> record<value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/name") $auth.query)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<phase: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/progress") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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

# Starts a task.
#
# POST /tasks/{taskId}/start
# operationId: start_1
export def "tasks-start start-by-task-id" [
  task_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($task_id | is-empty) { error make --unspanned { msg: "path parameter 'taskId' must be non-empty" } }
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/tasks/{task_id}/start") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# Returns list of simple users representations
#
# GET /users
# operationId: getAllNamesWithIds_1
export def "users get-list-names" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users" $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<customFields: table<key: string, name: string, type: string, value: record>, email: string, firstName: string, gender: string, id: int, lastName: string, login: string, mobilePhone: string, phone: string, positionName: string, timeZoneId: string, userGroupName: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me" $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<displayName: string, id: string, offset: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me/timeZone" $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Returns user details.
#
# GET /users/{userId}
# operationId: getById_6
export def "users get-by-user-id" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<customFields: table<key: string, name: string, type: string, value: record>, email: string, firstName: string, gender: string, id: int, lastName: string, login: string, mobilePhone: string, phone: string, positionName: string, timeZoneId: string, userGroupName: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Updates an existing user.
#
# PUT /users/{userId}
# operationId: update_3
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
export def "users update-by-user-id" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
]: any -> record<customFields: table<key: string, name: string, type: string, value: record>, email: string, firstName: string, gender: string, id: int, lastName: string, login: string, mobilePhone: string, phone: string, positionName: string, timeZoneId: string, userGroupName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}") $auth.query)
  let req_body = {"customFields": $custom_fields, "email": $email, "firstName": $first_name, "gender": $gender, "id": $id, "lastName": $last_name, "login": $login, "mobilePhone": $mobile_phone, "phone": $phone, "positionName": $position_name, "timeZoneId": $time_zone_id, "userGroupName": $user_group_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
}

# Returns custom fields of a given user.
#
# GET /users/{userId}/customFields
# operationId: getCustomFields_4
export def "users-custom-fields get-by-user-id" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<key: string, name: string, type: string, value: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/customFields") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Updates custom fields of a given user.
#
# PUT /users/{userId}/customFields
# operationId: updateCustomFields_2
# --customFields item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
export def "users-custom-fields update-by-user-id" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-fields: list # item shape: {key?: string, name?: string, type?: "TEXT"|"DATE"|"DATE_AND_TIME"|"NUMBER"|"CHECKBOX"|"SELECTION"|"MULTI_SELECTION", value?: record}
  --empty: oneof<nothing, bool>
]: any -> table<key: string, name: string, type: string, value: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/customFields") $auth.query)
  let req_body = {"customFields": $custom_fields, "empty": $empty} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
}

# Returns custom field of a given user.
#
# GET /users/{userId}/customFields/{customFieldKey}
# operationId: getCustomField_1
export def "users-custom-fields get-by-user-id-custom-field-key" [
  user_id: int
  custom_field_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: string, name: string, type: string, value: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($custom_field_key | is-empty) { error make --unspanned { msg: "path parameter 'customFieldKey' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), custom_field_key: (encode-path-segment $custom_field_key)} | format pattern "/users/{user_id}/customFields/{custom_field_key}") $auth.query)
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Updates given custom field of a given user.
#
# PUT /users/{userId}/customFields/{customFieldKey}
# operationId: updateCustomField_1
export def "users-custom-fields update-by-user-id-custom-field-key" [
  user_id: int
  custom_field_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string
  --name: string
  --type: string@type-completer-1
  --value: record
]: any -> record<key: string, name: string, type: string, value: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  if ($custom_field_key | is-empty) { error make --unspanned { msg: "path parameter 'customFieldKey' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), custom_field_key: (encode-path-segment $custom_field_key)} | format pattern "/users/{user_id}/customFields/{custom_field_key}") $auth.query)
  let req_body = {"key": $key, "name": $name, "type": $type, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/vnd.xtrf-v1+json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --new-password: string # new password
  --old-password: string # old password
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/password") $auth.query)
  let req_body = {"newPassword": $new_password, "oldPassword": $old_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body_wire $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-project-id: string # job's externalProjectId
  --external-id: string # job's external identifier
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "externalProjectId" $external_project_id "scalar") (serialize-qp "externalId" $external_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/jobs/for-external-id" $qp $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"externalProjectId": $external_project_id, "externalId": $external_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full []
}

# Returns details for a job.
#
# GET /v2/jobs/{jobId}
# operationId: getFileById_1
export def "jobs get-file-by-job-id" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list<record>, languages: list<int>>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --actual-end-date: int # format: int64
  --actual-start-date: int # format: int64
  --deadline: int # format: int64
  --start-date: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/dates") $auth.query)
  let req_body = {"actualEndDate": $actual_end_date, "actualStartDate": $actual_start_date, "deadline": $deadline, "startDate": $start_date} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/files/addExternalLink") $auth.query)
  let req_body = {"category": $category, "externalInfo": $external_info, "filename": $filename, "languageCombinationIds": $language_combination_ids, "languageIds": $language_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
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
  send-post $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list, languages: list>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/files/delivered") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --files: list # item shape: {category?: string, fileId?: string, languageCombinationIds?: list, languageIds?: list<int>}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/files/delivered/add") $auth.query)
  let req_body = {"files": $files} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-links: list # item shape: {category?: string, externalInfo?: record, filename?: string, languageCombinationIds?: list, languageIds?: list<int>, toBeGenerated?: bool, url?: string}
]: any -> record<files: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/files/delivered/addLink") $auth.query)
  let req_body = {"fileLinks": $file_links} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
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
  send-post $req $req_body $insecure $raw $allow_errors $full []
}

# Uploads file to the project as a file delivered in the job.
#
# POST /v2/jobs/{jobId}/files/delivered/upload
# operationId: uploadFile_1
export def "jobs-files-delivered-upload upload-by-job-id" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # format: binary
]: any -> record<fileId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/files/delivered/upload") $auth.query)
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
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
  send-post $req $mp.body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list, languages: list>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/files/sharedReferenceFiles") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --files: list<string>
]: any -> record<statuses: table<fileId: string, message: string, successful: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/files/sharedReferenceFiles/share") $auth.query)
  let req_body = {"files": $files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list, languages: list>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/files/sharedWorkFiles") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --files: list<string>
]: any -> record<statuses: table<fileId: string, message: string, successful: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/files/sharedWorkFiles/share") $auth.query)
  let req_body = {"files": $files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --files: list<string>
]: any -> record<statuses: table<fileId: string, message: string, successful: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/files/stopSharing") $auth.query)
  let req_body = {"files": $files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full []
}

# Updates instructions for a job.
#
# PUT /v2/jobs/{jobId}/instructions
# operationId: updateInstructions_4
export def "jobs-instructions update-by-job-id" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/instructions") $auth.query)
  let req_body = {"value": $value} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Changes job status if possible (400 Bad Request is returned otherwise).
#
# PUT /v2/jobs/{jobId}/status
# operationId: changeStatus_1
export def "jobs-status update-change-by-job-id" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-id: string
  --status: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/status") $auth.query)
  let req_body = {"externalId": $external_id, "status": $status} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Assigns vendor to a job in a project.
#
# PUT /v2/jobs/{jobId}/vendor
# operationId: assignVendor_1
export def "jobs-vendor assign-by-job-id" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --vendor-price-profile-id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($job_id | is-empty) { error make --unspanned { msg: "path parameter 'jobId' must be non-empty" } }
  let full_url = (build-url $base ({job_id: (encode-path-segment $job_id)} | format pattern "/v2/jobs/{job_id}/vendor") $auth.query)
  let req_body = {"vendorPriceProfileId": $vendor_price_profile_id} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Creates a new Smart Project.
#
# POST /v2/projects
# operationId: create_6
export def "projects create-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: int # format: int64
  --external-id: string
  --name: string
  --service-id: int # format: int64
]: any -> record<budgetCode: string, categoryIds: list<int>, clientDeadline: int, clientId: int, clientNotes: string, clientReferenceNumber: string, documents: record<projectConfirmationStatus: string>, id: string, instructionsForAllJobs: string, internalNotes: string, isClassicProject: bool, languages: record<languageCombinations: list<record>, sourceLanguageId: int, specializationId: int, targetLanguageIds: list<int>>, name: string, orderedOn: int, origin: string, people: record<projectManagerId: int>, projectId: string, projectIdNumber: string, quoteIdNumber: string, serviceId: int, status: string, volume: record<unitId: int, value: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects" $auth.query)
  let req_body = {"clientId": $client_id, "externalId": $external_id, "name": $name, "serviceId": $service_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --files: list<string>
]: any -> record<archiveUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/projects/files/archive" $auth.query)
  let req_body = {"files": $files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
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
  send-post $req $req_body $insecure $raw $allow_errors $full []
}

# Returns details of a file.
#
# GET /v2/projects/files/{fileId}
# operationId: getFileById_2
export def "projects-files get-by-file-id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list<record>, languages: list<int>>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'fileId' must be non-empty" } }
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/v2/projects/files/{file_id}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'fileId' must be non-empty" } }
  if ($file_name | is-empty) { error make --unspanned { msg: "path parameter 'fileName' must be non-empty" } }
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id), file_name: (encode-path-segment $file_name)} | format pattern "/v2/projects/files/{file_id}/download/{file_name}") $auth.query)
  let accept_val = "multipart/form-data"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Returns project details.
#
# GET /v2/projects/for-external-id/{externalProjectId}
# operationId: getByExternalId_1
export def "projects-for-external-id get-by-external-project-id" [
  external_project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<budgetCode: string, categoryIds: list<int>, clientDeadline: int, clientId: int, clientNotes: string, clientReferenceNumber: string, documents: record<projectConfirmationStatus: string>, id: string, instructionsForAllJobs: string, internalNotes: string, isClassicProject: bool, languages: record<languageCombinations: list<record>, sourceLanguageId: int, specializationId: int, targetLanguageIds: list<int>>, name: string, orderedOn: int, origin: string, people: record<projectManagerId: int>, projectId: string, projectIdNumber: string, quoteIdNumber: string, serviceId: int, status: string, volume: record<unitId: int, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($external_project_id | is-empty) { error make --unspanned { msg: "path parameter 'externalProjectId' must be non-empty" } }
  let full_url = (build-url $base ({external_project_id: (encode-path-segment $external_project_id)} | format pattern "/v2/projects/for-external-id/{external_project_id}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Returns project details.
#
# GET /v2/projects/{projectId}
# operationId: getById_9
export def "projects get-by-project-id-by-project-id-1" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<budgetCode: string, categoryIds: list<int>, clientDeadline: int, clientId: int, clientNotes: string, clientReferenceNumber: string, documents: record<projectConfirmationStatus: string>, id: string, instructionsForAllJobs: string, internalNotes: string, isClassicProject: bool, languages: record<languageCombinations: list<record>, sourceLanguageId: int, specializationId: int, targetLanguageIds: list<int>>, name: string, orderedOn: int, origin: string, people: record<projectManagerId: int>, projectId: string, projectIdNumber: string, quoteIdNumber: string, serviceId: int, status: string, volume: record<unitId: int, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<projectCreatedInCatToolOrCreationIsQueued: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/addJob") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-post $req null $insecure $raw $allow_errors $full []
}

# Returns if cat tool project is created or queued.
#
# GET /v2/projects/{projectId}/catToolProject
# operationId: getCATToolProjectInfo
export def "projects-cat-tool-project get" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<projectCreatedInCatToolOrCreationIsQueued: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/catToolProject") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Returns Client Contacts information for a project.
#
# GET /v2/projects/{projectId}/clientContacts
# operationId: getContacts_2
export def "projects-client-contacts get-by-project-id" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<additionalIds: list<int>, primaryId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/clientContacts") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Updates Client Contacts for a project.
#
# PUT /v2/projects/{projectId}/clientContacts
# operationId: updateContacts_2
export def "projects-client-contacts update-by-project-id" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-ids: list<int>
  --primary-id: int # format: int64
]: any -> record<additionalIds: list<int>, primaryId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/clientContacts") $auth.query)
  let req_body = {"additionalIds": $additional_ids, "primaryId": $primary_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/clientDeadline") $auth.query)
  let req_body = {"value": $value} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/clientNotes") $auth.query)
  let req_body = {"value": $value} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/clientReferenceNumber") $auth.query)
  let req_body = {"value": $value} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Returns a list of custom field keys and values for a project.
#
# GET /v2/projects/{projectId}/customFields
# operationId: getCustomFields_8
export def "projects-custom-fields get-by-project-id-by-project-id-1" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<key: string, name: string, type: string, value: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/customFields") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Updates a custom field with a specified key in a project
#
# PUT /v2/projects/{projectId}/customFields/{key}
# operationId: updateCustomField_2
export def "projects-custom-fields update-by-project-id-key" [
  project_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), key: (encode-path-segment $key)} | format pattern "/v2/projects/{project_id}/customFields/{key}") $auth.query)
  let req_body = {"value": $value} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list, languages: list>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/files") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Adds files to the project as added by PM.
#
# PUT /v2/projects/{projectId}/files/add
# operationId: addFiles_1
# --files item shape: {category?: string, fileId?: string, languageCombinationIds?: list, languageIds?: list<int>}
export def "projects-files-add create-by-project-id" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --files: list # item shape: {category?: string, fileId?: string, languageCombinationIds?: list, languageIds?: list<int>}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/files/add") $auth.query)
  let req_body = {"files": $files} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/files/addExternalLink") $auth.query)
  let req_body = {"category": $category, "externalInfo": $external_info, "filename": $filename, "languageCombinationIds": $language_combination_ids, "languageIds": $language_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
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
  send-post $req $req_body $insecure $raw $allow_errors $full []
}

# Adds file links to the project as added by PM.
#
# POST /v2/projects/{projectId}/files/addLink
# operationId: addFileLinks_1
# --fileLinks item shape: {category?: string, externalInfo?: record, filename?: string, languageCombinationIds?: list, languageIds?: list<int>, toBeGenerated?: bool, url?: string}
export def "projects-files-add-link create-by-project-id" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-links: list # item shape: {category?: string, externalInfo?: record, filename?: string, languageCombinationIds?: list, languageIds?: list<int>, toBeGenerated?: bool, url?: string}
]: any -> record<files: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/files/addLink") $auth.query)
  let req_body = {"fileLinks": $file_links} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
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
  send-post $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list, languages: list>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/files/deliverable") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Uploads file to the project as a file uploaded by PM.
#
# POST /v2/projects/{projectId}/files/upload
# operationId: uploadFile_2
export def "projects-files-upload upload-by-project-id" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # format: binary
]: any -> record<fileId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/files/upload") $auth.query)
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
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
  send-post $req $mp.body $insecure $raw $allow_errors $full []
}

# Returns finance information for a project.
#
# GET /v2/projects/{projectId}/finance
# operationId: getFinance_2
export def "projects-finance get-by-project-id" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ROI: float, currencyId: int, margin: float, payables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, profit: float, receivables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, totalAgreed: float, totalCost: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/finance") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Adds a payable to a project.
#
# POST /v2/projects/{projectId}/finance/payables
# operationId: createPayable_2
# --catLogFile shape: {content?: string, name?: string, token?: string, url?: string}
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "projects-finance-payables create-by-project-id" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --type: string@type-completer-2
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/finance/payables") $auth.query)
  let req_body = {"calculationUnitId": $calculation_unit_id, "catLogFile": $cat_log_file, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobId": $job_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
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
  send-post $req $req_body $insecure $raw $allow_errors $full []
}

# Deletes a payable.
#
# DELETE /v2/projects/{projectId}/finance/payables/{payableId}
# operationId: deletePayable_2
export def "projects-finance-payables delete-by-project-id-payable-id" [
  project_id: string
  payable_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($payable_id | is-empty) { error make --unspanned { msg: "path parameter 'payableId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), payable_id: (encode-path-segment $payable_id)} | format pattern "/v2/projects/{project_id}/finance/payables/{payable_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Updates a payable.
#
# PUT /v2/projects/{projectId}/finance/payables/{payableId}
# operationId: updatePayable_2
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "projects-finance-payables update-by-project-id-payable-id" [
  project_id: string
  payable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --type: string@type-completer-2
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($payable_id | is-empty) { error make --unspanned { msg: "path parameter 'payableId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), payable_id: (encode-path-segment $payable_id)} | format pattern "/v2/projects/{project_id}/finance/payables/{payable_id}") $auth.query)
  let req_body = {"calculationUnitId": $calculation_unit_id, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobId": $job_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
}

# Adds a receivable to a project.
#
# POST /v2/projects/{projectId}/finance/receivables
# operationId: createReceivable_2
# --catLogFile shape: {content?: string, name?: string, token?: string, url?: string}
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "projects-finance-receivables create-by-project-id" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --type: string@type-completer-2
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/finance/receivables") $auth.query)
  let req_body = {"calculationUnitId": $calculation_unit_id, "catLogFile": $cat_log_file, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "taskId": $task_id, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
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
  send-post $req $req_body $insecure $raw $allow_errors $full []
}

# Deletes a receivable.
#
# DELETE /v2/projects/{projectId}/finance/receivables/{receivableId}
# operationId: deleteReceivable_2
export def "projects-finance-receivables delete-by-project-id-receivable-id" [
  project_id: string
  receivable_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($receivable_id | is-empty) { error make --unspanned { msg: "path parameter 'receivableId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), receivable_id: (encode-path-segment $receivable_id)} | format pattern "/v2/projects/{project_id}/finance/receivables/{receivable_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Updates a receivable.
#
# PUT /v2/projects/{projectId}/finance/receivables/{receivableId}
# operationId: updateReceivable_2
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "projects-finance-receivables update-by-project-id-receivable-id" [
  project_id: string
  receivable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --type: string@type-completer-2
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($receivable_id | is-empty) { error make --unspanned { msg: "path parameter 'receivableId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), receivable_id: (encode-path-segment $receivable_id)} | format pattern "/v2/projects/{project_id}/finance/receivables/{receivable_id}") $auth.query)
  let req_body = {"calculationUnitId": $calculation_unit_id, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "taskId": $task_id, "total": $total, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/internalNotes") $auth.query)
  let req_body = {"value": $value} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<communication: record<instructionsForAllJobs: string, instructionsForJob: string, noteFromVendor: string>, dates: record<actualEndDate: int, actualStartDate: int, deadline: int, startDate: int>, documents: record<purchaseOrderStatus: string>, files: record<deliveredInJobFiles: list, sharedReferenceFiles: list, sharedWorkFiles: list>, id: string, idNumber: string, languages: list<record>, name: string, status: string, stepNumber: int, stepType: record<id: string, jobTypeId: int, name: string, semantics: record>, vendorId: int, vendorPriceProfileId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/jobs") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/orderDate") $auth.query)
  let req_body = {"value": $value} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<projectCreatedInCatToolOrCreationIsQueued: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/process") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-language-id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/sourceLanguage") $auth.query)
  let req_body = {"sourceLanguageId": $source_language_id} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --specialization-id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/specialization") $auth.query)
  let req_body = {"specializationId": $specialization_id} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Changes project status if possible (400 Bad Request is returned otherwise).
#
# PUT /v2/projects/{projectId}/status
# operationId: changeStatus_2
export def "projects-status update-change-by-project-id" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/status") $auth.query)
  let req_body = {"status": $status} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-language-ids: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/targetLanguages") $auth.query)
  let req_body = {"targetLanguageIds": $target_language_ids} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/vendorInstructions") $auth.query)
  let req_body = {"value": $value} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: float
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/v2/projects/{project_id}/volume") $auth.query)
  let req_body = {"value": $value} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Creates a new Smart Quote.
#
# POST /v2/quotes
# operationId: create_7
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
  --client-id: int # format: int64
  --name: string
  --opportunity-offer-id: int # format: int64
  --service-id: int # format: int64
]: any -> record<budgetCode: string, businessDays: int, categoryIds: list<int>, clientDeadline: int, clientId: int, clientNotes: string, clientReferenceNumber: string, createdOn: int, documents: record<projectConfirmationStatus: string>, expectedDeliveryDate: int, id: string, instructionsForAllJobs: string, internalNotes: string, isClassicQuote: bool, languages: record<languageCombinations: list<record>, sourceLanguageId: int, specializationId: int, targetLanguageIds: list<int>>, name: string, origin: string, people: record<projectManagerId: int>, quoteExpiry: int, quoteId: string, quoteIdNumber: string, serviceId: int, status: string, volume: record<unitId: int, value: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/quotes" $auth.query)
  let req_body = {"clientId": $client_id, "name": $name, "opportunityOfferId": $opportunity_offer_id, "serviceId": $service_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Prepares a ZIP archive that contains the specified files.
#
# POST /v2/quotes/files/archive
# operationId: archive_1
export def "quotes-files-archive archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --files: list<string>
]: any -> record<archiveUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/quotes/files/archive" $auth.query)
  let req_body = {"files": $files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full []
}

# Returns details of a file.
#
# GET /v2/quotes/files/{fileId}
# operationId: getFileById_3
export def "quotes-files get-by-file-id" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list<record>, languages: list<int>>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'fileId' must be non-empty" } }
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/v2/quotes/files/{file_id}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Downloads a file content.
#
# GET /v2/quotes/files/{fileId}/download/{fileName}
# operationId: getFileContentById_1
export def "quotes-files-download get-content-by-file-id-file-name" [
  file_id: string
  file_name: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($file_id | is-empty) { error make --unspanned { msg: "path parameter 'fileId' must be non-empty" } }
  if ($file_name | is-empty) { error make --unspanned { msg: "path parameter 'fileName' must be non-empty" } }
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id), file_name: (encode-path-segment $file_name)} | format pattern "/v2/quotes/files/{file_id}/download/{file_name}") $auth.query)
  let accept_val = "multipart/form-data"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Returns quote details.
#
# GET /v2/quotes/{quoteId}
# operationId: getById_10
export def "quotes get-by-quote-id-by-quote-id-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<budgetCode: string, businessDays: int, categoryIds: list<int>, clientDeadline: int, clientId: int, clientNotes: string, clientReferenceNumber: string, createdOn: int, documents: record<projectConfirmationStatus: string>, expectedDeliveryDate: int, id: string, instructionsForAllJobs: string, internalNotes: string, isClassicQuote: bool, languages: record<languageCombinations: list<record>, sourceLanguageId: int, specializationId: int, targetLanguageIds: list<int>>, name: string, origin: string, people: record<projectManagerId: int>, quoteExpiry: int, quoteId: string, quoteIdNumber: string, serviceId: int, status: string, volume: record<unitId: int, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: int
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/businessDays") $auth.query)
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Returns Client Contacts information for a quote.
#
# GET /v2/quotes/{quoteId}/clientContacts
# operationId: getContacts_3
export def "quotes-client-contacts get-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<additionalIds: list<int>, primaryId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/clientContacts") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Updates Client Contacts for a quote.
#
# PUT /v2/quotes/{quoteId}/clientContacts
# operationId: updateContacts_3
export def "quotes-client-contacts update-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-ids: list<int>
  --primary-id: int # format: int64
]: any -> record<additionalIds: list<int>, primaryId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/clientContacts") $auth.query)
  let req_body = {"additionalIds": $additional_ids, "primaryId": $primary_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json;charset=UTF-8"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full []
}

# Updates Client Notes for a quote.
#
# PUT /v2/quotes/{quoteId}/clientNotes
# operationId: updateClientNotes_1
export def "quotes-client-notes update-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/clientNotes") $auth.query)
  let req_body = {"value": $value} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Updates Client Reference Number for a quote.
#
# PUT /v2/quotes/{quoteId}/clientReferenceNumber
# operationId: updateClientReferenceNumber_1
export def "quotes-client-reference-number update-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/clientReferenceNumber") $auth.query)
  let req_body = {"value": $value} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Returns a list of custom field keys and values for a project.
#
# GET /v2/quotes/{quoteId}/customFields
# operationId: getCustomFields_9
export def "quotes-custom-fields get-by-quote-id-by-quote-id-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<key: string, name: string, type: string, value: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/customFields") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Updates a custom field with a specified key in a quote.
#
# PUT /v2/quotes/{quoteId}/customFields/{key}
# operationId: updateCustomField_3
export def "quotes-custom-fields update-by-quote-id-key" [
  quote_id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), key: (encode-path-segment $key)} | format pattern "/v2/quotes/{quote_id}/customFields/{key}") $auth.query)
  let req_body = {"value": $value} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/expectedDeliveryDate") $auth.query)
  let req_body = {"value": $value} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Returns list of files in a quote.
#
# GET /v2/quotes/{quoteId}/files
# operationId: getFiles_1
export def "quotes-files get-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<addedBy: record<userType: string, vendorId: int>, addedInJob: string, addedInLastStep: bool, addedInStep: int, categoryKey: string, id: string, isAccepted: bool, isLink: bool, isRemote: bool, languageRelation: record<languageCombinations: list, languages: list>, lastModifiedOn: int, name: string, remoteCATToolReferences: record<catResourceId: string, catToolDocumentId: string, editorUrl: string>, sharedWithJobs: list<string>, size: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/files") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Adds files to the quote as added by PM.
#
# PUT /v2/quotes/{quoteId}/files/add
# operationId: addFiles_2
export def "quotes-files-add create-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/files/add") $auth.query)
  let req_body = {"value": $value} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Uploads file to the quote as a file uploaded by PM.
#
# POST /v2/quotes/{quoteId}/files/upload
# operationId: uploadFile_3
export def "quotes-files-upload upload-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # format: binary
]: any -> record<fileId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/files/upload") $auth.query)
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
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
  send-post $req $mp.body $insecure $raw $allow_errors $full []
}

# Returns finance information for a quote.
#
# GET /v2/quotes/{quoteId}/finance
# operationId: getFinance_3
export def "quotes-finance get-by-quote-id-by-quote-id-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ROI: float, currencyId: int, margin: float, payables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, profit: float, receivables: table<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record, languageCombinationIdNumber: string, minimumCharge: float, rateOrigin: string, total: float, type: string>, totalAgreed: float, totalCost: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/finance") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
}

# Adds a payable to a quote.
#
# POST /v2/quotes/{quoteId}/finance/payables
# operationId: createPayable_3
# --catLogFile shape: {content?: string, name?: string, token?: string, url?: string}
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-payables create-by-quote-id-by-quote-id-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --type: string@type-completer-2
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/finance/payables") $auth.query)
  let req_body = {"calculationUnitId": $calculation_unit_id, "catLogFile": $cat_log_file, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobId": $job_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "total": $total, "type": $type} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full []
}

# Deletes a payable.
#
# DELETE /v2/quotes/{quoteId}/finance/payables/{payableId}
# operationId: deletePayable_3
export def "quotes-finance-payables delete-by-quote-id-payable-id-by-quote-id-payable-id-1" [
  quote_id: string
  payable_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  if ($payable_id | is-empty) { error make --unspanned { msg: "path parameter 'payableId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), payable_id: (encode-path-segment $payable_id)} | format pattern "/v2/quotes/{quote_id}/finance/payables/{payable_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Updates a payable.
#
# PUT /v2/quotes/{quoteId}/finance/payables/{payableId}
# operationId: updatePayable_3
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-payables update-by-quote-id-payable-id-by-quote-id-payable-id-1" [
  quote_id: string
  payable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --type: string@type-completer-2
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobId: record, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  if ($payable_id | is-empty) { error make --unspanned { msg: "path parameter 'payableId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), payable_id: (encode-path-segment $payable_id)} | format pattern "/v2/quotes/{quote_id}/finance/payables/{payable_id}") $auth.query)
  let req_body = {"calculationUnitId": $calculation_unit_id, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobId": $job_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "total": $total, "type": $type} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
}

# Adds a receivable to a quote.
#
# POST /v2/quotes/{quoteId}/finance/receivables
# operationId: createReceivable_3
# --catLogFile shape: {content?: string, name?: string, token?: string, url?: string}
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-receivables create-by-quote-id-by-quote-id-1" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --type: string@type-completer-2
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/finance/receivables") $auth.query)
  let req_body = {"calculationUnitId": $calculation_unit_id, "catLogFile": $cat_log_file, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "taskId": $task_id, "total": $total, "type": $type} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full []
}

# Deletes a receivable.
#
# DELETE /v2/quotes/{quoteId}/finance/receivables/{receivableId}
# operationId: deleteReceivable_3
export def "quotes-finance-receivables delete-by-quote-id-receivable-id-by-quote-id-receivable-id-1" [
  quote_id: string
  receivable_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  if ($receivable_id | is-empty) { error make --unspanned { msg: "path parameter 'receivableId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), receivable_id: (encode-path-segment $receivable_id)} | format pattern "/v2/quotes/{quote_id}/finance/receivables/{receivable_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Updates a receivable.
#
# PUT /v2/quotes/{quoteId}/finance/receivables/{receivableId}
# operationId: updateReceivable_3
# --languageCombination shape: {sourceLanguageId?: int, targetLanguageId?: int}
export def "quotes-finance-receivables update-by-quote-id-receivable-id-by-quote-id-receivable-id-1" [
  quote_id: string
  receivable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --type: string@type-completer-2
]: any -> record<calculationUnitId: int, currencyId: int, description: string, id: int, ignoreMinimumCharge: bool, invoiceId: string, jobTypeId: int, languageCombination: record<sourceLanguageId: int, targetLanguageId: int>, languageCombinationIdNumber: string, minimumCharge: float, quantity: float, rate: float, rateOrigin: string, taskId: int, total: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  if ($receivable_id | is-empty) { error make --unspanned { msg: "path parameter 'receivableId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id), receivable_id: (encode-path-segment $receivable_id)} | format pattern "/v2/quotes/{quote_id}/finance/receivables/{receivable_id}") $auth.query)
  let req_body = {"calculationUnitId": $calculation_unit_id, "currencyId": $currency_id, "description": $description, "id": $id, "ignoreMinimumCharge": $ignore_minimum_charge, "invoiceId": $invoice_id, "jobTypeId": $job_type_id, "languageCombination": $language_combination, "languageCombinationIdNumber": $language_combination_id_number, "minimumCharge": $minimum_charge, "quantity": $quantity, "rate": $rate, "rateOrigin": $rate_origin, "taskId": $task_id, "total": $total, "type": $type} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full []
}

# Updates Internal Notes for a quote.
#
# PUT /v2/quotes/{quoteId}/internalNotes
# operationId: updateInternalNotes_1
export def "quotes-internal-notes update-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/internalNotes") $auth.query)
  let req_body = {"value": $value} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Returns list of jobs in a quote.
#
# GET /v2/quotes/{quoteId}/jobs
# operationId: getJobs_1
export def "quotes-jobs get-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<communication: record<instructionsForAllJobs: string, instructionsForJob: string, noteFromVendor: string>, dates: record<actualEndDate: int, actualStartDate: int, deadline: int, startDate: int>, documents: record<purchaseOrderStatus: string>, files: record<deliveredInJobFiles: list, sharedReferenceFiles: list, sharedWorkFiles: list>, id: string, idNumber: string, languages: list<record>, name: string, status: string, stepNumber: int, stepType: record<id: string, jobTypeId: int, name: string, semantics: record>, vendorId: int, vendorPriceProfileId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/jobs") $auth.query)
  let accept_val = "application/json;charset=UTF-8"
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
  send-get $req $insecure $raw $allow_errors $full []
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/quoteExpiry") $auth.query)
  let req_body = {"value": $value} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Updates source language for a quote.
#
# PUT /v2/quotes/{quoteId}/sourceLanguage
# operationId: updateSourceLanguage_1
export def "quotes-source-language update-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-language-id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/sourceLanguage") $auth.query)
  let req_body = {"sourceLanguageId": $source_language_id} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Updates specialization for a quote.
#
# PUT /v2/quotes/{quoteId}/specialization
# operationId: updateSpecialization_1
export def "quotes-specialization update-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --specialization-id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/specialization") $auth.query)
  let req_body = {"specializationId": $specialization_id} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Changes quote status if possible (400 Bad Request is returned otherwise).
#
# PUT /v2/quotes/{quoteId}/status
# operationId: changeStatus_3
export def "quotes-status update-change-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/status") $auth.query)
  let req_body = {"status": $status} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Updates target languages for a quote.
#
# PUT /v2/quotes/{quoteId}/targetLanguages
# operationId: updateTargetLanguages_1
export def "quotes-target-languages update-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-language-ids: list<int>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/targetLanguages") $auth.query)
  let req_body = {"targetLanguageIds": $target_language_ids} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Updates instructions for all vendors performing the jobs in a quote.
#
# PUT /v2/quotes/{quoteId}/vendorInstructions
# operationId: updateVendorInstructions_1
export def "quotes-vendor-instructions update-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/vendorInstructions") $auth.query)
  let req_body = {"value": $value} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Updates volume for a quote.
#
# PUT /v2/quotes/{quoteId}/volume
# operationId: updateVolume_1
export def "quotes-volume update-by-quote-id" [
  quote_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: float
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-auth-access-token"))
  let base = ($base_url | default $BASE_URL)
  if ($quote_id | is-empty) { error make --unspanned { msg: "path parameter 'quoteId' must be non-empty" } }
  let full_url = (build-url $base ({quote_id: (encode-path-segment $quote_id)} | format pattern "/v2/quotes/{quote_id}/volume") $auth.query)
  let req_body = {"value": $value} | compact
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
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}
