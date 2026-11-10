# Auto-generated client for Vault API v9.3.0
# Source: https://api.apis.guru/v2/specs/apideck.com/vault/9.3.0/openapi.json
# Auth: --token flag or $env.VAULT_API_TOKEN

const BASE_URL = "https://unify.apideck.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o VAULT_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
    "x-apideck-app-id" => { {scheme: $scheme, headers: {"x-apideck-app-id": $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://unify.apideck.com"] }
def auth-scheme-completer [] { ["bearer" "x-apideck-app-id" "none"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["connections-authorize" "connections-callback" "connections-all" "connections-delete" "connections-one" "connections-update" "connections-add" "connections-import" "connections-token" "connection-settings-all" "connection-settings-update" "consumers-all" "consumers-add" "consumers-delete" "consumers-one" "consumers-update" "consumer-request-counts-all" "logs-all" "connections-revoke" "sessions-create" "commands"] | sort) } | get name | first)
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

# Authorize
#
# GET /vault/authorize/{service_id}/{application_id}
# operationId: connectionsAuthorize
export def "connections-authorize" [
  service_id: string
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
  --state: string # An opaque value the applications adds to the initial request that the authorization server includes when redirecting the back to the application. This value must be used by the application to prevent CSRF attacks. (required, e.g. eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjb25zdW1lcl9pZCI6InRlc3RfdXNlcl9pZCIsInVuaWZpZWRfYXBpIjoiZGVmYXVsdCIsInNlcnZpY2VfaWQiOiJ0ZWFtbGVhZGVyIiwiYXBwbGljYXRpb25faWQiOiIxMTExIiwiaWF0IjoxNjIyMTI2Nzg3fQ.97_pn1UAXc7mctXBdr15czUNO1jjdQ9sJUOIE_Myzbk)
  --redirect-uri: string # URL to redirect back to after authorization. When left empty the default configured redirect uri will be used. (required, e.g. http://example.com/integrations)
  --scope: list<string> # One or more OAuth scopes to request from the connector. OAuth scopes control the set of resources and operations that are allowed after authorization. Refer to the connector's documentation for the available scopes. (e.g. [openid, leads:write, profile:read])
]: nothing -> oneof<record<detail: any, error: string, message: string, ref: string, status_code: float, type_name: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application_id' must be non-empty" } }
  if ($state == null) { error make --unspanned { msg: "required query parameter 'state' missing: pass --state" } }
  if ($redirect_uri == null) { error make --unspanned { msg: "required query parameter 'redirect_uri' missing: pass --redirect-uri" } }
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "scope" $scope "ssv")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id), application_id: (encode-path-segment $application_id)} | format pattern "/vault/authorize/{service_id}/{application_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"state": $state, "redirect_uri": $redirect_uri, "scope": $scope} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [301]
}

# Callback
#
# GET /vault/callback
# operationId: connectionsCallback
export def "connections-callback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # An opaque value the applications adds to the initial request that the authorization server includes when redirecting the back to the application. This value must be used by the application to prevent CSRF attacks. (required, e.g. eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjb25zdW1lcl9pZCI6InRlc3RfdXNlcl9pZCIsInVuaWZpZWRfYXBpIjoiZGVmYXVsdCIsInNlcnZpY2VfaWQiOiJ0ZWFtbGVhZGVyIiwiYXBwbGljYXRpb25faWQiOiIxMTExIiwiaWF0IjoxNjIyMTI2Nzg3fQ.97_pn1UAXc7mctXBdr15czUNO1jjdQ9sJUOIE_Myzbk)
  --code: string # An authorization code from the connector which Apideck Vault will later exchange for an access token. (required, e.g. g0ZGZmNjVmOWI)
]: nothing -> oneof<record<detail: any, error: string, message: string, ref: string, status_code: float, type_name: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($state == null) { error make --unspanned { msg: "required query parameter 'state' missing: pass --state" } }
  if ($code == null) { error make --unspanned { msg: "required query parameter 'code' missing: pass --code" } }
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "code" $code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vault/callback" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"state": $state, "code": $code} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [301]
}

# Get all connections
#
# GET /vault/connections
# operationId: connectionsAll
export def "connections-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api: string # Scope results to Unified API (e.g. crm)
  --configured: oneof<nothing, bool> # Scopes results to connections that have been configured or not (e.g. true)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
]: nothing -> oneof<record<data: table<auth_type: string, authorize_url: string, configurable_resources: list, configuration: list, created_at: float, enabled: bool, form_fields: list, has_guide: bool, icon: string, id: string, integration_state: string, logo: string, metadata: record, name: string, oauth_grant_type: string, resource_schema_support: list, resource_settings_support: list, revoke_url: string, service_id: string, settings: record, settings_required_for_authorization: list, state: string, status: string, subscriptions: list, tag_line: string, unified_api: string, updated_at: float, validation_support: bool, website: string>, status: string, status_code: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($x_apideck_consumer_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-consumer-id' missing: pass --x-apideck-consumer-id" } }
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  let qp = [(serialize-qp "api" $api "scalar") (serialize-qp "configured" $configured "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vault/connections" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"api": $api, "configured": $configured} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a connection
#
# DELETE /vault/connections/{unified_api}/{service_id}
# operationId: connectionsDelete
export def "connections-delete" [
  unified_api: string
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
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($unified_api | is-empty) { error make --unspanned { msg: "path parameter 'unified_api' must be non-empty" } }
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($x_apideck_consumer_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-consumer-id' missing: pass --x-apideck-consumer-id" } }
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  let full_url = (build-url $base ({unified_api: (encode-path-segment $unified_api), service_id: (encode-path-segment $service_id)} | format pattern "/vault/connections/{unified_api}/{service_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Get connection
#
# GET /vault/connections/{unified_api}/{service_id}
# operationId: connectionsOne
export def "connections-one" [
  unified_api: string
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
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
]: nothing -> oneof<record<data: record<auth_type: string, authorize_url: string, configurable_resources: list<string>, configuration: list<record>, created_at: float, enabled: bool, form_fields: list<record>, has_guide: bool, icon: string, id: string, integration_state: string, logo: string, metadata: record, name: string, oauth_grant_type: string, resource_schema_support: list<string>, resource_settings_support: list<string>, revoke_url: string, service_id: string, settings: record, settings_required_for_authorization: list<string>, state: string, status: string, subscriptions: list<record>, tag_line: string, unified_api: string, updated_at: float, validation_support: bool, website: string>, status: string, status_code: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($unified_api | is-empty) { error make --unspanned { msg: "path parameter 'unified_api' must be non-empty" } }
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($x_apideck_consumer_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-consumer-id' missing: pass --x-apideck-consumer-id" } }
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  let full_url = (build-url $base ({unified_api: (encode-path-segment $unified_api), service_id: (encode-path-segment $service_id)} | format pattern "/vault/connections/{unified_api}/{service_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Update connection
#
# PATCH /vault/connections/{unified_api}/{service_id}
# operationId: connectionsUpdate
export def "connections-update" [
  unified_api: string
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
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --configuration: list # item shape: {defaults?: list, resource?: string}
  --enabled: oneof<nothing, bool> # Whether the connection is enabled or not. You can enable or disable a connection using the Update Connection API. (e.g. true)
  --metadata: record # Attach your own consumer specific metadata (nullable, e.g. {account: {id: c01458a5-7276-41ce-bc19-639906b0450a, name: My Company}, plan: enterprise})
  --settings: record # Connection settings. Values will persist to `form_fields` with corresponding id (nullable, e.g. {api_key: 12345xxxxxx, instance_url: https://eu28.salesforce.com})
]: any -> oneof<record<data: record<auth_type: string, authorize_url: string, configurable_resources: list<string>, configuration: list<record>, created_at: float, enabled: bool, form_fields: list<record>, has_guide: bool, icon: string, id: string, integration_state: string, logo: string, metadata: record, name: string, oauth_grant_type: string, resource_schema_support: list<string>, resource_settings_support: list<string>, revoke_url: string, service_id: string, settings: record, settings_required_for_authorization: list<string>, state: string, status: string, subscriptions: list<record>, tag_line: string, unified_api: string, updated_at: float, validation_support: bool, website: string>, status: string, status_code: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($unified_api | is-empty) { error make --unspanned { msg: "path parameter 'unified_api' must be non-empty" } }
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($x_apideck_consumer_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-consumer-id' missing: pass --x-apideck-consumer-id" } }
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  let full_url = (build-url $base ({unified_api: (encode-path-segment $unified_api), service_id: (encode-path-segment $service_id)} | format pattern "/vault/connections/{unified_api}/{service_id}") $auth.query)
  let req_body = {"configuration": $configuration, "enabled": $enabled, "metadata": $metadata, "settings": $settings} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create connection
#
# POST /vault/connections/{unified_api}/{service_id}
# operationId: connectionsAdd
export def "connections-add" [
  unified_api: string
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
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --configuration: list # item shape: {defaults?: list, resource?: string}
  --enabled: oneof<nothing, bool> # Whether the connection is enabled or not. You can enable or disable a connection using the Update Connection API. (e.g. true)
  --metadata: record # Attach your own consumer specific metadata (nullable, e.g. {account: {id: c01458a5-7276-41ce-bc19-639906b0450a, name: My Company}, plan: enterprise})
  --settings: record # Connection settings. Values will persist to `form_fields` with corresponding id (nullable, e.g. {api_key: 12345xxxxxx, instance_url: https://eu28.salesforce.com})
]: any -> oneof<record<data: record<auth_type: string, authorize_url: string, configurable_resources: list<string>, configuration: list<record>, created_at: float, enabled: bool, form_fields: list<record>, has_guide: bool, icon: string, id: string, integration_state: string, logo: string, metadata: record, name: string, oauth_grant_type: string, resource_schema_support: list<string>, resource_settings_support: list<string>, revoke_url: string, service_id: string, settings: record, settings_required_for_authorization: list<string>, state: string, status: string, subscriptions: list<record>, tag_line: string, unified_api: string, updated_at: float, validation_support: bool, website: string>, status: string, status_code: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($unified_api | is-empty) { error make --unspanned { msg: "path parameter 'unified_api' must be non-empty" } }
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($x_apideck_consumer_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-consumer-id' missing: pass --x-apideck-consumer-id" } }
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  let full_url = (build-url $base ({unified_api: (encode-path-segment $unified_api), service_id: (encode-path-segment $service_id)} | format pattern "/vault/connections/{unified_api}/{service_id}") $auth.query)
  let req_body = {"configuration": $configuration, "enabled": $enabled, "metadata": $metadata, "settings": $settings} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Import connection
#
# POST /vault/connections/{unified_api}/{service_id}/import
# operationId: connectionsImport
export def "connections-import" [
  unified_api: string
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
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --credentials: record # e.g. {access_token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c, refresh_token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.cThIIoDvwdueQB468K5xDc5633seEFoqwxjF_xSJyQQ} — shape: {access_token?: string, expires_in?: int, issued_at?: string, refresh_token: string}
  --metadata: record # Attach your own consumer specific metadata (nullable, e.g. {account: {id: c01458a5-7276-41ce-bc19-639906b0450a, name: My Company}, plan: enterprise})
  --settings: record # Connection settings. Values will persist to `form_fields` with corresponding id (nullable, e.g. {instance_url: https://eu28.salesforce.com})
]: any -> oneof<record<data: record<auth_type: string, authorize_url: string, configurable_resources: list<string>, configuration: list<record>, created_at: float, enabled: bool, form_fields: list<record>, has_guide: bool, icon: string, id: string, integration_state: string, logo: string, metadata: record, name: string, oauth_grant_type: string, resource_schema_support: list<string>, resource_settings_support: list<string>, revoke_url: string, service_id: string, settings: record, settings_required_for_authorization: list<string>, state: string, status: string, subscriptions: list<record>, tag_line: string, unified_api: string, updated_at: float, validation_support: bool, website: string>, status: string, status_code: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($unified_api | is-empty) { error make --unspanned { msg: "path parameter 'unified_api' must be non-empty" } }
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($x_apideck_consumer_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-consumer-id' missing: pass --x-apideck-consumer-id" } }
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  let full_url = (build-url $base ({unified_api: (encode-path-segment $unified_api), service_id: (encode-path-segment $service_id)} | format pattern "/vault/connections/{unified_api}/{service_id}/import") $auth.query)
  let req_body = {"credentials": $credentials, "metadata": $metadata, "settings": $settings} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get Access Token
#
# POST /vault/connections/{unified_api}/{service_id}/token
# operationId: connectionsToken
export def "connections-token" [
  unified_api: string
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
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --body: record
]: any -> oneof<record<data: record<auth_type: string, authorize_url: string, configurable_resources: list<string>, configuration: list<record>, created_at: float, enabled: bool, form_fields: list<record>, has_guide: bool, icon: string, id: string, integration_state: string, logo: string, metadata: record, name: string, oauth_grant_type: string, resource_schema_support: list<string>, resource_settings_support: list<string>, revoke_url: string, service_id: string, settings: record, settings_required_for_authorization: list<string>, state: string, status: string, subscriptions: list<record>, tag_line: string, unified_api: string, updated_at: float, validation_support: bool, website: string>, status: string, status_code: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($unified_api | is-empty) { error make --unspanned { msg: "path parameter 'unified_api' must be non-empty" } }
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($x_apideck_consumer_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-consumer-id' missing: pass --x-apideck-consumer-id" } }
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  let full_url = (build-url $base ({unified_api: (encode-path-segment $unified_api), service_id: (encode-path-segment $service_id)} | format pattern "/vault/connections/{unified_api}/{service_id}/token") $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get resource settings
#
# GET /vault/connections/{unified_api}/{service_id}/{resource}/config
# operationId: connectionSettingsAll
export def "connection-settings-all" [
  unified_api: string
  service_id: string
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
]: nothing -> oneof<record<data: record<auth_type: string, authorize_url: string, configurable_resources: list<string>, configuration: list<record>, created_at: float, enabled: bool, form_fields: list<record>, has_guide: bool, icon: string, id: string, integration_state: string, logo: string, metadata: record, name: string, oauth_grant_type: string, resource_schema_support: list<string>, resource_settings_support: list<string>, revoke_url: string, service_id: string, settings: record, settings_required_for_authorization: list<string>, state: string, status: string, subscriptions: list<record>, tag_line: string, unified_api: string, updated_at: float, validation_support: bool, website: string>, status: string, status_code: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($unified_api | is-empty) { error make --unspanned { msg: "path parameter 'unified_api' must be non-empty" } }
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  if ($x_apideck_consumer_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-consumer-id' missing: pass --x-apideck-consumer-id" } }
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  let full_url = (build-url $base ({unified_api: (encode-path-segment $unified_api), service_id: (encode-path-segment $service_id), resource: (encode-path-segment $resource)} | format pattern "/vault/connections/{unified_api}/{service_id}/{resource}/config") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Update settings
#
# PATCH /vault/connections/{unified_api}/{service_id}/{resource}/config
# operationId: connectionSettingsUpdate
export def "connection-settings-update" [
  unified_api: string
  service_id: string
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --configuration: list # item shape: {defaults?: list, resource?: string}
  --enabled: oneof<nothing, bool> # Whether the connection is enabled or not. You can enable or disable a connection using the Update Connection API. (e.g. true)
  --metadata: record # Attach your own consumer specific metadata (nullable, e.g. {account: {id: c01458a5-7276-41ce-bc19-639906b0450a, name: My Company}, plan: enterprise})
  --settings: record # Connection settings. Values will persist to `form_fields` with corresponding id (nullable, e.g. {api_key: 12345xxxxxx, instance_url: https://eu28.salesforce.com})
]: any -> oneof<record<data: record<auth_type: string, authorize_url: string, configurable_resources: list<string>, configuration: list<record>, created_at: float, enabled: bool, form_fields: list<record>, has_guide: bool, icon: string, id: string, integration_state: string, logo: string, metadata: record, name: string, oauth_grant_type: string, resource_schema_support: list<string>, resource_settings_support: list<string>, revoke_url: string, service_id: string, settings: record, settings_required_for_authorization: list<string>, state: string, status: string, subscriptions: list<record>, tag_line: string, unified_api: string, updated_at: float, validation_support: bool, website: string>, status: string, status_code: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($unified_api | is-empty) { error make --unspanned { msg: "path parameter 'unified_api' must be non-empty" } }
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  if ($x_apideck_consumer_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-consumer-id' missing: pass --x-apideck-consumer-id" } }
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  let full_url = (build-url $base ({unified_api: (encode-path-segment $unified_api), service_id: (encode-path-segment $service_id), resource: (encode-path-segment $resource)} | format pattern "/vault/connections/{unified_api}/{service_id}/{resource}/config") $auth.query)
  let req_body = {"configuration": $configuration, "enabled": $enabled, "metadata": $metadata, "settings": $settings} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get all consumers
#
# GET /vault/consumers
# operationId: consumersAll
export def "consumers-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
]: nothing -> oneof<record<data: table<aggregated_request_count: float, application_id: string, consumer_id: string, created: string, metadata: record, modified: string, request_count_updated: string, request_counts: record, services: list>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, status: string, status_code: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vault/consumers" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-app-id": $x_apideck_app_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create consumer
#
# POST /vault/consumers
# operationId: consumersAdd
export def "consumers-add" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  consumer_id: string # Unique consumer identifier. You can freely choose a consumer ID yourself. Most of the time, this is an ID of your internal data model that represents a user or account in your system (for example account:12345). If the consumer doesn't exist yet, Vault will upsert a consumer based on your ID. (e.g. test_consumer_id)
  --metadata: record # The metadata of the consumer. This is used to display the consumer in the sidebar. This is optional, but recommended. — shape: {account_name?: string, email?: string, image?: string, user_name?: string}
]: any -> oneof<record<data: record<aggregated_request_count: float, application_id: string, connections: list<record>, consumer_id: string, created: string, metadata: record<account_name: string, email: string, image: string, user_name: string>, modified: string, request_count_updated: string, request_counts: record<proxy: float, unify: float, vault: float>, services: list<string>>, status: string, status_code: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  let full_url = (build-url $base "/vault/consumers" $auth.query)
  let req_body = {"consumer_id": $consumer_id, "metadata": $metadata} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-app-id": $x_apideck_app_id} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete consumer
#
# DELETE /vault/consumers/{consumer_id}
# operationId: consumersDelete
export def "consumers-delete" [
  consumer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
]: nothing -> oneof<record<data: record<consumer_id: string>, status: string, status_code: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consumer_id | is-empty) { error make --unspanned { msg: "path parameter 'consumer_id' must be non-empty" } }
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  let full_url = (build-url $base ({consumer_id: (encode-path-segment $consumer_id)} | format pattern "/vault/consumers/{consumer_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-app-id": $x_apideck_app_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Get consumer
#
# GET /vault/consumers/{consumer_id}
# operationId: consumersOne
export def "consumers-one" [
  consumer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
]: nothing -> oneof<record<data: record<aggregated_request_count: float, application_id: string, connections: list<record>, consumer_id: string, created: string, metadata: record<account_name: string, email: string, image: string, user_name: string>, modified: string, request_count_updated: string, request_counts: record<proxy: float, unify: float, vault: float>, services: list<string>>, status: string, status_code: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consumer_id | is-empty) { error make --unspanned { msg: "path parameter 'consumer_id' must be non-empty" } }
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  let full_url = (build-url $base ({consumer_id: (encode-path-segment $consumer_id)} | format pattern "/vault/consumers/{consumer_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-app-id": $x_apideck_app_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# Update consumer
#
# PATCH /vault/consumers/{consumer_id}
# operationId: consumersUpdate
export def "consumers-update" [
  consumer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --metadata: record # The metadata of the consumer. This is used to display the consumer in the sidebar. This is optional, but recommended. — shape: {account_name?: string, email?: string, image?: string, user_name?: string}
]: any -> oneof<record<data: record<aggregated_request_count: float, application_id: string, connections: list<record>, consumer_id: string, created: string, metadata: record<account_name: string, email: string, image: string, user_name: string>, modified: string, request_count_updated: string, request_counts: record<proxy: float, unify: float, vault: float>, services: list<string>>, status: string, status_code: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consumer_id | is-empty) { error make --unspanned { msg: "path parameter 'consumer_id' must be non-empty" } }
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  let full_url = (build-url $base ({consumer_id: (encode-path-segment $consumer_id)} | format pattern "/vault/consumers/{consumer_id}") $auth.query)
  let req_body = {"metadata": $metadata} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-app-id": $x_apideck_app_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Consumer request counts
#
# GET /vault/consumers/{consumer_id}/stats
# operationId: consumerRequestCountsAll
export def "consumer-request-counts-all" [
  consumer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-datetime: string # Scopes results to requests that happened after datetime (required, e.g. 2021-05-01T12:00:00.000Z)
  --end-datetime: string # Scopes results to requests that happened before datetime (required, e.g. 2021-05-30T12:00:00.000Z)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
]: nothing -> oneof<record<data: record<aggregated_request_count: float, application_id: string, consumer_id: string, end_datetime: string, request_counts: record<proxy: float, unify: float, vault: float>, start_datetime: string>, status: string, status_code: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consumer_id | is-empty) { error make --unspanned { msg: "path parameter 'consumer_id' must be non-empty" } }
  if ($start_datetime == null) { error make --unspanned { msg: "required query parameter 'start_datetime' missing: pass --start-datetime" } }
  if ($end_datetime == null) { error make --unspanned { msg: "required query parameter 'end_datetime' missing: pass --end-datetime" } }
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  let qp = [(serialize-qp "start_datetime" $start_datetime "scalar") (serialize-qp "end_datetime" $end_datetime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({consumer_id: (encode-path-segment $consumer_id)} | format pattern "/vault/consumers/{consumer_id}/stats") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-app-id": $x_apideck_app_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start_datetime": $start_datetime, "end_datetime": $end_datetime} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all consumer request logs
#
# GET /vault/logs
# operationId: logsAll
export def "logs-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Filter results
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
]: nothing -> oneof<record<data: table<api_style: string, base_url: string, child_request: bool, consumer_id: string, duration: float, error_message: string, execution: int, has_children: bool, http_method: string, id: string, latency: float, operation: record, parent_id: string, path: string, sandbox: bool, service: record, source_ip: string, status_code: int, success: bool, timestamp: string, unified_api: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, status: string, status_code: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  if ($x_apideck_consumer_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-consumer-id' missing: pass --x-apideck-consumer-id" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vault/logs" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-app-id": $x_apideck_app_id, "x-apideck-consumer-id": $x_apideck_consumer_id} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"filter": $filter, "cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Revoke connection
#
# GET /vault/revoke/{service_id}/{application_id}
# operationId: connectionsRevoke
export def "connections-revoke" [
  service_id: string
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
  --state: string # An opaque value the applications adds to the initial request that the authorization server includes when redirecting the back to the application. This value must be used by the application to prevent CSRF attacks. (required, e.g. eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjb25zdW1lcl9pZCI6InRlc3RfdXNlcl9pZCIsInVuaWZpZWRfYXBpIjoiZGVmYXVsdCIsInNlcnZpY2VfaWQiOiJ0ZWFtbGVhZGVyIiwiYXBwbGljYXRpb25faWQiOiIxMTExIiwiaWF0IjoxNjIyMTI2Nzg3fQ.97_pn1UAXc7mctXBdr15czUNO1jjdQ9sJUOIE_Myzbk)
  --redirect-uri: string # URL to redirect back to after authorization. When left empty the default configured redirect uri will be used. (required, e.g. http://example.com/integrations)
]: nothing -> oneof<record<detail: any, error: string, message: string, ref: string, status_code: float, type_name: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application_id' must be non-empty" } }
  if ($state == null) { error make --unspanned { msg: "required query parameter 'state' missing: pass --state" } }
  if ($redirect_uri == null) { error make --unspanned { msg: "required query parameter 'redirect_uri' missing: pass --redirect-uri" } }
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id), application_id: (encode-path-segment $application_id)} | format pattern "/vault/revoke/{service_id}/{application_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"state": $state, "redirect_uri": $redirect_uri} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [301]
}

# Create Session
#
# POST /vault/sessions
# operationId: sessionsCreate
export def "sessions-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from (required)
  --x-apideck-app-id: string # The ID of your Unify application (required, e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --consumer-metadata: record # The metadata of the consumer. This is used to display the consumer in the sidebar. This is optional, but recommended. — shape: {account_name?: string, email?: string, image?: string, user_name?: string}
  --custom-consumer-settings: record # Custom consumer settings that are passed as part of the session. (e.g. {feature_flag_1: true, tax_rates: [{id: 6, label: 6%}, {id: 21, label: 21%}]})
  --redirect-uri: string # The URL to redirect the user to after the session has been configured. (e.g. https://mysaas.com/dashboard)
  --settings: record # Settings to change the way the Vault is displayed. — shape: {allow_actions?: list<string>, auto_redirect?: bool, hide_guides?: bool, hide_resource_settings?: bool, isolation_mode?: bool, sandbox_mode?: bool, session_length?: string, show_logs?: bool, show_sidebar?: bool, show_suggestions?: bool, unified_apis?: list<string>}
  --theme: record # Theming options to change the look and feel of Vault. — shape: {favicon?: string, logo?: string, primary_color?: string, privacy_url?: string, sidepanel_background_color?: string, sidepanel_text_color?: string, terms_url?: string, vault_name?: string}
]: any -> oneof<record<data: record<session_token: string, session_uri: string>, status: string, status_code: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($x_apideck_consumer_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-consumer-id' missing: pass --x-apideck-consumer-id" } }
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  let full_url = (build-url $base "/vault/sessions" $auth.query)
  let req_body = {"consumer_metadata": $consumer_metadata, "custom_consumer_settings": $custom_consumer_settings, "redirect_uri": $redirect_uri, "settings": $settings, "theme": $theme} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
