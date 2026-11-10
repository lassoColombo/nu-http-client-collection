# Auto-generated client for Proxy API v9.3.0
# Source: https://api.apis.guru/v2/specs/apideck.com/proxy/9.3.0/openapi.json
# Auth: --token flag or $env.PROXY_API_TOKEN

const BASE_URL = "https://unify.apideck.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o PROXY_API_TOKEN | default "" }
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

# OPTIONS — bodyless
def send-options [req: record, insecure: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http options --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure $req.url
  $resp | handle-response $allow_errors $full $ok_codes
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

def base-url-completer [] { ["https://unify.apideck.com"] }
def auth-scheme-completer [] { ["bearer" "x-apideck-app-id"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["delete-proxy" "get-proxy" "options-proxy" "patch-proxy" "post-proxy" "put-proxy" "commands"] | sort) } | get name | first)
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

# DELETE
#
# DELETE /proxy
# operationId: deleteProxy
export def "delete-proxy" [
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
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API. (required, e.g. close)
  --x-apideck-downstream-url: string # Downstream URL (required, e.g. https://api.close.com/api/v1/lead)
  --x-apideck-downstream-authorization: string # Downstream authorization header. This will skip the Vault token injection. (e.g. Bearer XXXXXXXXXXXXXXXXX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($x_apideck_consumer_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-consumer-id' missing: pass --x-apideck-consumer-id" } }
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  if ($x_apideck_service_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-service-id' missing: pass --x-apideck-service-id" } }
  if ($x_apideck_downstream_url == null) { error make --unspanned { msg: "required header parameter 'x-apideck-downstream-url' missing: pass --x-apideck-downstream-url" } }
  let full_url = (build-url $base "/proxy" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id, "x-apideck-downstream-url": $x_apideck_downstream_url, "x-apideck-downstream-authorization": $x_apideck_downstream_authorization} | compact
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

# GET
#
# GET /proxy
# operationId: getProxy
export def "get-proxy" [
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
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API. (required, e.g. close)
  --x-apideck-downstream-url: string # Downstream URL (required, e.g. https://api.close.com/api/v1/lead)
  --x-apideck-downstream-authorization: string # Downstream authorization header. This will skip the Vault token injection. (e.g. Bearer XXXXXXXXXXXXXXXXX)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($x_apideck_consumer_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-consumer-id' missing: pass --x-apideck-consumer-id" } }
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  if ($x_apideck_service_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-service-id' missing: pass --x-apideck-service-id" } }
  if ($x_apideck_downstream_url == null) { error make --unspanned { msg: "required header parameter 'x-apideck-downstream-url' missing: pass --x-apideck-downstream-url" } }
  let full_url = (build-url $base "/proxy" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id, "x-apideck-downstream-url": $x_apideck_downstream_url, "x-apideck-downstream-authorization": $x_apideck_downstream_authorization} | compact
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

# OPTIONS
#
# OPTIONS /proxy
# operationId: optionsProxy
export def "options-proxy" [
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
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API. (required, e.g. close)
  --x-apideck-downstream-url: string # Downstream URL (required, e.g. https://api.close.com/api/v1/lead)
  --x-apideck-downstream-authorization: string # Downstream authorization header. This will skip the Vault token injection. (e.g. Bearer XXXXXXXXXXXXXXXXX)
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($x_apideck_consumer_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-consumer-id' missing: pass --x-apideck-consumer-id" } }
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  if ($x_apideck_service_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-service-id' missing: pass --x-apideck-service-id" } }
  if ($x_apideck_downstream_url == null) { error make --unspanned { msg: "required header parameter 'x-apideck-downstream-url' missing: pass --x-apideck-downstream-url" } }
  let full_url = (build-url $base "/proxy" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id, "x-apideck-downstream-url": $x_apideck_downstream_url, "x-apideck-downstream-authorization": $x_apideck_downstream_authorization} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "options"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-options $req $insecure $allow_errors $full [200]
}

# PATCH
#
# PATCH /proxy
# operationId: patchProxy
export def "patch-proxy" [
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
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API. (required, e.g. close)
  --x-apideck-downstream-url: string # Downstream URL (required, e.g. https://api.close.com/api/v1/lead)
  --x-apideck-downstream-authorization: string # Downstream authorization header. This will skip the Vault token injection. (e.g. Bearer XXXXXXXXXXXXXXXXX)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($x_apideck_consumer_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-consumer-id' missing: pass --x-apideck-consumer-id" } }
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  if ($x_apideck_service_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-service-id' missing: pass --x-apideck-service-id" } }
  if ($x_apideck_downstream_url == null) { error make --unspanned { msg: "required header parameter 'x-apideck-downstream-url' missing: pass --x-apideck-downstream-url" } }
  let full_url = (build-url $base "/proxy" $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id, "x-apideck-downstream-url": $x_apideck_downstream_url, "x-apideck-downstream-authorization": $x_apideck_downstream_authorization} | compact
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

# POST
#
# POST /proxy
# operationId: postProxy
export def "post-proxy" [
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
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API. (required, e.g. close)
  --x-apideck-downstream-url: string # Downstream URL (required, e.g. https://api.close.com/api/v1/lead)
  --x-apideck-downstream-authorization: string # Downstream authorization header. This will skip the Vault token injection. (e.g. Bearer XXXXXXXXXXXXXXXXX)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($x_apideck_consumer_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-consumer-id' missing: pass --x-apideck-consumer-id" } }
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  if ($x_apideck_service_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-service-id' missing: pass --x-apideck-service-id" } }
  if ($x_apideck_downstream_url == null) { error make --unspanned { msg: "required header parameter 'x-apideck-downstream-url' missing: pass --x-apideck-downstream-url" } }
  let full_url = (build-url $base "/proxy" $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id, "x-apideck-downstream-url": $x_apideck_downstream_url, "x-apideck-downstream-authorization": $x_apideck_downstream_authorization} | compact
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

# PUT
#
# PUT /proxy
# operationId: putProxy
export def "put-proxy" [
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
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API. (required, e.g. close)
  --x-apideck-downstream-url: string # Downstream URL (required, e.g. https://api.close.com/api/v1/lead)
  --x-apideck-downstream-authorization: string # Downstream authorization header. This will skip the Vault token injection. (e.g. Bearer XXXXXXXXXXXXXXXXX)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($x_apideck_consumer_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-consumer-id' missing: pass --x-apideck-consumer-id" } }
  if ($x_apideck_app_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-app-id' missing: pass --x-apideck-app-id" } }
  if ($x_apideck_service_id == null) { error make --unspanned { msg: "required header parameter 'x-apideck-service-id' missing: pass --x-apideck-service-id" } }
  if ($x_apideck_downstream_url == null) { error make --unspanned { msg: "required header parameter 'x-apideck-downstream-url' missing: pass --x-apideck-downstream-url" } }
  let full_url = (build-url $base "/proxy" $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id, "x-apideck-downstream-url": $x_apideck_downstream_url, "x-apideck-downstream-authorization": $x_apideck_downstream_authorization} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
