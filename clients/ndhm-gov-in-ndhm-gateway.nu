# Auto-generated client for Gateway v0.5
# Source: https://api.apis.guru/v2/specs/ndhm.gov.in/ndhm-gateway/0.5/openapi.json
# Auth: --token flag or $env.GATEWAY_TOKEN

const BASE_URL = "https://dev.ndhm.gov.in/gateway"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o GATEWAY_TOKEN | default "" }
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

def base-url-completer [] { ["https://dev.ndhm.gov.in/gateway" "https://your-hrp-server.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }
def status-completer [] { ["ACKNOWLEDGED" "ERRORED"] }
def grant-type-completer [] { ["client_credentials" "refresh_token"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v0-5-well-known-openid-configuration get" } } | get name | first)
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

# Get openid configuration
#
# GET /v0.5/.well-known/openid-configuration
export def "v0-5-well-known-openid-configuration get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<jwks_uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/.well-known/openid-configuration" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Discover patient's accounts
#
# POST /v0.5/care-contexts/discover
# --patient shape: {gender: "M"|"F"|"O"|"U", id: string, name: string, unverifiedIdentifiers?: list, verifiedIdentifiers: list, yearOfBirth: int}
export def "v0-5-care-contexts-discover create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-hip-id: string # Identifier of the health information provider to which the request was intended.
  patient: record # shape: {gender: "M"|"F"|"O"|"U", id: string, name: string, unverifiedIdentifiers?: list, verifiedIdentifiers: list, yearOfBirth: int}
  request_id: string # a nonce, unique for each HTTP request. (format: uuid, e.g. 499a5a4a-7dda-4f20-9b67-e24589627061)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
  transaction_id: string # correlation-Id for patient discovery and subsequent care context linkage (format: uuid)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/care-contexts/discover" $auth.query)
  let req_body = {"patient": $patient, "requestId": $request_id, "timestamp": $timestamp, "transactionId": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIP-ID": $x_hip_id} | compact
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

# Response to patient's account discovery request
#
# POST /v0.5/care-contexts/on-discover
# --error shape: {code?: "1000"|"10001", message?: string}
# --patient shape: {careContexts?: list, display: string, matchedBy?: list<string>, referenceNumber: string}
# --resp shape: {requestId: string}
export def "v0-5-care-contexts-on-discover create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  --body-error: record # shape: {code?: "1000"|"10001", message?: string}
  --patient: record # shape: {careContexts?: list, display: string, matchedBy?: list<string>, referenceNumber: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
  transaction_id: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/care-contexts/on-discover" $auth.query)
  let req_body = {"error": $body_error, "patient": $patient, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp, "transactionId": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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

# Get certs for JWT verification
#
# GET /v0.5/certs
export def "v0-5-certs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<keys: table<alg: string, e: string, kid: string, kty: string, n: string, use: string, x5c: list, x5t: string, x5t_S256: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/certs" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Create consent request
#
# POST /v0.5/consent-requests/init
# --consent shape: {careContexts?: list, hiTypes: list<string>, hip?: record, hiu: record, patient: record, permission: record, purpose: record, requester: record}
export def "v0-5-consent-requests-init create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  consent: record # shape: {careContexts?: list, hiTypes: list<string>, hip?: record, hiu: record, patient: record, permission: record, purpose: record, requester: record}
  request_id: string # a nonce, unique for each HTTP request. (format: uuid, e.g. 499a5a4a-7dda-4f20-9b67-e24589627061)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/consent-requests/init" $auth.query)
  let req_body = {"consent": $consent, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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

# Response to consent request
#
# POST /v0.5/consent-requests/on-init
# --consentRequest shape: {id: string}
# --error shape: {code?: "1000"|"10001", message?: string}
# --resp shape: {requestId: string}
export def "v0-5-consent-requests-on-init create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-hiu-id: string # Identifier of the health information user to which the request was intended.
  --consent-request: record # shape: {id: string}
  --body-error: record # shape: {code?: "1000"|"10001", message?: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/consent-requests/on-init" $auth.query)
  let req_body = {"consentRequest": $consent_request, "error": $body_error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIU-ID": $x_hiu_id} | compact
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

# Result of consent request status
#
# POST /v0.5/consent-requests/on-status
# --consentRequest shape: {consentArtefacts?: list, id: string, status: "GRANTED"|"EXPIRED"|"DENIED"|"REQUESTED"|"REVOKED"}
# --error shape: {code?: "1000"|"10001", message?: string}
# --resp shape: {requestId: string}
export def "v0-5-consent-requests-on-status create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-hiu-id: string # Identifier of the health information user to which the request was intended.
  --consent-request: record # shape: {consentArtefacts?: list, id: string, status: "GRANTED"|"EXPIRED"|"DENIED"|"REQUESTED"|"REVOKED"}
  --body-error: record # shape: {code?: "1000"|"10001", message?: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/consent-requests/on-status" $auth.query)
  let req_body = {"consentRequest": $consent_request, "error": $body_error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIU-ID": $x_hiu_id} | compact
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

# Get consent request status
#
# POST /v0.5/consent-requests/status
export def "v0-5-consent-requests-status create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  consent_request_id: string
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/consent-requests/status" $auth.query)
  let req_body = {"consentRequestId": $consent_request_id, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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

# Get consent artefact
#
# POST /v0.5/consents/fetch
export def "v0-5-consents-fetch create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  consent_id: string
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/consents/fetch" $auth.query)
  let req_body = {"consentId": $consent_id, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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

# Consent notification
#
# POST /v0.5/consents/hip/notify
# --notification shape: {consentDetail: record, consentId: string, signature: string, status: "GRANTED"|"EXPIRED"|"DENIED"|"REQUESTED"|"REVOKED"}
export def "v0-5-consents-hip-notify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-hip-id: string # Identifier of the health information provider to which the request was intended.
  notification: record # shape: {consentDetail: record, consentId: string, signature: string, status: "GRANTED"|"EXPIRED"|"DENIED"|"REQUESTED"|"REVOKED"}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/consents/hip/notify" $auth.query)
  let req_body = {"notification": $notification, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIP-ID": $x_hip_id} | compact
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

# Consent notification
#
# POST /v0.5/consents/hip/on-notify
# --acknowledgement shape: {consentId: string, status: "OK"|"UNKNOWN"}
# --error shape: {code?: "1000"|"10001", message?: string}
# --resp shape: {requestId: string}
export def "v0-5-consents-hip-on-notify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  --acknowledgement: record # shape: {consentId: string, status: "OK"|"UNKNOWN"}
  --body-error: record # shape: {code?: "1000"|"10001", message?: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/consents/hip/on-notify" $auth.query)
  let req_body = {"acknowledgement": $acknowledgement, "error": $body_error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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

# Consent notification
#
# POST /v0.5/consents/hiu/notify
# --notification shape: {consentArtefacts?: list, consentRequestId: string, status: "GRANTED"|"EXPIRED"|"DENIED"|"REQUESTED"|"REVOKED"}
export def "v0-5-consents-hiu-notify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-hiu-id: string # Identifier of the health information user to which the request was intended.
  notification: record # shape: {consentArtefacts?: list, consentRequestId: string, status: "GRANTED"|"EXPIRED"|"DENIED"|"REQUESTED"|"REVOKED"}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/consents/hiu/notify" $auth.query)
  let req_body = {"notification": $notification, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIU-ID": $x_hiu_id} | compact
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

# Consent notification
#
# POST /v0.5/consents/hiu/on-notify
# --acknowledgement item shape: {consentId: string, status: "OK"|"UNKNOWN"}
# --error shape: {code?: "1000"|"10001", message?: string}
# --resp shape: {requestId: string}
export def "v0-5-consents-hiu-on-notify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  --acknowledgement: list # item shape: {consentId: string, status: "OK"|"UNKNOWN"}
  --body-error: record # shape: {code?: "1000"|"10001", message?: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/consents/hiu/on-notify" $auth.query)
  let req_body = {"acknowledgement": $acknowledgement, "error": $body_error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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

# Result of fetch request for a consent artefact
#
# POST /v0.5/consents/on-fetch
# --consent shape: {consentDetail: record, signature: string, status: "GRANTED"|"EXPIRED"|"DENIED"|"REQUESTED"|"REVOKED"}
# --error shape: {code?: "1000"|"10001", message?: string}
# --resp shape: {requestId: string}
export def "v0-5-consents-on-fetch create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-hiu-id: string # Identifier of the health information user to which the request was intended.
  --consent: record # shape: {consentDetail: record, signature: string, status: "GRANTED"|"EXPIRED"|"DENIED"|"REQUESTED"|"REVOKED"}
  --body-error: record # shape: {code?: "1000"|"10001", message?: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/consents/on-fetch" $auth.query)
  let req_body = {"consent": $consent, "error": $body_error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIU-ID": $x_hiu_id} | compact
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

# Health information data request
#
# POST /v0.5/health-information/cm/on-request
# --error shape: {code?: "1000"|"10001", message?: string}
# --hiRequest shape: {sessionStatus: "REQUESTED"|"ACKNOWLEDGED", transactionId: string}
# --resp shape: {requestId: string}
export def "v0-5-health-information-cm-on-request create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-hiu-id: string # Identifier of the health information user to which the request was intended.
  --body-error: record # shape: {code?: "1000"|"10001", message?: string}
  --hi-request: record # shape: {sessionStatus: "REQUESTED"|"ACKNOWLEDGED", transactionId: string}
  request_id: string # format: uuid, e.g. a1s2c932-2f70-3ds3-a3b5-2sfd46b12a18d
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/health-information/cm/on-request" $auth.query)
  let req_body = {"error": $body_error, "hiRequest": $hi_request, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIU-ID": $x_hiu_id} | compact
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

# Health information data request
#
# POST /v0.5/health-information/cm/request
# --hiRequest shape: {consent: record, dataPushUrl: string, dateRange: record, keyMaterial: record}
export def "v0-5-health-information-cm-request create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  hi_request: record # shape: {consent: record, dataPushUrl: string, dateRange: record, keyMaterial: record}
  request_id: string # format: uuid, e.g. a1s2c932-2f70-3ds3-a3b5-2sfd46b12a18d
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/health-information/cm/request" $auth.query)
  let req_body = {"hiRequest": $hi_request, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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

# Health information data request
#
# POST /v0.5/health-information/hip/on-request
# --error shape: {code?: "1000"|"10001", message?: string}
# --hiRequest shape: {sessionStatus: "ACKNOWLEDGED", transactionId: string}
# --resp shape: {requestId: string}
export def "v0-5-health-information-hip-on-request create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  --body-error: record # shape: {code?: "1000"|"10001", message?: string}
  --hi-request: record # shape: {sessionStatus: "ACKNOWLEDGED", transactionId: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/health-information/hip/on-request" $auth.query)
  let req_body = {"error": $body_error, "hiRequest": $hi_request, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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

# Health information data request
#
# POST /v0.5/health-information/hip/request
# --hiRequest shape: {consent: record, dataPushUrl: string, dateRange: record, keyMaterial: record}
export def "v0-5-health-information-hip-request create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-hip-id: string # Identifier of the health information provider to which the request was intended.
  hi_request: record # shape: {consent: record, dataPushUrl: string, dateRange: record, keyMaterial: record}
  request_id: string # format: uuid, e.g. a1s2c932-2f70-3ds3-a3b5-2sfd46b12a18d
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
  transaction_id: string # format: uuid, e.g. a1s2c932-2f70-3ds3-a3b5-2sfd46b12a18d
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/health-information/hip/request" $auth.query)
  let req_body = {"hiRequest": $hi_request, "requestId": $request_id, "timestamp": $timestamp, "transactionId": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIP-ID": $x_hip_id} | compact
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

# Notifications corresponding to events during data flow
#
# POST /v0.5/health-information/notify
# --notification shape: {consentId: string, doneAt: string, notifier: record, statusNotification: record, transactionId: string}
export def "v0-5-health-information-notify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  notification: record # shape: {consentId: string, doneAt: string, notifier: record, statusNotification: record, transactionId: string}
  request_id: string # a nonce, unique for each HTTP request. (format: uuid, e.g. 499a5a4a-7dda-4f20-9b67-e24589627061)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/health-information/notify" $auth.query)
  let req_body = {"notification": $notification, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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

# Get consent request status
#
# GET /v0.5/heartbeat
export def "v0-5-heartbeat get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<error: record<code: int, message: string>, status: string, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/heartbeat" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get bridge service details/profile by the serviceId provided.
#
# GET /v0.5/hi-services/{service-id}
export def "v0-5-hi-services get" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --authorization: string # Access token which was issued after successful login with gateway auth server.
]: nothing -> record<active: bool, endpoints: table<address: string, connectionType: string, use: string>, id: string, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service-id' must be non-empty" } }
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/v0.5/hi-services/{service_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# API for HIP initiated care-context linking for patient
#
# POST /v0.5/links/link/add-contexts
# --link shape: {accessToken: string, patient: record}
export def "v0-5-links-link-add-contexts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  link: record # shape: {accessToken: string, patient: record}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/links/link/add-contexts" $auth.query)
  let req_body = {"link": $link, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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

# Token submission by Consent Manager for link confirmation
#
# POST /v0.5/links/link/confirm
# --confirmation shape: {linkRefNumber: string, token: string}
export def "v0-5-links-link-confirm create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-hip-id: string # Identifier of the health information provider to which the request was intended.
  confirmation: record # shape: {linkRefNumber: string, token: string}
  request_id: string # format: uuid
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/links/link/confirm" $auth.query)
  let req_body = {"confirmation": $confirmation, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIP-ID": $x_hip_id} | compact
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

# Link patient's care contexts
#
# POST /v0.5/links/link/init
# --patient shape: {careContexts: list, id: string, referenceNumber: string}
export def "v0-5-links-link-init create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-hip-id: string # Identifier of the health information provider to which the request was intended.
  patient: record # shape: {careContexts: list, id: string, referenceNumber: string}
  request_id: string # format: uuid
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
  transaction_id: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/links/link/init" $auth.query)
  let req_body = {"patient": $patient, "requestId": $request_id, "timestamp": $timestamp, "transactionId": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIP-ID": $x_hip_id} | compact
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

# callback API for HIP initiated patient linking /link/add-context
#
# POST /v0.5/links/link/on-add-contexts
# --acknowledgement shape: {status: "SUCCESS"}
# --error shape: {code?: "1000"|"10001", message?: string}
# --resp shape: {requestId: string}
export def "v0-5-links-link-on-add-contexts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-hip-id: string # Identifier of the health information provider to which the request was intended.
  --acknowledgement: record # shape: {status: "SUCCESS"}
  --body-error: record # shape: {code?: "1000"|"10001", message?: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/links/link/on-add-contexts" $auth.query)
  let req_body = {"acknowledgement": $acknowledgement, "error": $body_error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIP-ID": $x_hip_id} | compact
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

# Token authenticated by HIP, indicating completion of linkage of care-contexts
#
# POST /v0.5/links/link/on-confirm
# --error shape: {code?: "1000"|"10001", message?: string}
# --patient shape: {careContexts: list, display: string, referenceNumber: string}
# --resp shape: {requestId: string}
export def "v0-5-links-link-on-confirm create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  --body-error: record # shape: {code?: "1000"|"10001", message?: string}
  --patient: record # shape: {careContexts: list, display: string, referenceNumber: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/links/link/on-confirm" $auth.query)
  let req_body = {"error": $body_error, "patient": $patient, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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

# Response to patient's care context link request
#
# POST /v0.5/links/link/on-init
# --error shape: {code?: "1000"|"10001", message?: string}
# --link shape: {authenticationType: "DIRECT"|"MEDIATED", meta?: record, referenceNumber: string}
# --resp shape: {requestId: string}
export def "v0-5-links-link-on-init create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  --body-error: record # shape: {code?: "1000"|"10001", message?: string}
  --link: record # shape: {authenticationType: "DIRECT"|"MEDIATED", meta?: record, referenceNumber: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
  transaction_id: string # format: uuid, e.g. a1s2c932-2f70-3ds3-a3b5-2sfd46b12a18d
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/links/link/on-init" $auth.query)
  let req_body = {"error": $body_error, "link": $link, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp, "transactionId": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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

# Identify a patient by her consent-manager user-id
#
# POST /v0.5/patients/find
# --query shape: {patient: record, requester: record}
export def "v0-5-patients-find create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  query: record # shape: {patient: record, requester: record}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/patients/find" $auth.query)
  let req_body = {"query": $query, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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

# Identification result for a consent-manager user-id
#
# POST /v0.5/patients/on-find
# --error shape: {code?: "1000"|"10001", message?: string}
# --patient shape: {id: string, name: string}
# --resp shape: {requestId: string}
export def "v0-5-patients-on-find create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --body-error: record # shape: {code?: "1000"|"10001", message?: string}
  --patient: record # shape: {id: string, name: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/patients/on-find" $auth.query)
  let req_body = {"error": $body_error, "patient": $patient, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Response to patient's share profile request
#
# POST /v0.5/patients/profile/on-share
# --acknowledgement shape: {healthId: string, status: "SUCCESS"|"FAILURE"}
# --error shape: {code?: "1000"|"10001", message?: string}
# --resp shape: {requestId: string}
export def "v0-5-patients-profile-on-share create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  acknowledgement: record # shape: {healthId: string, status: "SUCCESS"|"FAILURE"}
  --body-error: record # shape: {code?: "1000"|"10001", message?: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/patients/profile/on-share" $auth.query)
  let req_body = {"acknowledgement": $acknowledgement, "error": $body_error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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

# Share patient profile details
#
# POST /v0.5/patients/profile/share
# --patient shape: {hipCode?: string, userDemographics: record}
export def "v0-5-patients-profile-share create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-hip-id: string # Identifier of the health information provider to which the request was intended.
  patient: record # shape: {hipCode?: string, userDemographics: record}
  request_id: string # a nonce, unique for each HTTP request. (format: uuid, e.g. 499a5a4a-7dda-4f20-9b67-e24589627061)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://your-hrp-server.com")
  let full_url = (build-url $base "/v0.5/patients/profile/share" $auth.query)
  let req_body = {"patient": $patient, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIP-ID": $x_hip_id} | compact
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

# API for HIP to send SMS notifications to patients
#
# POST /v0.5/patients/sms/notify
# --notification shape: {careContextInfo: string, deeplinkUrl?: string, hip: record, phoneNo: string, receiverName?: string}
export def "v0-5-patients-sms-notify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  notification: record # shape: {careContextInfo: string, deeplinkUrl?: string, hip: record, phoneNo: string, receiverName?: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/patients/sms/notify" $auth.query)
  let req_body = {"notification": $notification, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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

# Acknowledgment response for SMS notification sent to patient by HIP
#
# POST /v0.5/patients/sms/on-notify
# --error shape: {code?: "1000"|"10001", message?: string}
# --resp shape: {requestId: string}
export def "v0-5-patients-sms-on-notify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-hip-id: string # Identifier of the health information provider to which the request was intended.
  --body-error: record # shape: {code?: "1000"|"10001", message?: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  --status: string@status-completer
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/patients/sms/on-notify" $auth.query)
  let req_body = {"error": $body_error, "requestId": $request_id, "resp": $resp, "status": $status, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIP-ID": $x_hip_id} | compact
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

# Get access token
#
# POST /v0.5/sessions
export def "v0-5-sessions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  client_id: string
  client_secret: string
  grant_type: string@grant-type-completer
  --refresh-token: string
]: any -> record<accessToken: string, expiresIn: int, refreshExpiresIn: int, refreshToken: string, tokenType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/sessions" $auth.query)
  let req_body = {"clientId": $client_id, "clientSecret": $client_secret, "grantType": $grant_type, "refreshToken": $refresh_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Request for subscription
#
# POST /v0.5/subscription-requests/cm/init
# --subscription shape: {categories: list<string>, hips?: list, hiu: record, patient: record, period: record, purpose: record}
export def "v0-5-subscription-requests-cm-init create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  request_id: string # a nonce, unique for each HTTP request. (format: uuid, e.g. 499a5a4a-7dda-4f20-9b67-e24589627061)
  subscription: record # shape: {categories: list<string>, hips?: list, hiu: record, patient: record, period: record, purpose: record}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/subscription-requests/cm/init" $auth.query)
  let req_body = {"requestId": $request_id, "subscription": $subscription, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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

# callback API for the /subscription-requests/cm/init to notify a HIU on acceptance/acknowledgement of the request for subscription.
#
# POST /v0.5/subscription-requests/cm/on-init
# --error shape: {code?: "1000"|"10001", message?: string}
# --resp shape: {requestId: string}
# --subscriptionRequest shape: {id: string}
export def "v0-5-subscription-requests-cm-on-init create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-hiu-id: string # Identifier of the health information user to which the request was intended.
  --body-error: record # shape: {code?: "1000"|"10001", message?: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  --subscription-request: record # shape: {id: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/subscription-requests/cm/on-init" $auth.query)
  let req_body = {"error": $body_error, "requestId": $request_id, "resp": $resp, "subscriptionRequest": $subscription_request, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIU-ID": $x_hiu_id} | compact
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

# Notification for subscription grant/deny/revoke
#
# POST /v0.5/subscription-requests/hiu/notify
# --notification shape: {status: "GRANTED"|"DENIED", subscription?: record, subscriptionRequestId?: string}
export def "v0-5-subscription-requests-hiu-notify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-hiu-id: string # Identifier of the health information user to which the request was intended.
  notification: record # shape: {status: "GRANTED"|"DENIED", subscription?: record, subscriptionRequestId?: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/subscription-requests/hiu/notify" $auth.query)
  let req_body = {"notification": $notification, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIU-ID": $x_hiu_id} | compact
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

# Callback API for /subscription-requests/hiu/notify to acknowledge receipt of notification.
#
# POST /v0.5/subscription-requests/hiu/on-notify
# --acknowledgement shape: {status: "OK", subscriptionRequestId: string}
# --error shape: {code?: "1000"|"10001", message?: string}
# --resp shape: {requestId: string}
export def "v0-5-subscription-requests-hiu-on-notify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  --acknowledgement: record # shape: {status: "OK", subscriptionRequestId: string}
  --body-error: record # shape: {code?: "1000"|"10001", message?: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/subscription-requests/hiu/on-notify" $auth.query)
  let req_body = {"acknowledgement": $acknowledgement, "error": $body_error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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

# Notification to HIU on basis of a granted subscription
#
# POST /v0.5/subscriptions/hiu/notify
# --event shape: {category: "LINK", content: record, id: string, published: string, subscriptionId: string}
export def "v0-5-subscriptions-hiu-notify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-hiu-id: string # Identifier of the health information user to which the request was intended.
  event: record # shape: {category: "LINK", content: record, id: string, published: string, subscriptionId: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/subscriptions/hiu/notify" $auth.query)
  let req_body = {"event": $event, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIU-ID": $x_hiu_id} | compact
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

# Callback API for /subscriptions/hiu/notify to acknowledge receipt of notification.
#
# POST /v0.5/subscriptions/hiu/on-notify
# --acknowledgement shape: {eventId: string, status: "OK"}
# --error shape: {code?: "1000"|"10001", message?: string}
# --resp shape: {requestId: string}
export def "v0-5-subscriptions-hiu-on-notify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  --acknowledgement: record # shape: {eventId: string, status: "OK"}
  --body-error: record # shape: {code?: "1000"|"10001", message?: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/subscriptions/hiu/on-notify" $auth.query)
  let req_body = {"acknowledgement": $acknowledgement, "error": $body_error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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

# Confirmation request sending token, otp or other authentication details from HIP/HIU for confirmation
#
# POST /v0.5/users/auth/confirm
# --credential shape: {authCode?: string, demographic?: record}
export def "v0-5-users-auth-confirm create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  credential: record # note, demographic details are only required for demographic auth at this point. — shape: {authCode?: string, demographic?: record}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
  transaction_id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/users/auth/confirm" $auth.query)
  let req_body = {"credential": $credential, "requestId": $request_id, "timestamp": $timestamp, "transactionId": $transaction_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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

# Get a patient's authentication modes relevant to specified purpose
#
# POST /v0.5/users/auth/fetch-modes
# --query shape: {id: string, purpose: "LINK"|"KYC"|"KYC_AND_LINK", requester: record}
export def "v0-5-users-auth-fetch-modes create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  query: record # shape: {id: string, purpose: "LINK"|"KYC"|"KYC_AND_LINK", requester: record}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/users/auth/fetch-modes" $auth.query)
  let req_body = {"query": $query, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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

# Initialize authentication from HIP
#
# POST /v0.5/users/auth/init
# --query shape: {authMode?: "MOBILE_OTP"|"DIRECT"|"DEMOGRAPHICS"|"AADHAAR_OTP", id: string, purpose: "LINK"|"KYC"|"KYC_AND_LINK", requester: record}
export def "v0-5-users-auth-init create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  query: record # shape: {authMode?: "MOBILE_OTP"|"DIRECT"|"DEMOGRAPHICS"|"AADHAAR_OTP", id: string, purpose: "LINK"|"KYC"|"KYC_AND_LINK", requester: record}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/users/auth/init" $auth.query)
  let req_body = {"query": $query, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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

# notification API in case of DIRECT mode of authentication by the CM
#
# POST /v0.5/users/auth/notify
# --auth shape: {accessToken?: string, patient?: record, status: "GRANTED"|"DENIED", transactionId: string, validity?: record}
export def "v0-5-users-auth-notify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-hip-id: string # Identifier of the health information provider to which the request was intended.
  --x-hiu-id: string # Identifier of the health information user to which the request was intended.
  --body-auth: record # depending on the purpose of auth, as specified in /auth/init, the response may include the following 1. LINK - only returns **accessToken** 2. KYC - only returns **patient** 3. KYC_AND_LINK - returns both **accessToken** and **patient** — shape: {accessToken?: string, patient?: record, status: "GRANTED"|"DENIED", transactionId: string, validity?: record}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/users/auth/notify" $auth.query)
  let req_body = {"auth": $body_auth, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIP-ID": $x_hip_id, "X-HIU-ID": $x_hiu_id} | compact
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

# callback API for /auth/confirm (in case of MEDIATED auth) to confirm user authentication or not
#
# POST /v0.5/users/auth/on-confirm
# --auth shape: {accessToken?: string, patient?: record, validity?: record}
# --error shape: {code?: "1000"|"10001", message?: string}
# --resp shape: {requestId: string}
export def "v0-5-users-auth-on-confirm create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-hip-id: string # Identifier of the health information provider to which the request was intended.
  --x-hiu-id: string # Identifier of the health information user to which the request was intended.
  --body-auth: record # depending on the purpose of auth, as specified in /auth/init, the response may include the following 1. LINK - only returns **accessToken** 2. KYC - only returns **patient** 3. KYC_AND_LINK - returns both **accessToken** and **patient** — shape: {accessToken?: string, patient?: record, validity?: record}
  --body-error: record # shape: {code?: "1000"|"10001", message?: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/users/auth/on-confirm" $auth.query)
  let req_body = {"auth": $body_auth, "error": $body_error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIP-ID": $x_hip_id, "X-HIU-ID": $x_hiu_id} | compact
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

# Identification result for a consent-manager user-id
#
# POST /v0.5/users/auth/on-fetch-modes
# --auth shape: {modes: list<string>, purpose: "LINK"|"KYC"|"KYC_AND_LINK"}
# --error shape: {code?: "1000"|"10001", message?: string}
# --resp shape: {requestId: string}
export def "v0-5-users-auth-on-fetch-modes create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-hip-id: string # Identifier of the health information provider to which the request was intended.
  --x-hiu-id: string # Identifier of the health information user to which the request was intended.
  --body-auth: record # shape: {modes: list<string>, purpose: "LINK"|"KYC"|"KYC_AND_LINK"}
  --body-error: record # shape: {code?: "1000"|"10001", message?: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/users/auth/on-fetch-modes" $auth.query)
  let req_body = {"auth": $body_auth, "error": $body_error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIP-ID": $x_hip_id, "X-HIU-ID": $x_hiu_id} | compact
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

# Response to user authentication initialization from HIP
#
# POST /v0.5/users/auth/on-init
# --auth shape: {meta?: record, mode: "MOBILE_OTP"|"DIRECT"|"DEMOGRAPHICS"|"AADHAAR_OTP", transactionId: string}
# --error shape: {code?: "1000"|"10001", message?: string}
# --resp shape: {requestId: string}
export def "v0-5-users-auth-on-init create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-hip-id: string # Identifier of the health information provider to which the request was intended.
  --x-hiu-id: string # Identifier of the health information user to which the request was intended.
  --body-auth: record # shape: {meta?: record, mode: "MOBILE_OTP"|"DIRECT"|"DEMOGRAPHICS"|"AADHAAR_OTP", transactionId: string}
  --body-error: record # shape: {code?: "1000"|"10001", message?: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/users/auth/on-init" $auth.query)
  let req_body = {"auth": $body_auth, "error": $body_error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIP-ID": $x_hip_id, "X-HIU-ID": $x_hiu_id} | compact
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

# callback API by HIU/HIPs as acknowledgement of auth notification
#
# POST /v0.5/users/auth/on-notify
# --acknowledgement shape: {status: "OK"}
# --error shape: {code?: "1000"|"10001", message?: string}
# --resp shape: {requestId: string}
export def "v0-5-users-auth-on-notify create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server.
  --x-cm-id: string # Suffix of the consent manager to which the request was intended.
  --acknowledgement: record # shape: {status: "OK"}
  --body-error: record # shape: {code?: "1000"|"10001", message?: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/users/auth/on-notify" $auth.query)
  let req_body = {"acknowledgement": $acknowledgement, "error": $body_error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
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
