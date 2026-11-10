# Auto-generated client for Health Repository Provider Specifications for HIU v0.5
# Source: https://api.apis.guru/v2/specs/ndhm.gov.in/ndhm-hiu/0.5/openapi.json
# Auth: --token flag or $env.HEALTH_REPOSITORY_PROVIDER_SPECIFICATIONS_FOR_HIU_TOKEN

const BASE_URL = "https://dev.ndhm.gov.in/gateway"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o HEALTH_REPOSITORY_PROVIDER_SPECIFICATIONS_FOR_HIU_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["https://dev.ndhm.gov.in/gateway" "https://dev.ndhm.gov.in/hiu"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-v0-5-well-known-openid-configuration" "get-v0-5-certs" "post-v0-5-consent-requests-init" "post-v0-5-consent-requests-on-init" "post-v0-5-consent-requests-on-status" "post-v0-5-consent-requests-status" "post-v0-5-consents-fetch" "post-v0-5-consents-hiu-notify" "post-v0-5-consents-hiu-on-notify" "post-v0-5-consents-on-fetch" "post-v0-5-health-information-cm-request" "post-v0-5-health-information-hiu-on-request" "post-v0-5-health-information-notify" "post-v0-5-health-information-transfer" "get-v0-5-heartbeat" "post-v0-5-patients-find" "post-v0-5-patients-on-find" "post-v0-5-sessions" "post-v0-5-subscription-requests-cm-init" "post-v0-5-subscription-requests-hiu-notify" "post-v0-5-subscription-requests-hiu-on-init" "post-v0-5-subscription-requests-hiu-on-notify" "post-v0-5-subscriptions-hiu-notify" "post-v0-5-subscriptions-hiu-on-notify" "post-v0-5-users-auth-confirm" "post-v0-5-users-auth-fetch-modes" "post-v0-5-users-auth-init" "post-v0-5-users-auth-notify" "post-v0-5-users-auth-on-confirm" "post-v0-5-users-auth-on-fetch-modes" "post-v0-5-users-auth-on-init" "post-v0-5-users-auth-on-notify" "commands"] | sort) } | get name | first)
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

# Get openid configuration
#
# GET /v0.5/.well-known/openid-configuration
export def "get-v0-5-well-known-openid-configuration" [
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
]: nothing -> oneof<record<jwks_uri: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/.well-known/openid-configuration" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Get certs for JWT verification
#
# GET /v0.5/certs
export def "get-v0-5-certs" [
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
]: nothing -> oneof<record<keys: table<alg: string, e: string, kid: string, kty: string, n: string, use: string, x5c: list, x5t: string, x5t_S256: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/certs" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Create consent request
#
# POST /v0.5/consent-requests/init
export def "post-v0-5-consent-requests-init" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-cm-id: string # Suffix of the consent manager to which the request was intended. (required)
  consent: record # shape: {careContexts?: list, hiTypes: list<string>, hip?: record, hiu: record, patient: record, permission: record, purpose: record, requester: record}
  request_id: string # a nonce, unique for each HTTP request. (format: uuid, e.g. 499a5a4a-7dda-4f20-9b67-e24589627061)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_cm_id == null) { error make --unspanned { msg: "required header parameter 'X-CM-ID' missing: pass --x-cm-id" } }
  let full_url = (build-url $base "/v0.5/consent-requests/init" $auth.query)
  let req_body = {"consent": $consent, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-consent-requests-on-init" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-hiu-id: string # Identifier of the health information user to which the request was intended. (required)
  --consent-request: record # shape: {id: string}
  --error: record # shape: {code: "1000"|"10001", message: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://dev.ndhm.gov.in/hiu")
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_hiu_id == null) { error make --unspanned { msg: "required header parameter 'X-HIU-ID' missing: pass --x-hiu-id" } }
  let full_url = (build-url $base "/v0.5/consent-requests/on-init" $auth.query)
  let req_body = {"consentRequest": $consent_request, "error": $error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIU-ID": $x_hiu_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-consent-requests-on-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-hiu-id: string # Identifier of the health information user to which the request was intended. (required)
  --consent-request: record # shape: {consentArtefacts: list, id: string, status: "GRANTED"|"EXPIRED"|"DENIED"|"REQUESTED"|"REVOKED"}
  --error: record # shape: {code: "1000"|"10001", message: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://dev.ndhm.gov.in/hiu")
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_hiu_id == null) { error make --unspanned { msg: "required header parameter 'X-HIU-ID' missing: pass --x-hiu-id" } }
  let full_url = (build-url $base "/v0.5/consent-requests/on-status" $auth.query)
  let req_body = {"consentRequest": $consent_request, "error": $error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIU-ID": $x_hiu_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-consent-requests-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-cm-id: string # Suffix of the consent manager to which the request was intended. (required)
  consent_request_id: string
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_cm_id == null) { error make --unspanned { msg: "required header parameter 'X-CM-ID' missing: pass --x-cm-id" } }
  let full_url = (build-url $base "/v0.5/consent-requests/status" $auth.query)
  let req_body = {"consentRequestId": $consent_request_id, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-consents-fetch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-cm-id: string # Suffix of the consent manager to which the request was intended. (required)
  consent_id: string
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_cm_id == null) { error make --unspanned { msg: "required header parameter 'X-CM-ID' missing: pass --x-cm-id" } }
  let full_url = (build-url $base "/v0.5/consents/fetch" $auth.query)
  let req_body = {"consentId": $consent_id, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-consents-hiu-notify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-hiu-id: string # Identifier of the health information user to which the request was intended. (required)
  notification: record # shape: {consentArtefacts?: list, consentRequestId: string, status: "GRANTED"|"EXPIRED"|"DENIED"|"REQUESTED"|"REVOKED"}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://dev.ndhm.gov.in/hiu")
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_hiu_id == null) { error make --unspanned { msg: "required header parameter 'X-HIU-ID' missing: pass --x-hiu-id" } }
  let full_url = (build-url $base "/v0.5/consents/hiu/notify" $auth.query)
  let req_body = {"notification": $notification, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIU-ID": $x_hiu_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-consents-hiu-on-notify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-cm-id: string # Suffix of the consent manager to which the request was intended. (required)
  --acknowledgement: list # item shape: {consentId: string, status: "OK"|"UNKNOWN"}
  --error: record # shape: {code: "1000"|"10001", message: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_cm_id == null) { error make --unspanned { msg: "required header parameter 'X-CM-ID' missing: pass --x-cm-id" } }
  let full_url = (build-url $base "/v0.5/consents/hiu/on-notify" $auth.query)
  let req_body = {"acknowledgement": $acknowledgement, "error": $error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-consents-on-fetch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-hiu-id: string # Identifier of the health information user to which the request was intended. (required)
  --consent: record # shape: {consentDetail: record, signature: string, status: "GRANTED"|"EXPIRED"|"DENIED"|"REQUESTED"|"REVOKED"}
  --error: record # shape: {code: "1000"|"10001", message: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://dev.ndhm.gov.in/hiu")
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_hiu_id == null) { error make --unspanned { msg: "required header parameter 'X-HIU-ID' missing: pass --x-hiu-id" } }
  let full_url = (build-url $base "/v0.5/consents/on-fetch" $auth.query)
  let req_body = {"consent": $consent, "error": $error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIU-ID": $x_hiu_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-health-information-cm-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-cm-id: string # Suffix of the consent manager to which the request was intended. (required)
  hi_request: record # shape: {consent: record, dataPushUrl: string, dateRange: record, keyMaterial: record}
  request_id: string # format: uuid, e.g. a1s2c932-2f70-3ds3-a3b5-2sfd46b12a18d
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_cm_id == null) { error make --unspanned { msg: "required header parameter 'X-CM-ID' missing: pass --x-cm-id" } }
  let full_url = (build-url $base "/v0.5/health-information/cm/request" $auth.query)
  let req_body = {"hiRequest": $hi_request, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
# POST /v0.5/health-information/hiu/on-request
export def "post-v0-5-health-information-hiu-on-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-hiu-id: string # Identifier of the health information user to which the request was intended. (required)
  --error: record # shape: {code: "1000"|"10001", message: string}
  --hi-request: record # shape: {sessionStatus: "REQUESTED"|"ACKNOWLEDGED", transactionId: string}
  request_id: string # format: uuid, e.g. a1s2c932-2f70-3ds3-a3b5-2sfd46b12a18d
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://dev.ndhm.gov.in/hiu")
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_hiu_id == null) { error make --unspanned { msg: "required header parameter 'X-HIU-ID' missing: pass --x-hiu-id" } }
  let full_url = (build-url $base "/v0.5/health-information/hiu/on-request" $auth.query)
  let req_body = {"error": $error, "hiRequest": $hi_request, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIU-ID": $x_hiu_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-health-information-notify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-cm-id: string # Suffix of the consent manager to which the request was intended. (required)
  notification: record # shape: {consentId: string, doneAt: string, notifier: record, statusNotification: record, transactionId: string}
  request_id: string # a nonce, unique for each HTTP request. (format: uuid, e.g. 499a5a4a-7dda-4f20-9b67-e24589627061)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_cm_id == null) { error make --unspanned { msg: "required header parameter 'X-CM-ID' missing: pass --x-cm-id" } }
  let full_url = (build-url $base "/v0.5/health-information/notify" $auth.query)
  let req_body = {"notification": $notification, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# health information transfer API
#
# POST /v0.5/health-information/transfer
export def "post-v0-5-health-information-transfer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  entries: list
  key_material: record # shape: {cryptoAlg: string, curve: string, dhPublicKey: record, nonce: string}
  page_count: int # Total number of pages.
  page_number: int # Current page number.
  transaction_id: string # Transaction Id issued when data requested. (format: uuid)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://dev.ndhm.gov.in/hiu")
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  let full_url = (build-url $base "/v0.5/health-information/transfer" $auth.query)
  let req_body = {"entries": $entries, "keyMaterial": $key_material, "pageCount": $page_count, "pageNumber": $page_number, "transactionId": $transaction_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
# GET /v0.5/heartbeat
export def "get-v0-5-heartbeat" [
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
]: nothing -> oneof<record<error: record<code: int, message: string>, status: string, timestamp: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://dev.ndhm.gov.in/hiu")
  let full_url = (build-url $base "/v0.5/heartbeat" $auth.query)
  let accept_val = ($accept | default "application/json")
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

# Identify a patient by her consent-manager user-id
#
# POST /v0.5/patients/find
export def "post-v0-5-patients-find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-cm-id: string # Suffix of the consent manager to which the request was intended. (required)
  query: record # shape: {patient: record, requester: record}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_cm_id == null) { error make --unspanned { msg: "required header parameter 'X-CM-ID' missing: pass --x-cm-id" } }
  let full_url = (build-url $base "/v0.5/patients/find" $auth.query)
  let req_body = {"query": $query, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-patients-on-find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --error: record # shape: {code: "1000"|"10001", message: string}
  --patient: record # shape: {id: string, name: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://dev.ndhm.gov.in/hiu")
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  let full_url = (build-url $base "/v0.5/patients/on-find" $auth.query)
  let req_body = {"error": $error, "patient": $patient, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-sessions" [
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
]: any -> oneof<record<accessToken: string, expiresIn: int, refreshExpiresIn: int, refreshToken: string, tokenType: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v0.5/sessions" $auth.query)
  let req_body = {"clientId": $client_id, "clientSecret": $client_secret} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = ($accept | default "application/json")
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

# Request for subscription
#
# POST /v0.5/subscription-requests/cm/init
export def "post-v0-5-subscription-requests-cm-init" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-cm-id: string # Suffix of the consent manager to which the request was intended. (required)
  request_id: string # a nonce, unique for each HTTP request. (format: uuid, e.g. 499a5a4a-7dda-4f20-9b67-e24589627061)
  subscription: record # shape: {categories: list<string>, hips?: list, hiu: record, patient: record, period: record, purpose: record}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_cm_id == null) { error make --unspanned { msg: "required header parameter 'X-CM-ID' missing: pass --x-cm-id" } }
  let full_url = (build-url $base "/v0.5/subscription-requests/cm/init" $auth.query)
  let req_body = {"requestId": $request_id, "subscription": $subscription, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-subscription-requests-hiu-notify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-hiu-id: string # Identifier of the health information user to which the request was intended. (required)
  notification: record # shape: {status: "GRANTED"|"DENIED", subscription?: record, subscriptionRequestId?: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_hiu_id == null) { error make --unspanned { msg: "required header parameter 'X-HIU-ID' missing: pass --x-hiu-id" } }
  let full_url = (build-url $base "/v0.5/subscription-requests/hiu/notify" $auth.query)
  let req_body = {"notification": $notification, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIU-ID": $x_hiu_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
# POST /v0.5/subscription-requests/hiu/on-init
export def "post-v0-5-subscription-requests-hiu-on-init" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-hiu-id: string # Identifier of the health information user to which the request was intended. (required)
  --error: record # shape: {code: "1000"|"10001", message: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  --subscription-request: record # shape: {id: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_hiu_id == null) { error make --unspanned { msg: "required header parameter 'X-HIU-ID' missing: pass --x-hiu-id" } }
  let full_url = (build-url $base "/v0.5/subscription-requests/hiu/on-init" $auth.query)
  let req_body = {"error": $error, "requestId": $request_id, "resp": $resp, "subscriptionRequest": $subscription_request, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIU-ID": $x_hiu_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-subscription-requests-hiu-on-notify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-cm-id: string # Suffix of the consent manager to which the request was intended. (required)
  --acknowledgement: record # shape: {status: "OK", subscriptionRequestId: string}
  --error: record # shape: {code: "1000"|"10001", message: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_cm_id == null) { error make --unspanned { msg: "required header parameter 'X-CM-ID' missing: pass --x-cm-id" } }
  let full_url = (build-url $base "/v0.5/subscription-requests/hiu/on-notify" $auth.query)
  let req_body = {"acknowledgement": $acknowledgement, "error": $error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-subscriptions-hiu-notify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-hiu-id: string # Identifier of the health information user to which the request was intended. (required)
  event: record # shape: {category: "LINK", content: record, id: string, published: string, subscriptionId: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_hiu_id == null) { error make --unspanned { msg: "required header parameter 'X-HIU-ID' missing: pass --x-hiu-id" } }
  let full_url = (build-url $base "/v0.5/subscriptions/hiu/notify" $auth.query)
  let req_body = {"event": $event, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIU-ID": $x_hiu_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-subscriptions-hiu-on-notify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-cm-id: string # Suffix of the consent manager to which the request was intended. (required)
  --acknowledgement: record # shape: {eventId: string, status: "OK"}
  --error: record # shape: {code: "1000"|"10001", message: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_cm_id == null) { error make --unspanned { msg: "required header parameter 'X-CM-ID' missing: pass --x-cm-id" } }
  let full_url = (build-url $base "/v0.5/subscriptions/hiu/on-notify" $auth.query)
  let req_body = {"acknowledgement": $acknowledgement, "error": $error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-users-auth-confirm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-cm-id: string # Suffix of the consent manager to which the request was intended. (required)
  credential: record # note, demographic details are only required for demographic auth at this point. — shape: {authCode?: string, demographic?: record}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
  transaction_id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_cm_id == null) { error make --unspanned { msg: "required header parameter 'X-CM-ID' missing: pass --x-cm-id" } }
  let full_url = (build-url $base "/v0.5/users/auth/confirm" $auth.query)
  let req_body = {"credential": $credential, "requestId": $request_id, "timestamp": $timestamp, "transactionId": $transaction_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-users-auth-fetch-modes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-cm-id: string # Suffix of the consent manager to which the request was intended. (required)
  query: record # shape: {id: string, purpose: "LINK"|"KYC"|"KYC_AND_LINK", requester: record}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_cm_id == null) { error make --unspanned { msg: "required header parameter 'X-CM-ID' missing: pass --x-cm-id" } }
  let full_url = (build-url $base "/v0.5/users/auth/fetch-modes" $auth.query)
  let req_body = {"query": $query, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-users-auth-init" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-cm-id: string # Suffix of the consent manager to which the request was intended. (required)
  query: record # shape: {authMode?: "MOBILE_OTP"|"DIRECT"|"DEMOGRAPHICS"|"AADHAAR_OTP", id: string, purpose: "LINK"|"KYC"|"KYC_AND_LINK", requester: record}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_cm_id == null) { error make --unspanned { msg: "required header parameter 'X-CM-ID' missing: pass --x-cm-id" } }
  let full_url = (build-url $base "/v0.5/users/auth/init" $auth.query)
  let req_body = {"query": $query, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-users-auth-notify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-hip-id: string # Identifier of the health information provider to which the request was intended. (required)
  --x-hiu-id: string # Identifier of the health information user to which the request was intended. (required)
  --body-auth: record # depending on the purpose of auth, as specified in /auth/init, the response may include the following 1. LINK - only returns **accessToken** 2. KYC - only returns **patient** 3. KYC_AND_LINK - returns both **accessToken** and **patient** — shape: {accessToken?: string, patient?: record, status: "GRANTED"|"DENIED", transactionId: string, validity?: record} (spec name: auth)
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_hip_id == null) { error make --unspanned { msg: "required header parameter 'X-HIP-ID' missing: pass --x-hip-id" } }
  if ($x_hiu_id == null) { error make --unspanned { msg: "required header parameter 'X-HIU-ID' missing: pass --x-hiu-id" } }
  let full_url = (build-url $base "/v0.5/users/auth/notify" $auth.query)
  let req_body = {"auth": $body_auth, "requestId": $request_id, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIP-ID": $x_hip_id, "X-HIU-ID": $x_hiu_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-users-auth-on-confirm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-hip-id: string # Identifier of the health information provider to which the request was intended. (required)
  --x-hiu-id: string # Identifier of the health information user to which the request was intended. (required)
  --body-auth: record # depending on the purpose of auth, as specified in /auth/init, the response may include the following 1. LINK - only returns **accessToken** 2. KYC - only returns **patient** 3. KYC_AND_LINK - returns both **accessToken** and **patient** — shape: {accessToken?: string, patient?: record, validity?: record} (spec name: auth)
  --error: record # shape: {code: "1000"|"10001", message: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_hip_id == null) { error make --unspanned { msg: "required header parameter 'X-HIP-ID' missing: pass --x-hip-id" } }
  if ($x_hiu_id == null) { error make --unspanned { msg: "required header parameter 'X-HIU-ID' missing: pass --x-hiu-id" } }
  let full_url = (build-url $base "/v0.5/users/auth/on-confirm" $auth.query)
  let req_body = {"auth": $body_auth, "error": $error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIP-ID": $x_hip_id, "X-HIU-ID": $x_hiu_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-users-auth-on-fetch-modes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-hip-id: string # Identifier of the health information provider to which the request was intended. (required)
  --x-hiu-id: string # Identifier of the health information user to which the request was intended. (required)
  --body-auth: record # shape: {modes: list<string>, purpose: "LINK"|"KYC"|"KYC_AND_LINK"} (spec name: auth)
  --error: record # shape: {code: "1000"|"10001", message: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_hip_id == null) { error make --unspanned { msg: "required header parameter 'X-HIP-ID' missing: pass --x-hip-id" } }
  if ($x_hiu_id == null) { error make --unspanned { msg: "required header parameter 'X-HIU-ID' missing: pass --x-hiu-id" } }
  let full_url = (build-url $base "/v0.5/users/auth/on-fetch-modes" $auth.query)
  let req_body = {"auth": $body_auth, "error": $error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIP-ID": $x_hip_id, "X-HIU-ID": $x_hiu_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-users-auth-on-init" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-hip-id: string # Identifier of the health information provider to which the request was intended. (required)
  --x-hiu-id: string # Identifier of the health information user to which the request was intended. (required)
  --body-auth: record # shape: {meta?: record, mode: "MOBILE_OTP"|"DIRECT"|"DEMOGRAPHICS"|"AADHAAR_OTP", transactionId: string} (spec name: auth)
  --error: record # shape: {code: "1000"|"10001", message: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_hip_id == null) { error make --unspanned { msg: "required header parameter 'X-HIP-ID' missing: pass --x-hip-id" } }
  if ($x_hiu_id == null) { error make --unspanned { msg: "required header parameter 'X-HIU-ID' missing: pass --x-hiu-id" } }
  let full_url = (build-url $base "/v0.5/users/auth/on-init" $auth.query)
  let req_body = {"auth": $body_auth, "error": $error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-HIP-ID": $x_hip_id, "X-HIU-ID": $x_hiu_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "post-v0-5-users-auth-on-notify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Access token which was issued after successful login with gateway auth server, which will be sent by gateway to authenticate itself with API bridge. (required)
  --x-cm-id: string # Suffix of the consent manager to which the request was intended. (required)
  --acknowledgement: record # shape: {status: "OK"}
  --error: record # shape: {code: "1000"|"10001", message: string}
  request_id: string # a nonce, unique for each HTTP request (format: uuid, e.g. 5f7a535d-a3fd-416b-b069-c97d021fbacd)
  resp: record # shape: {requestId: string}
  timestamp: string # Date time format in UTC, includes miliseconds YYYY-MM-DDThh:mm:ss.vZ (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authorization == null) { error make --unspanned { msg: "required header parameter 'Authorization' missing: pass --authorization" } }
  if ($x_cm_id == null) { error make --unspanned { msg: "required header parameter 'X-CM-ID' missing: pass --x-cm-id" } }
  let full_url = (build-url $base "/v0.5/users/auth/on-notify" $auth.query)
  let req_body = {"acknowledgement": $acknowledgement, "error": $error, "requestId": $request_id, "resp": $resp, "timestamp": $timestamp} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-CM-ID": $x_cm_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
