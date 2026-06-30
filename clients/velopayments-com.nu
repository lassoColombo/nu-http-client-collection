# Auto-generated client for Velo Payments APIs v2.34.63
# Source: https://api.apis.guru/v2/specs/velopayments.com/2.34.63/openapi.json
# Auth: --token flag or $env.VELO_PAYMENTS_APIS_TOKEN

const BASE_URL = "https://api.sandbox.velopayments.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o VELO_PAYMENTS_APIS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.sandbox.velopayments.com" "https://api.payouts.velopayments.com"] }
def auth-scheme-completer [] { ["bearer" "basic" "none" "basic-credentials"] }

# Completers for enum parameters
def link-type-completer [] { ["PARENT_OF"] }
def type-completer [] { ["FBO" "PRIVATE" "WUBS_DECOUPLED"] }
def type-completer-1 [] { ["BACKOFFICE" "PAYEE" "PAYOR"] }
def status-completer [] { ["DISABLED" "ENABLED" "PENDING"] }
def payee-type-completer [] { ["COMPANY" "INDIVIDUAL"] }
def mfa-type-completer [] { ["SMS" "TOTP" "YUBIKEY"] }
def user-type-completer [] { ["BACKOFFICE" "PAYEE" "PAYOR"] }
def mfa-type-completer-1 [] { ["TOTP" "YUBIKEY"] }
def token-type-completer [] { ["INVITE_MFA_USER" "MFA_REGISTRATION"] }
def payee-type-completer-1 [] { ["Company" "Individual"] }
def status-completer-1 [] { ["ACCEPTED" "ACCEPTED_BY_RAILS" "AWAITING_FUNDS" "BANK_PAYMENT_REQUESTED" "CONFIRMED" "FAILED" "FUNDED" "REJECTED" "RETURNED" "UNFUNDED" "WITHDRAWN"] }
def status-completer-2 [] { ["ACCEPTED" "COMPLETED" "CONFIRMED" "INCOMPLETE" "INSTRUCTED" "QUOTED" "REJECTED" "SUBMITTED" "WITHDRAWN"] }
def status-completer-3 [] { ["ACCEPTED" "REJECTED" "WITHDRAWABLE" "WITHDRAWN"] }
def transmission-type-completer [] { ["ACH" "SAME_DAY_ACH" "WIRE"] }
def transmission-type-completer-1 [] { ["ACH" "GACHO" "LOCAL" "SAME_DAY_ACH" "WIRE"] }
def schedule-status-completer [] { ["ANY" "EXECUTED" "FAILED" "SCHEDULED"] }
def post-instruct-fx-status-completer [] { ["ANY" "CANCELLED" "COMPLETED" "EXECUTED" "INITIATED" "REFUNDED" "RESUBMITTED" "RETURNED"] }
def include-completer [] { ["payorAndDescendants" "payorOnly"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "authenticate create-velo-auth" } } | get name | first)
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

# Authentication endpoint
#
# POST /v1/authenticate
# operationId: veloAuth
export def "authenticate create-velo-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --grant-type: string # OAuth grant type. Should use 'client_credentials' (default: client_credentials)
]: nothing -> record<access_token: string, entityIds: list<string>, expires_in: float, refresh_token: string, scope: string, token_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "grant_type" $grant_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/authenticate" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"grant_type": $grant_type} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Get Funding Audit Delta
#
# GET /v1/deltas/fundings
# operationId: listFundingAuditDeltas
export def "deltas-fundings list-audit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # format: uuid
  --updated-since: string # format: date-time
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
]: nothing -> record<content: table<amount: int, currency: string, fundingId: string, status: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payor_id "scalar") (serialize-qp "updatedSince" $updated_since "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/deltas/fundings" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"payorId": $payor_id, "updatedSince": $updated_since, "page": $page, "pageSize": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# V1 List Payment Changes
#
# GET /v1/deltas/payments
# DEPRECATED
# operationId: listPaymentChanges
@deprecated
export def "deltas-payments list-changes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The Payor ID to find associated Payments (format: uuid)
  --updated-since: string # The updatedSince filter in the format YYYY-MM-DDThh:mm:ss+hh:mm (format: date-time)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 100)
]: nothing -> record<content: table<paymentAmount: int, paymentCurrency: string, paymentId: string, payorPaymentId: string, payoutId: string, sourceAmount: int, sourceCurrency: string, status: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payor_id "scalar") (serialize-qp "updatedSince" $updated_since "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/deltas/payments" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"payorId": $payor_id, "updatedSince": $updated_since, "page": $page, "pageSize": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Funding
#
# GET /v1/fundings/{fundingId}
# operationId: getFundingByIdV1
export def "fundings get" [
  funding_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allocationDate: string, allocationType: string, amount: int, currency: string, detectedFundingRef: string, fundingAccountType: string, fundingId: string, hiddenDate: string, payorId: string, physicalAccountName: string, reason: string, sourceAccountId: string, status: string, text: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($funding_id | is-empty) { error make --unspanned { msg: "path parameter 'fundingId' must be non-empty" } }
  let full_url = (build-url $base ({funding_id: (encode-path-segment $funding_id)} | format pattern "/v1/fundings/{funding_id}") $auth.query)
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

# Logout
#
# POST /v1/logout
# operationId: logout
export def "logout create" [
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
  let full_url = (build-url $base "/v1/logout" $auth.query)
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

# Reset password
#
# POST /v1/password/reset
# operationId: resetPassword
export def "password-reset reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # the email address of the user requesting the reset password (format: email, e.g. foo@example.com)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/password/reset" $auth.query)
  let req_body = {"email": $email} | compact
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

# List Payment Channel Country Rules
#
# GET /v1/paymentChannelRules
# operationId: listPaymentChannelRulesV1
export def "payment-channel-rules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bank: table<isoCountryCode: string, rules: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/paymentChannelRules" $auth.query)
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

# V1 Get Fundings for Payor
#
# GET /v1/paymentaudit/fundings
# DEPRECATED
# operationId: getFundingsV1
@deprecated
export def "paymentaudit-fundings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The account owner Payor ID (format: uuid)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields. Example: ```?sort=destinationCurrency:asc,destinationAmount:asc``` Default is no sort. The supported sort fields are: dateTime and amount.
]: nothing -> record<content: table<amount: float, currency: string, dateTime: string, events: list, fundingAccountName: string, fundingType: string, sourceAccountName: string, status: string, topupType: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payor_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/paymentaudit/fundings" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"payorId": $payor_id, "page": $page, "pageSize": $page_size, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# V1 Get Payout Statistics
#
# GET /v1/paymentaudit/payoutStatistics
# DEPRECATED
# operationId: getPayoutStatsV1
@deprecated
export def "paymentaudit-payout-statistics get-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The account owner Payor ID. Required for external users. (format: uuid)
]: nothing -> record<thisMonthFailedPaymentsCount: int, thisMonthPayoutsCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payor_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/paymentaudit/payoutStatistics" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"payorId": $payor_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Withdraw a Payment
#
# POST /v1/payments/{paymentId}/withdraw
# operationId: withdrawPayment
export def "payments-withdraw create" [
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
  reason: string # Reason for withdrawal (e.g. Payment submitted in error)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id)} | format pattern "/v1/payments/{payment_id}/withdraw") $auth.query)
  let req_body = {"reason": $reason} | compact
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

# List Payor Links
#
# GET /v1/payorLinks
# operationId: payorLinksV1
export def "payor-links get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --descendants-of-payor: string # The Payor ID from which to start the query to show all descendants (format: uuid)
  --parent-of-payor: string # Query for the parent payor details for this payor id (format: uuid)
  --fields: string # List of additional Payor fields to include in the response for each Payor The values of payorId and payorName are always included for each Payor by default You can add fields to the response for each payor by including them in the fields parameter separated by commas The supported fields are any combination of: primaryContactEmail,kycState
]: nothing -> record<links: table<fromPayorId: string, linkId: string, linkType: string, toPayorId: string>, payors: table<kycState: string, payorId: string, payorName: string, primaryContactEmail: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "descendantsOfPayor" $descendants_of_payor "scalar") (serialize-qp "parentOfPayor" $parent_of_payor "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/payorLinks" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"descendantsOfPayor": $descendants_of_payor, "parentOfPayor": $parent_of_payor, "fields": $fields} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a Payor Link
#
# POST /v1/payorLinks
# operationId: createPayorLinks
export def "payor-links create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  from_payor_id: string # format: uuid
  link_type: string@link-type-completer
  to_payor_id: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/payorLinks" $auth.query)
  let req_body = {"fromPayorId": $from_payor_id, "linkType": $link_type, "toPayorId": $to_payor_id} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get Payor
#
# GET /v1/payors/{payorId}
# DEPRECATED
# operationId: getPayorByIdV1
@deprecated
export def "payors get-by-payor-id" [
  payor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: record<city: string, country: string, countyOrProvince: string, line1: string, line2: string, line3: string, line4: string, zipOrPostcode: string>, allowsLanguageChoice: bool, collectiveAlias: string, dbaName: string, fundingAccountAccountName: string, fundingAccountAccountNumber: string, fundingAccountRoutingNumber: string, includesReports: bool, kycState: string, language: string, manualLockout: bool, maxMasterPayorAdmins: int, payeeGracePeriodDays: int, payeeGracePeriodProcessingEnabled: bool, payorId: string, payorName: string, primaryContactEmail: string, primaryContactName: string, primaryContactPhone: string, reminderEmailsOptOut: bool, supportContact: string, transmissionTypes: record<ACH: bool, SAME_DAY_ACH: bool, WIRE: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payor_id | is-empty) { error make --unspanned { msg: "path parameter 'payorId' must be non-empty" } }
  let full_url = (build-url $base ({payor_id: (encode-path-segment $payor_id)} | format pattern "/v1/payors/{payor_id}") $auth.query)
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

# Create Application
#
# POST /v1/payors/{payorId}/applications
# operationId: payorCreateApplicationV1
export def "payors-applications create" [
  payor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the application. (nullable, e.g. SAP Application integration)
  name: string # The name of the application. (e.g. SAP)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payor_id | is-empty) { error make --unspanned { msg: "path parameter 'payorId' must be non-empty" } }
  let full_url = (build-url $base ({payor_id: (encode-path-segment $payor_id)} | format pattern "/v1/payors/{payor_id}/applications") $auth.query)
  let req_body = {"description": $description, "name": $name} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Create API Key
#
# POST /v1/payors/{payorId}/applications/{applicationId}/keys
# operationId: payorCreateApiKeyV1
export def "payors-applications-keys create" [
  payor_id: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of the key. (nullable, e.g. Key for iOS mobile application)
  name: string # A name for the key. (e.g. iOS Key)
  roles: list<string> # A role to assign to the key. If you want your API key to have write access then assign the role velo.payor.admin A later version will change this property from a list to string (e.g. [velo.payor.admin])
]: any -> record<apiKey: string, apiSecret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payor_id | is-empty) { error make --unspanned { msg: "path parameter 'payorId' must be non-empty" } }
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let full_url = (build-url $base ({payor_id: (encode-path-segment $payor_id), application_id: (encode-path-segment $application_id)} | format pattern "/v1/payors/{payor_id}/applications/{application_id}/keys") $auth.query)
  let req_body = {"description": $description, "name": $name, "roles": $roles} | compact
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

# Get Branding
#
# GET /v1/payors/{payorId}/branding
# operationId: payorGetBranding
export def "payors-branding get" [
  payor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<collectiveAlias: string, dbaName: string, logoUrl: string, payorName: string, supportContact: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payor_id | is-empty) { error make --unspanned { msg: "path parameter 'payorId' must be non-empty" } }
  let full_url = (build-url $base ({payor_id: (encode-path-segment $payor_id)} | format pattern "/v1/payors/{payor_id}/branding") $auth.query)
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

# Add Logo
#
# POST /v1/payors/{payorId}/branding/logos
# operationId: payorAddPayorLogoV1
export def "payors-branding-logos create" [
  payor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --logo: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payor_id | is-empty) { error make --unspanned { msg: "path parameter 'payorId' must be non-empty" } }
  let full_url = (build-url $base ({payor_id: (encode-path-segment $payor_id)} | format pattern "/v1/payors/{payor_id}/branding/logos") $auth.query)
  let req_body = {"logo": $logo} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["logo"] $dry_run)
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
  send-post $req $mp.body $insecure $raw $allow_errors $full [204]
}

# Reminder Email Opt-Out
#
# POST /v1/payors/{payorId}/reminderEmailsUpdate
# operationId: payorEmailOptOut
export def "payors-reminder-emails-update create-opt-out" [
  payor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reminder-emails-opt-out: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payor_id | is-empty) { error make --unspanned { msg: "path parameter 'payorId' must be non-empty" } }
  let full_url = (build-url $base ({payor_id: (encode-path-segment $payor_id)} | format pattern "/v1/payors/{payor_id}/reminderEmailsUpdate") $auth.query)
  let req_body = {"reminderEmailsOptOut": $reminder_emails_opt_out} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Set notifications
#
# POST /v1/sourceAccounts/{sourceAccountId}/notifications
# DEPRECATED
# operationId: setNotificationsRequest
@deprecated
export def "source-accounts-notifications update-request-by-source-account-id" [
  source_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  minimum_balance: int # Amount to set as minimum balance in minor units (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_account_id | is-empty) { error make --unspanned { msg: "path parameter 'sourceAccountId' must be non-empty" } }
  let full_url = (build-url $base ({source_account_id: (encode-path-segment $source_account_id)} | format pattern "/v1/sourceAccounts/{source_account_id}/notifications") $auth.query)
  let req_body = {"minimumBalance": $minimum_balance} | compact
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

# List Supported Countries
#
# GET /v1/supportedCountries
# DEPRECATED
# operationId: listSupportedCountriesV1
@deprecated
export def "supported-countries list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countries: table<currencies: list, isoCountryCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/supportedCountries" $auth.query)
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

# validate
#
# POST /v1/validate
# operationId: validateAccessToken
export def "validate validate-access-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer token authorization leg of validate
  otp: string # an OTP either sent via sms or generated by a registered MFA device (e.g. 123456)
]: any -> record<access_token: string, entityIds: list<string>, expires_in: int, refresh_token: string, scope: string, token_type: string, user_info: record<mfa_details: record<mfa_type: string, verified: bool>, userType: string, user_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/validate" $auth.query)
  let req_body = {"otp": $otp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# List the details about the webhooks for the given payor.
#
# GET /v1/webhooks
# operationId: listWebhooksV1
export def "webhooks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --payor-id: string # The Payor ID (format: uuid)
]: nothing -> record<content: table<authorizationHeader: string, categories: list, enabled: bool, id: string, payorId: string, webhookUrl: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "payorId" $payor_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/webhooks" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "payorId": $payor_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create Webhook
#
# POST /v1/webhooks
# operationId: createWebhookV1
export def "webhooks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization-header: string # the authorization header to include with the notification.
  --categories: list<string> # the categories to enable.
  --enabled: oneof<nothing, bool> # whether the webhook is enabled.
  payor_id: string # format: uuid
  webhook_url: string # the webhook URL to use.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/webhooks" $auth.query)
  let req_body = {"authorizationHeader": $authorization_header, "categories": $categories, "enabled": $enabled, "payorId": $payor_id, "webhookUrl": $webhook_url} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get details about the given webhook.
#
# GET /v1/webhooks/{webhookId}
# operationId: getWebhookV1
export def "webhooks get" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<authorizationHeader: string, categories: list<string>, enabled: bool, id: string, payorId: string, webhookUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webhook_id | is-empty) { error make --unspanned { msg: "path parameter 'webhookId' must be non-empty" } }
  let full_url = (build-url $base ({webhook_id: (encode-path-segment $webhook_id)} | format pattern "/v1/webhooks/{webhook_id}") $auth.query)
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

# Update Webhook
#
# POST /v1/webhooks/{webhookId}
# operationId: updateWebhookV1
export def "webhooks update" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization-header: string # the authorization header to include with the notification. (nullable)
  --categories: list<string> # The notification categories to enable. (nullable)
  --enabled: oneof<nothing, bool> # whether the webhook is enabled.
  --webhook-url: string # the webhook URL to use.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webhook_id | is-empty) { error make --unspanned { msg: "path parameter 'webhookId' must be non-empty" } }
  let full_url = (build-url $base ({webhook_id: (encode-path-segment $webhook_id)} | format pattern "/v1/webhooks/{webhook_id}") $auth.query)
  let req_body = {"authorizationHeader": $authorization_header, "categories": $categories, "enabled": $enabled, "webhookUrl": $webhook_url} | compact
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

# POST /v1/webhooks/{webhookId}/ping
#
# operationId: pingWebhookV1
export def "webhooks-ping ping" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, webhookId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($webhook_id | is-empty) { error make --unspanned { msg: "path parameter 'webhookId' must be non-empty" } }
  let full_url = (build-url $base ({webhook_id: (encode-path-segment $webhook_id)} | format pattern "/v1/webhooks/{webhook_id}/ping") $auth.query)
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
  send-post $req null $insecure $raw $allow_errors $full [202]
}

# List Supported Currencies
#
# GET /v2/currencies
# operationId: listSupportedCurrenciesV2
export def "currencies list-supported" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<currencies: table<currency: string, maxPaymentAmount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/currencies" $auth.query)
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

# Get Funding Accounts
#
# GET /v2/fundingAccounts
# operationId: getFundingAccountsV2
export def "funding-accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # format: uuid
  --name: string # The descriptive funding account name
  --country: string # The 2 letter ISO 3166-1 country code (upper case) (e.g. US)
  --currency: string # The ISO 4217 currency code (e.g. USD)
  --type: string # The type of funding account. (e.g. FBO)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields (e.g. ?sort=accountName:asc,name:asc) Default is accountName:asc The supported sort fields are - accountName, name. (default: accountName:asc)
  --sensitive: oneof<nothing, bool> # default: false
]: nothing -> record<content: table<accountName: string, accountNumber: string, archived: bool, country: string, currency: string, id: string, name: string, payorId: string, routingNumber: string, type: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payor_id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "currency" $currency "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sensitive" $sensitive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/fundingAccounts" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"payorId": $payor_id, "name": $name, "country": $country, "currency": $currency, "type": $type, "page": $page, "pageSize": $page_size, "sort": $qp_sort, "sensitive": $sensitive} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create Funding Account
#
# POST /v2/fundingAccounts
# operationId: createFundingAccountV2
export def "funding-accounts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-name: string # Required if type is either FBO or PRIVATE
  --account-number: string # Required if type is either FBO or PRIVATE
  --currency: string # ISO 4217 currency code, Required if type is either WUBS_DECOUPLED or PRIVATE (e.g. USD)
  name: string
  payor_id: string # format: uuid
  --routing-number: string # Required if type is either FBO or PRIVATE
  type: string@type-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/fundingAccounts" $auth.query)
  let req_body = {"accountName": $account_name, "accountNumber": $account_number, "currency": $currency, "name": $name, "payorId": $payor_id, "routingNumber": $routing_number, "type": $type} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Get Funding Account
#
# GET /v2/fundingAccounts/{fundingAccountId}
# operationId: getFundingAccountV2
export def "funding-accounts get" [
  funding_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sensitive: oneof<nothing, bool> # default: false
]: nothing -> record<accountName: string, accountNumber: string, archived: bool, country: string, currency: string, id: string, name: string, payorId: string, routingNumber: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($funding_account_id | is-empty) { error make --unspanned { msg: "path parameter 'fundingAccountId' must be non-empty" } }
  let qp = [(serialize-qp "sensitive" $sensitive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({funding_account_id: (encode-path-segment $funding_account_id)} | format pattern "/v2/fundingAccounts/{funding_account_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sensitive": $sensitive} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Payor
#
# GET /v2/payors/{payorId}
# operationId: getPayorByIdV2
export def "payors get-by-payor-id-1" [
  payor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: record<city: string, country: string, countyOrProvince: string, line1: string, line2: string, line3: string, line4: string, zipOrPostcode: string>, allowsLanguageChoice: bool, collectiveAlias: string, dbaName: string, includesReports: bool, kycState: string, language: string, managingPayees: bool, manualLockout: bool, maxMasterPayorAdmins: int, openBankingEnabled: bool, payeeGracePeriodDays: int, payeeGracePeriodProcessingEnabled: bool, paymentRails: string, payorId: string, payorName: string, payorXid: string, primaryContactEmail: string, primaryContactName: string, primaryContactPhone: string, provider: string, reminderEmailsOptOut: bool, remoteSystemIds: list<string>, supportContact: string, transmissionTypes: record<ACH: bool, SAME_DAY_ACH: bool, WIRE: bool>, usdTxnValueReportingThreshold: int, wuCustomerId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payor_id | is-empty) { error make --unspanned { msg: "path parameter 'payorId' must be non-empty" } }
  let full_url = (build-url $base ({payor_id: (encode-path-segment $payor_id)} | format pattern "/v2/payors/{payor_id}") $auth.query)
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

# Get list of source accounts
#
# GET /v2/sourceAccounts
# DEPRECATED
# operationId: getSourceAccountsV2
@deprecated
export def "source-accounts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --physical-account-name: string # Physical Account Name
  --physical-account-id: string # The physical account ID (format: uuid)
  --payor-id: string # The account owner Payor ID (format: uuid)
  --funding-account-id: string # The funding account ID (format: uuid)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields e.g. ?sort=name:asc Default is name:asc The supported sort fields are - fundingRef, name, balance (default: fundingRef:asc)
]: nothing -> record<content: table<accountType: string, autoTopUpConfig: record, balance: int, balanceVisible: bool, currency: string, customerId: string, fundingAccountId: string, fundingRef: string, id: string, name: string, notifications: record, payorId: string, physicalAccountId: string, physicalAccountName: string, pooled: bool, railsId: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "physicalAccountName" $physical_account_name "scalar") (serialize-qp "physicalAccountId" $physical_account_id "scalar") (serialize-qp "payorId" $payor_id "scalar") (serialize-qp "fundingAccountId" $funding_account_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/sourceAccounts" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"physicalAccountName": $physical_account_name, "physicalAccountId": $physical_account_id, "payorId": $payor_id, "fundingAccountId": $funding_account_id, "page": $page, "pageSize": $page_size, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Source Account
#
# GET /v2/sourceAccounts/{sourceAccountId}
# DEPRECATED
# operationId: getSourceAccountV2
@deprecated
export def "source-accounts get-by-source-account-id" [
  source_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accountType: string, autoTopUpConfig: record<enabled: bool, minBalance: int, targetBalance: int>, balance: int, balanceVisible: bool, currency: string, customerId: string, fundingAccountId: string, fundingRef: string, id: string, name: string, notifications: record<minimumBalance: int>, payorId: string, physicalAccountId: string, physicalAccountName: string, pooled: bool, railsId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_account_id | is-empty) { error make --unspanned { msg: "path parameter 'sourceAccountId' must be non-empty" } }
  let full_url = (build-url $base ({source_account_id: (encode-path-segment $source_account_id)} | format pattern "/v2/sourceAccounts/{source_account_id}") $auth.query)
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

# Create Funding Request
#
# POST /v2/sourceAccounts/{sourceAccountId}/fundingRequest
# DEPRECATED
# operationId: createFundingRequestV2
@deprecated
export def "source-accounts-funding-request create-by-source-account-id" [
  source_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: int # Amount to fund, decimal implied (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_account_id | is-empty) { error make --unspanned { msg: "path parameter 'sourceAccountId' must be non-empty" } }
  let full_url = (build-url $base ({source_account_id: (encode-path-segment $source_account_id)} | format pattern "/v2/sourceAccounts/{source_account_id}/fundingRequest") $auth.query)
  let req_body = {"amount": $amount} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Transfer Funds between source accounts
#
# POST /v2/sourceAccounts/{sourceAccountId}/transfers
# DEPRECATED
# operationId: transferFundsV2
@deprecated
export def "source-accounts-transfers create-funds-by-source-account-id" [
  source_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: int # Amount to transfer, in minor units (format: int64)
  currency: string # e.g. USD
  to_source_account_id: string # The 'to' source account id, which will be credited (format: uuid)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_account_id | is-empty) { error make --unspanned { msg: "path parameter 'sourceAccountId' must be non-empty" } }
  let full_url = (build-url $base ({source_account_id: (encode-path-segment $source_account_id)} | format pattern "/v2/sourceAccounts/{source_account_id}/transfers") $auth.query)
  let req_body = {"amount": $amount, "currency": $currency, "toSourceAccountId": $to_source_account_id} | compact
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

# List Supported Countries
#
# GET /v2/supportedCountries
# operationId: listSupportedCountriesV2
export def "supported-countries list-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countries: table<currencies: list, isoCountryCode: string, regions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/supportedCountries" $auth.query)
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

# List Users
#
# GET /v2/users
# operationId: listUsers
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-1 # The Type of the User. (e.g. PAYOR)
  --status: string@status-completer # The status of the User. (e.g. ENABLED)
  --entity-id: string # The entityId of the User. (format: uuid)
  --payee-type: string@payee-type-completer # The Type of the Payee entity. Either COMPANY or INDIVIDUAL. (e.g. COMPANY)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields (e.g. ?sort=email:asc,lastName:asc) Default is email:asc 'name' The supported sort fields are - email, lastNmae. (default: email:asc)
]: nothing -> record<content: table<companyName: string, email: string, entityId: string, firstName: string, id: string, lastName: string, lockedOut: bool, lockedOutTimestamp: string, mfaStatus: string, mfaType: string, primaryContactNumber: string, roles: list, secondaryContactNumber: string, smsNumber: string, status: string, userType: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "entityId" $entity_id "scalar") (serialize-qp "payeeType" $payee_type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/users" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "status": $status, "entityId": $entity_id, "payeeType": $payee_type, "page": $page, "pageSize": $page_size, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Invite a User
#
# POST /v2/users/invite
# operationId: inviteUser
export def "users-invite create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # the email address of the invited user (format: email, e.g. foo@example.com)
  --entity-id: string # The payorId or payeeId or null if the user is a backoffice admin (nullable, format: uuid, e.g. 7fffa261-ac68-49e6-b605-d24a444d9206)
  --first-name: string # e.g. John
  --last-name: string # e.g. Doe
  mfa_type: string@mfa-type-completer # The MFA type that the user will use The type may be conditional on the role(s) the user has (e.g. TOTP)
  primary_contact_number: string # The main contact number for the user (e.g. 11235555555)
  roles: list<string> # The role(s) for the user The role must exist The role can be a custom role or a system role but the invoker must have the permissions to assign the role System roles are: velo.backoffice.admin, velo.payor.master_admin, velo.payor.admin, velo.payor.support, velo.payee.admin, velo.payee.support (e.g. [velo.payor.admin])
  --secondary-contact-number: string # The secondary contact number for the user (nullable, e.g. 11235555550)
  sms_number: string # The phone number of a device that the user can receive sms messages on (e.g. 11235555555)
  --user-type: string@user-type-completer # Will default to PAYOR if not provided but entityId is provided (e.g. PAYEE)
  --verification-code: string # Optional property that MUST be suppied when manually verifying a user The user's smsNumber is registered via a separate endpoint and an OTP sent to them (nullable, e.g. 123456)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/users/invite" $auth.query)
  let req_body = {"email": $email, "entityId": $entity_id, "firstName": $first_name, "lastName": $last_name, "mfaType": $mfa_type, "primaryContactNumber": $primary_contact_number, "roles": $roles, "secondaryContactNumber": $secondary_contact_number, "smsNumber": $sms_number, "userType": $user_type, "verificationCode": $verification_code} | compact
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

# Register SMS Number
#
# POST /v2/users/registration/sms
# operationId: registerSms
export def "users-registration-sms create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  sms_number: string # The phone number of a device that the user can receive sms messages on (e.g. 11235555555)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/users/registration/sms" $auth.query)
  let req_body = {"smsNumber": $sms_number} | compact
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

# Get Self
#
# GET /v2/users/self
# operationId: getSelf
export def "users-self get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<companyName: string, email: string, entityId: string, firstName: string, id: string, lastName: string, lockedOut: bool, lockedOutTimestamp: string, mfaStatus: string, mfaType: string, primaryContactNumber: string, roles: table<name: string>, secondaryContactNumber: string, smsNumber: string, status: string, userType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/users/self" $auth.query)
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

# Unregister MFA for Self
#
# POST /v2/users/self/mfa/unregister
# operationId: unregisterMFAForSelf
export def "users-self-mfa-unregister delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer token authorization leg of validate
  mfa_type: string@mfa-type-completer # The type of the MFA device (e.g. TOTP)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/users/self/mfa/unregister" $auth.query)
  let req_body = {"mfaType": $mfa_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Update Password for self
#
# POST /v2/users/self/password
# operationId: updatePasswordSelf
export def "users-self-password update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  new_password: string # The new password (e.g. My_new_password)
  old_password: string # The user's current password (e.g. My_current_password)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/users/self/password" $auth.query)
  let req_body = {"newPassword": $new_password, "oldPassword": $old_password} | compact
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

# Validate the proposed password
#
# POST /v2/users/self/password/validate
# operationId: validatePasswordSelf
export def "users-self-password-validate validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # a password that passes validation (e.g. My_strong_password)
]: any -> record<score: int, suggestions: list<string>, valid: bool, warning: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/users/self/password/validate" $auth.query)
  let req_body = {"password": $password} | compact
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

# Update User Details for self
#
# POST /v2/users/self/userDetailsUpdate
# operationId: userDetailsUpdateForSelf
export def "users-self-user-details-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # the email address of the user (nullable, format: email, e.g. foo@example.com)
  --first-name: string # nullable, e.g. John
  --last-name: string # nullable, e.g. Doe
  --primary-contact-number: string # The main contact number for the user (nullable, e.g. 11235555555)
  --secondary-contact-number: string # The secondary contact number for the user (nullable, e.g. 11235555550)
  --sms-number: string # The phone number of a device that the user can receive sms messages on (nullable, e.g. 11235555555)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/users/self/userDetailsUpdate" $auth.query)
  let req_body = {"email": $email, "firstName": $first_name, "lastName": $last_name, "primaryContactNumber": $primary_contact_number, "secondaryContactNumber": $secondary_contact_number, "smsNumber": $sms_number} | compact
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

# Delete a User
#
# DELETE /v2/users/{userId}
# operationId: deleteUserByIdV2
export def "users delete" [
  user_id: string
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
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/v2/users/{user_id}") $auth.query)
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

# Get User
#
# GET /v2/users/{userId}
# operationId: getUserByIdV2
export def "users get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<companyName: string, email: string, entityId: string, firstName: string, id: string, lastName: string, lockedOut: bool, lockedOutTimestamp: string, mfaStatus: string, mfaType: string, primaryContactNumber: string, roles: table<name: string>, secondaryContactNumber: string, smsNumber: string, status: string, userType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/v2/users/{user_id}") $auth.query)
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

# Disable a User
#
# POST /v2/users/{userId}/disable
# operationId: disableUserV2
export def "users-disable disable" [
  user_id: string
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
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/v2/users/{user_id}/disable") $auth.query)
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

# Enable a User
#
# POST /v2/users/{userId}/enable
# operationId: enableUserV2
export def "users-enable enable" [
  user_id: string
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
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/v2/users/{user_id}/enable") $auth.query)
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

# Unregister MFA for the user
#
# POST /v2/users/{userId}/mfa/unregister
# operationId: unregisterMFA
export def "users-mfa-unregister delete" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  mfa_type: string@mfa-type-completer-1 # The type of the MFA device (e.g. TOTP)
  --verification-code: string # Optional property that MUST be suppied when manually verifying a user The user's smsNumber is registered via a separate endpoint and an OTP sent to them (nullable, e.g. 123456)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/v2/users/{user_id}/mfa/unregister") $auth.query)
  let req_body = {"mfaType": $mfa_type, "verificationCode": $verification_code} | compact
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

# Update User Role
#
# POST /v2/users/{userId}/roleUpdate
# operationId: roleUpdate
export def "users-role-update update" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  roles: list<string> # The role(s) for the user The role must exist The role can be a custom role or a system role but the invoker must have the permissions to assign the role System roles are: backoffice.admin, payor.master_admin, payor.admin, payor.support (e.g. [payor.admin])
  --verification-code: string # Optional property that MUST be suppied when manually verifying a user The user's smsNumber is registered via a separate endpoint and an OTP sent to them (nullable, e.g. 123456)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/v2/users/{user_id}/roleUpdate") $auth.query)
  let req_body = {"roles": $roles, "verificationCode": $verification_code} | compact
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

# Resend a token
#
# POST /v2/users/{userId}/tokens
# operationId: resendToken
export def "users-tokens resend" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  token_type: string@token-type-completer # The type of the token to resend (e.g. INVITE_MFA_USER)
  --verification-code: string # Optional property that MUST be suppied when manually verifying a user The user's smsNumber is registered via a separate endpoint and an OTP sent to them (nullable, e.g. 123456)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/v2/users/{user_id}/tokens") $auth.query)
  let req_body = {"tokenType": $token_type, "verificationCode": $verification_code} | compact
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

# Unlock a User
#
# POST /v2/users/{userId}/unlock
# operationId: unlockUserV2
export def "users-unlock unlock" [
  user_id: string
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
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/v2/users/{user_id}/unlock") $auth.query)
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

# Update User Details
#
# POST /v2/users/{userId}/userDetailsUpdate
# operationId: userDetailsUpdate
export def "users-user-details-update update" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # the email address of the user (nullable, format: email, e.g. foo@example.com)
  --first-name: string # nullable, e.g. John
  --last-name: string # nullable, e.g. Doe
  --mfa-type: string@mfa-type-completer # The type of the MFA device (nullable, e.g. TOTP)
  --primary-contact-number: string # The main contact number for the user (nullable, e.g. 11235555555)
  --secondary-contact-number: string # The secondary contact number for the user (nullable, e.g. 11235555550)
  --sms-number: string # The phone number of a device that the user can receive sms messages on (nullable, e.g. 11235555555)
  --verification-code: string # Optional property that MUST be suppied when manually verifying a user The user's smsNumber is registered via a separate endpoint and an OTP sent to them (nullable, e.g. 123456)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/v2/users/{user_id}/userDetailsUpdate") $auth.query)
  let req_body = {"email": $email, "firstName": $first_name, "lastName": $last_name, "mfaType": $mfa_type, "primaryContactNumber": $primary_contact_number, "secondaryContactNumber": $secondary_contact_number, "smsNumber": $sms_number, "verificationCode": $verification_code} | compact
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

# List Payees
#
# GET /v3/payees
# DEPRECATED
# operationId: listPayeesV3
@deprecated
export def "payees list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The account owner Payor ID (format: uuid)
  --watchlist-status: string # The watchlistStatus of the payees.
  --disabled: oneof<nothing, bool> # Payee disabled
  --onboarded-status: string # The onboarded status of the payees.
  --email: string # Email address (format: email, e.g. bob@example.com)
  --display-name: string # The display name of the payees. (e.g. Bob Smith)
  --remote-id: string # The remote id of the payees. (e.g. remoteId123)
  --payee-type: string # The onboarded status of the payees.
  --payee-country: string # The country of the payee - 2 letter ISO 3166-1 country code (upper case) (e.g. US)
  --page: int # Page number. Default is 1. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. Default is 25. Max allowable is 100. (format: int32, default: 25, e.g. 25)
  --qp-sort: string # List of sort fields (e.g. ?sort=onboardedStatus:asc,name:asc) Default is name:asc 'name' is treated as company name for companies - last name + ',' + firstName for individuals The supported sort fields are - payeeId, displayName, payoutStatus, onboardedStatus. (default: displayName:asc, e.g. displayName:asc)
]: nothing -> record<content: table<company: record, country: string, created: string, disabled: bool, disabledComment: string, disabledUpdatedTimestamp: string, displayName: string, email: string, individual: record, language: string, onboardedStatus: string, payeeId: string, payeeType: string, payorRefs: list, watchlistOverrideComment: string, watchlistStatus: string, watchlistStatusUpdatedTimestamp: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>, summary: record<totalInvitedCount: int, totalOnboardedCount: int, totalPayeesCount: int, totalRegisteredCount: int, totalWatchlistFailedCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payor_id "scalar") (serialize-qp "watchlistStatus" $watchlist_status "scalar") (serialize-qp "disabled" $disabled "scalar") (serialize-qp "onboardedStatus" $onboarded_status "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "displayName" $display_name "scalar") (serialize-qp "remoteId" $remote_id "scalar") (serialize-qp "payeeType" $payee_type "scalar") (serialize-qp "payeeCountry" $payee_country "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/payees" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"payorId": $payor_id, "watchlistStatus": $watchlist_status, "disabled": $disabled, "onboardedStatus": $onboarded_status, "email": $email, "displayName": $display_name, "remoteId": $remote_id, "payeeType": $payee_type, "payeeCountry": $payee_country, "page": $page, "pageSize": $page_size, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Initiate Payee Creation
#
# POST /v3/payees
# DEPRECATED
# operationId: createPayeeV3
# --payees item shape: {address: record, challenge?: record, company?: record, email: string, individual?: record, language?: string, paymentChannel?: record, remoteId: string, type: string}
@deprecated
export def "payees create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  payees: list # item shape: {address: record, challenge?: record, company?: record, email: string, individual?: record, language?: string, paymentChannel?: record, remoteId: string, type: string}
  payor_id: string # e.g. 9ac75325-5dcd-42d5-b992-175d7e0a035e
]: any -> record<batchId: string, rejectedCsvRows: table<lineNumber: int, message: string, rejectedContent: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/payees" $auth.query)
  let req_body = {"payees": $payees, "payorId": $payor_id} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Query Batch Status
#
# GET /v3/payees/batch/{batchId}
# DEPRECATED
# operationId: queryBatchStatusV3
@deprecated
export def "payees-batch list-status-by-batch-id" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<failureCount: int, failures: table<failedSubmission: record, failureMessage: string>, pendingCount: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_id | is-empty) { error make --unspanned { msg: "path parameter 'batchId' must be non-empty" } }
  let full_url = (build-url $base ({batch_id: (encode-path-segment $batch_id)} | format pattern "/v3/payees/batch/{batch_id}") $auth.query)
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

# List Payee Changes
#
# GET /v3/payees/deltas
# DEPRECATED
# operationId: listPayeeChangesV3
@deprecated
export def "payees-deltas list-changes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The Payor ID to find associated Payees (format: uuid)
  --updated-since: string # The updatedSince filter in the format YYYY-MM-DDThh:mm:ss+hh:mm (format: date-time)
  --page: int # Page number. Default is 1. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. Default is 100. Max allowable is 1000. (format: int32, default: 100, e.g. 100)
]: nothing -> record<content: table<dbaName: string, displayName: string, email: string, onboardedStatus: string, payeeCountry: string, payeeId: string, remoteId: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payor_id "scalar") (serialize-qp "updatedSince" $updated_since "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/payees/deltas" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"payorId": $payor_id, "updatedSince": $updated_since, "page": $page, "pageSize": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Payee Invitation Status
#
# GET /v3/payees/payors/{payorId}/invitationStatus
# DEPRECATED
# operationId: getPayeesInvitationStatusV3
@deprecated
export def "payees-payors-invitation-status get-by-payor-id" [
  payor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payee-id: string # The UUID of the payee. (format: uuid, e.g. 2aa5d7e0-2ecb-403f-8494-1865ed0454e9)
  --invitation-status: string # The invitation status of the payees.
  --page: int # Page number. Default is 1. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. Default is 25. Max allowable is 100. (format: int32, default: 25, e.g. 25)
]: nothing -> record<content: table<gracePeriodEndDate: string, invitationStatus: string, payeeId: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payor_id | is-empty) { error make --unspanned { msg: "path parameter 'payorId' must be non-empty" } }
  let qp = [(serialize-qp "payeeId" $payee_id "scalar") (serialize-qp "invitationStatus" $invitation_status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({payor_id: (encode-path-segment $payor_id)} | format pattern "/v3/payees/payors/{payor_id}/invitationStatus") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"payeeId": $payee_id, "invitationStatus": $invitation_status, "page": $page, "pageSize": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete Payee by Id
#
# DELETE /v3/payees/{payeeId}
# DEPRECATED
# operationId: deletePayeeByIdV3
@deprecated
export def "payees delete-by-payee-id" [
  payee_id: string
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
  if ($payee_id | is-empty) { error make --unspanned { msg: "path parameter 'payeeId' must be non-empty" } }
  let full_url = (build-url $base ({payee_id: (encode-path-segment $payee_id)} | format pattern "/v3/payees/{payee_id}") $auth.query)
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

# Get Payee by Id
#
# GET /v3/payees/{payeeId}
# DEPRECATED
# operationId: getPayeeByIdV3
@deprecated
export def "payees get-by-payee-id" [
  payee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> record<acceptTermsAndConditionsTimestamp: string, address: record<city: string, country: string, countyOrProvince: string, line1: string, line2: string, line3: string, line4: string, zipOrPostcode: string>, cellphoneNumber: string, challenge: record<description: string, value: string>, company: record<name: string, operatingName: string, taxId: string>, country: string, created: string, disabled: bool, disabledComment: string, disabledUpdatedTimestamp: string, displayName: string, email: string, enhancedKycCompleted: bool, gracePeriodEndDate: string, individual: record<dateOfBirth: string, name: record<firstName: string, lastName: string, otherNames: string, title: string>, nationalIdentification: string>, kycCompletedTimestamp: string, language: string, marketingOptInDecision: bool, marketingOptInTimestamp: string, onboardedStatus: string, pausePayment: bool, pausePaymentTimestamp: string, payeeId: string, payeeType: string, payorRefs: table<invitationStatus: string, invitationStatusTimestamp: string, payableIssues: list, payableStatus: bool, paymentChannelId: string, payorId: string, remoteId: string>, watchlistOverrideComment: string, watchlistOverrideExpiresAtTimestamp: string, watchlistStatus: string, watchlistStatusUpdatedTimestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payee_id | is-empty) { error make --unspanned { msg: "path parameter 'payeeId' must be non-empty" } }
  let qp = [(serialize-qp "sensitive" $sensitive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({payee_id: (encode-path-segment $payee_id)} | format pattern "/v3/payees/{payee_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sensitive": $sensitive} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Resend Payee Invite
#
# POST /v3/payees/{payeeId}/invite
# DEPRECATED
# operationId: resendPayeeInviteV3
@deprecated
export def "payees-invite resend-by-payee-id" [
  payee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  payor_id: string # format: uuid, e.g. 9ac75325-5dcd-42d5-b992-175d7e0a035e
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payee_id | is-empty) { error make --unspanned { msg: "path parameter 'payeeId' must be non-empty" } }
  let full_url = (build-url $base ({payee_id: (encode-path-segment $payee_id)} | format pattern "/v3/payees/{payee_id}/invite") $auth.query)
  let req_body = {"payorId": $payor_id} | compact
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

# Update Payee Details
#
# POST /v3/payees/{payeeId}/payeeDetailsUpdate
# DEPRECATED
# operationId: payeeDetailsUpdateV3
# --address shape: {city: string, country: string, countyOrProvince?: string, line1: string, line2?: string, line3?: string, line4?: string, zipOrPostcode?: string}
# --challenge shape: {description: string, value: string}
# --company shape: {name: string, operatingName?: string, taxId?: string}
# --individual shape: {name: any}
@deprecated
export def "payees-payee-details-update update-by-payee-id" [
  payee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # e.g. {city: Key West, country: US, countyOrProvince: FL, line1: 500 Duval St, line2: line2, line3: line3, line4: line4, zipOrPostcode: 33945} — shape: {city: string, country: string, countyOrProvince?: string, line1: string, line2?: string, line3?: string, line4?: string, zipOrPostcode?: string}
  --challenge: record # e.g. {description: challenge description, value: challenge test} — shape: {description: string, value: string}
  --company: record # nullable, e.g. {name: ABC Group Plc, operatingName: ABC Co, taxId: 123123123} — shape: {name: string, operatingName?: string, taxId?: string}
  --email: string # nullable, format: email, e.g. bob@example.com
  --individual: record # e.g. {dateOfBirth: 1985-01-01, name: {firstName: Bob, lastName: Smith, otherNames: A, title: Mr}, nationalIdentification: AB123456C} — shape: {name: any}
  --language: string # An IETF BCP 47 language code which has been configured for use within this Velo environment. See the /v1/supportedLanguages endpoint to list the available codes for an environment. (e.g. en-US)
  --payee-type: string@payee-type-completer-1 # The type of the payee
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payee_id | is-empty) { error make --unspanned { msg: "path parameter 'payeeId' must be non-empty" } }
  let full_url = (build-url $base ({payee_id: (encode-path-segment $payee_id)} | format pattern "/v3/payees/{payee_id}/payeeDetailsUpdate") $auth.query)
  let req_body = {"address": $address, "challenge": $challenge, "company": $company, "email": $email, "individual": $individual, "language": $language, "payeeType": $payee_type} | compact
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

# Update Payee Remote Id
#
# POST /v3/payees/{payeeId}/remoteIdUpdate
# DEPRECATED
@deprecated
export def "payees-remote-id-update create-by-payee-id" [
  payee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  payor_id: string # format: uuid, e.g. 9ac75325-5dcd-42d5-b992-175d7e0a035e
  remote_id: string # e.g. remoteId123
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payee_id | is-empty) { error make --unspanned { msg: "path parameter 'payeeId' must be non-empty" } }
  let full_url = (build-url $base ({payee_id: (encode-path-segment $payee_id)} | format pattern "/v3/payees/{payee_id}/remoteIdUpdate") $auth.query)
  let req_body = {"payorId": $payor_id, "remoteId": $remote_id} | compact
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

# V3 Get List of Payments
#
# GET /v3/paymentaudit/payments
# DEPRECATED
# operationId: listPaymentsAuditV3
@deprecated
export def "paymentaudit-payments list-audit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payee-id: string # The UUID of the payee. (format: uuid)
  --payor-id: string # The account owner Payor Id. Required for external users. (format: uuid)
  --payor-name: string # The payor’s name. This filters via a case insensitive substring match.
  --remote-id: string # The remote id of the payees.
  --status: string@status-completer-1 # Payment Status
  --source-account-name: string # The source account name filter. This filters via a case insensitive substring match.
  --source-amount-from: int # The source amount from range filter. Filters for sourceAmount >= sourceAmountFrom (format: int32)
  --source-amount-to: int # The source amount to range filter. Filters for sourceAmount ⇐ sourceAmountTo (format: int32)
  --source-currency: string # The source currency filter. Filters based on an exact match on the currency.
  --payment-amount-from: int # The payment amount from range filter. Filters for paymentAmount >= paymentAmountFrom (format: int32)
  --payment-amount-to: int # The payment amount to range filter. Filters for paymentAmount ⇐ paymentAmountTo (format: int32)
  --payment-currency: string # The payment currency filter. Filters based on an exact match on the currency.
  --submitted-date-from: string # The submitted date from range filter. Format is yyyy-MM-dd. (format: date)
  --submitted-date-to: string # The submitted date to range filter. Format is yyyy-MM-dd. (format: date)
  --payment-memo: string # The payment memo filter. This filters via a case insensitive substring match.
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields (e.g. ?sort=submittedDateTime:asc,status:asc). Default is sort by remoteId The supported sort fields are: sourceAmount, sourceCurrency, paymentAmount, paymentCurrency, routingNumber, accountNumber, remoteId, submittedDateTime and status
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> record<content: table<accountName: string, accountNumber: string, countryCode: string, events: list, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentScheme: string, payorId: string, payorName: string, payorPaymentId: string, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, returnCost: int, returnReason: string, routingNumber: string, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payeeId" $payee_id "scalar") (serialize-qp "payorId" $payor_id "scalar") (serialize-qp "payorName" $payor_name "scalar") (serialize-qp "remoteId" $remote_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sourceAccountName" $source_account_name "scalar") (serialize-qp "sourceAmountFrom" $source_amount_from "scalar") (serialize-qp "sourceAmountTo" $source_amount_to "scalar") (serialize-qp "sourceCurrency" $source_currency "scalar") (serialize-qp "paymentAmountFrom" $payment_amount_from "scalar") (serialize-qp "paymentAmountTo" $payment_amount_to "scalar") (serialize-qp "paymentCurrency" $payment_currency "scalar") (serialize-qp "submittedDateFrom" $submitted_date_from "scalar") (serialize-qp "submittedDateTo" $submitted_date_to "scalar") (serialize-qp "paymentMemo" $payment_memo "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sensitive" $sensitive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/paymentaudit/payments" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"payeeId": $payee_id, "payorId": $payor_id, "payorName": $payor_name, "remoteId": $remote_id, "status": $status, "sourceAccountName": $source_account_name, "sourceAmountFrom": $source_amount_from, "sourceAmountTo": $source_amount_to, "sourceCurrency": $source_currency, "paymentAmountFrom": $payment_amount_from, "paymentAmountTo": $payment_amount_to, "paymentCurrency": $payment_currency, "submittedDateFrom": $submitted_date_from, "submittedDateTo": $submitted_date_to, "paymentMemo": $payment_memo, "page": $page, "pageSize": $page_size, "sort": $qp_sort, "sensitive": $sensitive} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# V3 Get Payment
#
# GET /v3/paymentaudit/payments/{paymentId}
# DEPRECATED
# operationId: getPaymentDetailsV3
@deprecated
export def "paymentaudit-payments get-details-by-payment-id" [
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
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> record<accountName: string, accountNumber: string, countryCode: string, events: table<accountName: string, accountNumber: string, eventDateTime: string, eventId: string, eventType: string, iban: string, paymentAmount: int, paymentCurrency: string, principal: string, routingNumber: string, sourceAmount: int, sourceCurrency: string>, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentScheme: string, payorId: string, payorName: string, payorPaymentId: string, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, returnCost: int, returnReason: string, routingNumber: string, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let qp = [(serialize-qp "sensitive" $sensitive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id)} | format pattern "/v3/paymentaudit/payments/{payment_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sensitive": $sensitive} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# V3 Get Payouts for Payor
#
# GET /v3/paymentaudit/payouts
# DEPRECATED
# operationId: getPayoutsForPayorV3
@deprecated
export def "paymentaudit-payouts get-for-payor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The account owner Payor ID (format: uuid)
  --payout-memo: string # Payout Memo filter - case insensitive sub-string match
  --status: string@status-completer-2 # Payout Status
  --submitted-date-from: string # The submitted date from range filter. Format is yyyy-MM-dd. (format: date)
  --submitted-date-to: string # The submitted date to range filter. Format is yyyy-MM-dd. (format: date)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields (e.g. ?sort=submittedDateTime:asc,instructedDateTime:asc,status:asc) Default is submittedDateTime:asc The supported sort fields are: submittedDateTime, instructedDateTime, status.
]: nothing -> record<content: table<fxSummaries: list, instructedDateTime: string, payorId: string, payoutId: string, payoutMemo: string, sourceAccountSummary: list, status: string, submittedDateTime: string, totalFailedPayments: int, totalIncompletePayments: int, totalPayments: int, withdrawnDateTime: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payor_id "scalar") (serialize-qp "payoutMemo" $payout_memo "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "submittedDateFrom" $submitted_date_from "scalar") (serialize-qp "submittedDateTo" $submitted_date_to "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/paymentaudit/payouts" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"payorId": $payor_id, "payoutMemo": $payout_memo, "status": $status, "submittedDateFrom": $submitted_date_from, "submittedDateTo": $submitted_date_to, "page": $page, "pageSize": $page_size, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# V3 Get Payments for Payout
#
# GET /v3/paymentaudit/payouts/{payoutId}
# DEPRECATED
# operationId: getPaymentsForPayout_PA_V3
@deprecated
export def "paymentaudit-payouts get-payments-for-pa" [
  payout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --remote-id: string # The remote id of the payees.
  --status: string@status-completer-1 # Payment Status
  --source-amount-from: int # The source amount from range filter. Filters for sourceAmount >= sourceAmountFrom (format: int32)
  --source-amount-to: int # The source amount to range filter. Filters for sourceAmount ⇐ sourceAmountTo (format: int32)
  --payment-amount-from: int # The payment amount from range filter. Filters for paymentAmount >= paymentAmountFrom (format: int32)
  --payment-amount-to: int # The payment amount to range filter. Filters for paymentAmount ⇐ paymentAmountTo (format: int32)
  --submitted-date-from: string # The submitted date from range filter. Format is yyyy-MM-dd. (format: date)
  --submitted-date-to: string # The submitted date to range filter. Format is yyyy-MM-dd. (format: date)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields (e.g. ?sort=submittedDateTime:asc,status:asc). Default is sort by remoteId The supported sort fields are: sourceAmount, sourceCurrency, paymentAmount, paymentCurrency, routingNumber, accountNumber, remoteId, submittedDateTime and status
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> record<content: table<accountName: string, accountNumber: string, countryCode: string, events: list, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentScheme: string, payorId: string, payorName: string, payorPaymentId: string, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, returnCost: int, returnReason: string, routingNumber: string, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>, summary: record<confirmedPayments: int, failedPayments: int, incompletePayments: int, instructedDateTime: string, payoutMemo: string, payoutStatus: string, releasedPayments: int, submittedDateTime: string, totalPayments: int, withdrawnDateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payout_id | is-empty) { error make --unspanned { msg: "path parameter 'payoutId' must be non-empty" } }
  let qp = [(serialize-qp "remoteId" $remote_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sourceAmountFrom" $source_amount_from "scalar") (serialize-qp "sourceAmountTo" $source_amount_to "scalar") (serialize-qp "paymentAmountFrom" $payment_amount_from "scalar") (serialize-qp "paymentAmountTo" $payment_amount_to "scalar") (serialize-qp "submittedDateFrom" $submitted_date_from "scalar") (serialize-qp "submittedDateTo" $submitted_date_to "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sensitive" $sensitive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({payout_id: (encode-path-segment $payout_id)} | format pattern "/v3/paymentaudit/payouts/{payout_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"remoteId": $remote_id, "status": $status, "sourceAmountFrom": $source_amount_from, "sourceAmountTo": $source_amount_to, "paymentAmountFrom": $payment_amount_from, "paymentAmountTo": $payment_amount_to, "submittedDateFrom": $submitted_date_from, "submittedDateTo": $submitted_date_to, "page": $page, "pageSize": $page_size, "sort": $qp_sort, "sensitive": $sensitive} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# V3 Export Transactions
#
# GET /v3/paymentaudit/transactions
# DEPRECATED
# operationId: exportTransactionsCSVV3
@deprecated
export def "paymentaudit-transactions export-csvv3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The Payor ID for whom you wish to run the report. For a Payor requesting the report, this could be their exact Payor, or it could be a child/descendant Payor. (format: uuid)
  --start-date: string # Start date, inclusive. Format is YYYY-MM-DD (format: date)
  --end-date: string # End date, inclusive. Format is YYYY-MM-DD (format: date)
]: nothing -> record<credit: int, creditCurrency: string, dateFundingRequested: string, debit: int, debitCurrency: string, fundingType: string, fxApplied: float, payeeType: string, paymentAmount: int, paymentCurrency: string, paymentMemo: string, paymentRails: string, paymentStatus: string, payorPaymentId: string, rejectReason: string, remoteId: string, reportTransactionType: string, returnCode: string, returnDescription: string, returnFee: string, returnFeeCurrency: string, returnFeeDescription: string, sourceAccount: string, transactionDate: string, transactionTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payor_id "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/paymentaudit/transactions" $qp $auth.query)
  let accept_val = "application/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"payorId": $payor_id, "startDate": $start_date, "endDate": $end_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Submit Payout
#
# POST /v3/payouts
# operationId: submitPayoutV3
# --payments item shape: {amount: int, currency: string, paymentMemo?: string, paymentMetadata?: string, payorPaymentId?: string, remoteId: string, remoteSystemId?: string, sourceAccountName: string, transmissionType?: "SAME_DAY_ACH"|"WIRE"|"ACH"|"LOCAL"|"SWIFT"}
export def "payouts submit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  payments: list # item shape: {amount: int, currency: string, paymentMemo?: string, paymentMetadata?: string, payorPaymentId?: string, remoteId: string, remoteSystemId?: string, sourceAccountName: string, transmissionType?: "SAME_DAY_ACH"|"WIRE"|"ACH"|"LOCAL"|"SWIFT"}
  --payout-from-payor-id: string # The id of the payor whose source account(s) will be debited payoutFromPayorId and payoutToPayorId must be both supplied or both omitted (format: uuid, e.g. c4261044-13df-4a6c-b1d4-fa8be2b46f5a)
  --payout-memo: string # Text applied to all payment memos unless specified explicitly on a payment This should be the reference field on the statement seen by the payee (but not via ACH) (e.g. Monthly Payment)
  --payout-to-payor-id: string # The id of the payor whose payees will be paid payoutFromPayorId and payoutToPayorId must be both supplied or both omitted (format: uuid, e.g. 9afc6b39-de12-466a-a9ca-07c7a23b312d)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/payouts" $auth.query)
  let req_body = {"payments": $payments, "payoutFromPayorId": $payout_from_payor_id, "payoutMemo": $payout_memo, "payoutToPayorId": $payout_to_payor_id} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Withdraw Payout
#
# DELETE /v3/payouts/{payoutId}
# operationId: withdrawPayoutV3
export def "payouts delete-withdraw" [
  payout_id: string
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
  if ($payout_id | is-empty) { error make --unspanned { msg: "path parameter 'payoutId' must be non-empty" } }
  let full_url = (build-url $base ({payout_id: (encode-path-segment $payout_id)} | format pattern "/v3/payouts/{payout_id}") $auth.query)
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
  send-delete $req null $insecure $raw $allow_errors $full [202]
}

# Get Payout Summary
#
# GET /v3/payouts/{payoutId}
# operationId: getPayoutSummaryV3
export def "payouts get-summary" [
  payout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<acceptedPayments: table<amount: int, currencyType: string, paymentMemo: string, paymentMetadata: string, payorPaymentId: string, railsId: string, remoteId: string, remoteSystemId: string, sourceAccountName: string>, accounts: table<currency: string, sourceAccountId: string, sourceAccountName: string, totalPayoutCost: int>, fxSummaries: table<creationTime: string, expiryTime: string, fundingStatus: string, invertedRate: float, paymentCurrency: string, quoteId: string, rate: float, sourceCurrency: string, status: string, totalPaymentAmount: int, totalSourceAmount: int>, paymentsAccepted: int, paymentsRejected: int, paymentsSubmitted: int, paymentsWithdrawn: int, payoutId: string, rejectedPayments: table<amount: int, currencyType: string, lineNumber: int, message: string, paymentMetadata: string, payorPaymentId: string, reason: string, reasonCode: string, remoteId: string, remoteSystemId: string, sourceAccountName: string>, schedule: record<notificationsEnabled: bool, scheduleStatus: string, scheduledAt: string, scheduledByPrincipalId: string, scheduledFor: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payout_id | is-empty) { error make --unspanned { msg: "path parameter 'payoutId' must be non-empty" } }
  let full_url = (build-url $base ({payout_id: (encode-path-segment $payout_id)} | format pattern "/v3/payouts/{payout_id}") $auth.query)
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

# Instruct Payout
#
# POST /v3/payouts/{payoutId}
# operationId: instructPayoutV3
export def "payouts create-instruct" [
  payout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fx-rate-degredation-threshold-percentage: float # Halt instruction if the FX rates have become worse since the last quote (format: float)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payout_id | is-empty) { error make --unspanned { msg: "path parameter 'payoutId' must be non-empty" } }
  let full_url = (build-url $base ({payout_id: (encode-path-segment $payout_id)} | format pattern "/v3/payouts/{payout_id}") $auth.query)
  let req_body = {"fxRateDegredationThresholdPercentage": $fx_rate_degredation_threshold_percentage} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Retrieve payments for a payout
#
# GET /v3/payouts/{payoutId}/payments
# operationId: getPaymentsForPayoutV3
export def "payouts-payments get" [
  payout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-3 # Payment Status * ACCEPTED: any payment which was accepted at submission time (status may have changed since) * REJECTED: any payment rejected by initial submission processing * WITHDRAWN: any payment which has been withdrawn * WITHDRAWABLE: any payment eligible for withdrawal
  --remote-id: string # The remote id of the payees.
  --payor-payment-id: string # Payor's Id of the Payment
  --source-account-name: string # Physical Account Name
  --transmission-type: string@transmission-type-completer # Transmission Type * ACH * SAME_DAY_ACH * WIRE
  --payment-memo: string # Payment Memo of the Payment
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
]: nothing -> record<content: table<amount: int, autoWithdrawnReasonCode: string, currency: string, payee: record, paymentId: string, paymentMemo: string, paymentMetadata: string, payorPaymentId: string, railsId: string, remoteId: string, remoteSystemId: string, sourceAccountName: string, status: string, transmissionType: string, withdrawable: bool>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payout_id | is-empty) { error make --unspanned { msg: "path parameter 'payoutId' must be non-empty" } }
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "remoteId" $remote_id "scalar") (serialize-qp "payorPaymentId" $payor_payment_id "scalar") (serialize-qp "sourceAccountName" $source_account_name "scalar") (serialize-qp "transmissionType" $transmission_type "scalar") (serialize-qp "paymentMemo" $payment_memo "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({payout_id: (encode-path-segment $payout_id)} | format pattern "/v3/payouts/{payout_id}/payments") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"status": $status, "remoteId": $remote_id, "payorPaymentId": $payor_payment_id, "sourceAccountName": $source_account_name, "transmissionType": $transmission_type, "paymentMemo": $payment_memo, "pageSize": $page_size, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a quote for the payout
#
# POST /v3/payouts/{payoutId}/quote
# operationId: createQuoteForPayoutV3
export def "payouts-quote create" [
  payout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<fxSummaries: table<creationTime: string, expiryTime: string, fundingStatus: string, invertedRate: float, paymentCurrency: string, quoteId: string, rate: float, sourceCurrency: string, status: string, totalPaymentAmount: int, totalSourceAmount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payout_id | is-empty) { error make --unspanned { msg: "path parameter 'payoutId' must be non-empty" } }
  let full_url = (build-url $base ({payout_id: (encode-path-segment $payout_id)} | format pattern "/v3/payouts/{payout_id}/quote") $auth.query)
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
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Deschedule a payout
#
# DELETE /v3/payouts/{payoutId}/schedule
# operationId: deschedulePayout
export def "payouts-schedule delete-deschedule" [
  payout_id: string
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
  if ($payout_id | is-empty) { error make --unspanned { msg: "path parameter 'payoutId' must be non-empty" } }
  let full_url = (build-url $base ({payout_id: (encode-path-segment $payout_id)} | format pattern "/v3/payouts/{payout_id}/schedule") $auth.query)
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

# Schedule a payout
#
# POST /v3/payouts/{payoutId}/schedule
# operationId: scheduleForPayout
export def "payouts-schedule create" [
  payout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notifications-enabled: oneof<nothing, bool> # Flag to indicate whether to receive notifications when scheduled payout is processed
  scheduled_for: string # UTC timestamp for instructing the payout. Format is ISO-8601. (format: date-time, e.g. 2025-01-01T10:00:00Z)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payout_id | is-empty) { error make --unspanned { msg: "path parameter 'payoutId' must be non-empty" } }
  let full_url = (build-url $base ({payout_id: (encode-path-segment $payout_id)} | format pattern "/v3/payouts/{payout_id}/schedule") $auth.query)
  let req_body = {"notificationsEnabled": $notifications_enabled, "scheduledFor": $scheduled_for} | compact
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

# Get list of source accounts
#
# GET /v3/sourceAccounts
# operationId: getSourceAccountsV3
export def "source-accounts get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --physical-account-name: string # Physical Account Name
  --physical-account-id: string # The physical account ID (format: uuid)
  --payor-id: string # The account owner Payor ID (format: uuid)
  --funding-account-id: string # The funding account ID (format: uuid)
  --include-user-deleted: string # A filter for retrieving both active accounts and user deleted ones (format: boolean)
  --type: string # The type of source account.
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields e.g. ?sort=name:asc Default is name:asc The supported sort fields are - fundingRef, name, balance (default: fundingRef:asc)
]: nothing -> record<content: table<autoTopUpConfig: record, balance: int, country: string, currency: string, customerId: string, deleted: bool, deletedAt: string, fundingRef: string, id: string, name: string, notifications: record, payorId: string, physicalAccountId: string, physicalAccountName: string, pooled: bool, railsId: string, type: string, userDeleted: bool>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "physicalAccountName" $physical_account_name "scalar") (serialize-qp "physicalAccountId" $physical_account_id "scalar") (serialize-qp "payorId" $payor_id "scalar") (serialize-qp "fundingAccountId" $funding_account_id "scalar") (serialize-qp "includeUserDeleted" $include_user_deleted "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/sourceAccounts" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"physicalAccountName": $physical_account_name, "physicalAccountId": $physical_account_id, "payorId": $payor_id, "fundingAccountId": $funding_account_id, "includeUserDeleted": $include_user_deleted, "type": $type, "page": $page, "pageSize": $page_size, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a source account by ID
#
# DELETE /v3/sourceAccounts/{sourceAccountId}
# operationId: deleteSourceAccountV3
export def "source-accounts delete" [
  source_account_id: string
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
  if ($source_account_id | is-empty) { error make --unspanned { msg: "path parameter 'sourceAccountId' must be non-empty" } }
  let full_url = (build-url $base ({source_account_id: (encode-path-segment $source_account_id)} | format pattern "/v3/sourceAccounts/{source_account_id}") $auth.query)
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

# Get details about given source account.
#
# GET /v3/sourceAccounts/{sourceAccountId}
# operationId: getSourceAccountV3
export def "source-accounts get-by-source-account-id-1" [
  source_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<autoTopUpConfig: record<enabled: bool, fundingAccountId: string, minBalance: int, targetBalance: int>, balance: int, country: string, currency: string, customerId: string, deleted: bool, deletedAt: string, fundingRef: string, id: string, name: string, notifications: record<minimumBalance: int>, payorId: string, physicalAccountId: string, physicalAccountName: string, pooled: bool, railsId: string, type: string, userDeleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_account_id | is-empty) { error make --unspanned { msg: "path parameter 'sourceAccountId' must be non-empty" } }
  let full_url = (build-url $base ({source_account_id: (encode-path-segment $source_account_id)} | format pattern "/v3/sourceAccounts/{source_account_id}") $auth.query)
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

# Create Funding Request
#
# POST /v3/sourceAccounts/{sourceAccountId}/fundingRequest
# operationId: createFundingRequestV3
export def "source-accounts-funding-request create-by-source-account-id-1" [
  source_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: int # Amount to fund in minor units (format: int64)
  funding_account_id: string # The funding account id (format: uuid)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_account_id | is-empty) { error make --unspanned { msg: "path parameter 'sourceAccountId' must be non-empty" } }
  let full_url = (build-url $base ({source_account_id: (encode-path-segment $source_account_id)} | format pattern "/v3/sourceAccounts/{source_account_id}/fundingRequest") $auth.query)
  let req_body = {"amount": $amount, "fundingAccountId": $funding_account_id} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Set notifications
#
# POST /v3/sourceAccounts/{sourceAccountId}/notifications
# operationId: setNotificationsRequestV3
export def "source-accounts-notifications update-request-by-source-account-id-1" [
  source_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  minimum_balance: int # Amount to set as minimum balance for notifications in minor units (format: int64, e.g. 10000000)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_account_id | is-empty) { error make --unspanned { msg: "path parameter 'sourceAccountId' must be non-empty" } }
  let full_url = (build-url $base ({source_account_id: (encode-path-segment $source_account_id)} | format pattern "/v3/sourceAccounts/{source_account_id}/notifications") $auth.query)
  let req_body = {"minimumBalance": $minimum_balance} | compact
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

# Transfer Funds between source accounts
#
# POST /v3/sourceAccounts/{sourceAccountId}/transfers
# operationId: transferFundsV3
export def "source-accounts-transfers create-funds-by-source-account-id-1" [
  source_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: int # Amount to transfer, in minor units (format: int64)
  currency: string # Valid ISO 4217 3 letter currency code. See the ISO specification (https://www.iso.org/iso-4217-currency-codes.html) for details. (e.g. USD)
  to_source_account_id: string # The 'to' source account id, which will be credited (format: uuid)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_account_id | is-empty) { error make --unspanned { msg: "path parameter 'sourceAccountId' must be non-empty" } }
  let full_url = (build-url $base ({source_account_id: (encode-path-segment $source_account_id)} | format pattern "/v3/sourceAccounts/{source_account_id}/transfers") $auth.query)
  let req_body = {"amount": $amount, "currency": $currency, "toSourceAccountId": $to_source_account_id} | compact
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

# List Payees
#
# GET /v4/payees
# operationId: listPayeesV4
export def "payees list-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The account owner Payor ID (format: uuid)
  --watchlist-status: string # The watchlistStatus of the payees.
  --disabled: oneof<nothing, bool> # Payee disabled
  --onboarded-status: string # The onboarded status of the payees.
  --email: string # Email address (format: email, e.g. bob@example.com)
  --display-name: string # The display name of the payees. (e.g. Bob Smith)
  --remote-id: string # The remote id of the payees. (e.g. remoteId123)
  --payee-type: string # The onboarded status of the payees.
  --payee-country: string # The country of the payee - 2 letter ISO 3166-1 country code (upper case) (e.g. US)
  --ofac-status: string # The ofacStatus of the payees.
  --page: int # Page number. Default is 1. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. Default is 25. Max allowable is 100. (format: int32, default: 25, e.g. 25)
  --qp-sort: string # List of sort fields (e.g. ?sort=onboardedStatus:asc,name:asc) Default is name:asc 'name' is treated as company name for companies - last name + ',' + firstName for individuals The supported sort fields are - payeeId, displayName, payoutStatus, onboardedStatus. (default: displayName:asc, e.g. displayName:asc)
]: nothing -> record<content: table<company: record, country: string, created: string, disabled: bool, disabledComment: string, disabledUpdatedTimestamp: string, displayName: string, email: string, individual: record, language: string, onboardedStatus: string, payeeId: string, payeeType: string, payorRefs: list, watchlistOverrideComment: string, watchlistStatus: string, watchlistStatusUpdatedTimestamp: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>, summary: record<totalInvitedCount: int, totalOnboardedCount: int, totalPayeesCount: int, totalRegisteredCount: int, totalWatchlistFailedCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payor_id "scalar") (serialize-qp "watchlistStatus" $watchlist_status "scalar") (serialize-qp "disabled" $disabled "scalar") (serialize-qp "onboardedStatus" $onboarded_status "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "displayName" $display_name "scalar") (serialize-qp "remoteId" $remote_id "scalar") (serialize-qp "payeeType" $payee_type "scalar") (serialize-qp "payeeCountry" $payee_country "scalar") (serialize-qp "ofacStatus" $ofac_status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/payees" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"payorId": $payor_id, "watchlistStatus": $watchlist_status, "disabled": $disabled, "onboardedStatus": $onboarded_status, "email": $email, "displayName": $display_name, "remoteId": $remote_id, "payeeType": $payee_type, "payeeCountry": $payee_country, "ofacStatus": $ofac_status, "page": $page, "pageSize": $page_size, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Initiate Payee Creation
#
# POST /v4/payees
# operationId: v4CreatePayee
# --payees item shape: {address: record, challenge?: record, company?: record, email: string, individual?: record, language?: string, paymentChannel?: record, remoteId: string, type: "Individual"|"Company"}
export def "payees create-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  payees: list # item shape: {address: record, challenge?: record, company?: record, email: string, individual?: record, language?: string, paymentChannel?: record, remoteId: string, type: "Individual"|"Company"}
  payor_id: string # e.g. 9ac75325-5dcd-42d5-b992-175d7e0a035e
]: any -> record<batchId: string, rejectedCsvRows: table<lineNumber: int, message: string, rejectedContent: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/payees" $auth.query)
  let req_body = {"payees": $payees, "payorId": $payor_id} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Query Batch Status
#
# GET /v4/payees/batch/{batchId}
# operationId: queryBatchStatusV4
export def "payees-batch list-status-by-batch-id-1" [
  batch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<failureCount: int, failures: table<failedSubmission: record, failureMessage: string>, pendingCount: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($batch_id | is-empty) { error make --unspanned { msg: "path parameter 'batchId' must be non-empty" } }
  let full_url = (build-url $base ({batch_id: (encode-path-segment $batch_id)} | format pattern "/v4/payees/batch/{batch_id}") $auth.query)
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

# List Payee Changes
#
# GET /v4/payees/deltas
# operationId: listPayeeChangesV4
export def "payees-deltas list-changes-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The Payor ID to find associated Payees (format: uuid)
  --updated-since: string # The updatedSince filter in the format YYYY-MM-DDThh:mm:ss+hh:mm (format: date-time)
  --page: int # Page number. Default is 1. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. Default is 100. Max allowable is 1000. (format: int32, default: 100, e.g. 100)
]: nothing -> record<content: table<dbaName: string, displayName: string, email: string, onboardedStatus: string, payeeCountry: string, payeeId: string, remoteId: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payor_id "scalar") (serialize-qp "updatedSince" $updated_since "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/payees/deltas" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"payorId": $payor_id, "updatedSince": $updated_since, "page": $page, "pageSize": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Payee Invitation Status
#
# GET /v4/payees/payors/{payorId}/invitationStatus
# operationId: getPayeesInvitationStatusV4
export def "payees-payors-invitation-status get-by-payor-id-1" [
  payor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payee-id: string # The UUID of the payee. (format: uuid, e.g. 2aa5d7e0-2ecb-403f-8494-1865ed0454e9)
  --invitation-status: string # The invitation status of the payees.
  --page: int # Page number. Default is 1. (format: int32, default: 1, e.g. 1)
  --page-size: int # Page size. Default is 25. Max allowable is 100. (format: int32, default: 25, e.g. 25)
]: nothing -> record<content: table<gracePeriodEndDate: string, invitationStatus: string, payeeId: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payor_id | is-empty) { error make --unspanned { msg: "path parameter 'payorId' must be non-empty" } }
  let qp = [(serialize-qp "payeeId" $payee_id "scalar") (serialize-qp "invitationStatus" $invitation_status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({payor_id: (encode-path-segment $payor_id)} | format pattern "/v4/payees/payors/{payor_id}/invitationStatus") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"payeeId": $payee_id, "invitationStatus": $invitation_status, "page": $page, "pageSize": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete Payee by Id
#
# DELETE /v4/payees/{payeeId}
# operationId: deletePayeeByIdV4
export def "payees delete-by-payee-id-1" [
  payee_id: string
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
  if ($payee_id | is-empty) { error make --unspanned { msg: "path parameter 'payeeId' must be non-empty" } }
  let full_url = (build-url $base ({payee_id: (encode-path-segment $payee_id)} | format pattern "/v4/payees/{payee_id}") $auth.query)
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

# Get Payee by Id
#
# GET /v4/payees/{payeeId}
# operationId: getPayeeByIdV4
export def "payees get-by-payee-id-1" [
  payee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> record<acceptTermsAndConditionsTimestamp: string, address: record<city: string, country: string, countyOrProvince: string, line1: string, line2: string, line3: string, line4: string, zipOrPostcode: string>, cellphoneNumber: string, challenge: record<description: string, value: string>, company: record<name: string, operatingName: string, taxId: string>, country: string, created: string, disabled: bool, disabledComment: string, disabledUpdatedTimestamp: string, displayName: string, email: string, enhancedKycCompleted: bool, gracePeriodEndDate: string, individual: record<dateOfBirth: string, name: record<firstName: string, lastName: string, otherNames: string, title: string>, nationalIdentification: string>, kycCompletedTimestamp: string, language: string, marketingOptInDecision: bool, marketingOptInTimestamp: string, onboardedStatus: string, pausePayment: bool, pausePaymentTimestamp: string, payeeId: string, payeeType: string, payorRefs: table<invitationStatus: string, invitationStatusTimestamp: string, payableIssues: list, payableStatus: bool, paymentChannelId: string, payorId: string, remoteId: string>, watchlistOverrideComment: string, watchlistOverrideExpiresAtTimestamp: string, watchlistStatus: string, watchlistStatusUpdatedTimestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payee_id | is-empty) { error make --unspanned { msg: "path parameter 'payeeId' must be non-empty" } }
  let qp = [(serialize-qp "sensitive" $sensitive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({payee_id: (encode-path-segment $payee_id)} | format pattern "/v4/payees/{payee_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sensitive": $sensitive} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Resend Payee Invite
#
# POST /v4/payees/{payeeId}/invite
# operationId: resendPayeeInviteV4
export def "payees-invite resend-by-payee-id-1" [
  payee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  payor_id: string # format: uuid, e.g. 9ac75325-5dcd-42d5-b992-175d7e0a035e
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payee_id | is-empty) { error make --unspanned { msg: "path parameter 'payeeId' must be non-empty" } }
  let full_url = (build-url $base ({payee_id: (encode-path-segment $payee_id)} | format pattern "/v4/payees/{payee_id}/invite") $auth.query)
  let req_body = {"payorId": $payor_id} | compact
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

# Update Payee Details
#
# POST /v4/payees/{payeeId}/payeeDetailsUpdate
# operationId: payeeDetailsUpdateV4
# --address shape: {city: string, country: string, countyOrProvince?: string, line1: string, line2?: string, line3?: string, line4?: string, zipOrPostcode?: string}
# --challenge shape: {description: string, value: string}
# --company shape: {name: string, operatingName?: string, taxId?: string}
# --individual shape: {name: any}
export def "payees-payee-details-update update-by-payee-id-1" [
  payee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address: record # e.g. {city: Key West, country: US, countyOrProvince: FL, line1: 500 Duval St, line2: line2, line3: line3, line4: line4, zipOrPostcode: 33945} — shape: {city: string, country: string, countyOrProvince?: string, line1: string, line2?: string, line3?: string, line4?: string, zipOrPostcode?: string}
  --challenge: record # Used to override the default challenge presented to the payee when they onboard Not used after the payee has onboarded (e.g. {description: challenge description, value: 11984567}) — shape: {description: string, value: string}
  --company: record # nullable, e.g. {name: ABC Group Plc, operatingName: ABC Co, taxId: 123123123} — shape: {name: string, operatingName?: string, taxId?: string}
  --contact-sms-number: string # The phone number of a device that the payee wishes to receive sms messages on (e.g. 11235555555)
  --email: string # nullable, format: email, e.g. bob@example.com
  --individual: record # e.g. {dateOfBirth: 1985-01-01, name: {firstName: Bob, lastName: Smith, otherNames: A, title: Mr}, nationalIdentification: AB123456C} — shape: {name: any}
  --language: string # An IETF BCP 47 language code which has been configured for use within this Velo environment. See the /v1/supportedLanguages endpoint to list the available codes for an environment. (e.g. en-US)
  --payee-type: string@payee-type-completer-1 # The type of the payee
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payee_id | is-empty) { error make --unspanned { msg: "path parameter 'payeeId' must be non-empty" } }
  let full_url = (build-url $base ({payee_id: (encode-path-segment $payee_id)} | format pattern "/v4/payees/{payee_id}/payeeDetailsUpdate") $auth.query)
  let req_body = {"address": $address, "challenge": $challenge, "company": $company, "contactSmsNumber": $contact_sms_number, "email": $email, "individual": $individual, "language": $language, "payeeType": $payee_type} | compact
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

# Update Payee Remote Id
#
# POST /v4/payees/{payeeId}/remoteIdUpdate
export def "payees-remote-id-update create-by-payee-id-1" [
  payee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  payor_id: string # format: uuid, e.g. 9ac75325-5dcd-42d5-b992-175d7e0a035e
  remote_id: string # e.g. remoteId123
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payee_id | is-empty) { error make --unspanned { msg: "path parameter 'payeeId' must be non-empty" } }
  let full_url = (build-url $base ({payee_id: (encode-path-segment $payee_id)} | format pattern "/v4/payees/{payee_id}/remoteIdUpdate") $auth.query)
  let req_body = {"payorId": $payor_id, "remoteId": $remote_id} | compact
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

# Get Fundings for Payor
#
# GET /v4/paymentaudit/fundings
# operationId: getFundingsV4
export def "paymentaudit-fundings get-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The account owner Payor ID (format: uuid)
  --source-account-name: string # The source account name
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields. Example: ```?sort=destinationCurrency:asc,destinationAmount:asc``` Default is no sort. The supported sort fields are: dateTime and amount.
]: nothing -> record<content: table<amount: float, currency: string, dateTime: string, events: list, fundingAccountName: string, fundingType: string, sourceAccountName: string, status: string, topupType: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payor_id "scalar") (serialize-qp "sourceAccountName" $source_account_name "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/paymentaudit/fundings" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"payorId": $payor_id, "sourceAccountName": $source_account_name, "page": $page, "pageSize": $page_size, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get List of Payments
#
# GET /v4/paymentaudit/payments
# operationId: listPaymentsAuditV4
export def "paymentaudit-payments list-audit-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payee-id: string # The UUID of the payee. (format: uuid)
  --payor-id: string # The account owner Payor Id. Required for external users. (format: uuid)
  --payor-name: string # The payor’s name. This filters via a case insensitive substring match.
  --remote-id: string # The remote id of the payees.
  --remote-system-id: string # The id of the remote system that is orchestrating payments
  --status: string@status-completer-1 # Payment Status
  --transmission-type: string@transmission-type-completer-1 # Transmission Type * ACH * SAME_DAY_ACH * WIRE * GACHO
  --source-account-name: string # The source account name filter. This filters via a case insensitive substring match.
  --source-amount-from: int # The source amount from range filter. Filters for sourceAmount >= sourceAmountFrom (format: int32)
  --source-amount-to: int # The source amount to range filter. Filters for sourceAmount ⇐ sourceAmountTo (format: int32)
  --source-currency: string # The source currency filter. Filters based on an exact match on the currency.
  --payment-amount-from: int # The payment amount from range filter. Filters for paymentAmount >= paymentAmountFrom (format: int32)
  --payment-amount-to: int # The payment amount to range filter. Filters for paymentAmount ⇐ paymentAmountTo (format: int32)
  --payment-currency: string # The payment currency filter. Filters based on an exact match on the currency.
  --submitted-date-from: string # The submitted date from range filter. Format is yyyy-MM-dd. (format: date)
  --submitted-date-to: string # The submitted date to range filter. Format is yyyy-MM-dd. (format: date)
  --payment-memo: string # The payment memo filter. This filters via a case insensitive substring match.
  --rails-id: string # Payout Rails ID filter - case insensitive match. Any value is allowed, but you should use one of the supported railsId values. To get this list of values, you should call the 'Get Supported Rails' endpoint.
  --scheduled-for-date-from: string # Filter payouts scheduled to run on or after the given date. Format is yyyy-MM-dd. (format: date)
  --scheduled-for-date-to: string # Filter payouts scheduled to run on or before the given date. Format is yyyy-MM-dd. (format: date)
  --schedule-status: string@schedule-status-completer # Payout Schedule Status
  --post-instruct-fx-status: string@post-instruct-fx-status-completer # The status of the post instruct FX step if one was required for the payment
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields (e.g. ?sort=submittedDateTime:asc,status:asc). Default is sort by submittedDateTime:desc,paymentId:asc The supported sort fields are: sourceAmount, sourceCurrency, paymentAmount, paymentCurrency, routingNumber, accountNumber, remoteId, submittedDateTime, status and paymentId
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> record<content: table<accountName: string, accountNumber: string, autoWithdrawnReasonCode: string, countryCode: string, events: list, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, isPaymentCcyBaseCcy: bool, payeeAddressCountryCode: string, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentMetadata: string, paymentScheme: string, paymentTrackingReference: string, payorId: string, payorName: string, payorPaymentId: string, payout: record, postInstructFxInfo: record, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, remoteSystemId: string, remoteSystemPaymentId: string, returnCost: int, returnReason: string, routingNumber: string, schedule: record, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string, transmissionType: string, withdrawable: bool, withdrawnReason: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payeeId" $payee_id "scalar") (serialize-qp "payorId" $payor_id "scalar") (serialize-qp "payorName" $payor_name "scalar") (serialize-qp "remoteId" $remote_id "scalar") (serialize-qp "remoteSystemId" $remote_system_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "transmissionType" $transmission_type "scalar") (serialize-qp "sourceAccountName" $source_account_name "scalar") (serialize-qp "sourceAmountFrom" $source_amount_from "scalar") (serialize-qp "sourceAmountTo" $source_amount_to "scalar") (serialize-qp "sourceCurrency" $source_currency "scalar") (serialize-qp "paymentAmountFrom" $payment_amount_from "scalar") (serialize-qp "paymentAmountTo" $payment_amount_to "scalar") (serialize-qp "paymentCurrency" $payment_currency "scalar") (serialize-qp "submittedDateFrom" $submitted_date_from "scalar") (serialize-qp "submittedDateTo" $submitted_date_to "scalar") (serialize-qp "paymentMemo" $payment_memo "scalar") (serialize-qp "railsId" $rails_id "scalar") (serialize-qp "scheduledForDateFrom" $scheduled_for_date_from "scalar") (serialize-qp "scheduledForDateTo" $scheduled_for_date_to "scalar") (serialize-qp "scheduleStatus" $schedule_status "scalar") (serialize-qp "postInstructFxStatus" $post_instruct_fx_status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sensitive" $sensitive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/paymentaudit/payments" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"payeeId": $payee_id, "payorId": $payor_id, "payorName": $payor_name, "remoteId": $remote_id, "remoteSystemId": $remote_system_id, "status": $status, "transmissionType": $transmission_type, "sourceAccountName": $source_account_name, "sourceAmountFrom": $source_amount_from, "sourceAmountTo": $source_amount_to, "sourceCurrency": $source_currency, "paymentAmountFrom": $payment_amount_from, "paymentAmountTo": $payment_amount_to, "paymentCurrency": $payment_currency, "submittedDateFrom": $submitted_date_from, "submittedDateTo": $submitted_date_to, "paymentMemo": $payment_memo, "railsId": $rails_id, "scheduledForDateFrom": $scheduled_for_date_from, "scheduledForDateTo": $scheduled_for_date_to, "scheduleStatus": $schedule_status, "postInstructFxStatus": $post_instruct_fx_status, "page": $page, "pageSize": $page_size, "sort": $qp_sort, "sensitive": $sensitive} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Payment
#
# GET /v4/paymentaudit/payments/{paymentId}
# operationId: getPaymentDetailsV4
export def "paymentaudit-payments get-details-by-payment-id-1" [
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
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> record<accountName: string, accountNumber: string, autoWithdrawnReasonCode: string, countryCode: string, events: table<accountName: string, accountNumber: string, eventDateTime: string, eventId: string, eventType: string, iban: string, paymentAmount: int, paymentCurrency: string, principal: string, routingNumber: string, scheduledAt: string, scheduledBy: string, scheduledFor: string, sourceAmount: int, sourceCurrency: string>, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, isPaymentCcyBaseCcy: bool, payeeAddressCountryCode: string, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentMetadata: string, paymentScheme: string, paymentTrackingReference: string, payorId: string, payorName: string, payorPaymentId: string, payout: record<payoutFrom: record<dbaName: string, payorId: string, payorName: string, principal: string, principalId: string>, payoutId: string, payoutTo: record<dbaName: string, payorId: string, payorName: string, principal: string, principalId: string>>, postInstructFxInfo: record<fxMode: string, fxStatus: string, fxStatusUpdatedAt: string, fxTransactionReference: string>, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, remoteSystemId: string, remoteSystemPaymentId: string, returnCost: int, returnReason: string, routingNumber: string, schedule: record<notificationsEnabled: bool, scheduleStatus: string, scheduledAt: string, scheduledBy: string, scheduledByPrincipalId: string, scheduledFor: string>, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string, transmissionType: string, withdrawable: bool, withdrawnReason: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let qp = [(serialize-qp "sensitive" $sensitive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({payment_id: (encode-path-segment $payment_id)} | format pattern "/v4/paymentaudit/payments/{payment_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sensitive": $sensitive} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Payout Statistics
#
# GET /v4/paymentaudit/payoutStatistics
# operationId: getPayoutStatsV4
export def "paymentaudit-payout-statistics get-stats-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The account owner Payor ID. Required for external users. (format: uuid)
]: nothing -> record<thisMonthFailedPaymentsCount: int, thisMonthPayoutsCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payor_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/paymentaudit/payoutStatistics" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"payorId": $payor_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Payouts for Payor
#
# GET /v4/paymentaudit/payouts
# operationId: getPayoutsForPayorV4
export def "paymentaudit-payouts get-for-payor-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The id (UUID) of the payor funding the payout or the payor whose payees are being paid. (format: uuid)
  --payout-memo: string # Payout Memo filter - case insensitive sub-string match
  --status: string@status-completer-2 # Payout Status
  --submitted-date-from: string # The submitted date from range filter. Format is yyyy-MM-dd. (format: date)
  --submitted-date-to: string # The submitted date to range filter. Format is yyyy-MM-dd. (format: date)
  --from-payor-name: string # The name of the payor whose payees are being paid. This filters via a case insensitive substring match.
  --scheduled-for-date-from: string # Filter payouts scheduled to run on or after the given date. Format is yyyy-MM-dd. (format: date)
  --scheduled-for-date-to: string # Filter payouts scheduled to run on or before the given date. Format is yyyy-MM-dd. (format: date)
  --schedule-status: string@schedule-status-completer # Payout Schedule Status
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields (e.g. ?sort=submittedDateTime:asc,instructedDateTime:asc,status:asc) Default is submittedDateTime:asc The supported sort fields are: submittedDateTime, instructedDateTime, status, totalPayments, payoutId, scheduledFor
]: nothing -> record<content: table<dateTime: string, fxSummaries: list, instructedDateTime: string, payorId: string, payorName: string, payoutId: string, payoutMemo: string, payoutType: string, schedule: record, sourceAccountSummary: list, status: string, submittedDateTime: string, totalIncompletePayments: int, totalPayments: int, totalReturnedPayments: int, totalWithdrawnPayments: int, withdrawnDateTime: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payor_id "scalar") (serialize-qp "payoutMemo" $payout_memo "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "submittedDateFrom" $submitted_date_from "scalar") (serialize-qp "submittedDateTo" $submitted_date_to "scalar") (serialize-qp "fromPayorName" $from_payor_name "scalar") (serialize-qp "scheduledForDateFrom" $scheduled_for_date_from "scalar") (serialize-qp "scheduledForDateTo" $scheduled_for_date_to "scalar") (serialize-qp "scheduleStatus" $schedule_status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/paymentaudit/payouts" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"payorId": $payor_id, "payoutMemo": $payout_memo, "status": $status, "submittedDateFrom": $submitted_date_from, "submittedDateTo": $submitted_date_to, "fromPayorName": $from_payor_name, "scheduledForDateFrom": $scheduled_for_date_from, "scheduledForDateTo": $scheduled_for_date_to, "scheduleStatus": $schedule_status, "page": $page, "pageSize": $page_size, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Payments for Payout
#
# GET /v4/paymentaudit/payouts/{payoutId}
# operationId: getPaymentsForPayoutV4
export def "paymentaudit-payouts get-payments" [
  payout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --remote-id: string # The remote id of the payees.
  --remote-system-id: string # The id of the remote system that is orchestrating payments
  --status: string@status-completer-1 # Payment Status
  --source-amount-from: int # The source amount from range filter. Filters for sourceAmount >= sourceAmountFrom (format: int32)
  --source-amount-to: int # The source amount to range filter. Filters for sourceAmount ⇐ sourceAmountTo (format: int32)
  --payment-amount-from: int # The payment amount from range filter. Filters for paymentAmount >= paymentAmountFrom (format: int32)
  --payment-amount-to: int # The payment amount to range filter. Filters for paymentAmount ⇐ paymentAmountTo (format: int32)
  --submitted-date-from: string # The submitted date from range filter. Format is yyyy-MM-dd. (format: date)
  --submitted-date-to: string # The submitted date to range filter. Format is yyyy-MM-dd. (format: date)
  --transmission-type: string@transmission-type-completer-1 # Transmission Type * ACH * SAME_DAY_ACH * WIRE * GACHO
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 25)
  --qp-sort: string # List of sort fields (e.g. ?sort=submittedDateTime:asc,status:asc). Default is sort by remoteId The supported sort fields are: sourceAmount, sourceCurrency, paymentAmount, paymentCurrency, routingNumber, accountNumber, remoteId, submittedDateTime and status
  --sensitive: oneof<nothing, bool> # Optional. If omitted or set to false, any Personal Identifiable Information (PII) values are returned masked. If set to true, and you have permission, the PII values will be returned as their original unmasked values.
]: nothing -> record<content: table<accountName: string, accountNumber: string, autoWithdrawnReasonCode: string, countryCode: string, events: list, filenameReference: string, fundingStatus: string, iban: string, individualIdentificationNumber: string, invertedRate: float, isPaymentCcyBaseCcy: bool, payeeAddressCountryCode: string, payeeId: string, paymentAmount: int, paymentChannelId: string, paymentChannelName: string, paymentCurrency: string, paymentId: string, paymentMemo: string, paymentMetadata: string, paymentScheme: string, paymentTrackingReference: string, payorId: string, payorName: string, payorPaymentId: string, payout: record, postInstructFxInfo: record, quoteId: string, railsBatchId: string, railsId: string, railsPaymentId: string, rate: float, rejectionReason: string, remoteId: string, remoteSystemId: string, remoteSystemPaymentId: string, returnCost: int, returnReason: string, routingNumber: string, schedule: record, sourceAccountId: string, sourceAccountName: string, sourceAmount: int, sourceCurrency: string, status: string, submittedDateTime: string, traceNumber: string, transmissionType: string, withdrawable: bool, withdrawnReason: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>, summary: record<confirmedPayments: int, incompletePayments: int, instructed: record<principal: string, principalId: string>, instructedDateTime: string, payoutFrom: record<dbaName: string, payorId: string, payorName: string, principal: string, principalId: string>, payoutMemo: string, payoutStatus: string, payoutTo: record<dbaName: string, payorId: string, payorName: string, principal: string, principalId: string>, payoutType: string, quoted: record<principal: string, principalId: string>, quotedDateTime: string, releasedPayments: int, returnedPayments: int, schedule: record<notificationsEnabled: bool, scheduleStatus: string, scheduledAt: string, scheduledBy: string, scheduledByPrincipalId: string, scheduledFor: string>, submittedDateTime: string, submitting: record<dbaName: string, payorId: string, payorName: string, principal: string, principalId: string>, totalPayments: int, withdrawn: record<principal: string, principalId: string>, withdrawnDateTime: string, withdrawnPayments: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($payout_id | is-empty) { error make --unspanned { msg: "path parameter 'payoutId' must be non-empty" } }
  let qp = [(serialize-qp "remoteId" $remote_id "scalar") (serialize-qp "remoteSystemId" $remote_system_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sourceAmountFrom" $source_amount_from "scalar") (serialize-qp "sourceAmountTo" $source_amount_to "scalar") (serialize-qp "paymentAmountFrom" $payment_amount_from "scalar") (serialize-qp "paymentAmountTo" $payment_amount_to "scalar") (serialize-qp "submittedDateFrom" $submitted_date_from "scalar") (serialize-qp "submittedDateTo" $submitted_date_to "scalar") (serialize-qp "transmissionType" $transmission_type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sensitive" $sensitive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({payout_id: (encode-path-segment $payout_id)} | format pattern "/v4/paymentaudit/payouts/{payout_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"remoteId": $remote_id, "remoteSystemId": $remote_system_id, "status": $status, "sourceAmountFrom": $source_amount_from, "sourceAmountTo": $source_amount_to, "paymentAmountFrom": $payment_amount_from, "paymentAmountTo": $payment_amount_to, "submittedDateFrom": $submitted_date_from, "submittedDateTo": $submitted_date_to, "transmissionType": $transmission_type, "page": $page, "pageSize": $page_size, "sort": $qp_sort, "sensitive": $sensitive} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Export Transactions
#
# GET /v4/paymentaudit/transactions
# operationId: exportTransactionsCSVV4
export def "paymentaudit-transactions export-csvv4" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The Payor ID for whom you wish to run the report. For a Payor requesting the report, this could be their exact Payor, or it could be a child/descendant Payor. (format: uuid)
  --start-date: string # Start date, inclusive. Format is YYYY-MM-DD (format: date)
  --end-date: string # End date, inclusive. Format is YYYY-MM-DD (format: date)
  --include: string@include-completer # Mode to determine whether to include other Payor's data in the results. May only be used if payorId is specified. Can be omitted or set to 'payorOnly' or 'payorAndDescendants'. payorOnly: Only include results for the specified Payor. This is the default if 'include' is omitted. payorAndDescendants: Aggregate results for all descendant Payors of the specified Payor. Should only be used if the Payor with the specified payorId has at least one child Payor. Note when a Payor requests the report and include=payorAndDescendants is used, the following additional columns are included in the CSV: Payor Name, Payor Id
]: nothing -> record<credit: int, creditCurrency: string, dateFundingRequested: string, debit: int, debitCurrency: string, fundingType: string, fxApplied: float, payeeEmail: string, payeeName: string, payeeType: string, paymentAmount: int, paymentCurrency: string, paymentMemo: string, paymentRails: string, paymentStatus: string, payorPaymentId: string, rejectReason: string, remoteId: string, reportTransactionType: string, returnCode: string, returnDescription: string, returnFee: string, returnFeeCurrency: string, returnFeeDescription: string, sourceAccount: string, transactionDate: string, transactionTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payor_id "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/paymentaudit/transactions" $qp $auth.query)
  let accept_val = "application/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"payorId": $payor_id, "startDate": $start_date, "endDate": $end_date, "include": $include} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List Payment Changes
#
# GET /v4/payments/deltas
# operationId: listPaymentChangesV4
export def "payments-deltas list-changes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payor-id: string # The Payor ID to find associated Payments (format: uuid)
  --updated-since: string # The updatedSince filter in the format YYYY-MM-DDThh:mm:ss+hh:mm (format: date-time)
  --page: int # Page number. Default is 1. (format: int32, default: 1)
  --page-size: int # The number of results to return in a page (format: int32, default: 100)
]: nothing -> record<content: table<paymentAmount: int, paymentCurrency: string, paymentId: string, payorPaymentId: string, payoutId: string, sourceAmount: int, sourceCurrency: string, status: string>, links: table<href: string, rel: string>, page: record<numberOfElements: int, page: int, pageSize: int, totalElements: int, totalPages: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payorId" $payor_id "scalar") (serialize-qp "updatedSince" $updated_since "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/payments/deltas" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"payorId": $payor_id, "updatedSince": $updated_since, "page": $page, "pageSize": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
