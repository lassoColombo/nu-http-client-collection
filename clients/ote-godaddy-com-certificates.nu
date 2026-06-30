# Auto-generated client for  v1.0.0
# Source: https://api.apis.guru/v2/specs/ote-godaddy.com/certificates/1.0.0/openapi.json
# Auth: --token flag or $env._TOKEN

const BASE_URL = "http://localhost//api.ote-godaddy.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o _TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost//api.ote-godaddy.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def product-type-completer [] { ["DV_SSL" "DV_WILDCARD_SSL" "EV_SSL" "OV_CS" "OV_DS" "OV_SSL" "OV_WILDCARD_SSL" "UCC_DV_SSL" "UCC_EV_SSL" "UCC_OV_SSL"] }
def root-type-completer [] { ["GODADDY_SHA_1" "GODADDY_SHA_2" "STARFIELD_SHA_1" "STARFIELD_SHA_2"] }
def slot-size-completer [] { ["FIFTEEN" "FIFTY" "FIVE" "FOURTY" "ONE_HUNDRED" "TEN" "THIRTY" "TWENTY"] }
def reason-completer [] { ["AFFILIATION_CHANGED" "CESSATION_OF_OPERATION" "KEY_COMPROMISE" "PRIVILEGE_WITHDRAWN" "SUPERSEDED"] }
def theme-completer [] { ["DARK" "LIGHT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "certificates create" } } | get name | first)
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

# Create a pending order for certificate
#
# POST /v1/certificates
# operationId: certificate_create
# --contact shape: {email: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, phone: string, suffix?: string}
# --organization shape: {address?: any, assumedName?: string, name: string, phone: string, registrationAgent?: string, registrationNumber?: string}
export def "certificates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-market-id: string # Setting locale for communications such as emails and error messages
  --callback-url: string # Required if client would like to receive stateful actions via callback during certificate lifecyle
  --common-name: string # Name to be secured in certificate. If provided, CN field in CSR will be ignored.
  contact: any # shape: {email: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, phone: string, suffix?: string}
  csr: string # Certificate Signing Request
  --intel-v-pro: oneof<nothing, bool> # Only used for OV (default: false)
  --organization: any # shape: {address?: any, assumedName?: string, name: string, phone: string, registrationAgent?: string, registrationNumber?: string}
  period: int # Number of years for certificate validity period
  product_type: string@product-type-completer # Type of product requesting a certificate. Only required non-renewal
  --root-type: string@root-type-completer # Root Type. Depending on certificate expiration date, SHA_1 not be allowed. Will default to SHA_2 if expiration date exceeds sha1 allowed date (default: STARFIELD_SHA_2)
  --slot-size: string@slot-size-completer # Number of subject alternative names(SAN) to be included in certificate
  --subject-alternative-names: list<string> # Subject Alternative names. Collection of subjectAlternativeNames to be included in certificate.
]: any -> record<certificateId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/certificates" $auth.query)
  let req_body = {"callbackUrl": $callback_url, "commonName": $common_name, "contact": $contact, "csr": $csr, "intelVPro": $intel_v_pro, "organization": $organization, "period": $period, "productType": $product_type, "rootType": $root_type, "slotSize": $slot_size, "subjectAlternativeNames": $subject_alternative_names} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Market-Id": $x_market_id} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Validate a pending order for certificate
#
# POST /v1/certificates/validate
# operationId: certificate_validate
# --contact shape: {email: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, phone: string, suffix?: string}
# --organization shape: {address?: any, assumedName?: string, name: string, phone: string, registrationAgent?: string, registrationNumber?: string}
export def "certificates-validate validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-market-id: string # Setting locale for communications such as emails and error messages
  --callback-url: string # Required if client would like to receive stateful actions via callback during certificate lifecyle
  --common-name: string # Name to be secured in certificate. If provided, CN field in CSR will be ignored.
  contact: any # shape: {email: string, jobTitle?: string, nameFirst: string, nameLast: string, nameMiddle?: string, phone: string, suffix?: string}
  csr: string # Certificate Signing Request
  --intel-v-pro: oneof<nothing, bool> # Only used for OV (default: false)
  --organization: any # shape: {address?: any, assumedName?: string, name: string, phone: string, registrationAgent?: string, registrationNumber?: string}
  period: int # Number of years for certificate validity period
  product_type: string@product-type-completer # Type of product requesting a certificate. Only required non-renewal
  --root-type: string@root-type-completer # Root Type. Depending on certificate expiration date, SHA_1 not be allowed. Will default to SHA_2 if expiration date exceeds sha1 allowed date (default: STARFIELD_SHA_2)
  --slot-size: string@slot-size-completer # Number of subject alternative names(SAN) to be included in certificate
  --subject-alternative-names: list<string> # Subject Alternative names. Collection of subjectAlternativeNames to be included in certificate.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/certificates/validate" $auth.query)
  let req_body = {"callbackUrl": $callback_url, "commonName": $common_name, "contact": $contact, "csr": $csr, "intelVPro": $intel_v_pro, "organization": $organization, "period": $period, "productType": $product_type, "rootType": $root_type, "slotSize": $slot_size, "subjectAlternativeNames": $subject_alternative_names} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Market-Id": $x_market_id} | compact
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

# Retrieve certificate details
#
# GET /v1/certificates/{certificateId}
# operationId: certificate_get
export def "certificates get" [
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<certificateId: string, commonName: string, contact: record<email: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, phone: string, suffix: string>, createdAt: string, deniedReason: string, organization: record<address: record<address1: string, address2: string, city: string, country: string, postalCode: string, state: string>, assumedName: string, jurisdictionOfIncorporation: record<city: string, country: string, county: string, state: string>, name: string, phone: string, registrationAgent: string, registrationNumber: string>, period: int, productType: string, progress: int, revokedAt: string, rootType: string, serialNumber: string, serialNumberHex: string, slotSize: string, status: string, subjectAlternativeNames: table<status: string, subjectAlternativeName: string>, validEnd: string, validStart: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_id | is-empty) { error make --unspanned { msg: "path parameter 'certificateId' must be non-empty" } }
  let full_url = (build-url $base ({certificate_id: (encode-path-segment $certificate_id)} | format pattern "/v1/certificates/{certificate_id}") $auth.query)
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

# Retrieve all certificate actions
#
# GET /v1/certificates/{certificateId}/actions
# operationId: certificate_action_retrieve
export def "certificates-actions get" [
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<createdAt: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_id | is-empty) { error make --unspanned { msg: "path parameter 'certificateId' must be non-empty" } }
  let full_url = (build-url $base ({certificate_id: (encode-path-segment $certificate_id)} | format pattern "/v1/certificates/{certificate_id}/actions") $auth.query)
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

# Unregister system callback
#
# DELETE /v1/certificates/{certificateId}/callback
# operationId: certificate_callback_delete
export def "certificates-callback delete" [
  certificate_id: string
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
  if ($certificate_id | is-empty) { error make --unspanned { msg: "path parameter 'certificateId' must be non-empty" } }
  let full_url = (build-url $base ({certificate_id: (encode-path-segment $certificate_id)} | format pattern "/v1/certificates/{certificate_id}/callback") $auth.query)
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

# Retrieve system stateful action callback url
#
# GET /v1/certificates/{certificateId}/callback
# operationId: certificate_callback_get
export def "certificates-callback get" [
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<callbackUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_id | is-empty) { error make --unspanned { msg: "path parameter 'certificateId' must be non-empty" } }
  let full_url = (build-url $base ({certificate_id: (encode-path-segment $certificate_id)} | format pattern "/v1/certificates/{certificate_id}/callback") $auth.query)
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

# Register of certificate action callback
#
# PUT /v1/certificates/{certificateId}/callback
# operationId: certificate_callback_replace
export def "certificates-callback update" [
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-url: string # Callback url registered/replaced to receive stateful actions
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_id | is-empty) { error make --unspanned { msg: "path parameter 'certificateId' must be non-empty" } }
  let qp = [(serialize-qp "callbackUrl" $callback_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({certificate_id: (encode-path-segment $certificate_id)} | format pattern "/v1/certificates/{certificate_id}/callback") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"callbackUrl": $callback_url} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [204]
}

# Cancel a pending certificate
#
# POST /v1/certificates/{certificateId}/cancel
# operationId: certificate_cancel
export def "certificates-cancel cancel" [
  certificate_id: string
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
  if ($certificate_id | is-empty) { error make --unspanned { msg: "path parameter 'certificateId' must be non-empty" } }
  let full_url = (build-url $base ({certificate_id: (encode-path-segment $certificate_id)} | format pattern "/v1/certificates/{certificate_id}/cancel") $auth.query)
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

# Download certificate
#
# GET /v1/certificates/{certificateId}/download
# operationId: certificate_download
export def "certificates-download download" [
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<pems: record<certificate: string, cross: string, intermediate: string, root: string>, serialNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_id | is-empty) { error make --unspanned { msg: "path parameter 'certificateId' must be non-empty" } }
  let full_url = (build-url $base ({certificate_id: (encode-path-segment $certificate_id)} | format pattern "/v1/certificates/{certificate_id}/download") $auth.query)
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

# Retrieve email history
#
# GET /v1/certificates/{certificateId}/email/history
# operationId: certificate_email_history
export def "certificates-email-history get" [
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accountId: int, body: string, dateEntered: string, fromType: string, id: int, recipients: string, subject: string, templateType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_id | is-empty) { error make --unspanned { msg: "path parameter 'certificateId' must be non-empty" } }
  let full_url = (build-url $base ({certificate_id: (encode-path-segment $certificate_id)} | format pattern "/v1/certificates/{certificate_id}/email/history") $auth.query)
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

# Add alternate email address
#
# POST /v1/certificates/{certificateId}/email/resend/{emailAddress}
# operationId: certificate_alternate_email_address
export def "certificates-email-resend create-alternate-address" [
  certificate_id: string
  email_address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accountId: int, body: string, dateEntered: string, fromType: string, id: int, recipients: string, subject: string, templateType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_id | is-empty) { error make --unspanned { msg: "path parameter 'certificateId' must be non-empty" } }
  if ($email_address | is-empty) { error make --unspanned { msg: "path parameter 'emailAddress' must be non-empty" } }
  let full_url = (build-url $base ({certificate_id: (encode-path-segment $certificate_id), email_address: (encode-path-segment $email_address)} | format pattern "/v1/certificates/{certificate_id}/email/resend/{email_address}") $auth.query)
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

# Resend an email
#
# POST /v1/certificates/{certificateId}/email/{emailId}/resend
# operationId: certificate_resend_email
export def "certificates-email-resend resend" [
  certificate_id: string
  email_id: string
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
  if ($certificate_id | is-empty) { error make --unspanned { msg: "path parameter 'certificateId' must be non-empty" } }
  if ($email_id | is-empty) { error make --unspanned { msg: "path parameter 'emailId' must be non-empty" } }
  let full_url = (build-url $base ({certificate_id: (encode-path-segment $certificate_id), email_id: (encode-path-segment $email_id)} | format pattern "/v1/certificates/{certificate_id}/email/{email_id}/resend") $auth.query)
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

# Resend email to email address
#
# POST /v1/certificates/{certificateId}/email/{emailId}/resend/{emailAddress}
# operationId: certificate_resend_email_address
export def "certificates-email-resend resend-address" [
  certificate_id: string
  email_id: string
  email_address: string
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
  if ($certificate_id | is-empty) { error make --unspanned { msg: "path parameter 'certificateId' must be non-empty" } }
  if ($email_id | is-empty) { error make --unspanned { msg: "path parameter 'emailId' must be non-empty" } }
  if ($email_address | is-empty) { error make --unspanned { msg: "path parameter 'emailAddress' must be non-empty" } }
  let full_url = (build-url $base ({certificate_id: (encode-path-segment $certificate_id), email_id: (encode-path-segment $email_id), email_address: (encode-path-segment $email_address)} | format pattern "/v1/certificates/{certificate_id}/email/{email_id}/resend/{email_address}") $auth.query)
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

# Reissue active certificate
#
# POST /v1/certificates/{certificateId}/reissue
# operationId: certificate_reissue
export def "certificates-reissue create" [
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-url: string # Required if client would like to receive stateful action via callback during certificate lifecyle
  --common-name: string # The common name of certificate to be secured (default: Existing common name)
  --csr: string # Certificate Signing Request. (default: Existing CSR)
  --delay-existing-revoke: int # In hours, time to delay revoking existing certificate after issuance of new certificate. If revokeExistingCertOnIssuance is enabled, this value will be ignored (default: 72)
  --force-domain-revetting: list<string> # Optional field. Domain verification will be required for each domain listed here. Specify a value of * to indicate that all domains associated with the request should have their domain information reverified.
  --root-type: string@root-type-completer # Root Type. Depending on certificate expiration date, SHA_1 not be allowed. Will default to SHA_2 if expiration date exceeds sha1 allowed date (default: GODADDY_SHA_1)
  --subject-alternative-names: list<string> # Only used for UCC products. An array of subject alternative names to include in certificate.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_id | is-empty) { error make --unspanned { msg: "path parameter 'certificateId' must be non-empty" } }
  let full_url = (build-url $base ({certificate_id: (encode-path-segment $certificate_id)} | format pattern "/v1/certificates/{certificate_id}/reissue") $auth.query)
  let req_body = {"callbackUrl": $callback_url, "commonName": $common_name, "csr": $csr, "delayExistingRevoke": $delay_existing_revoke, "forceDomainRevetting": $force_domain_revetting, "rootType": $root_type, "subjectAlternativeNames": $subject_alternative_names} | compact
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

# Renew active certificate
#
# POST /v1/certificates/{certificateId}/renew
# operationId: certificate_renew
export def "certificates-renew create" [
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-url: string # Required if client would like to receive stateful actions via callback during certificate lifecyle
  --common-name: string # The common name of certificate to be secured (default: Existing common name)
  --csr: string # Certificate Signing Request. (default: Existing CSR)
  --period: int # Number of years for certificate validity period, if different from previous certificate (default: 0)
  --root-type: string@root-type-completer # Root Type. Depending on certificate expiration date, SHA_1 not be allowed. Will default to SHA_2 if expiration date exceeds sha1 allowed date (default: GODADDY_SHA_1)
  --subject-alternative-names: list<string> # Only used for UCC products. An array of subject alternative names to include in certificate. Not including a subject alternative name that was in the previous certificate will remove it from the renewed certificate.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_id | is-empty) { error make --unspanned { msg: "path parameter 'certificateId' must be non-empty" } }
  let full_url = (build-url $base ({certificate_id: (encode-path-segment $certificate_id)} | format pattern "/v1/certificates/{certificate_id}/renew") $auth.query)
  let req_body = {"callbackUrl": $callback_url, "commonName": $common_name, "csr": $csr, "period": $period, "rootType": $root_type, "subjectAlternativeNames": $subject_alternative_names} | compact
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

# Revoke active certificate
#
# POST /v1/certificates/{certificateId}/revoke
# operationId: certificate_revoke
export def "certificates-revoke delete" [
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  reason: string@reason-completer # Reason for revocation
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_id | is-empty) { error make --unspanned { msg: "path parameter 'certificateId' must be non-empty" } }
  let full_url = (build-url $base ({certificate_id: (encode-path-segment $certificate_id)} | format pattern "/v1/certificates/{certificate_id}/revoke") $auth.query)
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

# Get Site seal
#
# GET /v1/certificates/{certificateId}/siteSeal
# operationId: certificate_siteseal_get
export def "certificates-site-seal get-siteseal" [
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --theme: string@theme-completer # This value represents the visual theme of the seal. If seal doesn't exist, default values are used if params not present. If seal does exist, default values will not be used to update unless params present. (default: LIGHT)
  --locale: string # Determine locale for text displayed in seal image and verification page. If seal doesn't exist, default values are used if params not present. If seal does exist, default values will not be used to update unless params present. (default: en)
]: nothing -> record<html: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($certificate_id | is-empty) { error make --unspanned { msg: "path parameter 'certificateId' must be non-empty" } }
  let qp = [(serialize-qp "theme" $theme "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({certificate_id: (encode-path-segment $certificate_id)} | format pattern "/v1/certificates/{certificate_id}/siteSeal") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"theme": $theme, "locale": $locale} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Check Domain Control
#
# POST /v1/certificates/{certificateId}/verifyDomainControl
# operationId: certificate_verifydomaincontrol
export def "certificates-verify-domain-control create-verifydomaincontrol" [
  certificate_id: string
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
  if ($certificate_id | is-empty) { error make --unspanned { msg: "path parameter 'certificateId' must be non-empty" } }
  let full_url = (build-url $base ({certificate_id: (encode-path-segment $certificate_id)} | format pattern "/v1/certificates/{certificate_id}/verifyDomainControl") $auth.query)
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

# Search for certificate details by entitlement
#
# GET /v2/certificates
# operationId: certificate_get_entitlement
export def "certificates get-entitlement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entitlement-id: string # Entitlement id to lookup
  --latest: oneof<nothing, bool> # Fetch only the most recent certificate (default: true)
]: nothing -> table<certificateId: string, commonName: string, contact: record<email: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, phone: string, suffix: string>, createdAt: string, deniedReason: string, organization: record<address: record, assumedName: string, jurisdictionOfIncorporation: record, name: string, phone: string, registrationAgent: string, registrationNumber: string>, period: int, productType: string, progress: int, revokedAt: string, rootType: string, serialNumber: string, serialNumberHex: string, slotSize: string, status: string, subjectAlternativeNames: list<record>, validEnd: string, validStart: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entitlementId" $entitlement_id "scalar") (serialize-qp "latest" $latest "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/certificates" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"entitlementId": $entitlement_id, "latest": $latest} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Download certificate by entitlement
#
# GET /v2/certificates/download
# operationId: certificate_download_entitlement
export def "certificates-download download-entitlement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entitlement-id: string # Entitlement id to download
]: nothing -> record<pems: record<certificate: string, cross: string, intermediate: string, root: string>, serialNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entitlementId" $entitlement_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/certificates/download" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"entitlementId": $entitlement_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve customer's certificates
#
# GET /v2/customers/{customerId}/certificates
# operationId: getCustomerCertificatesByCustomerId
export def "customers-certificates get" [
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
  --offset: int # Number of results to skip for pagination (format: integer-positive)
  --limit: int # Maximum number of items to return (format: integer-positive)
]: nothing -> record<certificates: table<certificateId: string, commonName: string, completedAt: string, createdAt: string, period: int, renewalAvailable: bool, revokedAt: string, serialNumber: string, slotSize: string, status: string, subjectAlternativeNames: list, type: string, validEndAt: string, validStartAt: string>, pagination: record<first: string, last: string, next: string, previous: string, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/v2/customers/{customer_id}/certificates") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieves the external account binding for the specified customer
#
# GET /v2/customers/{customerId}/certificates/acme/externalAccountBinding
# operationId: getAcmeExternalAccountBinding
export def "customers-certificates-acme-external-account-binding get" [
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
]: nothing -> record<directoryUrl: string, hmacKey: string, keyId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id)} | format pattern "/v2/customers/{customer_id}/certificates/acme/externalAccountBinding") $auth.query)
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

# Retrieve individual certificate details
#
# GET /v2/customers/{customerId}/certificates/{certificateId}
# operationId: getCertificateDetailByCertIdentifier
export def "customers-certificates get-detail-by-cert-identifier" [
  customer_id: string
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<certificateId: string, commonName: string, completedAt: string, contact: record<email: string, jobTitle: string, nameFirst: string, nameLast: string, nameMiddle: string, phone: string, suffix: string>, createdAt: string, csr: string, deniedReason: string, organization: record<address: record<address1: string, address2: string, city: string, country: string, postalCode: string, state: string>, assumedName: string, jurisdictionOfIncorporation: record<city: string, country: string, county: string, state: string>, name: string, phone: string, registrationAgent: string, registrationNumber: string>, period: int, progress: int, renewalAvailable: bool, revokedAt: string, rootType: string, serialNumber: string, serialNumberHex: string, slotSize: string, status: string, subjectAlternativeNames: list<string>, type: string, validEndAt: string, validStartAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($certificate_id | is-empty) { error make --unspanned { msg: "path parameter 'certificateId' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), certificate_id: (encode-path-segment $certificate_id)} | format pattern "/v2/customers/{customer_id}/certificates/{certificate_id}") $auth.query)
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

# Retrieve domain verification status
#
# GET /v2/customers/{customerId}/certificates/{certificateId}/domainVerifications
# operationId: getDomainInformationByCertificateId
export def "customers-certificates-domain-verifications get-information" [
  customer_id: string
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<createdAt: string, dceToken: string, domain: string, domainEntityId: int, modifiedAt: string, status: string, type: string, usage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($certificate_id | is-empty) { error make --unspanned { msg: "path parameter 'certificateId' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), certificate_id: (encode-path-segment $certificate_id)} | format pattern "/v2/customers/{customer_id}/certificates/{certificate_id}/domainVerifications") $auth.query)
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

# Retrieve detailed information for supplied domain
#
# GET /v2/customers/{customerId}/certificates/{certificateId}/domainVerifications/{domain}
# operationId: getDomainDetailsByDomain
export def "customers-certificates-domain-verifications get-details" [
  customer_id: string
  certificate_id: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdAt: string, dceToken: string, domain: string, domainEntityId: int, modifiedAt: string, status: string, type: string, usage: string, certificateAuthorityAuthorization: record<completedAt: string, queryPaths: list<string>, recommendations: list<string>, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($customer_id | is-empty) { error make --unspanned { msg: "path parameter 'customerId' must be non-empty" } }
  if ($certificate_id | is-empty) { error make --unspanned { msg: "path parameter 'certificateId' must be non-empty" } }
  if ($domain | is-empty) { error make --unspanned { msg: "path parameter 'domain' must be non-empty" } }
  let full_url = (build-url $base ({customer_id: (encode-path-segment $customer_id), certificate_id: (encode-path-segment $certificate_id), domain: (encode-path-segment $domain)} | format pattern "/v2/customers/{customer_id}/certificates/{certificate_id}/domainVerifications/{domain}") $auth.query)
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
