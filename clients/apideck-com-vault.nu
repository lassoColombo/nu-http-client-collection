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
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "x-apideck-app-id" => { {scheme: $scheme, headers: {x-apideck-app-id: $token_val}, query: "", location: "header"} }
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "vault-authorize get-connections" } } | get name | first)
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

# Authorize
#
# GET /vault/authorize/{service_id}/{application_id}
# operationId: connectionsAuthorize
export def "vault-authorize get-connections" [
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
  --state: string # An opaque value the applications adds to the initial request that the authorization server includes when redirecting the back to the application. This value must be used by the application to prevent CSRF attacks. (e.g. eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjb25zdW1lcl9pZCI6InRlc3RfdXNlcl9pZCIsInVuaWZpZWRfYXBpIjoiZGVmYXVsdCIsInNlcnZpY2VfaWQiOiJ0ZWFtbGVhZGVyIiwiYXBwbGljYXRpb25faWQiOiIxMTExIiwiaWF0IjoxNjIyMTI2Nzg3fQ.97_pn1UAXc7mctXBdr15czUNO1jjdQ9sJUOIE_Myzbk)
  --redirect-uri: string # URL to redirect back to after authorization. When left empty the default configured redirect uri will be used. (e.g. http://example.com/integrations)
  --scope: list<string> # One or more OAuth scopes to request from the connector. OAuth scopes control the set of resources and operations that are allowed after authorization. Refer to the connector's documentation for the available scopes. (e.g. [openid, leads:write, profile:read])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application_id' must be non-empty" } }
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "scope" $scope "ssv")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id), application_id: (encode-path-segment $application_id)} | format pattern "/vault/authorize/{service_id}/{application_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
export def "vault-callback get-connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string # An opaque value the applications adds to the initial request that the authorization server includes when redirecting the back to the application. This value must be used by the application to prevent CSRF attacks. (e.g. eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjb25zdW1lcl9pZCI6InRlc3RfdXNlcl9pZCIsInVuaWZpZWRfYXBpIjoiZGVmYXVsdCIsInNlcnZpY2VfaWQiOiJ0ZWFtbGVhZGVyIiwiYXBwbGljYXRpb25faWQiOiIxMTExIiwiaWF0IjoxNjIyMTI2Nzg3fQ.97_pn1UAXc7mctXBdr15czUNO1jjdQ9sJUOIE_Myzbk)
  --code: string # An authorization code from the connector which Apideck Vault will later exchange for an access token. (e.g. g0ZGZmNjVmOWI)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "code" $code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vault/callback" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
export def "vault-connections list" [
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
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api" $api "scalar") (serialize-qp "configured" $configured "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vault/connections" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
export def "vault-connections delete" [
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
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($unified_api | is-empty) { error make --unspanned { msg: "path parameter 'unified_api' must be non-empty" } }
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  let full_url = (build-url $base ({unified_api: (encode-path-segment $unified_api), service_id: (encode-path-segment $service_id)} | format pattern "/vault/connections/{unified_api}/{service_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id} | compact
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

# Get connection
#
# GET /vault/connections/{unified_api}/{service_id}
# operationId: connectionsOne
export def "vault-connections get-one" [
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
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($unified_api | is-empty) { error make --unspanned { msg: "path parameter 'unified_api' must be non-empty" } }
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  let full_url = (build-url $base ({unified_api: (encode-path-segment $unified_api), service_id: (encode-path-segment $service_id)} | format pattern "/vault/connections/{unified_api}/{service_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id} | compact
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

# Update connection
#
# PATCH /vault/connections/{unified_api}/{service_id}
# operationId: connectionsUpdate
# --configuration item shape: {defaults?: list, resource?: string}
# --form_fields item shape: {allow_custom_values?: bool, custom_field?: bool, description?: string, disabled?: bool, hidden?: bool, id?: string, label?: string, options?: list, placeholder?: string, prefix?: string, required?: bool, sensitive?: bool, suffix?: string, type?: "text"|"checkbox"|"tel"|"email"|"url"|"textarea"|"select"|"filtered-select"|"multi-select"|"datetime"|"date"|"time"|"number"}
# --subscriptions item shape: {created_at?: string, downstream_event_types?: list<string>, downstream_id?: string, execute_url?: string, unify_event_types?: list<string>}
export def "vault-connections update" [
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
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --configuration: list # item shape: {defaults?: list, resource?: string}
  --enabled: oneof<nothing, bool> # Whether the connection is enabled or not. You can enable or disable a connection using the Update Connection API. (e.g. true)
  --metadata: record # Attach your own consumer specific metadata (nullable, e.g. {account: {id: c01458a5-7276-41ce-bc19-639906b0450a, name: My Company}, plan: enterprise})
  --settings: record # Connection settings. Values will persist to `form_fields` with corresponding id (nullable, e.g. {api_key: 12345xxxxxx, instance_url: https://eu28.salesforce.com})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($unified_api | is-empty) { error make --unspanned { msg: "path parameter 'unified_api' must be non-empty" } }
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  let full_url = (build-url $base ({unified_api: (encode-path-segment $unified_api), service_id: (encode-path-segment $service_id)} | format pattern "/vault/connections/{unified_api}/{service_id}") $auth.query)
  let req_body = {"configuration": $configuration, "enabled": $enabled, "metadata": $metadata, "settings": $settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
# --configuration item shape: {defaults?: list, resource?: string}
# --form_fields item shape: {allow_custom_values?: bool, custom_field?: bool, description?: string, disabled?: bool, hidden?: bool, id?: string, label?: string, options?: list, placeholder?: string, prefix?: string, required?: bool, sensitive?: bool, suffix?: string, type?: "text"|"checkbox"|"tel"|"email"|"url"|"textarea"|"select"|"filtered-select"|"multi-select"|"datetime"|"date"|"time"|"number"}
# --subscriptions item shape: {created_at?: string, downstream_event_types?: list<string>, downstream_id?: string, execute_url?: string, unify_event_types?: list<string>}
export def "vault-connections create" [
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
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --configuration: list # item shape: {defaults?: list, resource?: string}
  --enabled: oneof<nothing, bool> # Whether the connection is enabled or not. You can enable or disable a connection using the Update Connection API. (e.g. true)
  --metadata: record # Attach your own consumer specific metadata (nullable, e.g. {account: {id: c01458a5-7276-41ce-bc19-639906b0450a, name: My Company}, plan: enterprise})
  --settings: record # Connection settings. Values will persist to `form_fields` with corresponding id (nullable, e.g. {api_key: 12345xxxxxx, instance_url: https://eu28.salesforce.com})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($unified_api | is-empty) { error make --unspanned { msg: "path parameter 'unified_api' must be non-empty" } }
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  let full_url = (build-url $base ({unified_api: (encode-path-segment $unified_api), service_id: (encode-path-segment $service_id)} | format pattern "/vault/connections/{unified_api}/{service_id}") $auth.query)
  let req_body = {"configuration": $configuration, "enabled": $enabled, "metadata": $metadata, "settings": $settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id} | compact
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

# Import connection
#
# POST /vault/connections/{unified_api}/{service_id}/import
# operationId: connectionsImport
# --credentials shape: {access_token?: string, expires_in?: int, issued_at?: string, refresh_token: string}
export def "vault-connections-import import" [
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
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --credentials: record # e.g. {access_token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c, refresh_token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.cThIIoDvwdueQB468K5xDc5633seEFoqwxjF_xSJyQQ} — shape: {access_token?: string, expires_in?: int, issued_at?: string, refresh_token: string}
  --metadata: record # Attach your own consumer specific metadata (nullable, e.g. {account: {id: c01458a5-7276-41ce-bc19-639906b0450a, name: My Company}, plan: enterprise})
  --settings: record # Connection settings. Values will persist to `form_fields` with corresponding id (nullable, e.g. {instance_url: https://eu28.salesforce.com})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($unified_api | is-empty) { error make --unspanned { msg: "path parameter 'unified_api' must be non-empty" } }
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  let full_url = (build-url $base ({unified_api: (encode-path-segment $unified_api), service_id: (encode-path-segment $service_id)} | format pattern "/vault/connections/{unified_api}/{service_id}/import") $auth.query)
  let req_body = {"credentials": $credentials, "metadata": $metadata, "settings": $settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id} | compact
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

# Get Access Token
#
# POST /vault/connections/{unified_api}/{service_id}/token
# operationId: connectionsToken
export def "vault-connections-token create" [
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
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($unified_api | is-empty) { error make --unspanned { msg: "path parameter 'unified_api' must be non-empty" } }
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  let full_url = (build-url $base ({unified_api: (encode-path-segment $unified_api), service_id: (encode-path-segment $service_id)} | format pattern "/vault/connections/{unified_api}/{service_id}/token") $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id} | compact
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

# Get resource settings
#
# GET /vault/connections/{unified_api}/{service_id}/{resource}/config
# operationId: connectionSettingsAll
export def "vault-connections-config list-settings" [
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
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($unified_api | is-empty) { error make --unspanned { msg: "path parameter 'unified_api' must be non-empty" } }
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  let full_url = (build-url $base ({unified_api: (encode-path-segment $unified_api), service_id: (encode-path-segment $service_id), resource: (encode-path-segment $resource)} | format pattern "/vault/connections/{unified_api}/{service_id}/{resource}/config") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id} | compact
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

# Update settings
#
# PATCH /vault/connections/{unified_api}/{service_id}/{resource}/config
# operationId: connectionSettingsUpdate
# --configuration item shape: {defaults?: list, resource?: string}
# --form_fields item shape: {allow_custom_values?: bool, custom_field?: bool, description?: string, disabled?: bool, hidden?: bool, id?: string, label?: string, options?: list, placeholder?: string, prefix?: string, required?: bool, sensitive?: bool, suffix?: string, type?: "text"|"checkbox"|"tel"|"email"|"url"|"textarea"|"select"|"filtered-select"|"multi-select"|"datetime"|"date"|"time"|"number"}
# --subscriptions item shape: {created_at?: string, downstream_event_types?: list<string>, downstream_id?: string, execute_url?: string, unify_event_types?: list<string>}
export def "vault-connections-config update-settings" [
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
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --configuration: list # item shape: {defaults?: list, resource?: string}
  --enabled: oneof<nothing, bool> # Whether the connection is enabled or not. You can enable or disable a connection using the Update Connection API. (e.g. true)
  --metadata: record # Attach your own consumer specific metadata (nullable, e.g. {account: {id: c01458a5-7276-41ce-bc19-639906b0450a, name: My Company}, plan: enterprise})
  --settings: record # Connection settings. Values will persist to `form_fields` with corresponding id (nullable, e.g. {api_key: 12345xxxxxx, instance_url: https://eu28.salesforce.com})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($unified_api | is-empty) { error make --unspanned { msg: "path parameter 'unified_api' must be non-empty" } }
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  let full_url = (build-url $base ({unified_api: (encode-path-segment $unified_api), service_id: (encode-path-segment $service_id), resource: (encode-path-segment $resource)} | format pattern "/vault/connections/{unified_api}/{service_id}/{resource}/config") $auth.query)
  let req_body = {"configuration": $configuration, "enabled": $enabled, "metadata": $metadata, "settings": $settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
export def "vault-consumers list" [
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
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vault/consumers" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-app-id": $x_apideck_app_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
# --connections item shape: {consumer_id?: string, created_at?: string, enabled?: bool, icon?: string, logo?: string, metadata?: record, name?: string, service_id?: string, settings?: record, state?: "available"|"callable"|"added"|"configured"|"authorized", unified_api?: string, updated_at?: string}
# --metadata shape: {account_name?: string, email?: string, image?: string, user_name?: string}
# --request_counts shape: {proxy?: float, unify?: float, vault?: float}
export def "vault-consumers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  consumer_id: string # Unique consumer identifier. You can freely choose a consumer ID yourself. Most of the time, this is an ID of your internal data model that represents a user or account in your system (for example account:12345). If the consumer doesn't exist yet, Vault will upsert a consumer based on your ID. (e.g. test_consumer_id)
  --metadata: record # The metadata of the consumer. This is used to display the consumer in the sidebar. This is optional, but recommended. — shape: {account_name?: string, email?: string, image?: string, user_name?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vault/consumers" $auth.query)
  let req_body = {"consumer_id": $consumer_id, "metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-app-id": $x_apideck_app_id} | compact
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

# Delete consumer
#
# DELETE /vault/consumers/{consumer_id}
# operationId: consumersDelete
export def "vault-consumers delete" [
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
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consumer_id | is-empty) { error make --unspanned { msg: "path parameter 'consumer_id' must be non-empty" } }
  let full_url = (build-url $base ({consumer_id: (encode-path-segment $consumer_id)} | format pattern "/vault/consumers/{consumer_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-app-id": $x_apideck_app_id} | compact
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
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Get consumer
#
# GET /vault/consumers/{consumer_id}
# operationId: consumersOne
export def "vault-consumers get-one" [
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
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consumer_id | is-empty) { error make --unspanned { msg: "path parameter 'consumer_id' must be non-empty" } }
  let full_url = (build-url $base ({consumer_id: (encode-path-segment $consumer_id)} | format pattern "/vault/consumers/{consumer_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-app-id": $x_apideck_app_id} | compact
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

# Update consumer
#
# PATCH /vault/consumers/{consumer_id}
# operationId: consumersUpdate
# --metadata shape: {account_name?: string, email?: string, image?: string, user_name?: string}
export def "vault-consumers update" [
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
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --metadata: record # The metadata of the consumer. This is used to display the consumer in the sidebar. This is optional, but recommended. — shape: {account_name?: string, email?: string, image?: string, user_name?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consumer_id | is-empty) { error make --unspanned { msg: "path parameter 'consumer_id' must be non-empty" } }
  let full_url = (build-url $base ({consumer_id: (encode-path-segment $consumer_id)} | format pattern "/vault/consumers/{consumer_id}") $auth.query)
  let req_body = {"metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-app-id": $x_apideck_app_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
export def "vault-consumers-stats request-counts-list" [
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
  --start-datetime: string # Scopes results to requests that happened after datetime (e.g. 2021-05-01T12:00:00.000Z)
  --end-datetime: string # Scopes results to requests that happened before datetime (e.g. 2021-05-30T12:00:00.000Z)
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($consumer_id | is-empty) { error make --unspanned { msg: "path parameter 'consumer_id' must be non-empty" } }
  let qp = [(serialize-qp "start_datetime" $start_datetime "scalar") (serialize-qp "end_datetime" $end_datetime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({consumer_id: (encode-path-segment $consumer_id)} | format pattern "/vault/consumers/{consumer_id}/stats") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-app-id": $x_apideck_app_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
export def "vault-logs list" [
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
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vault/logs" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-app-id": $x_apideck_app_id, "x-apideck-consumer-id": $x_apideck_consumer_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
export def "vault-revoke delete-connections" [
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
  --state: string # An opaque value the applications adds to the initial request that the authorization server includes when redirecting the back to the application. This value must be used by the application to prevent CSRF attacks. (e.g. eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjb25zdW1lcl9pZCI6InRlc3RfdXNlcl9pZCIsInVuaWZpZWRfYXBpIjoiZGVmYXVsdCIsInNlcnZpY2VfaWQiOiJ0ZWFtbGVhZGVyIiwiYXBwbGljYXRpb25faWQiOiIxMTExIiwiaWF0IjoxNjIyMTI2Nzg3fQ.97_pn1UAXc7mctXBdr15czUNO1jjdQ9sJUOIE_Myzbk)
  --redirect-uri: string # URL to redirect back to after authorization. When left empty the default configured redirect uri will be used. (e.g. http://example.com/integrations)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'service_id' must be non-empty" } }
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'application_id' must be non-empty" } }
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id), application_id: (encode-path-segment $application_id)} | format pattern "/vault/revoke/{service_id}/{application_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
# --consumer_metadata shape: {account_name?: string, email?: string, image?: string, user_name?: string}
# --settings shape: {allow_actions?: list<string>, auto_redirect?: bool, hide_guides?: bool, hide_resource_settings?: bool, isolation_mode?: bool, sandbox_mode?: bool, session_length?: string, show_logs?: bool, show_sidebar?: bool, show_suggestions?: bool, unified_apis?: list<string>}
# --theme shape: {favicon?: string, logo?: string, primary_color?: string, privacy_url?: string, sidepanel_background_color?: string, sidepanel_text_color?: string, terms_url?: string, vault_name?: string}
export def "vault-sessions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --consumer-metadata: record # The metadata of the consumer. This is used to display the consumer in the sidebar. This is optional, but recommended. — shape: {account_name?: string, email?: string, image?: string, user_name?: string}
  --custom-consumer-settings: record # Custom consumer settings that are passed as part of the session. (e.g. {feature_flag_1: true, tax_rates: [{id: 6, label: 6%}, {id: 21, label: 21%}]})
  --redirect-uri: string # The URL to redirect the user to after the session has been configured. (e.g. https://mysaas.com/dashboard)
  --settings: record # Settings to change the way the Vault is displayed. — shape: {allow_actions?: list<string>, auto_redirect?: bool, hide_guides?: bool, hide_resource_settings?: bool, isolation_mode?: bool, sandbox_mode?: bool, session_length?: string, show_logs?: bool, show_sidebar?: bool, show_suggestions?: bool, unified_apis?: list<string>}
  --theme: record # Theming options to change the look and feel of Vault. — shape: {favicon?: string, logo?: string, primary_color?: string, privacy_url?: string, sidepanel_background_color?: string, sidepanel_text_color?: string, terms_url?: string, vault_name?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vault/sessions" $auth.query)
  let req_body = {"consumer_metadata": $consumer_metadata, "custom_consumer_settings": $custom_consumer_settings, "redirect_uri": $redirect_uri, "settings": $settings, "theme": $theme} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id} | compact
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
