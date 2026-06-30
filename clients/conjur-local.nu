# Auto-generated client for Conjur v5.3.0
# Source: https://api.apis.guru/v2/specs/conjur.local/5.3.0/openapi.json
# Auth: --token flag or $env.CONJUR_TOKEN

const BASE_URL = "http://conjur.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CONJUR_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "mutual" => { {scheme: $scheme, headers: {Authorization: $"Mutual ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Merge multiple auth records (AND-form security: every scheme must be sent).
def merge-auth [parts: list]: nothing -> record {
  let active = ($parts | where {|p| $p.location != "none" })
  let headers = ($parts | reduce --fold {} {|p, acc| $acc | merge $p.headers })
  let query = ($parts | each {|p| $p.query } | where {|q| $q | is-not-empty } | str join "&")
  let locs = ($active | each {|p| $p.location } | uniq)
  let location = if ($locs | is-empty) { "none" } else { $locs | str join "+" }
  {scheme: ($parts | each {|p| $p.scheme } | str join "+"), headers: $headers, query: $query, location: $location}
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

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://conjur.local" "http://localhost"] }
def auth-scheme-completer [] { ["basic" "bearer" "mutual" "none" "basic-credentials"] }

# Completers for enum parameters
def accept-encoding-completer [] { ["application/json" "base64"] }
def accept-encoding-completer-1 [] { ["base64"] }
def accept-completer [] { ["application/json" "application/x-pem-file"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "authenticators get" } } | get name | first)
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

# Details about which authenticators are on the Conjur Server
#
# GET /authenticators
# operationId: getAuthenticators
export def "authenticators get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> record<configured: list<string>, enabled: list<string>, installed: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authenticators" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
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

# Gets a short-lived access token for applications running in Azure.
#
# POST /authn-azure/{service_id}/{account}/{login}/authenticate
# operationId: getAccessTokenViaAzure
export def "authn-azure-authenticate get-access-token-via" [
  service_id: string
  account: string
  login: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: string@accept-encoding-completer # Setting the Accept-Encoding header to base64 will return a pre-encoded access token
  --jwt: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  if ($login | is-empty) { error make --unspanned { msg: "path parameter 'login' must be non-empty" } }
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id), account: (encode-path-segment $account), login: (encode-path-segment $login)} | format pattern "/authn-azure/{service_id}/{account}/{login}/authenticate") $auth.query)
  let req_body = {"jwt": $jwt} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Encoding": $accept_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Gets a short-lived access token for applications running in Google Cloud Platform.
#
# POST /authn-gcp/{account}/authenticate
# operationId: getAccessTokenViaGCP
export def "authn-gcp-authenticate get-access-token-via" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --accept-encoding: string@accept-encoding-completer-1 # Setting the Accept-Encoding header to base64 will return a pre-encoded access token
  --jwt: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  let full_url = (build-url $base ({account: (encode-path-segment $account)} | format pattern "/authn-gcp/{account}/authenticate") $auth.query)
  let req_body = {"jwt": $jwt} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id, "Accept-Encoding": $accept_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Details whether an authentication service has been configured properly
#
# GET /authn-gcp/{account}/status
# operationId: getGCPAuthenticatorStatus
export def "authn-gcp-status get-authenticator" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  let full_url = (build-url $base ({account: (encode-path-segment $account)} | format pattern "/authn-gcp/{account}/status") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
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

# Get a short-lived access token for applications running in AWS.
#
# POST /authn-iam/{service_id}/{account}/{login}/authenticate
# operationId: getAccessTokenViaAWS
export def "authn-iam-authenticate get-access-token-via-aws" [
  service_id: string
  account: string
  login: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: string@accept-encoding-completer # Setting the Accept-Encoding header to base64 will return a pre-encoded access token
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  if ($login | is-empty) { error make --unspanned { msg: "path parameter 'login' must be non-empty" } }
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id), account: (encode-path-segment $account), login: (encode-path-segment $login)} | format pattern "/authn-iam/{service_id}/{account}/{login}/authenticate") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Encoding": $accept_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "text/plain"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets a short-lived access token for applications using JSON Web Token (JWT) to access the Conjur API.
#
# POST /authn-jwt/{service_id}/{account}/authenticate
# operationId: getAccessTokenViaJWT
export def "authn-jwt-authenticate get-access-token-via-by-service-id-account" [
  service_id: string
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --jwt: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id), account: (encode-path-segment $account)} | format pattern "/authn-jwt/{service_id}/{account}/authenticate") $auth.query)
  let req_body = {"jwt": $jwt} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Gets a short-lived access token for applications using JSON Web Token (JWT) to access the Conjur API. Covers the case of use of optional URL parameter "ID"
#
# POST /authn-jwt/{service_id}/{account}/{id}/authenticate
# operationId: getAccessTokenViaJWTWithId
export def "authn-jwt-authenticate get-access-token-via-by-service-id-account-id" [
  service_id: string
  account: string
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id), account: (encode-path-segment $account), id: (encode-path-segment $id)} | format pattern "/authn-jwt/{service_id}/{account}/{id}/authenticate") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# For applications running in Kubernetes; sends Conjur a certificate signing request (CSR) and requests a client certificate injected into the application's Kubernetes pod.
#
# POST /authn-k8s/{service_id}/inject_client_cert
# operationId: k8sInjectClientCert
export def "authn-k8s-inject-client-cert create" [
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
  --host-id-prefix: string # Dot-separated policy tree, prefixed by `host.`, where the application identity is defined (e.g. host/conjur/authn-k8s/my-authenticator-id/apps)
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/authn-k8s/{service_id}/inject_client_cert") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Host-Id-Prefix": $host_id_prefix} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "text/plain"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [202]
}

# Gets a short-lived access token for applications running in Kubernetes.
#
# POST /authn-k8s/{service_id}/{account}/{login}/authenticate
# operationId: getAccessTokenViaKubernetes
export def "authn-k8s-authenticate get-access-token-via-kubernetes" [
  service_id: string
  account: string
  login: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: string@accept-encoding-completer # Setting the Accept-Encoding header to base64 will return a pre-encoded access token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "mutual"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  if ($login | is-empty) { error make --unspanned { msg: "path parameter 'login' must be non-empty" } }
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id), account: (encode-path-segment $account), login: (encode-path-segment $login)} | format pattern "/authn-k8s/{service_id}/{account}/{login}/authenticate") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Encoding": $accept_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Gets the Conjur API key of a user given the LDAP username and password via HTTP Basic Authentication.
#
# GET /authn-ldap/{service_id}/{account}/login
# operationId: getAPIKeyViaLDAP
export def "authn-ldap-login get-key-via" [
  service_id: string
  account: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id), account: (encode-path-segment $account)} | format pattern "/authn-ldap/{service_id}/{account}/login") $auth.query)
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

# Gets a short-lived access token for users and hosts using their LDAP identity to access the Conjur API.
#
# POST /authn-ldap/{service_id}/{account}/{login}/authenticate
# operationId: getAccessTokenViaLDAP
export def "authn-ldap-authenticate get-access-token-via" [
  service_id: string
  account: string
  login: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: string@accept-encoding-completer # Setting the Accept-Encoding header to base64 will return a pre-encoded access token
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  if ($login | is-empty) { error make --unspanned { msg: "path parameter 'login' must be non-empty" } }
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id), account: (encode-path-segment $account), login: (encode-path-segment $login)} | format pattern "/authn-ldap/{service_id}/{account}/{login}/authenticate") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Encoding": $accept_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "text/plain"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets a short-lived access token for applications using OpenID Connect (OIDC) to access the Conjur API.
#
# POST /authn-oidc/{service_id}/{account}/authenticate
# operationId: getAccessTokenViaOIDC
export def "authn-oidc-authenticate get-access-token-via" [
  service_id: string
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id-token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id), account: (encode-path-segment $account)} | format pattern "/authn-oidc/{service_id}/{account}/authenticate") $auth.query)
  let req_body = {"id_token": $id_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Rotates a role's API key.
#
# PUT /authn/{account}/api_key
# operationId: rotateApiKey
export def "authn-api-key update-rotate" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token-basicauth: string # Auth token for basicAuth (Authorization)
  --token-conjurauth: string # Auth token for conjurAuth (Authorization)
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string # (**Optional**) role specifier in `{kind}:{identifier}` format ##### Permissions required `update` privilege on the role whose API key is being rotated.
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> any {
  let auth = (merge-auth [(build-auth ($token_basicauth | default ($env | get -o CONJUR_BASICAUTH_TOKEN | default "")) "basic") (build-auth ($token_conjurauth | default ($env | get -o CONJUR_CONJURAUTH_TOKEN | default "")) "bearer")])
  let base = ($base_url | default $BASE_URL)
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  let qp = [(serialize-qp "role" $role "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account: (encode-path-segment $account)} | format pattern "/authn/{account}/api_key") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: ({"role": $role} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Gets the API key of a user given the username and password via HTTP Basic Authentication.
#
# GET /authn/{account}/login
# operationId: getAPIKey
export def "authn-login get-key" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  let full_url = (build-url $base ({account: (encode-path-segment $account)} | format pattern "/authn/{account}/login") $auth.query)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
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

# Changes a user’s password.
#
# PUT /authn/{account}/password
# operationId: changePassword
export def "authn-password update-change" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  let full_url = (build-url $base ({account: (encode-path-segment $account)} | format pattern "/authn/{account}/password") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "text/plain"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Gets a short-lived access token, which is required in the header of most subsequent API requests.
#
# POST /authn/{account}/{login}/authenticate
# operationId: getAccessToken
export def "authn-authenticate get-access-token" [
  account: string
  login: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --accept-encoding: string@accept-encoding-completer # Setting the Accept-Encoding header to base64 will return a pre-encoded access token
  --body: any
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  if ($login | is-empty) { error make --unspanned { msg: "path parameter 'login' must be non-empty" } }
  let full_url = (build-url $base ({account: (encode-path-segment $account), login: (encode-path-segment $login)} | format pattern "/authn/{account}/{login}/authenticate") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id, "Accept-Encoding": $accept_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "text/plain"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Gets a signed certificate from the configured Certificate Authority service.
#
# POST /ca/{account}/{service_id}/sign
# operationId: sign
export def "ca-sign create" [
  account: string
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
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --hdr-accept: string # Setting the Accept header to `application/x-pem-file` allows Conjur to respond with a formatted certificate (e.g. application/x-pem-file)
  csr: string
  ttl: string
]: any -> record<certificate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  let full_url = (build-url $base ({account: (encode-path-segment $account), service_id: (encode-path-segment $service_id)} | format pattern "/ca/{account}/{service_id}/sign") $auth.query)
  let req_body = {"csr": $csr, "ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# Health info about conjur
#
# GET /health
# operationId: health
export def "health get" [
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health" $auth.query)
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

# Creates a Host using the Host Factory.
#
# POST /host_factories/hosts
# operationId: createHost
export def "host-factories-hosts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --annotations: record # Annotations to apply to the new host (e.g. {description: new db host, puppet: true})
  id: string # Identifier of the host to be created. It will be created within the account of the host factory. (e.g. my-new-host)
]: any -> record<annotations: list<string>, api_key: string, created_at: string, id: string, owner: string, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/host_factories/hosts" $auth.query)
  let req_body = {"annotations": $annotations, "id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# Creates one or more host identity tokens.
#
# POST /host_factory_tokens
# operationId: createToken
export def "host-factory-tokens create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --cidr: list<string> # Number of host tokens to create (e.g. [127.0.0.1/32])
  --count: int # Number of host tokens to create (e.g. 2)
  expiration: string # `ISO 8601 datetime` denoting a requested expiration time. (e.g. 2017-08-04T22:27:20+00:00)
  host_factory: string # Fully qualified host factory ID (e.g. myorg:host_factory:hf-db)
]: any -> table<cidr: list<string>, expiration: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/host_factory_tokens" $auth.query)
  let req_body = {"cidr": $cidr, "count": $count, "expiration": $expiration, "host_factory": $host_factory} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# Revokes a token, immediately disabling it.
#
# DELETE /host_factory_tokens/{token}
# operationId: revokeToken
export def "host-factory-tokens delete" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($token_arg | is-empty) { error make --unspanned { msg: "path parameter 'token' must be non-empty" } }
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/host_factory_tokens/{token_arg}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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

# Basic information about the Conjur Enterprise server
#
# GET /info
# operationId: info
export def "info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<authenticators: record<configured: list<string>, enabled: list<string>, installed: list<string>>, configuration: record, container: string, release: string, role: string, services: record, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/info" $auth.query)
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

# Modifies an existing Conjur policy.
#
# PATCH /policies/{account}/policy/{identifier}
# operationId: updatePolicy
export def "policies-policy update-by-account-identifier" [
  account: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  if ($identifier | is-empty) { error make --unspanned { msg: "path parameter 'identifier' must be non-empty" } }
  let full_url = (build-url $base ({account: (encode-path-segment $account), identifier: (encode-path-segment $identifier)} | format pattern "/policies/{account}/policy/{identifier}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-yaml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [201]
}

# Adds data to the existing Conjur policy.
#
# POST /policies/{account}/policy/{identifier}
# operationId: loadPolicy
export def "policies-policy create-load" [
  account: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  if ($identifier | is-empty) { error make --unspanned { msg: "path parameter 'identifier' must be non-empty" } }
  let full_url = (build-url $base ({account: (encode-path-segment $account), identifier: (encode-path-segment $identifier)} | format pattern "/policies/{account}/policy/{identifier}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-yaml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Loads or replaces a Conjur policy document.
#
# PUT /policies/{account}/policy/{identifier}
# operationId: replacePolicy
export def "policies-policy update-by-account-identifier-1" [
  account: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --body: any
]: any -> record<created_roles: record, version: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  if ($identifier | is-empty) { error make --unspanned { msg: "path parameter 'identifier' must be non-empty" } }
  let full_url = (build-url $base ({account: (encode-path-segment $account), identifier: (encode-path-segment $identifier)} | format pattern "/policies/{account}/policy/{identifier}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-yaml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [201]
}

# Shows all public keys for a resource.
#
# GET /public_keys/{account}/{kind}/{identifier}
# operationId: showPublicKeys
export def "public-keys get-show" [
  account: string
  kind: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  if ($identifier | is-empty) { error make --unspanned { msg: "path parameter 'identifier' must be non-empty" } }
  let full_url = (build-url $base ({account: (encode-path-segment $account), kind: (encode-path-segment $kind), identifier: (encode-path-segment $identifier)} | format pattern "/public_keys/{account}/{kind}/{identifier}") $auth.query)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
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

# Health info about a given Conjur Enterprise server
#
# GET /remote_health/{remote}
# operationId: remoteHealth
export def "remote-health get" [
  remote: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($remote | is-empty) { error make --unspanned { msg: "path parameter 'remote' must be non-empty" } }
  let full_url = (build-url $base ({remote: (encode-path-segment $remote)} | format pattern "/remote_health/{remote}") $auth.query)
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

# Lists resources within an organization account.
#
# GET /resources
# operationId: showResourcesForAllAccounts
export def "resources list-show-for-accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account: string # Organization account name (e.g. default)
  --kind: string # Type of resource (e.g. variable)
  --search: string # Filter resources based on this value by name (e.g. password)
  --offset: int # When listing resources, start at this item number. (e.g. 20)
  --limit: int # When listing resources, return up to this many results. (e.g. 10)
  --count: oneof<nothing, bool> # When listing resources, if `true`, return only the count of the results. (e.g. true)
  --role: string # Retrieves the resources list for a different role if the authenticated role has access (e.g. myorg:host:host1)
  --acting-as: string # Retrieves the resources list for a different role if the authenticated role has access (e.g. myorg:host:host1)
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> table<annotations: list<string>, created_at: string, id: string, owner: string, permissions: list<record>, policy: string, policy_versions: list<record>, restricted_to: list<string>, secrets: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "account" $account "scalar") (serialize-qp "kind" $kind "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "acting_as" $acting_as "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/resources" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"account": $account, "kind": $kind, "search": $search, "offset": $offset, "limit": $limit, "count": $count, "role": $role, "acting_as": $acting_as} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists resources within an organization account.
#
# GET /resources/{account}
# operationId: showResourcesForAccount
export def "resources get-show-by-account" [
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kind: string # Type of resource (e.g. variable)
  --search: string # Filter resources based on this value by name (e.g. password)
  --offset: int # When listing resources, start at this item number. (e.g. 20)
  --limit: int # When listing resources, return up to this many results. (e.g. 10)
  --count: oneof<nothing, bool> # When listing resources, if `true`, return only the count of the results. (e.g. true)
  --role: string # Retrieves the resources list for a different role if the authenticated role has access (e.g. myorg:host:host1)
  --acting-as: string # Retrieves the resources list for a different role if the authenticated role has access (e.g. myorg:host:host1)
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  let qp = [(serialize-qp "kind" $kind "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "acting_as" $acting_as "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account: (encode-path-segment $account)} | format pattern "/resources/{account}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"kind": $kind, "search": $search, "offset": $offset, "limit": $limit, "count": $count, "role": $role, "acting_as": $acting_as} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists resources of the same kind within an organization account.
#
# GET /resources/{account}/{kind}
# operationId: showResourcesForKind
export def "resources get-show-by-account-kind" [
  account: string
  kind: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Filter resources based on this value by name (e.g. password)
  --offset: int # When listing resources, start at this item number. (e.g. 20)
  --limit: int # When listing resources, return up to this many results. (e.g. 10)
  --count: oneof<nothing, bool> # When listing resources, if `true`, return only the count of the results. (e.g. true)
  --role: string # Retrieves the resources list for a different role if the authenticated role has access (e.g. myorg:host:host1)
  --acting-as: string # Retrieves the resources list for a different role if the authenticated role has access (e.g. myorg:host:host1)
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "acting_as" $acting_as "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account: (encode-path-segment $account), kind: (encode-path-segment $kind)} | format pattern "/resources/{account}/{kind}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"search": $search, "offset": $offset, "limit": $limit, "count": $count, "role": $role, "acting_as": $acting_as} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Shows a description of a single resource.
#
# GET /resources/{account}/{kind}/{identifier}
# operationId: showResource
export def "resources get-show-by-account-kind-identifier" [
  account: string
  kind: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --permitted-roles: oneof<nothing, bool> # Lists the roles which have the named privilege on a resource. (e.g. true)
  --privilege: string # Level of privilege to filter on. Can only be used in combination with `permitted_roles` or `check` parameter. (e.g. execute)
  --check: oneof<nothing, bool> # Check whether a role has a privilege on a resource. (e.g. true)
  --role: string # Role to check privilege on. Can only be used in combination with `check` parameter. (e.g. myorg:host:host1)
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> record<annotations: list<string>, created_at: string, id: string, owner: string, permissions: table<policy: string, privilege: string, role: string>, policy: string, policy_versions: table<client_ip: string, created_at: string, finished_at: string, id: string, policy_sha256: string, policy_text: string, role: string, version: float>, restricted_to: list<string>, secrets: table<expires_at: string, version: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  if ($identifier | is-empty) { error make --unspanned { msg: "path parameter 'identifier' must be non-empty" } }
  let qp = [(serialize-qp "permitted_roles" $permitted_roles "scalar") (serialize-qp "privilege" $privilege "scalar") (serialize-qp "check" $check "scalar") (serialize-qp "role" $role "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account: (encode-path-segment $account), kind: (encode-path-segment $kind), identifier: (encode-path-segment $identifier)} | format pattern "/resources/{account}/{kind}/{identifier}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"permitted_roles": $permitted_roles, "privilege": $privilege, "check": $check, "role": $role} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 204]
}

# Deletes an existing role membership
#
# DELETE /roles/{account}/{kind}/{identifier}
# operationId: removeMemberFromRole
export def "roles delete-member" [
  account: string
  kind: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --members: string # Returns a list of the Role's members.
  --member: string # The identifier of the Role to be added as a member.
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  if ($identifier | is-empty) { error make --unspanned { msg: "path parameter 'identifier' must be non-empty" } }
  let qp = [(serialize-qp "members" $members "scalar") (serialize-qp "member" $member "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account: (encode-path-segment $account), kind: (encode-path-segment $kind), identifier: (encode-path-segment $identifier)} | format pattern "/roles/{account}/{kind}/{identifier}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"members": $members, "member": $member} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get role information
#
# GET /roles/{account}/{kind}/{identifier}
# operationId: showRole
export def "roles get-show" [
  account: string
  kind: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --all: string # Returns an array of Role IDs representing all role memberships, expanded recursively.
  --memberships: string # Returns all direct role memberships (members not expanded recursively).
  --members: string # Returns a list of the Role's members.
  --offset: int # When listing members, start at this item number. (e.g. 20)
  --limit: int # When listing members, return up to this many results. (e.g. 10)
  --count: oneof<nothing, bool> # When listing members, if `true`, return only the count of members. (e.g. true)
  --search: string # When listing members, the results will be narrowed to only those matching the provided string (e.g. user)
  --graph: string # If included in the query returns a graph view of the role (e.g. )
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  if ($identifier | is-empty) { error make --unspanned { msg: "path parameter 'identifier' must be non-empty" } }
  let qp = [(serialize-qp "all" $all "scalar") (serialize-qp "memberships" $memberships "scalar") (serialize-qp "members" $members "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "graph" $graph "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account: (encode-path-segment $account), kind: (encode-path-segment $kind), identifier: (encode-path-segment $identifier)} | format pattern "/roles/{account}/{kind}/{identifier}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"all": $all, "memberships": $memberships, "members": $members, "offset": $offset, "limit": $limit, "count": $count, "search": $search, "graph": $graph} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update or modify an existing role membership
#
# POST /roles/{account}/{kind}/{identifier}
# operationId: addMemberToRole
export def "roles create-member" [
  account: string
  kind: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --members: string # Returns a list of the Role's members.
  --member: string # The identifier of the Role to be added as a member.
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  if ($identifier | is-empty) { error make --unspanned { msg: "path parameter 'identifier' must be non-empty" } }
  let qp = [(serialize-qp "members" $members "scalar") (serialize-qp "member" $member "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account: (encode-path-segment $account), kind: (encode-path-segment $kind), identifier: (encode-path-segment $identifier)} | format pattern "/roles/{account}/{kind}/{identifier}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"members": $members, "member": $member} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# Fetch multiple secrets
#
# GET /secrets
# operationId: getSecrets
export def "secrets get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --variable-ids: string # Comma-delimited, URL-encoded resource IDs of the variables. (e.g. myorg:variable:secret1,myorg:variable:secret1)
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --accept-encoding: string@accept-encoding-completer-1 # Set the encoding of the response object
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "variable_ids" $variable_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/secrets" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id, "Accept-Encoding": $accept_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"variable_ids": $variable_ids} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Fetches the value of a secret from the specified Secret.
#
# GET /secrets/{account}/{kind}/{identifier}
# operationId: getSecret
export def "secrets get-by-account-kind-identifier" [
  account: string
  kind: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: int # (**Optional**) Version you want to retrieve (Conjur keeps the last 20 versions of a secret) (e.g. 1)
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  if ($identifier | is-empty) { error make --unspanned { msg: "path parameter 'identifier' must be non-empty" } }
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account: (encode-path-segment $account), kind: (encode-path-segment $kind), identifier: (encode-path-segment $identifier)} | format pattern "/secrets/{account}/{kind}/{identifier}") $qp $auth.query)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a secret value within the specified variable.
#
# POST /secrets/{account}/{kind}/{identifier}
# operationId: createSecret
export def "secrets create" [
  account: string
  kind: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --expirations: string # Tells the server to reset the variables expiration date
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  if ($kind | is-empty) { error make --unspanned { msg: "path parameter 'kind' must be non-empty" } }
  if ($identifier | is-empty) { error make --unspanned { msg: "path parameter 'identifier' must be non-empty" } }
  let qp = [(serialize-qp "expirations" $expirations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account: (encode-path-segment $account), kind: (encode-path-segment $kind), identifier: (encode-path-segment $identifier)} | format pattern "/secrets/{account}/{kind}/{identifier}") $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"expirations": $expirations} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/octet-stream"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Provides information about the client making an API request.
#
# GET /whoami
# operationId: whoAmI
export def "whoami get-who-am-i" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
]: nothing -> record<account: string, client_ip: string, token_issued_at: string, user_agent: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/whoami" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
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

# Enables or disables authenticator defined without service_id.
#
# PATCH /{authenticator}/{account}
# operationId: enableAuthenticator
export def "authentication enable" [
  authenticator: string
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-request-id: string # Add an ID to the request being made so it can be tracked in Conjur. If not provided the server will automatically generate one. (e.g. test-id)
  --enabled: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($authenticator | is-empty) { error make --unspanned { msg: "path parameter 'authenticator' must be non-empty" } }
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  let full_url = (build-url $base ({authenticator: (encode-path-segment $authenticator), account: (encode-path-segment $account)} | format pattern "/{authenticator}/{account}") $auth.query)
  let req_body = {"enabled": $enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Request-Id": $x_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body_wire $insecure $raw $allow_errors $full [204]
}

# Enables or disables authenticator service instances.
#
# PATCH /{authenticator}/{service_id}/{account}
# operationId: enableAuthenticatorInstance
export def "authentication enable-instance" [
  authenticator: string
  service_id: string
  account: string
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
  if ($authenticator | is-empty) { error make --unspanned { msg: "path parameter 'authenticator' must be non-empty" } }
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  let full_url = (build-url $base ({authenticator: (encode-path-segment $authenticator), service_id: (encode-path-segment $service_id), account: (encode-path-segment $account)} | format pattern "/{authenticator}/{service_id}/{account}") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body_wire $insecure $raw $allow_errors $full [204]
}

# Details whether an authentication service has been configured properly
#
# GET /{authenticator}/{service_id}/{account}/status
# operationId: getServiceAuthenticatorStatus
export def "status get" [
  authenticator: string
  service_id: string
  account: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<error: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($authenticator | is-empty) { error make --unspanned { msg: "path parameter 'authenticator' must be non-empty" } }
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($account | is-empty) { error make --unspanned { msg: "path parameter 'account' must be non-empty" } }
  let full_url = (build-url $base ({authenticator: (encode-path-segment $authenticator), service_id: (encode-path-segment $service_id), account: (encode-path-segment $account)} | format pattern "/{authenticator}/{service_id}/{account}/status") $auth.query)
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
